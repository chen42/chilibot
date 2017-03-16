#!/usr/bin/perl 

use POSIX 'setsid';

sub daemonize {
         chdir '/'               or die "Can't chdir to /: $!";
         open STDIN, '/dev/null' or die "Can't read /dev/null: $!";
         open STDOUT, '>/dev/null'
                                 or die "Can't write to /dev/null: $!";
         defined(my $pid = fork) or die "Can't fork: $!";
         exit if $pid;
        setsid                  or die "Can't start a new session: $!";
         open STDERR, '>&STDOUT' or die "Can't dup stdout: $!";
}

1;



