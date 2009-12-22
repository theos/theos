#!/usr/bin/env perl

use warnings;

# I WARN YOU
# THIS IS UGLY AS SIN
# SIN IS PRETTY UGLY
#
# NO WARRANTY YET

$filename = $ARGV[0];
open(FILE, $filename) or die "Could not open $filename";

@inputlines = ();
@outputlines = ();
$lineno = 1;

$firsthookline = -1;
$ctorline = -1;

@selectors = ();
@selectors2 = ();
@classes = ();
$numselectors = 0;
@argnames = ();
@argtypes = ();
$argcount = 0;

$hassubstrateh = 0;
$ignore = 0;

my $readignore = 0;

my $built = "";
my $building = 0;
READLOOP: while($line = <FILE>) {
	chomp($line);

	if($readignore && $line =~ /^.*?\*\/\s*/) {
		$readignore = 0;
		$line = $';
	}
	if($readignore) { next; }

	my @quotes = quotes($line);

	# Delete all single-line /* xxx */ comments.

	# Delete all single-line to-EOL // xxx comments.
	while($line =~ /\/\//g) {
		if(!fallsBetween($-[0], @quotes)) {
			$line = $`;
			@quotes = quotes($line); # Line was modified, re-generate the quotes.
			last;
		}
	}

	while($line =~ /\/\*.*?\*\//g) {
		if(!fallsBetween($-[0], @quotes)) {
			$line = $`.$';
			@quotes = quotes($line); # Line was modified, re-generate the quotes.
		}
	}
	
	# Start of a multi-line /* comment.
	while($line =~ /\/\*.*$/g) {
		if(!fallsBetween($-[0], @quotes)) {
			$line = $`;
			push(@inputlines, $line);
			$readignore = 1;
			next READLOOP;
		}
	}

	if(!$readignore) {
		# Line starts with - (return), start gluing lines together until we find a { or ;...
		if(!$building && $line =~ /^\s*([+-])\s*\(\s*(.*?)\s*\)/ && index($line, "{") == -1 && index($line, ";") == -1) {
			$building = $1;
			$built = $line;
			next;
		} elsif($building) {
			$built .= " ".$line;
			if(index($line,"{") != -1 || index($line,";") != -1) {
				push(@inputlines, $built);
				$building = 0;
				$built = "";
				next;
			}
			next;
		}
		push(@inputlines, $line) if !$readignore;
	}
}

close(FILE);

my $inclass = 0;
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
		if($line =~ /^\s*%(hook|class)\s+([\$_\w]+)/) {
			$firsthookline = $lineno if $firsthookline == -1;
			$class = $2;
			$inclass = 1;
			$line = $';
			redo;
		# - (return), but only when we're in a %hook.
		} elsif($inclass && $line =~ /^\s*([+-])\s*\(\s*(.*?)\s*\)/) {
			my $scope = $1;
			my $return = $2;
			my $selnametext = $';

			$selector = "";
			@argnames = ();
			@argtypes = ();
			$argcount = 0;

			# Yeah it's a hack to avoid finding a simple selector after a complex one.
			my $complexselector = 0;

			# word, then an optional: ": (argtype)argname"
			while($selnametext =~ /([\$\w]+)(:[\s]*\((.+?)\)[\s]*([\$\w]+?)(?=(\{|$|\s+)))?/) {
				$keyword = $1;
				if(!$2 && $complexselector != 1) {
					$selector = $keyword;
					$selnametext = $';
					last;
				} elsif (!$2 && $complexselector == 1) {
					last;
				} else {
					# build our selectors out of of keywords concat'd with :s
					$selector .= $keyword.":";
					$argreturn = $3;
					$argname = $4;
					$argtypes[$argcount] = $argreturn;
					$argnames[$argcount] = $argname;
					$argcount++;
					$complexselector = 1;
				}
				$selnametext = $';
			}
			$newselector = $selector;
			$newselector =~ s/:/\$/g;

			$classes[$numselectors] = $class;
			$selectors[$numselectors] = $selector;
			$selectors2[$numselectors] = $newselector;
			$numselectors++;

			$build = "";
			#$build = "META" if $scope eq "class";
			$build .= "static $return (*_$class\$$newselector)($class *, SEL"; 
			my $argtypelist = join(", ", @argtypes);
			$build .= ", ".$argtypelist if $argtypelist;

			my $arglist = "";
			for($i = 0; $i < $argcount; $i++) {
				$arglist .= ", ".$argtypes[$i]." ".$argnames[$i];
			}

			$build .= "); static $return \$$class\$$newselector($class *self, SEL sel".$arglist.")";
			$replacement = $build;
			$replacement .= $selnametext if $selnametext ne "";
			$line = $replacement;
			redo;
		} elsif($line =~ /%orig(inal)?(%?)(?=\W?)/) {
			$replacement = "_$class\$$newselector(self, sel";
			my $hasparens = 0;
			my $remaining = $';
			if($remaining) {
				# Walk a string char-by-char, noting parenthesis depth.
				# If we encounter a ) that puts us back at zero, we found a (
				# and have reached its closing ).
				my $parenmatch = $remaining;
				my $pdepth = 0;
				my $endindex = 0;
				my $last = "";
				my $ignore = 0;
				while($parenmatch =~ /(.)/g) {
					$endindex++;
					if($ignore == 0) {
						if($1 eq "(") { $pdepth++; }
						elsif($1 eq ")") {
							$pdepth--;
							if($pdepth == 0) { $hasparens = $endindex; last; }
						} elsif($1 eq "\"" || $1 eq "'") {
							# If we have an unescaped quote, turn on 'ignore' mode.
							if($last ne "\\") { $ignore = 1; }
						}
					} else {
						if($1 eq "\"" || $1 eq "'") {
							# If we have an unescaped quote, turn off 'ignore' mode.
							if($last ne "\\") { $ignore = 0; }
						}
					}
					$last = $1;
				}
			}
			if($hasparens > 0) {
				$parenstring = substr($remaining, 1, $hasparens-2);
				$remaining = substr($remaining, $hasparens);
				$replacement .= ", ".$parenstring;
			} else {
				my $argnamelist = join(", ", @argnames);
				$replacement .= ", ".$argnamelist if $argnamelist;
			}
			$replacement .= ")";
			$replacement .= $remaining;
			$line = $`.$replacement;
			redo;
		} elsif($line =~ /%log(%?)(?=\W?)/) {
			$replacement = "NSLog(\@\"$class";
			if(index($selector, ":") != -1) {
				my @keywords = split(/:/, $selector);
				for($i = 0; $i < $argcount; $i++) {
					$replacement .= " ".$keywords[$i].":".formatCharForArgType($argtypes[$i]);
				}
				$replacement .= "\"";
				for($i = 0; $i < $argcount; $i++) {
					$replacement .= ",".$argnames[$i];
				}
				$replacement .= ")";
			} else {
				$replacement .= " $selector\")";
			}
			$line = $`.$replacement.$';
			redo;
		} elsif($line =~ /%c(onstruc)?tor(%?)(?=\W?)/) {
			$ctorline = $lineno if $ctorline == -1;
			$line = $`.$';
			redo;
		} elsif($line =~ /%init(%?)(?=\W?)/) {
			$line = $`.generateConstructorBody().$';
			$ctorline = -2; # "Do not generate a constructor."
			redo;
		# %end (Make it the last thing we check for so we don't terminate something pre-emptively.
		} elsif($inclass && $line =~ /%end(%?)/) {
			$inclass = 0;
			$line = $`.$';
			redo;
		}
	}
	$lineno++;
	push(@outputlines, $line);
}

if($firsthookline != -1) {
	my $offset = 0;
	if(!$hassubstrateh) {
		splice(@outputlines, $firsthookline - 1, 0, "#include <substrate.h>");
		$offset++;
	}
	splice(@outputlines, $firsthookline - 1 + $offset, 0, generateClassList());
	$offset++;
	my $ctor = generateConstructor();
	if($ctorline == -2) {
		# No-op, do not paste a constructor.
	} elsif($ctorline != -1) {
		$outputlines[$ctorline + $offset - 1] = $ctor;
	} else {
		push(@outputlines, $ctor);
	}

}

splice(@outputlines, 0, 0, "#line 0 \"$filename\"");
foreach $oline (@outputlines) {
	print $oline."\n" if defined($oline);
}

sub generateConstructor {
	my $return = "";
	$return .= "static __attribute__((constructor)) void _logosLocalInit() { ";
	$return .= "NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; ";
	$return .= generateConstructorBody()." ";
	$return .= "[pool drain];";
	$return .= " }";
	return $return;
}

sub generateConstructorBody {
	my $return = "";
	map $return .= generateMSHookMessage($classes[$_], $selectors[$_], $selectors2[$_]), (0..$numselectors - 1);
	return $return;
}

sub generateMSHookMessage {
	my ($class, $original, $replacement) = @_;
	return "MSHookMessageEx(\$$class, \@selector($original), (IMP)&\$$class\$$replacement, (IMP*)&_$class\$$replacement);"
}

sub generateClassList {
	my $return = "";
	my %seenclasses;
	@uniqclasses = grep(!$seenclasses{$_}++, @classes);
	map $return .= generateClassLine($_), @uniqclasses;
	return $return;
}

sub generateClassLine {
	my ($class) = @_;
	return "\@class $class; static Class \$$class = objc_getClass(\"$class\");";
}

sub formatCharForArgType {
	my ($argtype) = @_;
	return "%d" if $argtype =~ /(int|long|bool)/i;
	return "%s" if $argtype =~ /char\s*\*/;
	return "%p" if $argtype =~ /void\s*\*/;
	return "%f" if $argtype =~ /(double|float)/;
	return "%c" if $argtype =~ /char/;
	return "%@";
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
		return 1 if ($start < $idx && ($end > $idx || !defined($end)))
	}
	return 0;
}
