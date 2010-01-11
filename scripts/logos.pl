#!/usr/bin/env perl

use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Logos::Method;
use Logos::Group;
use Logos::StaticClassGroup;
use Logos::Subclass;

$filename = $ARGV[0];
die "Syntax: $FindBin::Script filename\n" if !$filename;
open(FILE, $filename) or die "Could not open $filename.\n";

my @inputlines = ();
my $readignore = 0;
my $built = "";
my $building = 0;
READLOOP: while($line = <FILE>) {
	chomp($line);

	# End of a multi-line comment while ignoring input.
	if($readignore && $line =~ /^.*?\*\/\s*/) {
		$readignore = 0;
		$line = $';
	}
	if($readignore) { push(@inputlines, ""); next; }

	my @quotes = quotes($line);

	# Delete all single-line to-EOL // xxx comments.
	while($line =~ /\/\//g) {
		next if fallsBetween($-[0], @quotes);
		$line = $`;
		redo READLOOP;
	}

	# Delete all single-line /* xxx */ comments.
	while($line =~ /\/\*.*?\*\//g) {
		next if fallsBetween($-[0], @quotes);
		$line = $`.$';
		redo READLOOP;
	}
	
	# Start of a multi-line /* comment.
	while($line =~ /\/\*.*$/g) {
		next if fallsBetween($-[0], @quotes);
		$line = $`;
		push(@inputlines, $line);
		$readignore = 1;
		next READLOOP;
	}

	if(!$readignore) {
		# Line starts with - (return), start gluing lines together until we find a { or ;...
		if(!$building && $line =~ /^\s*(%new.*?)?\s*([+-])\s*\(\s*(.*?)\s*\)/ && index($line, "{") == -1 && index($line, ";") == -1) {
			$building = 1;
			$built = $line;
			push(@inputlines, "");
			next;
		} elsif($building) {
			$built .= " ".$line;
			if(index($line,"{") != -1 || index($line,";") != -1) {
				push(@inputlines, $built);
				$building = 0;
				$built = "";
				next;
			}
			push(@inputlines, "");
			next;
		}
		push(@inputlines, $line) if !$readignore;
	}
}

close(FILE);

@outputlines = ();
$lineno = 1;

$firsthookline = -1;
$ctorline = -1;

my $defaultGroup = Group->new();
$defaultGroup->name("_ungrouped");
$defaultGroup->explicit(0);
@groups = ($defaultGroup);

my %illegalNesting = (
	'hook' => ['hook', 'subclass'],
	'subclass' => ['hook', 'group', 'subclass'],
	'group' => ['group', 'subclass']
);

my $staticClassGroup = StaticClassGroup->new();
%classes = ();
%metaclasses = ();

$hassubstrateh = 0;
$ignore = 0;

my @nestingstack = ();
my $inclass = 0;
my $last_blockopen = -1;
my $lastInitLine = -1;
my $curGroup = $defaultGroup;
my $lastMethod;

my $isNewMethod = undef;

foreach $line (@inputlines) {
	# Search for a discrete %x% or an open-ended %x (or %x with a { or ; after it)
	if($line =~ /\s*#\s*include\s*[<"]substrate\.h[">]/) {
		$hassubstrateh = 1;
	} elsif($line =~ /^\s*#\s*if\s*0\s*$/) {
		$ignore = 1;
	} elsif($ignore == 1 && $line =~ /^\s*#\s*endif/) {
		$ignore = 0;
	} elsif($ignore == 0) {
		# %hook name
		my $matched = 0;
		
		# The Big Scanning Loop
		# Why is it this way? Why a giant loop with a bunch of small loops inside ending with redo?
		# Merely so I could use /g global searches for each command type and auto-skip ones in quotes.
		# Without /g, I'd process the same one over and over. /g only makes sense in a loop.
		#
		# We don't want to process in-order, either, so %group %thing %end won't kill itself automatically
		# because it found a %end with the %group. This allows things to proceed out-of-order:
		# we re-start the scan loop every time we find a match so that the commands don't need to
		# be in the processed order on every line. That would be pointless.
		SCANLOOP: while(1) {
			@quotes = quotes($line);

			# %hook at the beginning of a line after any amount of space
			while($line =~ /^\s*%(hook)\s+([\$_\w]+)/g) {
				next if fallsBetween($-[0], @quotes);

				checkIllegalNesting($lineno, $1, @nestingstack);

				$firsthookline = $lineno if $firsthookline == -1;

				nestPush($1, $lineno, \@nestingstack);

				$class = $2;
				$inclass = 1;
				$line = $';

				redo SCANLOOP;
			}

			while($line =~ /^\s*%(subclass)\s+([\$_\w]+)/g) {
				next if fallsBetween($-[0], @quotes);

				checkIllegalNesting($lineno, $1, @nestingstack);

				$firsthookline = $lineno if $firsthookline == -1;

				nestPush($1, $lineno, \@nestingstack);

				$class = $2;

				$curGroup = Subclass->new();
				$curGroup->name($lineno."_".$2);
				$curGroup->class($2);
				push(@groups, $curGroup);

				$inclass = 1;
				$line = $';

				redo SCANLOOP;
			}

			# %group at the beginning of a line after any amount of space
			while($line =~ /^\s*%(group)\s+([\$_\w]+)/g) {
				next if fallsBetween($-[0], @quotes);

				checkIllegalNesting($lineno, $1, @nestingstack);
				nestPush($1, $lineno, \@nestingstack);
				$line = $`.$';

				$curGroup = Group->new();
				$curGroup->name($2);
				push(@groups, $curGroup);

				redo SCANLOOP;
			}
			
			# %group at the beginning of a line after any amount of space
			while($line =~ /^\s*%(class)\s+([+-])?([\$_\w]+)/g) {
				next if fallsBetween($-[0], @quotes);

				# TODO: This will cause a constructor if you use %class but not %hook (blank constructor)
				# Not a really big deal, but still nice to fix. Maybe with a list of patchups instead of
				# "put this hre."
				$firsthookline = $lineno if $firsthookline == -1;

				my $scope = $2;
				$scope = "-" if !$scope;
				$class = $3;
				if($scope eq "+") {
					$staticClassGroup->addUsedMetaClass($class);
				} else {
					$staticClassGroup->addUsedClass($class);
				}
				$classes{$class}++;
				$line = $`.$';

				redo SCANLOOP;
			}
			
			# %new(type) at the beginning of a line after any amount of space
			while($line =~ /^\s*%new(\((.*?)\))?(%?)(?=\W?)/g) {
				next if fallsBetween($-[0], @quotes);

				fileError($lineno, "%new found outside of a %hook") if !nestingContains("hook", @nestingstack);
				my $xtype = "v\@:";
				$xtype = $2 if $2;
				fileWarning($lineno, "%new without a type specifier, assuming v\@: (void return, id and SEL args)") if !$2;
				$isNewMethod = $xtype;
				$line = $`.$';

				redo SCANLOOP;
			}
			
			# - (return), but only when we're in a %hook.
			while($inclass && $line =~ /^\s*([+-])\s*\(\s*(.*?)\s*\)/g) {
				next if fallsBetween($-[0], @quotes);

				my $scope = $1;
				my $return = $2;
				my $selnametext = $';

				my $currentMethod = Method->new();

				$currentMethod->class($class);
				if($scope eq "+") {
					$metaclasses{$class}++;
					$curGroup->addUsedMetaClass($class);
				} else {
					$classes{$class}++;
					$curGroup->addUsedClass($class);
				}

				$currentMethod->scope($scope);
				$currentMethod->return($return);

				if($isNewMethod) {
					$currentMethod->setNew(1);
					$currentMethod->type($isNewMethod);
					$isNewMethod = undef;
				}

				my @selparts = ();

				# word, then an optional: ": (argtype)argname"
				while($selnametext =~ /^\s*([\$\w]*)(:\s*\((.+?)\)\s*([\$\w]+?)\b)?/) {
					last if !$1 && !$2; # Exit the loop if both Keywords and Args are missing: e.g. false positive.

					$keyword = $1; # Add any keyword.
					push(@selparts, $keyword);

					$selnametext = $';

					last if !$2;  # Exit the loop if there are no args (single keyword.)
					$currentMethod->addArgument($3, $4);
				}

				$currentMethod->selectorParts(@selparts);
				$currentMethod->groupIdentifier(sanitize($curGroup->name));
				$curGroup->addMethod($currentMethod);
				$lastMethod = $currentMethod;

				$replacement = $currentMethod->buildMethodSignature;
				$replacement .= $selnametext if $selnametext ne "";
				$line = $replacement;

				redo SCANLOOP;
			}

			while($line =~ /%orig(inal)?(%?)(?=\W?)/g) {
				next if fallsBetween($-[0], @quotes);

				fileError($lineno, "$& found outside of a %hook") if !nestingContains("hook", @nestingstack);
				fileWarning($lineno, "$& in a new method will be non-operative.") if $lastMethod->isNew;

				my $hasparens = 0;
				my $remaining = $';
				$replacement = "";
				if($remaining) {
					# If we encounter a ) that puts us back at zero, we found a (
					# and have reached its closing ).
					my $parenmatch = $remaining;
					my $pdepth = 0;
					my @pquotes = quotes($parenmatch);
					while($parenmatch =~ /[()]/g) {
						next if fallsBetween($-[0], @pquotes);
						if($& eq "(") { $pdepth++; }
						elsif($& eq ")") {
							$pdepth--;
							if($pdepth == 0) { $hasparens = $+[0]; last; }
						}
					}
				}
				if($hasparens > 0) {
					$parenstring = substr($remaining, 1, $hasparens-2);
					$remaining = substr($remaining, $hasparens);
					$replacement .= $lastMethod->buildOriginalCall($parenstring);
				} else {
					$replacement .= $lastMethod->buildOriginalCall;
				}
				$replacement .= $remaining;
				$line = $`.$replacement;

				redo SCANLOOP;
			}
			
			while($line =~ /%log(%?)(?=\W?)/g) {
				next if fallsBetween($-[0], @quotes);

				fileError($lineno, "$& found outside of a %hook") if !nestingContains("hook", @nestingstack);
				$replacement = $lastMethod->buildLogCall;
				$line = $`.$replacement.$';

				redo SCANLOOP;
			}
			
			while($line =~ /%c(onstruc)?tor(%?)(?=\W?)/g) {
				next if fallsBetween($-[0], @quotes);

				fileError($lineno, "$& found inside of a %hook") if nestingContains("hook", @nestingstack);
				$ctorline = $lineno if $ctorline == -1;
				$line = $`.$';

				redo SCANLOOP;
			}

			while($line =~ /%init(\((.*?)\))?(%?);?(?=\W?)/g) {
				next if fallsBetween($-[0], @quotes);

				my $group = "_ungrouped";
				$group = $2 if $2;
				$line = $`.generateInitLines($group).$';
				$ctorline = -2; # "Do not generate a constructor."
				$lastInitLine = $lineno;

				redo SCANLOOP;
			}
			
			# %end (Make it the last thing we check for so we don't terminate something pre-emptively.
			while($line =~ /%end(%?)/g) {
				next if fallsBetween($-[0], @quotes);

				my $closing = nestPop(\@nestingstack);
				fileError($lineno, "dangling %end") if !$closing;
				if($closing eq "group") {
					$curGroup = getGroup("_ungrouped");
				} elsif($closing eq "hook") {
					$inclass = 0;
				}
				$line = $`.$';

				redo SCANLOOP;
			}

			# If we made it here, there are no more non-quoted commands on this line! Yay! Break free!
			last;
		}
	}
	$lineno++;
	push(@outputlines, $line);
}

push(@groups, $staticClassGroup);

if($firsthookline != -1) {
	my $offset = 0;
	if(!$hassubstrateh) {
		splice(@outputlines, $firsthookline - 1, 0, "#include <substrate.h>");
		$offset++;
	}
	splice(@outputlines, $firsthookline - 1 + $offset, 0, generateClassList());
	$offset++;
	splice(@outputlines, $firsthookline - 1 + $offset, 0, $staticClassGroup->declarations);
	$offset++;
	splice(@outputlines, $firsthookline - 1 + $offset, 0, "#line $firsthookline \"$filename\"");
	$offset++;
	if($ctorline == -2) {
		# If the static class list hasn't been initialized, glue it under the last %init line.
		if(!$staticClassGroup->initialized) {
			splice(@outputlines, $lastInitLine + $offset, 0, $staticClassGroup->initializers);
			$offset++;
			splice(@outputlines, $lastInitLine + $offset, 0, "#line ".($lastInitLine+1)." \"$filename\"");
			$offset++;
		}
	} elsif($ctorline != -1) {
		$outputlines[$ctorline + $offset - 1] = generateConstructor();
	} else {
		push(@outputlines, generateConstructor());
	}

}

my @unInitGroups = ();
foreach(@groups) {
	push(@unInitGroups, $_->name) if !$_->initialized && $_->explicit;
}
my $numUnGroups = @unInitGroups;
fileError(-1, "non-initialized hook group".($numUnGroups == 1 ? "" : "s").": ".join(", ", @unInitGroups)) if $numUnGroups > 0;

splice(@outputlines, 0, 0, "#line 0 \"$filename\"");
foreach $oline (@outputlines) {
	print $oline."\n" if defined($oline);
}

sub generateConstructor {
	my $return = "";
	my $explicitGroups = 0;
	foreach(@groups) {
		$explicitGroups++ if $_->explicit;
	}
	fileError($ctorline, "Cannot generate an autoconstructor with multiple %groups. Please explicitly create a constructor.") if $explicitGroups > 1;
	$return .= "static __attribute__((constructor)) void _logosLocalInit() { ";
	$return .= "NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; ";
	foreach(@groups) {
		next if $_->explicit;
		$return .= generateInitLines($_->name)." ";
	}
	$return .= "[pool drain];";
	$return .= " }";
	return $return;
}

sub generateInitLines {
	my $groupname = shift;
	$groupname = "_ungrouped" if !$groupname;
	my $group = getGroup($groupname);

	if(!$group) {
		fileError($lineno, "%init for an undefined %group $groupname");
		return;
	}

	if($group->initialized) {
		fileError($lineno, "re-%init of %group $groupname");
		return;
	}

	my $return = $group->initializers;
	return $return;
}

sub generateClassList {
	my $return = "";
	map $return .= "\@class $_; ", sort keys %classes;
	return $return;
}

sub quotes {
	my ($line) = @_;
	my @quotes = ();
	while($line =~ /(?<!\\)\"/g) {
		push(@quotes, $-[0]);
	}
	return @quotes;
}

sub fallsBetween {
	my $idx = shift;
	while(@_ > 0) {
		my $start = shift;
		my $end = shift;
		return 1 if ($start < $idx && (!defined($end) || $end > $idx))
	}
	return 0;
}

sub fileWarning {
	my $curline = shift;
	my $reason = shift;
	print STDERR "$filename:".($curline > -1 ? "$curline:" : "")." warning: $reason\n";
}

sub fileError {
	my $curline = shift;
	my $reason = shift;
	die "$filename:".($curline > -1 ? "$curline:" : "")." error: $reason\n";
}

sub nestingError {
	my $curline = shift;
	my $thisblock = shift;
	my $reason = shift;
	my @parts = split(/:/, $reason);
	fileError $curline, "%$thisblock inside a %".$parts[0].", opened on ".$parts[1];
}

sub checkIllegalNesting {
	my $lineno = shift;
	my $trying = shift;
	my @stack = @_;
	my @illegals = @{$illegalNesting{$trying}};
	foreach $illegal (@illegals) {
		nestingError($lineno, $trying, $_) if nestingContains($illegal, @stack);
	}
}

sub nestingContains {
	my $find = shift;
	my @stack = @_;
	my @parts = ();
	foreach $nest (@stack) {
		@parts = split(/:/, $nest);
		if($find eq $parts[0]) {
			$_ = $nest;
			return $_;
		}
	}
	$_ = undef;
	return undef;
}

sub nestPush {
	my $type = shift;
	my $line = shift;
	my $ref_stack = shift;
	push(@{$ref_stack}, $type.":".$line);
}

sub nestPop {
	my $ref_stack = shift;
	my $outgoing = pop(@{$ref_stack});
	return undef if !$outgoing;
	my @parts = split(/:/, $outgoing);
	return $parts[0];
}

sub sanitize {
	my $input = shift;
	my $output = $input;
	$output =~ s/[^\w]//g;
	return $output;
}

sub getGroup {
	my $name = shift;
	foreach(@groups) {
		return $_ if $_->name eq $name;
	}
	return undef;
}
