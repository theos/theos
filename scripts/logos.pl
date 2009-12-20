#!/usr/bin/env perl -w

# I WARN YOU
# THIS IS UGLY AS SIN
# SIN IS PRETTY UGLY
#
# NO WARRANTY YET

open(FILE, $ARGV[0]);

@selectors = ();
@selectors2 = ();
@classes = ();
$numselectors = 0;
@argnames = ();
@argreturns = ();
$argcount = 0;
while($line = <FILE>) {
	if($line =~ /(%(.*?)%)/) {
		my $cmdwrapper = $1;
		my $cmdspec = $2;
		my $replacement = parseCommand($cmdspec);
		$line =~ s/\Q$cmdwrapper\E/$replacement/g;
		print $line;
	} elsif($line =~ /(%(.*?)$)/) {
		my $cmdwrapper = $1;
		my $cmdspec = $2;
		my $replacement = parseCommand($cmdspec);
		$line =~ s/\Q$cmdwrapper\E/$replacement/g;
		print $line;
	} else {
		print $line;
	}
}

close(FILE);


sub parseCommand {
	my ($cmdspec) = @_;
	my $replacement = "";
	$cmdspec =~ /(\w*)/;
	my $command = $1;
	$cmdspec = $';

	$replacement = "";
	if($command eq "hook") {
		$cmdspec =~ /^\s*(.+?)\s+/;
		$cmdspec = $';
		$class = $1;

		$cmdspec =~ /^\s*([-+]?)\s*/;
		$cmdspec = $';
		my $scope = "instance";
		$scope = "class" if $1 && $1 eq "+";

		$cmdspec =~ /^\s*\(\s*(.+?)\s*\)\s*/;
		$cmdspec = $';
		$return = $1;

		$selector = "";
		@argnames = ();
		@argreturns = ();
		$argcount = 0;

		# Yeah it's a hack to avoid finding a simple selector after a complex one.
		my $complexselector = 0;

		while($cmdspec =~ /([\$\w]+)(:[\s]*\((.+?)\)[\s]*([\$\w]+?)($|\s+))?/) {
			$keyword = $1;
			if(!$2 && $complexselector != 1) {
				$selector = $keyword;
				$cmdspec = $';
				last;
			} elsif ($2 eq "" && $complexselector == 1) {
				last;
			} else {
				$selector .= $keyword.":";
				$argreturn = $3;
				$argname = $4;
				$argreturns[$argcount] = $argreturn;
				$argnames[$argcount] = $argname;
				$argcount++;
				$complexselector = 1;
			}
			$cmdspec = $';
		}
		$newselector = $selector;
		$newselector =~ s/:/\$/g;

		$classes[$numselectors] = $class;
		$selectors[$numselectors] = $selector;
		$selectors2[$numselectors] = $newselector;
		$numselectors++;

		$build = "";
		$build = "META" if $scope eq "class";
		$build .= "HOOK($class, $newselector, $return";
		for($i = 0; $i < $argcount; $i++) {
			$build .= ", ".$argreturns[$i]." ".$argnames[$i];
		}
		$build .= ")";
		$replacement = $build;
		$replacement .= $cmdspec if $cmdspec ne "";
	} elsif($command eq "orig" || $command eq "original") {
		$replacement = "CALL_ORIG($class, $newselector";
		my $hasparens = 0;
		if($cmdspec) {
			my $parenmatch = $cmdspec;
			my $pdepth = 0;
			my $endindex = 0;
			while($parenmatch =~ /(.)/g) {
				$endindex++;
				$pdepth++ if $1 eq "(";
				if($1 eq ")") {
					$pdepth--;
					if($pdepth == 0) { $hasparens = $endindex; last; }
				}
			}
		}
		if($hasparens > 0) {
			$parenstring = substr($cmdspec, 1, $hasparens-2);
			$cmdspec = substr($cmdspec, $hasparens);
			$replacement .= ", ".$parenstring;
		} else {
			for($i = 0; $i < $argcount; $i++) {
				$replacement .= ", ".$argnames[$i];
			}
		}
		$replacement .= ")";
		$replacement .= $cmdspec;
	} elsif($command eq "init") {
		for($i = 0; $i < $numselectors; $i++) {
			$replacement .= "HOOK_MESSAGE_REPLACEMENT(".$classes[$i].", ".$selectors[$i].", ".$selectors2[$i].");";
		}
	}
	return $replacement;
}
