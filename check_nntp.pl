#!/usr/bin/perl -w

use strict;
local $| = 1;

my($host, $timeout, $reportwhich) = @ARGV;

if (defined $host){
    chomp($host);
} else {
    $host = $ENV{'NNTPSERVER'};
}


if (defined $timeout){
} else {
    $timeout = 5;
}

if (defined $reportwhich){
    chomp($reportwhich);
} else {
    $reportwhich = "success";
}

use Net::NNTP;

my $nntp = Net::NNTP->new($host, Timeout=>$timeout);
#my $nntp = Net::NNTP->new($host, Timeout=>$timeout, Debug=>1 );
if (defined $nntp){
    $nntp->quit;
    if ($reportwhich eq "success"){
	print "Connection to ${host} succeeded in less than ${timeout} secs!\n";
    }
} else {
    if ($reportwhich eq "failure"){
	print "Connection to ${host} timed out in ${timeout} secs\n";
    }
}
