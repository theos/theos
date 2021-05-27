#!/usr/bin/perl
use JSON::PP;

$filename = shift;
$dir = shift;
$kind = shift;
@files = ();
while (true) {
    $curr_file = shift;
    if ($curr_file eq "-") {
        last;
    } else {
        push(@files, ($curr_file));
    }
}

# read out existing compile_commands and clear the file
if (-e $filename) {
    open(FH, '+<', $filename) or die $!;
    @commands = @{decode_json(<FH>)};
    seek(FH, 0, 0);
} else {
    open(FH, '>', $filename) or die $!;
    @commands = ();
}

foreach (@files) {
    push(@commands, {
        directory => $dir,
        file => $_,
        command => join(" ", @ARGV)
    });
}

print FH encode_json(\@commands);
truncate(FH, tell(FH));

exec @ARGV;
