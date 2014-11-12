#
# rudimentary functions used by lots of tools
#
# include it in your code as
# require '/home/check/bin/monitor.pl';

use strict;
local $| = 1;

use vars qw($config);

use Digest::MD5  qw(md5 md5_hex md5_base64);
use Time::HiRes;
use LWP::UserAgent;
use Sys::Syslog;
#Sys::Syslog::setlogsock('unix');

use RRDs;
$config->{'STEP'} = 300;

$config->{'DEBUG'} = 0;
$config->{'timeout'} = 15;
if (! defined $main::config->{'logfacility'}){
    $config->{'logfacility'} = 'user';
}

sub check_httpd {
    my($url, $username, $pwd, $timeout) = @_;
    my($rval) = 0;

    my($ua) = new LWP::UserAgent;
    $ua->timeout($timeout);

    my($start) = Time::HiRes::time ();
    my($request) = HTTP::Request->new(GET => $url);
    my($tcp_end) = Time::HiRes::time ();
    $request->authorization_basic($username, $pwd);
    my($response) = $ua->request($request);
    my($finish) = Time::HiRes::time ();
    my($content) = $ua->request($request)->content;
    $rval = $response->is_success - $response->is_error;
    my($contentsize) = length($content);
    my($md5) = md5_base64($content);

    undef $ua;
    return($rval, $response->code, $response->status_line, $start, $tcp_end, $finish, $contentsize, $content, $md5);
}

sub updateRRD {
    my($RRD, $t, @vals) = @_;

    if (! -e $RRD){
        return(1, "could not find ${RRD}");
    } else {
        my($vallist) = $t . ":" . join(':', @vals);

        RRDs::update("$RRD", "$vallist");
        if (my $error = RRDs::error()) {
            return(1, "RRDs::update - $RRD [$error] (${vallist})");
        } else {
            return(0, "OK");
        }
    }
}

sub notify {
  my($severity, $mesg, $who, $longmsg) = @_;
  if (! $who) {
    $who = "";
  }
  if (! $longmsg) {
    $longmsg = $mesg;
  }
  my($useverity) = uc($severity);

  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $year += 1900;
  $mon += 1;
  my($timestamp) = sprintf("%02d-%02d %02d:%02d:%02d", $mon, $mday, $hour, $min, $sec);
  my($pid) = $$;

  if ($config->{'DEBUG'}) {
    print STDERR "${useverity}: ($timestamp): $mesg\n";
  } else {
    if ($severity eq "debug") {
    } else {
      syslog($severity, "${useverity}: $mesg");
      if ($severity eq "emerg" || $severity eq "crit") {
	if ($who ne "") {
	  my($rv, $errmsg) = &sendmail($who, $who, "$mesg (${useverity})", $longmsg);
	  if ($rv) {
	    syslog('crit', "CRIT: could not send email to ${who} (${errmsg})");
	  }
	}
	#
	# send an snmp trap
	#
	#      my($trapdest) = "$config->{'snmpTrapCommunity'}\@$config->{'snmpTrapHost'}";
	#      snmptrap($trapdest, enterpriseOID,
	#            agent, generalID, specificID, OID, type, value,
	#            [OID, type, value ...])

      }
    }
  }
}

sub sendmail {
    my($to, $from, $subject, $msg) = @_;
    if (! $msg){
        $msg = $subject;
    }

    open MAIL,"| /usr/sbin/sendmail -t -oi" or return (1, "Couldn't pipe to sendmail: $!");

    print MAIL <<"MAIL";
To: ${to}
From: ${from}
Reply-To: ${from}
Subject: ${subject}

-------------8<----------cut here----------------8<-----------------
    ${msg}
-------------8<----------cut here----------------8<-----------------
MAIL

    close MAIL or return(1, "Couldn't close sendmail pipe: $!");
return(0, "okay");
}


sub pgrep {
	my($string) = @_;
	my(@pid) = `/bin/ps auxwww | /usr/bin/egrep "${string}"`;
	for my $l (@pid){
		chomp($l);
		my($u, $pid, $cpu, $mem, $vsz, $rss, $tt, $stat, $started, $time, @cmd) = split(/\s+/, $l);
		my($cmdstring) = join(' ', @cmd);
		next if ($cmdstring =~ /grep/);
		return($pid, $u, $cmdstring);
	}
}

1;
