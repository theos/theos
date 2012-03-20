#!/usr/bin/perl
my @o;
for(reverse @ARGV) {
	my $i = 0;
	for my $a (split /:/) {
		if(length $a > 0) {
			@o = () if($i == 0 && $o[$i] && $o[$i] ne $a);
			$o[$i] = $a;
		}
		$i++;
	}
}
print join(':', @o);
