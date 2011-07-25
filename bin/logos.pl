#!/usr/bin/perl

use warnings;
use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Digest::MD5 'md5_hex';
use Module::Load;
use Module::Load::Conditional 'can_load';

%main::CONFIG = ( generator => "MobileSubstrate"
		);

my $filename = $ARGV[0];
die "Syntax: $FindBin::Script filename\n" if !$filename;
open(FILE, $filename) or die "Could not open $filename.\n";

my @lines = ();
my $readignore = 0;
my $built = "";
my $building = 0;
my $preprocessed = 0;

my %lineMapping = ();

{
my $firstline = <FILE>;
seek(FILE, 0, Fcntl::SEEK_SET);
if($firstline =~ /^# \d+ \"(.*?)\"$/) {
	$preprocessed = 1;
	$filename = $1;
}
$.--; # Reset line number.
}

READLOOP: while(my $line = <FILE>) {
	chomp($line);

	if($preprocessed && $line =~ /^# (\d+) \"(.*?)\"/) {
		$lineMapping{$.+1} = [$2, $1];
	}

	# End of a multi-line comment while ignoring input.
	if($readignore && $line =~ /^.*?\*\/\s*/) {
		$readignore = 0;
		$line = $';
	}
	if($readignore) { push(@lines, ""); next; }

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
		push(@lines, $line);
		$readignore = 1;
		next READLOOP;
	}

	if(!$readignore) {
		# Line starts with - (return), start gluing lines together until we find a { or ;...
		if(!$building
				&& (
					$line =~ /^\s*(%new.*?)?\s*([+-])\s*\(\s*(.*?)\s*\)/
					|| $line =~ /%orig\s*\(/
					|| $line =~ /%init\s*\(/
				)
				&& index($line, "{") < $-[0] && index($line, ";") < $-[0]) {
			if(fallsBetween($-[0], @quotes)) {
				push(@lines, $line);
				next;
			}
			$building = 1;
			$built = $line;
			push(@lines, "");
			next;
		} elsif($building) {
			$line =~ s/^\s+//g;
			$built .= " ".$line;
			if(index($line,"{") != -1 || index($line,";") != -1) {
				push(@lines, $built);
				$building = 0;
				$built = "";
				next;
			}
			push(@lines, "");
			next;
		}
		push(@lines, $line) if !$readignore;
	}
}

close(FILE);

$lineMapping{1} = ["$filename", 1] if scalar keys %lineMapping == 0;

# Process the input lines for directives which must be parsed before main processing, such as %config
# Mk. I processing loop - preprocessing.
my $lineno = 1;
my $generatorLine = 1;
foreach my $line (@lines) {
	SCANLOOP: while(1) {
		my @quotes = quotes($line);
		while($line =~ /^\s*%config\s*\(\s*(\w+)\s*=\s*(.*?)\s*\)\s*;/g) {
			next if fallsBetween($-[0], @quotes);
			$line = $';
			$generatorLine = $lineno if($1 eq "generator");
			$main::CONFIG{$1} = $2;
			redo SCANLOOP;
		}
		last;
	}
	$lineno++;
}

my $generatorname = $main::CONFIG{generator};
$Module::Load::Conditional::VERBOSE = 1;
my $GeneratorPackage = "Logos::Generator::$generatorname";
fileError($generatorLine, "I can't find the \"$generatorname\" Generator!") if(!can_load(modules => {
			$GeneratorPackage."::Base" => undef,
		}));

load $GeneratorPackage."::Method";
load $GeneratorPackage."::Class";
load $GeneratorPackage."::Subclass";
load 'Logos::Group';
load $GeneratorPackage."::StaticClassGroup";

$lineno = 1;

my $firsthookline = -1;
my $generateAutoConstructor = 1;

my $defaultGroup = Group->new();
$defaultGroup->name("_ungrouped");
$defaultGroup->explicit(0);
my @groups = ($defaultGroup);

my $staticClassGroup = StaticClassGroup->new();
my %classes = ();

my $hassubstrateh = 0;
my $ignore = 0;

my @nestingstack = ();
my $inclass = 0;
my $class;

my $last_blockopen = -1;
my $lastInitLine = -1;
my $curGroup = $defaultGroup;
my $lastMethod;

my $isNewMethod = undef;

# Mk. II processing loop - directive processing.
foreach my $line (@lines) {
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
			my @quotes = quotes($line);

			# %hook at the beginning of a line after any amount of space
			while($line =~ /^\s*%(hook)\s+([\$_\w]+)/g) {
				next if fallsBetween($-[0], @quotes);

				nestingMustNotContain($lineno, "%$1", \@nestingstack, "hook", "subclass");

				$firsthookline = $lineno if $firsthookline == -1;

				nestPush($1, $lineno, \@nestingstack);

				$class = $curGroup->addClassNamed($2);
				$classes{$class->name}++;
				$inclass = 1;
				$line = $';

				redo SCANLOOP;
			}

			while($line =~ /^\s*%(subclass)\s+([\$_\w]+)\s*:\s*([\$_\w]+)\s*(\<\s*(.*?)\s*\>)?/g) {
				next if fallsBetween($-[0], @quotes);

				nestingMustNotContain($lineno, "%$1", \@nestingstack, "hook", "subclass");

				$firsthookline = $lineno if $firsthookline == -1;

				nestPush($1, $lineno, \@nestingstack);

				fileError($lineno, "cannot add a subclass to initialized group ".$curGroup->name." (initialized at ".lineDescriptionForPhysicalLine($curGroup->initLine).")") if $curGroup->initialized;

				my $classname = $2;
				my $superclassname = $3;
				$class = Subclass->new();
				$class->name($classname);
				$class->superclass($superclassname);
				if(defined($4) && defined($5)) {
					my @protocols = split(/\s*,\s*/, $5);
					foreach(@protocols) {
						$class->addProtocol($_);
					}
				}
				$curGroup->addClass($class);

				$staticClassGroup->addDeclaredOnlyClass($classname);
				$classes{$superclassname}++;
				$classes{$classname}++;

				$inclass = 1;
				$line = $';

				redo SCANLOOP;
			}

			# %group at the beginning of a line after any amount of space
			while($line =~ /^\s*%(group)\s+([\$_\w]+)/g) {
				next if fallsBetween($-[0], @quotes);

				nestingMustNotContain($lineno, "%$1", \@nestingstack, "group");
				nestPush($1, $lineno, \@nestingstack);
				$line = $`.$';

				$curGroup = getGroup($2);
				if(!defined($curGroup)) {
					$curGroup = Group->new();
					$curGroup->name($2);
					push(@groups, $curGroup);
				}

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
				my $classname = $3;
				if($scope eq "+") {
					$staticClassGroup->addUsedMetaClass($classname);
				} else {
					$staticClassGroup->addUsedClass($classname);
				}
				$classes{$classname}++;
				$line = $`.$';

				redo SCANLOOP;
			}
			
			while($line =~ /%c\(\s*([+-])?([\$_\w]+)\s*\)/g) {
				next if fallsBetween($-[0], @quotes);

				# TODO: Same caveats as %class.
				$firsthookline = $lineno if $firsthookline == -1;

				my $scope = $1;
				$scope = "-" if !$scope;
				my $classname = $2;
				if($scope eq "+") {
					$staticClassGroup->addUsedMetaClass($classname);
				} else {
					$staticClassGroup->addUsedClass($classname);
				}
				$classes{$classname}++;
				$line = $`.Generator->classReferenceWithScope($classname, $scope).$';

				redo SCANLOOP;
			}
			
			# %new(type) at the beginning of a line after any amount of space
			while($line =~ /^\s*%new(\((.*?)\))?(?=\W?)/g) {
				next if fallsBetween($-[0], @quotes);

				nestingMustContain($lineno, "%new", \@nestingstack, "hook", "subclass");
				my $xtype = "";
				$xtype = $2 if $2;
				$isNewMethod = $xtype;
				$line = $`.$';

				redo SCANLOOP;
			}
			
			# - (return), but only when we're in a %hook.
			while($inclass && $line =~ /^\s*([+-])\s*\(\s*(.*?)\s*\)/g) {
				next if fallsBetween($-[0], @quotes);

				# Gasp! We've been moved to a different group!
				if($class->group != $curGroup) {
					my $classname = $class->name;
					$class = $curGroup->addClassNamed($classname);
				}

				my $scope = $1;
				my $return = $2;
				my $selnametext = $';

				fileError($lineno, "cannot add hooks to initialized group ".$curGroup->name." (initialized at ".lineDescriptionForPhysicalLine($curGroup->initLine).")") if $curGroup->initialized;
				my $currentMethod = Method->new();

				$currentMethod->class($class);
				if($scope eq "+") {
					$class->hasmetahooks(1);
				} else {
					$class->hasinstancehooks(1);
				}

				$currentMethod->scope($scope);
				$currentMethod->return($return);

				if(defined $isNewMethod) {
					$currentMethod->setNew(1);
					$currentMethod->type($isNewMethod);
					$isNewMethod = undef;
				}

				my @selparts = ();

				# word, then an optional: ": (argtype)argname"
				while($selnametext =~ /^\s*([\$\w]*)(:\s*\((.+?)\)\s*([\$\w]+?)\b)?/) {
					last if !$1 && !$2; # Exit the loop if both Keywords and Args are missing: e.g. false positive.

					my $keyword = $1; # Add any keyword.
					push(@selparts, $keyword);

					$selnametext = $';

					last if !$2;  # Exit the loop if there are no args (single keyword.)
					$currentMethod->addArgument($3, $4);
				}

				$currentMethod->selectorParts(@selparts);
				$class->addMethod($currentMethod);
				$lastMethod = $currentMethod;

				my $replacement = $currentMethod->methodSignature;
				$replacement .= $selnametext if $selnametext ne "";
				$line = $replacement;

				redo SCANLOOP;
			}

			while($line =~ /%orig(?=\W?)/g) {
				next if fallsBetween($-[0], @quotes);

				nestingMustContain($lineno, $&, \@nestingstack, "hook", "subclass");
				fileWarning($lineno, "$& in a new method will be non-operative.") if $lastMethod->isNew;

				my $before = $`;
				my $remaining = $';
				my $replacement = "";
				my @p = nestedParenString($remaining);
				$replacement .= $lastMethod->originalCall($p[0]);
				$replacement .= $p[1];
				$line = $before.$replacement;

				redo SCANLOOP;
			}
			
			while($line =~ /%log(?=\W?)/g) {
				next if fallsBetween($-[0], @quotes);

				nestingMustContain($lineno, $&, \@nestingstack, "hook", "subclass");
				$line = $`.$lastMethod->buildLogCall.$';

				redo SCANLOOP;
			}
			
			while($line =~ /%ctor(?=\W?)/g) {
				next if fallsBetween($-[0], @quotes);

				nestingMustNotContain($lineno, $&, \@nestingstack, "hook", "subclass");
				my $replacement = "static __attribute__((constructor)) void _logosLocalCtor_".substr(md5_hex($`.$lineno.$'), 0, 8)."()";
				$line = $`.$replacement.$';

				redo SCANLOOP;
			}

			while($line =~ /%init(?=\W?)/g) {
				next if fallsBetween($-[0], @quotes);

				my $before = $`;
				my $after = $';

				my $groupname = "_ungrouped";
				my @p = nestedParenString($after);
				my @args;
				@args = smartSplit(qr/\s*,\s*/, $p[0]) if defined($p[0]);
				$after = $p[1];

				my $tempgroupname = undef;
				$tempgroupname = $args[0] if $args[0] && $args[0] !~ /=/;
				if(defined($tempgroupname)) {
					$groupname = $tempgroupname;
					shift(@args);
				}

				my $group = getGroup($groupname);

				foreach my $arg (@args) {
					if($arg !~ /=/) {
						fileWarning($lineno, "unknown argument to %init: $arg");
						next;
					}

					my @parts = smartSplit(qr/\s*=\s*/, $arg, 2);
					if(!defined($parts[0]) || !defined($parts[1])) {
						fileWarning($lineno, "invalid class=expr in %init");
						next;
					}

					my $classname = $parts[0];
					my $expr = $parts[1];
					my $scope = "-";
					if($classname =~ /^([+-])/) {
						$scope = $1;
						$classname = $';
					}

					my $class = $group->getClassNamed($classname);
					if(!defined($class)) {
						fileWarning($lineno, "tried to set expression for unknown class $classname in group $groupname");
						next;
					}

					$class->expression($expr) if $scope eq "-";
					$class->metaexpression($expr) if $scope eq "+";
				}

				if(!$group) {
					fileError($lineno, "%init for an undefined %group $groupname");
				}

				my $initLines = generateInitLines($group);
				if($groupname eq "_ungrouped") {
					$initLines = "{".$initLines.generateInitLines($staticClassGroup)."}";
				}
				$after =~ s/^\s*;//g; # Remove the first ; after %init.
				$line = $before.$initLines.$after;
				$generateAutoConstructor = 0; # "Do not generate a constructor."
				$lastInitLine = $lineno;

				redo SCANLOOP;
			}
			
			# %end (Make it the last thing we check for so we don't terminate something pre-emptively.
			while($line =~ /%end/g) {
				next if fallsBetween($-[0], @quotes);

				my $closing = nestPop(\@nestingstack);
				fileError($lineno, "dangling %end") if !$closing;
				if($closing eq "group") {
					$curGroup = getGroup("_ungrouped");
				} 
				if($closing eq "hook" || $closing eq "subclass") {
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
}

while(scalar(@nestingstack) > 0) {
	my $closing = pop(@nestingstack);
	my @parts = split(/:/, $closing);
	fileWarning($lineno, "missing %end (%".$parts[0]." opened at ".lineDescriptionForPhysicalLine($parts[1])." extends to EOF)");
}

# Always insert $staticClassGroup after _ungrouped.
splice(@groups, 1, 0, $staticClassGroup);

$hassubstrateh = 1 if($preprocessed);

if($firsthookline != -1) {
	my $offset = 0;
	if(!$hassubstrateh) {
		splice(@lines, $firsthookline - 1, 0, "#include <substrate.h>");
		$offset++;
	}
	splice(@lines, $firsthookline - 1 + $offset, 0, Generator->generateClassList(keys %classes));
	$offset++;
	splice(@lines, $firsthookline - 1 + $offset, 0, $staticClassGroup->declarations);
	$offset++;

	splice(@lines, $firsthookline - 1 + $offset, 0, generateLineDirectiveForPhysicalLine($firsthookline));
	$offset++;

	if(!$generateAutoConstructor) {
		# If the static class list hasn't been initialized, glue it under the last %init line.
		if(!$staticClassGroup->initialized) {
			splice(@lines, $lastInitLine + $offset, 0, $staticClassGroup->initializers);
			$offset++;
			splice(@lines, $lastInitLine + $offset, 0, generateLineDirectiveForPhysicalLine($lastInitLine));
			$offset++;
		}
	} else {
		push(@lines, generateConstructor());
	}

}

my @unInitGroups = ();
foreach(@groups) {
	push(@unInitGroups, $_->name) if !$_->initialized && $_->explicit;
}
my $numUnGroups = @unInitGroups;
fileError($lineno, "non-initialized hook group".($numUnGroups == 1 ? "" : "s").": ".join(", ", @unInitGroups)) if $numUnGroups > 0;

splice(@lines, 0, 0, generateLineDirectiveForPhysicalLine(1)) if !$preprocessed;
foreach my $oline (@lines) {
	print $oline."\n" if defined($oline);
}

sub generateConstructor {
	my $return = "";
	my $explicitGroups = 0;
	foreach(@groups) {
		$explicitGroups++ if $_->explicit;
	}
	fileError($lineno, "Cannot generate an autoconstructor with multiple %groups. Please explicitly create a constructor.") if $explicitGroups > 0;
	$return .= "static __attribute__((constructor)) void _logosLocalInit() { ";
	$return .= "NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; ";
	foreach(@groups) {
		next if $_->explicit;
		$return .= generateInitLines($_)." ";
	}
	$return .= "[pool drain];";
	$return .= " }";
	return $return;
}

sub generateInitLines {
	my $group = shift;
	$group = getGroup("_ungrouped") if !$group;

	if($group->initialized) {
		fileError($lineno, "re-%init of %group ".$group->name.", first initialized at ".lineDescriptionForPhysicalLine($group->initLine));
		return;
	}

	my $return = $group->initializers;
	$group->initLine($lineno);
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
	my @lineMap = lookupLineMapping($curline);
	my $filename = $lineMap[0];
	print STDERR "$filename:".($curline > -1 ? $lineMap[1].":" : "")." warning: $reason\n";
}

sub fileError {
	my $curline = shift;
	my $reason = shift;
	my @lineMap = lookupLineMapping($curline);
	my $filename = $lineMap[0];
	die "$filename:".($curline > -1 ? $lineMap[1].":" : "")." error: $reason\n";
}

sub nestingError {
	my $curline = shift;
	my $thisblock = shift;
	my $reason = shift;
	my @parts = split(/:/, $reason);
	fileError $curline, "$thisblock inside a %".$parts[0].", opened at ".lineDescriptionForPhysicalLine($parts[1]);
}

sub nestingMustContain {
	my $lineno = shift;
	my $trying = shift;
	my $stackref = shift;
	return if nestingContains($stackref, @_);
	fileError($lineno, "$trying found outside of ".join(" or ", @_));
}

sub nestingMustNotContain {
	my $lineno = shift;
	my $trying = shift;
	my $stackref = shift;
	nestingError($lineno, $trying, $_) if nestingContains($stackref, @_);
}

sub nestingContains {
	my $stackref = shift;
	my @stack = @$stackref;
	my @search = @_;
	my @parts = ();
	foreach my $nest (@stack) {
		@parts = split(/:/, $nest);
		foreach my $find (@search) {
			if($find eq $parts[0]) {
				$_ = $nest;
				return $_;
			}
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

sub matchedParenthesisSet {
	my $in = shift;
	my $atstart = shift or 1;
	my $opening = -1;
	my $closing = -1;
	if(!$atstart || $in =~ /^\s*\(/) {
		# If we encounter a ) that puts us back at zero, we found a (
		# and have reached its closing ).
		my $parenmatch = $in;
		my $pdepth = 0;
		my @pquotes = quotes($parenmatch);
		while($parenmatch =~ /[;()]/g) {
			next if fallsBetween($-[0], @pquotes);

			if($& eq "(") {
				if($pdepth == 0) { $opening = $+[0]; }
				$pdepth++;
			} elsif($& eq ")") {
				$pdepth--;
				if($pdepth == 0) { $closing = $+[0]; last; }
			}
		}
	}

	return undef if $opening == -1;
	fileError($lineno, "missing closing parenthesis") if $closing == -1;
	return ($opening, $closing);
}

sub nestedParenString {
	my $in = shift;
	my ($opening, $closing) = matchedParenthesisSet($in);

	my @ret;
	if(defined $opening) {
		$ret[0] = substr($in, $opening, $closing - $opening - 1);
		$in = substr($in, $closing);
	}
	$ret[1] = $in;
	return @ret;
}

sub smartSplit {
	my $re = shift;
	my $in = shift;
	return () if $in eq "";

	my $limit = shift or 0;

	my @quotes = quotes($in);
	my @parens = matchedParenthesisSet($in, 0);

	my $lstart = 0;
	my @pieces = ();
	my $piece = "";
	while($in =~ /$re/g) {
		next if (defined $parens[0] && fallsBetween($-[0], @parens)) || fallsBetween($-[0], @quotes);
		$piece = substr($in, $lstart, $-[0]-$lstart);
		push(@pieces, $piece);
		$lstart = $+[0];
		$limit--;
		last if($limit == 1); # One item left? Bail out and throw the rest of the string into it!
	}
	$piece = substr($in, $lstart);
	push(@pieces, $piece);
	return @pieces;
}

sub lookupLineMapping {
	my $fileline = shift;
	$fileline++;
	for (sort {$b <=> $a} keys %lineMapping) {
		if($fileline >= $_) {
			my @x = @{$lineMapping{$_}};
			return ($x[0], $x[1] + ($fileline-$_-1));
		}
	}
	return undef;
}

sub generateLineDirectiveForPhysicalLine {
	my $physline = shift;
	my @lineMap = lookupLineMapping($physline);
	my $filename = $lineMap[0];
	my $lineno = $lineMap[1];
	return ($preprocessed ? "# " : "#line ").$lineno." \"$filename\"";
}

sub lineDescriptionForPhysicalLine {
	my $physline = shift;
	my @lineMap = lookupLineMapping($physline);
	my $filename = $lineMap[0];
	my $lineno = $lineMap[1];
	return "$filename:$lineno";
}
