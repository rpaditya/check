#!/usr/bin/perl -w

use strict;
local $| = 1;

my($host, $timeout) = @ARGV;

if (defined $host){
    chomp($host);
} else {
    $host = $ENV{'NNTPSERVER'};
}


if (defined $timeout){
} else {
    $timeout = 5;
}

use Net::NNTP;

my $nntp = Net::NNTP->new($host, Timeout=>$timeout, Debug=>1 );
if (defined $nntp){
    $nntp->quit;
    print "Connection to ${host} succeeded in less than ${timeout} secs!\n";
} else {
    # print "Connection to ${host} timed out in ${timeout} secs\n";
}
