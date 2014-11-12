#!/usr/bin/perl -w

use strict;
local $| = 1;

use Getopt::Std;

require "$ENV{'HOME'}/projects/check/monitor.pl";

my(%opts);
getopts('h:t:r:D:', \%opts);    #Values in %opts

our $config;
$config->{'DEBUG'} = $opts{'D'} || 0;
if ($config->{'DEBUG'}){
    notify('debug', "DEBUG set to level $config->{'DEBUG'}");
}

$config->{'program'} = 'check_nntp';
$config->{'version'} = "0.01";
$config->{'whom'} = "noc\@grot.org";

if (! defined $config->{'logfacility'}){
    $config->{'logfacility'} = 'user';
}

openlog($config->{'program'},'cons,pid', $config->{'logfacility'});

#my($host, $timeout, $reportwhich) = @ARGV;

$config->{'host'} = $opts{'h'} || $ENV{'NNTPSERVER'};
$config->{'timeout'} = $opts{'t'} || 5;
$config->{'reportwhich'} = $opts{'r'} || "success";

use Net::NNTP;

my $nntp = Net::NNTP->new(
    $config->{'host'}, 
    Timeout=>$config->{'timeout'}, 
    Debug=>$config->{'DEBUG'}
);

if (defined $nntp){
    $nntp->quit;
    if ($config->{'reportwhich'} eq "success"){
	notify("crit", "Connection to $config->{'host'} succeeded in less than $config->{'timeout'} secs!");
    }
} else {
    if ($config->{'reportwhich'} eq "failure"){
	notify("crit", "Connection to $config->{'host'} timed out in $config->{'timeout'} secs");
    }
}
closelog();
