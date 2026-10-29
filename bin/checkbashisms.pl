#!/usr/bin/perl

# This script is essentially copied from /usr/share/lintian/checks/scripts,
# which is:
#   Copyright (C) 1998 Richard Braakman
#   Copyright (C) 2002 Josip Rodin
# This version is
#   Copyright (C) 2003 Julian Gilbey
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

use strict;
use warnings;
use Getopt::Long qw(:config bundling permute no_getopt_compat);
use File::Temp qw/tempfile/;

sub init_hashes;

(my $progname = $0) =~ s|.*/||;

my $usage = <<"EOF";
Usage: $progname [-n] [-f] [-x] [-e] [-l] script ...
   or: $progname --help
   or: $progname --version
This script performs basic checks for the presence of bashisms
in /bin/sh scripts and the lack of bashisms in /bin/bash ones.
EOF

my $version = <<"EOF";
This is $progname, from the Debian devscripts package, version ###VERSION###
This code is copyright 2003 by Julian Gilbey <jdg\@debian.org>,
based on original code which is copyright 1998 by Richard Braakman
and copyright 2002 by Josip Rodin.
This program comes with ABSOLUTELY NO WARRANTY.
You are free to redistribute this code under the terms of the
GNU General Public License, version 2, or (at your option) any later version.
EOF

my ($opt_echo, $opt_force, $opt_extra, $opt_posix, $opt_early_fail, $opt_lint);
my ($opt_help, $opt_version);
my @filenames;

# Detect if STDIN is a pipe
if (scalar(@ARGV) == 0 && (-p STDIN or -f STDIN)) {
    push(@ARGV, '-');
}

##
## handle command-line options
##
$opt_help = 1 if int(@ARGV) == 0;

GetOptions(
    "help|h"       => \$opt_help,
    "version|v"    => \$opt_version,
    "newline|n"    => \$opt_echo,
    "lint|l"       => \$opt_lint,
    "force|f"      => \$opt_force,
    "extra|x"      => \$opt_extra,
    "posix|p"      => \$opt_posix,
    "early-fail|e" => \$opt_early_fail,
  )
  or die
"Usage: $progname [options] filelist\nRun $progname --help for more details\n";

if ($opt_help)    { print $usage;   exit 0; }
if ($opt_version) { print $version; exit 0; }

$opt_echo = 1 if $opt_posix;

my $mode     = 0;
my $issues   = 0;
my $status   = 0;
my $makefile = 0;
my (%bashisms, %string_bashisms, %singlequote_bashisms);

my $LEADIN
  = qr'(?:(?:^|[`&;(|{])\s*|(?:(?:if|elif|while)(?:\s+!)?|then|do|shell)\s+)';
init_hashes;

my @bashisms_keys             = sort keys %bashisms;
my @string_bashisms_keys      = sort keys %string_bashisms;
my @singlequote_bashisms_keys = sort keys %singlequote_bashisms;

foreach my $filename (@ARGV) {
    my $check_lines_count = -1;

    my $display_filename = $filename;

    if ($filename eq '-') {
        my $tmp_fh;
        ($tmp_fh, $filename)
          = tempfile("chkbashisms_tmp.XXXX", TMPDIR => 1, UNLINK => 1);
        while (my $line = <STDIN>) {
            print $tmp_fh $line;
        }
        close($tmp_fh);
        $display_filename = "(stdin)";
    }

    if (!$opt_force) {
        $check_lines_count = script_is_evil_and_wrong($filename);
    }

    if ($check_lines_count == 0 or $check_lines_count == 1) {
        warn
"script $display_filename does not appear to be a /bin/sh script; skipping\n";
        next;
    }

    if ($check_lines_count != -1) {
        warn
"script $display_filename appears to be a shell wrapper; only checking the first "
          . "$check_lines_count lines\n";
    }

    unless (open C, '<', $filename) {
        warn "cannot open script $display_filename for reading: $!\n";
        $status |= 2;
        next;
    }

    $issues = 0;
    $mode   = 0;
    my $cat_string         = "";
    my $cat_indented       = 0;
    my $quote_string       = "";
    my $last_continued     = 0;
    my $continued          = 0;
    my $found_rules        = 0;
    my $buffered_orig_line = "";
    my $buffered_line      = "";
    my %start_lines;

    while (<C>) {
        next unless ($check_lines_count == -1 or $. <= $check_lines_count);

        if ($. == 1) {    # This should be an interpreter line
            if (m,^\#!\s*(?:\S+/env\s+)?(\S+),) {
                my $interpreter = $1;

                if ($interpreter =~ m,(?:^|/)make$,) {
                    init_hashes if !$makefile++;
                    $makefile = 1;
                } else {
                    init_hashes if $makefile--;
                    $makefile = 0;
                }
                next if $opt_force;

                if ($interpreter =~ m,(?:^|/)bash$,) {
                    $mode = 1;
                } elsif ($interpreter !~ m,(?:^|/)(sh|dash|posh)$,) {
### ksh/zsh?
                    warn
"script $display_filename does not appear to be a /bin/sh script; skipping\n";
                    $status |= 2;
                    last;
                }
            } else {
                warn
"script $display_filename does not appear to have a \#! interpreter line;\nyou may get strange results\n";
            }
        }

        chomp;
        my $orig_line = $_;

        # We want to remove end-of-line comments, so need to skip
        # comments that appear inside balanced pairs
        # of single or double quotes

        # Remove comments in the "quoted" part of a line that starts
        # in a quoted block? The problem is that we have no idea
        # whether the program interpreting the block treats the
        # quote character as part of the comment or as a quote
        # terminator. We err on the side of caution and assume it
        # will be treated as part of the comment.
        # s/^(?:.*?[^\\])?$quote_string(.*)$/$1/ if $quote_string ne "";

        # skip comment lines
        if (   m,^\s*\#,
            && $quote_string eq ''
            && $buffered_line eq ''
            && $cat_string eq '') {
            next;
        }

        # Remove quoted strings so we can more easily ignore comments
        # inside them
        s/(^|[^\\](?:\\\\)*)\'(?:\\.|[^\\\'])+\'/$1''/g;
        s/(^|[^\\](?:\\\\)*)\"(?:\\.|[^\\\"])+\"/$1""/g;

        # If inside a quoted string, remove everything before the quote
        s/^.+?\'//
          if ($quote_string eq "'");
        s/^.+?[^\\]\"//
          if ($quote_string eq '"');

        # If the remaining string contains what looks like a comment,
        # eat it. In either case, swap the unmodified script line
        # back in for processing.
        if (m/(?:^|[^[\\])[\s\&;\(\)](\#.*$)/) {
            $_ = $orig_line;
            s/\Q$1\E//;    # eat comments
        } else {
            $_ = $orig_line;
        }

        # Handle line continuation
        if (!$makefile && $cat_string eq '' && m/\\$/) {
            chop;
            $buffered_line      .= $_;
            $buffered_orig_line .= $orig_line . "\n";
            next;
        }

        if ($buffered_line ne '') {
            $_                  = $buffered_line . $_;
            $orig_line          = $buffered_orig_line . $orig_line;
            $buffered_line      = '';
            $buffered_orig_line = '';
        }

        if ($makefile) {
            $last_continued = $continued;
            if (/[^\\]\\$/) {
                $continued = 1;
            } else {
                $continued = 0;
            }

            # Don't match lines that look like a rule if we're in a
            # continuation line before the start of the rules
            if (/^[\w%-]+:+\s.*?;?(.*)$/
                and !($last_continued and !$found_rules)) {
                $found_rules = 1;
                $_           = $1 if $1;
            }

            last
              if m%^\s*(override\s|export\s)?\s*SHELL\s*:?=\s*(/bin/)?bash\s*%;

            # Remove "simple" target names
            s/^[\w%.-]+(?:\s+[\w%.-]+)*::?//;
            s/^\t//;
            s/(?<!\$)\$\((\w+)\)/\${$1}/g;
            s/(\$){2}/$1/g;
            s/^[\s\t]*[@-]{1,2}//;
        }

        if (
            $cat_string ne ""
            && (m/^\Q$cat_string\E$/
                || ($cat_indented && m/^\t*\Q$cat_string\E$/))
        ) {
            $cat_string = "";
            next;
        }
        my $within_another_shell = 0;
        if (m,(^|\s+)((/usr)?/bin/)?((b|d)?a|k|z|t?c)sh\s+-c\s*.+,) {
            $within_another_shell = 1;
        }
        # if cat_string is set, we are in a HERE document and need not
        # check for things
        if ($cat_string eq "" and !$within_another_shell) {
            my $found       = 0;
            my $match       = '';
            my $explanation = '';
            my $line        = $_;

            # Remove "" / '' as they clearly aren't quoted strings
            # and not considering them makes the matching easier
            $line =~ s/(^|[^\\])(\'\')+/$1/g;
            $line =~ s/(^|[^\\])(\"\")+/$1/g;

            if ($quote_string ne "") {
                my $otherquote = ($quote_string eq "\"" ? "\'" : "\"");
                # Inside a quoted block
                if ($line =~ /(?:^|^.*?[^\\])$quote_string(.*)$/) {
                    my $rest     = $1;
                    my $templine = $line;

                    # Remove quoted strings delimited with $otherquote
                    $templine
                      =~ s/(^|[^\\])$otherquote[^$quote_string]*?[^\\]$otherquote/$1/g;
                    # Remove quotes that are themselves quoted
                    # "a'b"
                    $templine
                      =~ s/(^|[^\\])$otherquote.*?$quote_string.*?[^\\]$otherquote/$1/g;
                    # "\""
                    $templine
                      =~ s/(^|[^\\])$quote_string\\$quote_string$quote_string/$1/g;

                    # After all that, were there still any quotes left?
                    my $count = () = $templine =~ /(^|[^\\])$quote_string/g;
                    next if $count == 0;

                    $count = () = $rest =~ /(^|[^\\])$quote_string/g;
                    if ($count % 2 == 0) {
                        # Quoted block ends on this line
                        # Ignore everything before the closing quote
                        $line         = $rest || '';
                        $quote_string = "";
                    } else {
                        next;
                    }
                } else {
                    # Still inside the quoted block, skip this line
                    next;
                }
            }

            # Check even if we removed the end of a quoted block
            # in the previous check, as a single line can end one
            # block and begin another
            if ($quote_string eq "") {
                # Possible start of a quoted block
                for my $quote ("\"", "\'") {
                    my $templine   = $line;
                    my $otherquote = ($quote eq "\"" ? "\'" : "\"");

                    # Remove balanced quotes and their content
                    while (1) {
                        my ($length_single, $length_double) = (0, 0);

                        # Determine which one would match first:
                        if ($templine
                            =~ m/(^.+?(?:^|[^\\\"](?:\\\\)*)\')[^\']*\'/) {
                            $length_single = length($1);
                        }
                        if ($templine
                            =~ m/(^.*?(?:^|[^\\\'](?:\\\\)*)\")(?:\\.|[^\\\"])+\"/
                        ) {
                            $length_double = length($1);
                        }

                        # Now simplify accordingly (shorter is preferred):
                        if (
                            $length_single != 0
                            && (   $length_single < $length_double
                                || $length_double == 0)
                        ) {
                            $templine =~ s/(^|[^\\\"](?:\\\\)*)\'[^\']*\'/$1/;
                        } elsif ($length_double != 0) {
                            $templine
                              =~ s/(^|[^\\\'](?:\\\\)*)\"(?:\\.|[^\\\"])+\"/$1/;
                        } else {
                            last;
                        }
                    }

                    # Don't flag quotes that are themselves quoted
                    # "a'b"
                    $templine =~ s/$otherquote.*?$quote.*?$otherquote//g;
                    # "\""
                    $templine =~ s/(^|[^\\])$quote\\$quote$quote/$1/g;
                    # \' or \"
                    $templine =~ s/\\[\'\"]//g;
                    my $count = () = $templine =~ /(^|(?!\\))$quote/g;

                    # If there's an odd number of non-escaped
                    # quotes in the line it's almost certainly the
                    # start of a quoted block.
                    if ($count % 2 == 1) {
                        $quote_string = $quote;
                        $start_lines{'quote_string'} = $.;
                        $line =~ s/^(.*)$quote.*$/$1/;
                        last;
                    }
                }
            }

            # since this test is ugly, I have to do it by itself
            # detect source (.) trying to pass args to the command it runs
            # The first expression weeds out '. "foo bar"'
            if (    not $found
                and not
m/$LEADIN\.\s+(\"[^\"]+\"|\'[^\']+\'|\$\([^)]+\)+(?:\/[^\s;]+)?)\s*(\&|\||\d?>|<|;|\Z)/o
                and m/$LEADIN(\.\s+[^\s;\`:]+\s+([^\s;]+))/o) {
                if ($2 =~ /^(\&|\||\d?>|<)/) {
                    # everything is ok
                    ;
                } else {
                    $found       = 1;
                    $match       = $1;
                    $explanation = "sourced script with arguments";
                    output_explanation($display_filename, $orig_line,
                        $explanation);
                }
            }

            # Remove "quoted quotes". They're likely to be inside
            # another pair of quotes; we're not interested in
            # them for their own sake and removing them makes finding
            # the limits of the outer pair far easier.
            $line =~ s/(^|[^\\\'\"])\"\'\"/$1/g;
            $line =~ s/(^|[^\\\'\"])\'\"\'/$1/g;

            foreach my $re (@singlequote_bashisms_keys) {
                my $expl = $singlequote_bashisms{$re};
                if ($line =~ m/($re)/) {
                    $found       = 1;
                    $match       = $1;
                    $explanation = $expl;
                    output_explanation($display_filename, $orig_line,
                        $explanation);
                }
            }

            my $re = '(?<![\$\\\])\$\'[^\']+\'';
            if ($line =~ m/(.*)($re)/o) {
                my $count = () = $1 =~ /(^|[^\\])\'/g;
                if ($count % 2 == 0) {
                    output_explanation($display_filename, $orig_line,
                        q<$'...' should be "$(printf '...')">);
                }
            }

            # $cat_line contains the version of the line we'll check
            # for heredoc delimiters later. Initially, remove any
            # spaces between << and the delimiter to make the following
            # updates to $cat_line easier. However, don't remove the
            # spaces if the delimiter starts with a -, as that changes
            # how the delimiter is searched.
            my $cat_line = $line;
            $cat_line =~ s/(<\<-?)\s+(?!-)/$1/g;

            # Ignore anything inside single quotes; it could be an
            # argument to grep or the like.
            $line =~ s/(^|[^\\\"](?:\\\\)*)\'(?:\\.|[^\\\'])+\'/$1''/g;

            # As above, with the exception that we don't remove the string
            # if the quote is immediately preceded by a < or a -, so we
            # can match "foo <<-?'xyz'" as a heredoc later
            # The check is a little more greedy than we'd like, but the
            # heredoc test itself will weed out any false positives
            $cat_line =~ s/(^|[^<\\\"-](?:\\\\)*)\'(?:\\.|[^\\\'])+\'/$1''/g;

            $re = '(?<![\$\\\])\$\"[^\"]+\"';
            if ($line =~ m/(.*)($re)/o) {
                my $count = () = $1 =~ /(^|[^\\])\"/g;
                if ($count % 2 == 0) {
                    output_explanation($display_filename, $orig_line,
                        q<$"foo" should be eval_gettext "foo">);
                }
            }

            foreach my $re (@string_bashisms_keys) {
                my $expl = $string_bashisms{$re};
                if ($line =~ m/($re)/) {
                    $found       = 1;
                    $match       = $1;
                    $explanation = $expl;
                    output_explanation($display_filename, $orig_line,
                        $explanation);
                }
            }

            # We've checked for all the things we still want to notice in
            # double-quoted strings, so now remove those strings as well.
            $line     =~ s/(^|[^\\\'](?:\\\\)*)\"(?:\\.|[^\\\"])+\"/$1""/g;
            $cat_line =~ s/(^|[^<\\\'-](?:\\\\)*)\"(?:\\.|[^\\\"])+\"/$1""/g;
            foreach my $re (@bashisms_keys) {
                my $expl = $bashisms{$re};
                if ($line =~ m/($re)/) {
                    $found       = 1;
                    $match       = $1;
                    $explanation = $expl;
                    output_explanation($display_filename, $orig_line,
                        $explanation);
                }
            }
            # This check requires the value to be compared, which could
            # be done in the regex itself but requires "use re 'eval'".
            # So it's better done in its own
            if ($line =~ m/$LEADIN((?:exit|return)\s+(\d{3,}))/o && $2 > 255) {
                $explanation = 'exit|return status code greater than 255';
                output_explanation($display_filename, $orig_line,
                    $explanation);
            }

            # Only look for the beginning of a heredoc here, after we've
            # stripped out quoted material, to avoid false positives.
            if ($cat_line
                =~ m/(?:^|[^<])\<\<(\-?)\s*(?:(?!<|'|")((?:[^\s;>|]+(?:(?<=\\)[\s;>|])?)+)|[\'\"](.*?)[\'\"])/
            ) {
                $cat_indented = ($1 && $1 eq '-') ? 1 : 0;
                my $quoted = defined($3);
                $cat_string = $quoted ? $3 : $2;
                unless ($quoted) {
                    # Now strip backslashes. Keep the position of the
                    # last match in a variable, as s/// resets it back
                    # to undef, but we don't want that.
                    my $pos = 0;
                    pos($cat_string) = $pos;
                    while ($cat_string =~ s/\G(.*?)\\/$1/) {
                        # position += length of match + the character
                        # that followed the backslash:
                        $pos += length($1) + 1;
                        pos($cat_string) = $pos;
                    }
                }
                $start_lines{'cat_string'} = $.;
            }
        }
    }

    warn
"error: $display_filename:  Unterminated heredoc found, EOF reached. Wanted: <$cat_string>, opened in line $start_lines{'cat_string'}\n"
      if ($cat_string ne '');
    warn
"error: $display_filename: Unterminated quoted string found, EOF reached. Wanted: <$quote_string>, opened in line $start_lines{'quote_string'}\n"
      if ($quote_string ne '');
    warn "error: $display_filename: EOF reached while on line continuation.\n"
      if ($buffered_line ne '');

    close C;

    if ($mode && !$issues) {
        warn "could not find any possible bashisms in bash script $filename\n";
        $status |= 4;
    }
}

exit $status;

sub output_explanation {
    my ($filename, $line, $explanation) = @_;

    if ($mode) {
        # When examining a bash script, just flag that there are indeed
        # bashisms present
        $issues = 1;
    } else {
        if ($opt_lint) {
            print "$filename:$.:1: warning: possible bashism; $explanation\n";
        } else {
            warn
              "possible bashism in $filename line $. ($explanation):\n$line\n";
        }
        if ($opt_early_fail) {
            exit 1;
        }
        $status |= 1;
    }
}

# Returns non-zero if the given file is not actually a shell script,
# just looks like one.
sub script_is_evil_and_wrong {
    my ($filename) = @_;
    my $ret = -1;
    # lintian's version of this function aborts if the file
    # can't be opened, but we simply return as the next
    # test in the calling code handles reporting the error
    # itself
    open(IN, '<', $filename) or return $ret;
    my $i            = 0;
    my $var          = "0";
    my $backgrounded = 0;
    local $_;
    while (<IN>) {
        chomp;
        next if /^#/o;
        next if /^$/o;
        last if (++$i > 55);
        if (
            m~
	    # the exec should either be "eval"ed or a new statement
	    (^\s*|\beval\s*[\'\"]|(;|&&|\b(then|else))\s*)

	    # eat anything between the exec and $0
	    exec\s*.+\s*

	    # optionally quoted executable name (via $0)
	    .?\$$var.?\s*

	    # optional "end of options" indicator
	    (--\s*)?

	    # Match expressions of the form '${1+$@}', '${1:+"$@"',
	    # '"${1+$@', "$@", etc where the quotes (before the dollar
	    # sign(s)) are optional and the second (or only if the $1
	    # clause is omitted) parameter may be $@ or $*.
	    #
	    # Finally the whole subexpression may be omitted for scripts
	    # which do not pass on their parameters (i.e. after re-execing
	    # they take their parameters (and potentially data) from stdin
	    .?(\$\{1:?\+.?)?(\$(\@|\*))?~x
        ) {
            $ret = $. - 1;
            last;
        } elsif (/^\s*(\w+)=\$0;/) {
            $var = $1;
        } elsif (
            m~
	    # Match scripts which use "foo $0 $@ &\nexec true\n"
	    # Program name
	    \S+\s+

	    # As above
	    .?\$$var.?\s*
	    (--\s*)?
	    .?(\$\{1:?\+.?)?(\$(\@|\*))?.?\s*\&~x
        ) {

            $backgrounded = 1;
        } elsif (
            $backgrounded
            and m~
	    # the exec should either be "eval"ed or a new statement
	    (^\s*|\beval\s*[\'\"]|(;|&&|\b(then|else))\s*)
	    exec\s+true(\s|\Z)~x
        ) {

            $ret = $. - 1;
            last;
        } elsif (m~\@DPATCH\@~) {
            $ret = $. - 1;
            last;
        }

    }
    close IN;
    return $ret;
}

sub init_hashes {

    %bashisms = (
        qr'(?:^|\s+)function [^<>\(\)\[\]\{\};|\s]+(\s|\(|\Z)' =>
          q<'function' is useless>,
        $LEADIN . qr'select\s+\w+'               => q<'select' is not POSIX>,
        qr'(test|-o|-a)\s*[^\s]+\s+==\s'         => q<should be 'b = a'>,
        qr'\[\s+[^\]]+\s+==\s'                   => q<should be 'b = a'>,
        qr'\s\|\&'                               => q<pipelining is not POSIX>,
        qr'[^\\\$]\{([^\s\\\}]*?,)+[^\\\}\s]*\}' => q<brace expansion>,
        qr'\{\d+\.\.\d+(?:\.\.\d+)?\}'           =>
          q<brace expansion, {a..b[..c]}should be $(seq a [c] b)>,
        qr'(?i)\{[a-z]\.\.[a-z](?:\.\.\d+)?\}' => q<brace expansion>,
        qr'(?:^|\s+)\w+\[\d+\]='               => q<bash arrays, H[0]>,
        $LEADIN
          . qr'read\s+(?:-[a-qs-zA-Z\d-]+)' =>
          q<read with option other than -r>,
        $LEADIN
          . qr'read\s*(?:-\w+\s*)*(?:\".*?\"|[\'].*?[\'])?\s*(?:;|$)' =>
          q<read without variable>,
        $LEADIN . qr'echo\s+(-n\s+)?-n?en?\s' => q<echo -e>,
        $LEADIN . qr'exec\s+-[acl]'           => q<exec -c/-l/-a name>,
        $LEADIN . qr'let\s'                   => q<let ...>,
        qr'(?<![\$\(])\(\(.*\)\)'             => q<'((' should be '$(('>,
        qr'(?:^|\s+)(\[|test)\s+-a' => q<test with unary -a (should be -e)>,
        qr'\&>'                     => q<should be \>word 2\>&1>,
        qr'(<\&|>\&)\s*((-|\d+)[^\s;|)}`&\\\\]|[^-\d\s]+(?<!\$)(?!\d))' =>
          q<should be \>word 2\>&1>,
        qr'\[\[(?!:)' =>
          q<alternative test command ([[ foo ]] should be [ foo ])>,
        qr'/dev/(tcp|udp)'               => q</dev/(tcp|udp)>,
        $LEADIN . qr'builtin\s'          => q<builtin>,
        $LEADIN . qr'caller\s'           => q<caller>,
        $LEADIN . qr'compgen\s'          => q<compgen>,
        $LEADIN . qr'complete\s'         => q<complete>,
        $LEADIN . qr'declare\s'          => q<declare>,
        $LEADIN . qr'dirs(\s|\Z)'        => q<dirs>,
        $LEADIN . qr'disown\s'           => q<disown>,
        $LEADIN . qr'enable\s'           => q<enable>,
        $LEADIN . qr'mapfile\s'          => q<mapfile>,
        $LEADIN . qr'readarray\s'        => q<readarray>,
        $LEADIN . qr'shopt(\s|\Z)'       => q<shopt>,
        $LEADIN . qr'suspend\s'          => q<suspend>,
        $LEADIN . qr'time\s'             => q<time>,
        $LEADIN . qr'type\s'             => q<type>,
        $LEADIN . qr'typeset\s'          => q<typeset>,
        $LEADIN . qr'ulimit(\s|\Z)'      => q<ulimit>,
        $LEADIN . qr'set\s+-[BHT]+'      => q<set -[BHT]>,
        $LEADIN . qr'alias\s+-p'         => q<alias -p>,
        $LEADIN . qr'unalias\s+-a'       => q<unalias -a>,
        $LEADIN . qr'local\s+-[a-zA-Z]+' => q<local -opt>,
        # function '=' is special-cased due to bash arrays (think of "foo=()")
        qr'(?:^|\s)\s*=\s*\(\s*\)\s*([\{|\(]|\Z)' =>
          q<function names should only contain [a-z0-9_]>,
qr'(?:^|\s)(?<func>function\s)?\s*(?:[^<>\(\)\[\]\{\};|\s]*[^<>\(\)\[\]\{\};|\s\w][^<>\(\)\[\]\{\};|\s]*)(?(<func>)(?=)|(?<!=))\s*(?(<func>)(?:\(\s*\))?|\(\s*\))\s*([\{|\(]|\Z)'
          => q<function names should only contain [a-z0-9_]>,
        $LEADIN . qr'(push|pop)d(\s|\Z)' => q<(push|pop)d>,
        $LEADIN . qr'export\s+-[^p]'   => q<export only takes -p as an option>,
        qr'(?:^|\s+)[<>]\(.*?\)'       => q<\<() process substitution>,
        $LEADIN . qr'readonly\s+-[af]' => q<readonly -[af]>,
        $LEADIN . qr'(sh|\$\{?SHELL\}?) -[rD]' => q<sh -[rD]>,
        $LEADIN . qr'(sh|\$\{?SHELL\}?) --\w+' => q<sh --long-option>,
        $LEADIN . qr'(sh|\$\{?SHELL\}?) [-+]O' => q<sh [-+]O>,
        qr'\[\^[^]]+\]'                        => q<[^] should be [!]>,
        $LEADIN
          . qr'printf\s+-v' =>
          q<'printf -v var ...' should be var='$(printf ...)'>,
        $LEADIN . qr'coproc\s' => q<coproc>,
        qr';;?&'               => q<;;& and ;& special case operators>,
        $LEADIN . qr'jobs\s'   => q<jobs>,
 #	$LEADIN . qr'jobs\s+-[^lp]\s' =>  q<'jobs' with option other than -l or -p>,
        $LEADIN
          . qr'command\s+(?:-[pvV]+\s+)*-(?:[pvV])*[^pvV\s]' =>
          q<'command' with option other than -p, -v or -V>,
        $LEADIN
          . qr'setvar\s' =>
          q<setvar 'foo' 'bar' should be eval 'foo="'"$bar"'"'>,
        $LEADIN
          . qr'trap\s+["\']?.*["\']?\s+.*(?:ERR|DEBUG|RETURN)' =>
          q<trap with ERR|DEBUG|RETURN>,
        $LEADIN
          . qr'(?:exit|return)\s+-\d' =>
          q<exit|return with negative status code>,
        $LEADIN
          . qr'(?:exit|return)\s+--' =>
          q<'exit --' should be 'exit' (idem for return)>,
        $LEADIN . qr'hash(\s|\Z)'                    => q<hash>,
        qr'(?:[:=\s])~(?:[+-]|[+-]?\d+)(?:[/\s]|\Z)' =>
          q<non-standard tilde expansion>,
    );

    %string_bashisms = (
        qr'\$\[[^][]+\]' => q<'$[' should be '$(('>,
        qr'\$\{(?:\w+|@|\*)\:(?:\d+|\$\{?\w+\}?)+(?::(?:\d+|\$\{?\w+\}?)+)?\}'
          => q<${foo:3[:1]}>,
        qr'\$\{!\w+[\@*]\}'                  => q<${!prefix[*|@]>,
        qr'\$\{!\w+\}'                       => q<${!name}>,
        qr'\$\{(?:\w+|@|\*)([,^]{1,2}.*?)\}' =>
          q<${parm,[,][pat]} or ${parm^[^][pat]}>,
        qr'\$\{[@*]([#%]{1,2}.*?)\}' => q<${[@|*]#[#]pat} or ${[@|*]%[%]pat}>,
        qr'\$\{#[@*]\}'              => q<${#@} or ${#*}>,
        qr'\$\{(?:\w+|@|\*)(/.+?){1,2}\}'      => q<${parm/?/pat[/str]}>,
        qr'\$\{\#?\w+\[.+\](?:[/,:#%^].+?)?\}' =>
          q<bash arrays, ${name[0|*|@]}>,
        qr'\$\{?RANDOM\}?\b'          => q<$RANDOM>,
        qr'\$\{?(OS|MACH)TYPE\}?\b'   => q<$(OS|MACH)TYPE>,
        qr'\$\{?HOST(TYPE|NAME)\}?\b' => q<$HOST(TYPE|NAME)>,
        qr'\$\{?DIRSTACK\}?\b'        => q<$DIRSTACK>,
        qr'\$\{?EUID\}?\b'            => q<$EUID should be "$(id -u)">,
        qr'\$\{?UID\}?\b'             => q<$UID should be "$(id -ru)">,
        qr'\$\{?SECONDS\}?\b'         => q<$SECONDS>,
        qr'\$\{?BASH_[A-Z]+\}?\b'     => q<$BASH_SOMETHING>,
        qr'\$\{?SHELLOPTS\}?\b'       => q<$SHELLOPTS>,
        qr'\$\{?PIPESTATUS\}?\b'      => q<$PIPESTATUS>,
        qr'\$\{?SHLVL\}?\b'           => q<$SHLVL>,
        qr'\$\{?FUNCNAME\}?\b'        => q<$FUNCNAME>,
        qr'\$\{?TMOUT\}?\b'           => q<$TMOUT>,
        qr'(?:^|\s+)TMOUT='           => q<TMOUT=>,
        qr'\$\{?TIMEFORMAT\}?\b'      => q<$TIMEFORMAT>,
        qr'(?:^|\s+)TIMEFORMAT='      => q<TIMEFORMAT=>,
        qr'(?<![$\\])\$\{?_\}?\b'     => q<$_>,
        qr'(?:^|\s+)GLOBIGNORE='      => q<GLOBIGNORE=>,
        qr'<<<'                       => q<\<\<\< here string>,
        $LEADIN
          . qr'echo\s+(?:-[^e\s]+\s+)?\"[^\"]*(\\[abcEfnrtv0])+.*?[\"]' =>
          q<unsafe echo with backslash>,
        qr'\$\(\([\s\w$*/+-]*\w\+\+.*?\)\)' =>
          q<'$((n++))' should be '$n; $((n=n+1))'>,
        qr'\$\(\([\s\w$*/+-]*\+\+\w.*?\)\)' =>
          q<'$((++n))' should be '$((n=n+1))'>,
        qr'\$\(\([\s\w$*/+-]*\w\-\-.*?\)\)' =>
          q<'$((n--))' should be '$n; $((n=n-1))'>,
        qr'\$\(\([\s\w$*/+-]*\-\-\w.*?\)\)' =>
          q<'$((--n))' should be '$((n=n-1))'>,
        qr'\$\(\([\s\w$*/+-]*\*\*.*?\)\)' => q<exponentiation is not POSIX>,
        $LEADIN . qr'printf\s["\'][^"\']*?%q.+?["\']' => q<printf %q>,
    );

    %singlequote_bashisms = (
        $LEADIN
          . qr'echo\s+(?:-[^e\s]+\s+)?\'[^\']*(\\[abcEfnrtv0])+.*?[\']' =>
          q<unsafe echo with backslash>,
        $LEADIN
          . qr'source\s+[\"\']?(?:\.\/|\/|\$|[\w~.-])\S*' =>
          q<should be '.', not 'source'>,
    );

    if ($opt_echo) {
        $bashisms{ $LEADIN . qr'echo\s+-[A-Za-z]*n' } = q<echo -n>;
    }
    if ($opt_posix) {
        $bashisms{ $LEADIN . qr'local\s+\w+(\s+\W|\s*[;&|)]|$)' }
          = q<local foo>;
        $bashisms{ $LEADIN . qr'local\s+\w+=' }      = q<local foo=bar>;
        $bashisms{ $LEADIN . qr'local\s+\w+\s+\w+' } = q<local x y>;
        $bashisms{ $LEADIN . qr'((?:test|\[)\s+.+\s-[ao])\s' } = q<test -a/-o>;
        $bashisms{ $LEADIN . qr'kill\s+-[^sl]\w*' } = q<kill -[0-9] or -[A-Z]>;
        $bashisms{ $LEADIN . qr'trap\s+["\']?.*["\']?\s+.*[1-9]' }
          = q<trap with signal numbers>;
    }

    if ($makefile) {
        $string_bashisms{qr'(\$\(|\`)\s*\<\s*([^\s\)]{2,}|[^DF])\s*(\)|\`)'}
          = q<'$(\< foo)' should be '$(cat foo)'>;
    } else {
        $bashisms{ $LEADIN . qr'\w+\+=' } = q<should be VAR="${VAR}foo">;
        $string_bashisms{qr'(\$\(|\`)\s*\<\s*\S+\s*(\)|\`)'}
          = q<'$(\< foo)' should be '$(cat foo)'>;
    }

    if ($opt_extra) {
        $string_bashisms{qr'\$\{?BASH\}?\b'}            = q<$BASH>;
        $string_bashisms{qr'(?:^|\s+)RANDOM='}          = q<RANDOM=>;
        $string_bashisms{qr'(?:^|\s+)(OS|MACH)TYPE='}   = q<(OS|MACH)TYPE=>;
        $string_bashisms{qr'(?:^|\s+)HOST(TYPE|NAME)='} = q<HOST(TYPE|NAME)=>;
        $string_bashisms{qr'(?:^|\s+)DIRSTACK='}        = q<DIRSTACK=>;
        $string_bashisms{qr'(?:^|\s+)EUID='}            = q<EUID=>;
        $string_bashisms{qr'(?:^|\s+)UID='}             = q<UID=>;
        $string_bashisms{qr'(?:^|\s+)BASH(_[A-Z]+)?='}  = q<BASH(_SOMETHING)=>;
        $string_bashisms{qr'(?:^|\s+)SHELLOPTS='}       = q<SHELLOPTS=>;
        $string_bashisms{qr'\$\{?POSIXLY_CORRECT\}?\b'} = q<$POSIXLY_CORRECT>;
    }
}
