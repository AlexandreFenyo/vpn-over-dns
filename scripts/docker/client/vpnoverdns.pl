#!/usr/bin/perl -w

# VPN-over-DNS perl client v1 2015-12-28

# Copyright (c) 2015, Alexandre Fenyo - www.fenyo.net - alex@fenyo.net
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

############################################################
# Installation  : https://www.vpnoverdns.com/download.html#cli
# User's manual : https://www.vpnoverdns.com/perl.html
# Other versions: https://www.vpnoverdns.com
# Support       : support@vpnoverdns.com
# Contact       : contact@vpnoverdns.com

############################################################
# BOOTSTRAP WITHOUT INTERNET CONNECTION
# You may need this file on sites without Internet access.
# In such a case, you may use nslookup/dig queries in order to bootstrap
# your Internet tunnel access.
# 1- Download and decode this file:
#    Either run "dig perl.vpnoverdns.com. txt +short | tr '\\' ' ' | xargs csh -c", or run under csh:
#      set i=0
#      while ( $i < 2000 )
#        dig $i.v1.src.vpnoverdns.com. TXT +short
#        @ i++
#      end | sed -e s/.// -e 's/.$//' | perl -MMIME::Base64 -ne 'print decode_base64($_);' > vpnoverdns.pl
# 2- Dealing with Perl non core modules:
#    Net::DNS is the only non core module fully required dependency of VPN-over-DNS.
#    Digest::HMAC is the only non core module dependency of Net::DNS but is not used by Net::DNS when
#    invoked by VPN-over-DNS. Thus, Net::DNS is really the only required dependency to make a tunnel.
#    To get Net::DNS, download and decode this tar-gziped files the same way, using:
#    {0..5000}.netdns1-02.src.vpnoverdns.com and get /CPAN/authors/id/N/NL/NLNETLABS/Net-DNS-1.02.tar.gz
#    For instance, you can do it running this script under csh:
#      set i=0
#      while ( $i < 5000 )
#        dig $i.netdns1-02.src.vpnoverdns.com. TXT +short
#        @ i++
#      end | sed -e s/.// -e 's/.$//' | perl -MMIME::Base64 -ne 'print decode_base64($_);' > Net-DNS-1.02.tar.gz
#    Compile and install this module:
#    - with root access permission:
#      % tar zxf Net-DNS-1.02.tar.gz; cd Net-DNS-1.02; perl Makefile.PL; make
#      % su
#      # make install
#    - without root access permission:
#      % cd $HOME
#      % cpan # select the local::lib approach when asked to
#      % cd .cpan/build/local-lib* ; make install # should have been done by CPAN, but sometimes you need to do it yourself...
#      set and export PERL5LIB environment variable to $HOME/perl5/lib/perl5
#
# If you get an error like "Not a GLOB reference at [...] IO/Select.pm" when using vpnoverdns.pl,
# uninstall your Net::DNS module and install the 1.02 or 1.04 (or higher) version instead
# (this is a known bug with Net::DNS 1.03).

############################################################
# INSTALLATION WITH AN INTERNET CONNECTION
# If you have an Internet connection, but do not have Net::DNS Perl package installed,
# read the instructions on https://www.vpnoverdns.com/download.html
# If an installation step waits indefinitely, press Ctrl-C to let the
# installer continue and try to install the package (may happen on Cygwin).

############################################################
# This file was included in the vpnoverdns.com zone file this way:
# perl -MMIME::Base64 -ne 'print encode_base64($_);' < vpnoverdns.pl | perl -ne 'print $i++.".v1.src IN TXT ".$_;' >> vpnoverdns.com

use strict;

# this file must only be edited with an UTF-8 compatible editor.
use utf8;

# use Data::Dumper;
use Pod::Usage;
use Getopt::Long;
use List::Util qw[ min max ];
use Time::HiRes qw[ usleep gettimeofday ];
use Socket;
use IO::Select;
use Compress::Zlib;
use MIME::Base64;

my $modNetDNS = eval {
  require Net::DNS;
  Net::DNS->import;
  1;
};

my $modXMLSimple = eval {
  require XML::Simple;
  XML::Simple->import(qw[ :strict ]);
  1;
};

my $modLWP = eval {
  require LWP::UserAgent;
  LWP::UserAgent->import;
  1;
};

my $modHTTPS = eval {
  require LWP::Protocol::https;
  LWP::Protocol::https->import;
  1;
};

my $modCONNECT = eval {
  require LWP::Protocol::connect;
  LWP::Protocol::connect->import;
  1;
};

# SSL debug: DEBUG perl -MIO::Socket::SSL=debug50

if (!$modNetDNS) {
    print STDERR "Net::DNS required Perl module not installed.\nNote that you should avoid installing Net::DNS 1.03 because of a bug in this specific version (see https://rt.cpan.org/Public/Bug/Display.html?id=108745).\nIf you have Internet access, try running 'cpan N/NL/NLNETLABS/Net-DNS-1.02.tar.gz'\nIf you do not have Internet access, try running the following two command lines:\ndig netdns.vpnoverdns.com. txt +short | tr '\\\\' ' ' | xargs csh -c\ncpan Net-DNS-1.02.tar.gz\nMore help available in the comments at the beginning of this Perl file and on https://www.vpnvoverdns.com/download.html#cli\n";
    exit 1;
}

# Error strings.
my %errstrings = map { our $cpt = 0 if !defined $cpt; $_ => $cpt++ }
my @errstrings = ( "SRV2CLT_OK", "SRV2CLT_NO_SUCH_COMMAND",
		   "SRV2CLT_EXCEPTION", "SRV2CLT_START_CHECKING_MAILS",
		   "SRV2CLT_CURRENTLY_CHECKING_MAILS", "SRV2CLT_NEW_MAIL",
		   "SRV2CLT_ERROR", "SRV2CLT_NO_UNREAD_MAIL", "SRV2CLT_SOCKET_ID",
		   "SRV2CLT_BAD_USER", "SRV2CLT_NMAILS", "SRV2CLT_NO_ACCOUNT",
		   "SRV2CLT_MAIL_SAVED" );

# Maximum number of bytes sent to the server in one "IN A" DNS
# request, at the lowest protocol layer.  This number is limited by
# the maximum size of one label in a domain name. Default to 30, the
# highest possible value.
my $optmaxwrite = 30;

# Maximum number of bytes received from the server in one "IN A" DNS
# request, at the lowest protocol layer. This number is limited by
# the maximum size of a DNS UDP packet. See DnsListener.java to know
# the lowest hazardous value. May be increased to speed up the tunnel.
# Note that $optmaxread + 1 bytes are received since beginning with
# the v2 protocol version, the byte array returned by a rd query
# starts with an appended unused byte (0 in IN A RRs, 48d in IN TXT
# RRs) to be sure it can not be mistaken with an error message starting
# with 'E'.
my $optmaxread = 64;

# Protocol constants.
my $domain = "tun.vpnoverdns.com";

# Protocol version.
my $version = 2;

# Server domain.
my $service = "v$version.$domain";

# Message fields delimiter.
my $SEP = "\x{a7}";

# Used to tunnel over DNS the initial SSL/TLS request that gets the user
# ID associated with a login and password.
my $initializeuuid = "initiali";

# Used to tunnel anonymous sessions.
my $anonymousuuid = "anonymou";

# File containing user ID, created at first use.
my $conffile = "$ENV{'HOME'}/.vpnoverdns";

# Maximum number of bytes an rtt request can give back. Must be the
# same value as in the server.
my $maxrttbufsize = 192;

# Waiting delay before retry, only used when the server has not
# immediately processed a message.
my $delaybetweenchecks = 200000;

# Dictionaries used to forge fuzzy queries.
my @tlds = ( 'com', 'net', 'edu', 'fr', 'co.uk', 'es', 'ru' );
my @dict = ( 'vpn', 'over', 'dns', 'cool', 'bad', 'hack', 'to', 'prime',
	     'number', 'avoid', 'name', 'load', 'request', 'check', 'crack',
	     'better', 'harder', 'faster', 'stop', 'wide', 'virus', 'void' );

# Default values for general options.
my $optdebug = 0;
my $optuuid = 0;
my $optfast = 0;
my $optfuzzy = 0;
my $optverbose = 0;
my $opthelp = 0;
my $optcheckmails = 0;
my $optsendmail = 0;
my $optinitialize = 0;
my $optanonymous = 0;
my $optnocheckcert = 0;
my $optglobal = 0;
my $optlocal = 0;
my $optping = 0;
my $optsilent = 0;
my $optssh = 0;
my $optsshoptions = "";
my $optsshcommand = "";
my $optproxy = 0;
my $optmaxtimeout = 8;
my $optinitlistenport = 8081;
my $optmaxparallelrequests = 20;
# Waiting delay before retry (microseconds), only used when the server
# has not immediately processed a message.
my $optretrydelaymessages = 200000;
# Waiting delay before retrying a DNS request that has been lost
# (microseconds).
my $optretrydelayrequests = 1000000;
# Maximum number of local bytes sent before requesting for remote
# bytes.
my $optlocalbytesbuffersize = 1024;
# Delay between two checks for remote data for a redirected
# channel. Only used when no need to send local data.
my $optchanneldelaycheck = 200000;

pod2usage 2 if $#ARGV < 0;

# Declare command-line parameters.
Getopt::Long::Configure('bundling');
my $optstatus = GetOptions('debug|d' => \$optdebug, 'verbose|v' => \$optverbose,
	        'help|h' => \$opthelp, 'initialize|i' => \$optinitialize,
		'anonymous|A' => \$optanonymous, 'fast|F' => \$optfast,
	        'nocheckcert|n' => \$optnocheckcert, 'global|g' => \$optglobal,
		'local|L' => \$optlocal, 'port|p=i' => \$optinitlistenport,
	        'maxwrite|m=i' => \$optmaxwrite, 'maxread|Y=i' => \$optmaxread,
                'silent|s' => \$optsilent, 'checkmails|c' => \$optcheckmails,
                'sendmail|w' => \$optsendmail, 'fuzzy|f=i' => \$optfuzzy,
                'rtt|r=i' => \$optping, 'proxy|X' => \$optproxy,
                'ssh|S' => \$optssh, 'o|options=s' => \$optsshoptions,
		 'C|command=s' => \$optsshcommand, 'uuid|u' => \$optuuid,
	        'delay4msg|M=i' => \$optretrydelaymessages,
	        'delay4req|R=i' => \$optretrydelayrequests,
	        'parallel|P=i' => \$optmaxparallelrequests,
	        'localbuf|b=i' => \$optlocalbytesbuffersize,
                'delaycheck|D=i' => \$optchanneldelaycheck,
	        'maxdelay|a=i' => \$optmaxtimeout);
die "$$: invalid arguments\n" if !$optstatus;

$optverbose = 1 if $optdebug;
pod2usage 2     if $opthelp;

# Avoid zombie processes.
$SIG{CHLD} = 'IGNORE';

# Low-level protocol error messages handling.
sub printReplyError($@) {
  my $message = shift;
  my @reply = @_;
  print STDERR "$$: $message error $reply[0] ($errstrings[$reply[0]]) / content: ".($#reply >= 1 ? $reply[1] : "")."\n";
}

# Walk around a server bug.
sub correctbugonserver1($) {
  my $param = shift;
  my $i = length $param;
  while (!ord substr $param, --$i, 1) {};
  return substr $param, 0, $i + 1;
}

# Build fixed-length numbers.
sub normalize($$) {
  my ( $len, $param ) = @_;
  return substr(10 ** ($len + 1), 1, $len - length $param).$param;
}

# Build fixed-length random numbers.
sub random($) {
  my $len = shift;
  return normalize $len, int rand 10 ** $len;
}

# Parallel bi-directional exchanges on top of DNS transactions, using
# "IN TXT" RRs.
sub getMultipleINTXT(@) {
    return getMultipleIN("TXT", @_);
}

# Low-level bi-directional exchange on top of DNS transactions, using
# "IN A" RRs.
sub getINA($) {
  return @{(getMultipleINA(@_))[0]};
}

# Parallel bi-directional exchanges on top of DNS transactions, using
# "IN A" RRs.
sub getMultipleINA(@) {
    return getMultipleIN("A", @_);
}

# Parallel bi-directional exchanges on top of DNS transactions.
sub getMultipleIN($@) {
  my $type = shift;
  my @names = @_;
  my $resolver = Net::DNS::Resolver->new;
  my $nfailed = 0;

  print STDERR "$$: ".(0 + @names)." parallel quer".(0 + @names > 1 ? "ies" : "y")."\n" if $optdebug;

  my ($nresults, @sockets, @tries, @results, @timeout, @timesent) = 0;
  my $pendingrequests = 0;

  # Main loop, until each query returned a response.
  do {
    my $select = IO::Select->new;
    my ($timenow, $waitingforsocket, $delaytotimeout) = (scalar gettimeofday, 0);

    # Send queries that are not pending.
    for (my $i = 0; $i <= $#names; $i++) {
      next if (defined $results[$i]);
      last if $pendingrequests >= $optmaxparallelrequests;

      if (!defined $sockets[$i]) {
	$tries[$i] = (!defined $tries[$i]) ? 1 : ($tries[$i] + 1);
	$timeout[$i] = min $tries[$i] * $optretrydelayrequests / 1E6, $optmaxtimeout;
	$timesent[$i] = gettimeofday;

	# Create a background noise.
	if ($optfuzzy) {
	  my $nreq = int rand $optfuzzy;

	  for (my $tmpcnt = 0; $tmpcnt < $nreq; $tmpcnt++) {
	    my $name;
	    my $parts = 1 + int rand 5;
	    for (my $i = 0; $i < $parts; $i++) {
	      my $partlen = 6 + int rand 10;
	      for (my $j = 0; $j < $partlen; $j++) {
		$name .= substr join('', 'a'..'z'), rand 26, 1;
	      }
	      $name .= ".";
	    }
	    $name = "www.".$name.$tlds[rand @tlds];
	    print "$$: fuzzy request: $name\n" if $optdebug;
	    my $tmpsock = $resolver->bgsend($name);
	    close $tmpsock if defined $tmpsock;
	  }

	  for (my $tmpcnt = 0; $tmpcnt < $optfuzzy - $nreq; $tmpcnt++) {
	    my $name = "";
	    if (int rand 2) {
	      my $partlen = 6 + int rand 10;
	      for (my $j = 0; $j < $partlen; $j++) {
		$name .= substr join('', 'a'..'z'), rand 26, 1;
	      }
	    } else {
	      $name = $dict[rand @dict].$dict[rand @dict].$dict[rand @dict];
	    }
	    my $reqtype = int rand 4;
	    $name = 'retry-001.sz-'.random(8).'.rn-'.random(8).'.id-'.random(8).".v$version.tun.".$name if $reqtype == 0;
	    $name = 'retry-001.rn-'.random(8).'.ck-00000000.id-'.random(8).".v$version.tun.".$name if $reqtype == 1;
	    if ($reqtype == 2) {
	      my $buf;
	      for (my $i = 0; $i < $optmaxwrite; $i++) {
		$buf .= sprintf "%02x", rand 256;
	      }
	      $name = 'retry-001.rn-'.random(8).".bf-$buf.wr-".random(8).'.id-'.random(8).".v$version.tun.".$name;
	    }
	    $name = 'retry-001.ln-'.random(3).'.rd-'.random(8).'.id-'.random(8).".v$version.tun.".$name if $reqtype == 3;
	    $name .= ".".$tlds[rand @tlds];
	    print "$$: fuzzy request: $name\n"  if $optdebug;
	    my $tmpsock = $resolver->bgsend($name);
	    close $tmpsock if defined $tmpsock;
	  }
	}

	usleep 100000 if $optsilent;
	$sockets[$i] = $resolver->bgsend("retry-".normalize(3, $tries[$i]).".".$names[$i], $type);
	if (!defined $sockets[$i]) {
	  print STDERR "$$:  background query failed for $names[$i]: try $tries[$i]: ".$resolver->errorstring."\n";
	} else {
	  $pendingrequests++;
	  print STDERR "$$:  background query sent for $names[$i]: try $tries[$i]\n" if $optdebug;
	  $select->add($sockets[$i]) or die "$$:  select: $!";
	  $waitingforsocket = 1;
	}
      } else {
	$select->add($sockets[$i]) or die "$$:  select: $!";
	$waitingforsocket = 1;
      }

      $delaytotimeout = !defined $delaytotimeout ? $timesent[$i] + $timeout[$i] - $timenow : min $timesent[$i] + $timeout[$i] - $timenow, $delaytotimeout;
    }

    print STDERR "$$: ".$pendingrequests." pending quer".($pendingrequests > 1 ? "ies" : "y")." - $nresults answer".($nresults > 0 ? "s" : "")." received\n" if $optdebug;

    # Wait for a reply or any pending query timeout.
    if (defined $delaytotimeout and $delaytotimeout > 0) {
      if ($waitingforsocket) {
	print STDERR "$$:  waiting for responses during $delaytotimeout s\n" if $optdebug;
	$select->can_read($delaytotimeout);
      } else {
	print STDERR "$$:  waiting for nothing during $delaytotimeout s\n" if $optdebug;
	usleep $delaytotimeout * 1E6;
      }
    } else {
      print STDERR "$$:  every timeout reached, no need to wait for responses\n" if $optdebug;
    }

    # Handle replies and timeouts.
    $timenow = gettimeofday;
    for (my $i = 0; $i <= $#names; $i++) {
      if (defined $sockets[$i]) {
 	if ($resolver->bgisready($sockets[$i])) {
	  # background reply is ready
	  my $RRs = $resolver->bgread($sockets[$i]);

	  my $error = 0;

	  if ($RRs->answer < 1) {
	      $error = 1;
	      print STDERR "$$: error: no answer in DNS reply for retry-".normalize(3, $tries[$i]).".".$names[$i]."\n" if $optdebug;
	  } else {
	      my $origin = ($RRs->answer)[0]->can("owner") ? ($RRs->answer)[0]->owner : ($RRs->answer)[0]->name;
	      if ($origin ne "retry-".normalize(3, $tries[$i]).".".$names[$i]) {
		  $error = 1;
		  print STDERR "$$: error: invalid answer: query for retry-".normalize(3, $tries[$i]).".".$names[$i]." returned RRs for ".$origin."\n" if $optdebug;
	      }
	  }

	  print STDERR "$$: warning for ".$tries[$i].".".$names[$i].": select->remove() error => $!\n" if (!defined $select->remove($sockets[$i]));
	  $sockets[$i]->close || print STDERR "$$: warning: socket->close() error => $!\n";
	  undef $sockets[$i];

	  $pendingrequests--;
	  if (!$RRs || $error) {
	    print STDERR "$$:  background response failed for $names[$i]: try $tries[$i]: ".$resolver->errorstring."\n" if $optdebug;
	    $nfailed++;
	  } else {
            print STDERR "$$:  background response for $names[$i]: try $tries[$i]\n" if $optdebug;
	    my @msgbytes;

	    foreach my $RR ($RRs->answer) {
	      if ($type eq "TXT") {
		print STDERR "$$:  one RR of type TXT\n" if $optdebug;
		@msgbytes = unpack('C*', $RR->txtdata);
	      }
	      if ($type eq "A") {
		print STDERR "$$:  one RR of type A\n" if $optdebug;
		my @bytes = split '\\.', $RR->address;
		my $nbytes = $bytes[0] >> 6;
		my $idx = $bytes[0] & 63;
		$msgbytes[3 * $idx] = $bytes[1];
		$msgbytes[3 * $idx + 1] = $bytes[2] if $nbytes > 1;
		$msgbytes[3 * $idx + 2] = $bytes[3] if $nbytes > 2;
	      }
	    }

	    if (!$optping and $#msgbytes == 1 and chr($msgbytes[0]) eq 'E' and ($msgbytes[1] != 0 and $msgbytes[1] != 10 and $msgbytes[1] != 14)) {
	      # The first RR in the array of answers contains the full length query name, other answers contain only
	      # pointers to it, this is why we do not use the owner or name field of the current RR in the following message.
	      my $origin = ($RRs->answer)[0]->can("owner") ? ($RRs->answer)[0]->owner : ($RRs->answer)[0]->name;
	      die "$$:  remote error ($origin for $names[$i]: try $tries[$i]: ".chr($msgbytes[0]).$msgbytes[1]."\n";
	    }

	    $results[$i] = \@msgbytes;
	    $nresults++;
	  }

	} else {
	  # background reply is not ready
	  if ($timesent[$i] + $timeout[$i] - $timenow < 0) {
	    print STDERR "$$:  timeout reached for $names[$i]: try $tries[$i]\n" if $optdebug;
	    
	    print STDERR "$$: warning for ".$tries[$i].".".$names[$i].": select->remove() error => $!\n" if (!defined $select->remove($sockets[$i]));
	    $sockets[$i]->close || print STDERR "$$: warning: socket->close() error => $!\n";
	    undef $sockets[$i];

            $pendingrequests--;
	    $nfailed++;
	  }
	}
      }
    }

  } while $nresults <= $#names;

  print STDERR "$$: parallel queries completed\n" if $optdebug;
  return $optping ? [ $nfailed ] : @results;
}

# Book a server buffer for a new message.
sub getTicket($) {
  my @msgbytes = getINA('sz-'.normalize(8, shift).'.rn-'.random(8).'.id-00000001.'.$service);
  die "$$: invalid DNS answer - the server may be down or unreachable\n" if ($#msgbytes < 2);
  return normalize 8, ($msgbytes[0] << 16) + ($msgbytes[1] << 8) + $msgbytes[2];
}

# Send an UTF-8 message.
sub sendMessage($) {
  return sendBinaryMessage(shift, undef);
}

# Send an UTF-8 message with a binary part attached.
sub sendBinaryMessage($$) {
  my ($message, $binarypart) = @_;

  print STDERR "$$: sending message: $message\n" if $optdebug;

  utf8::encode $message;
  if (!defined $binarypart) {
    $message = "\x{0}$message";
  } else {
    $message = chr(length $message).$message.$binarypart;
  }

  # Book a server buffer for the message request content.
  my $id = getTicket length $message;

  # Split the message in low-level DNS requests.
  my @names;
  if (!$optfast) {
      my $nmessages = int((length($message) + $optmaxwrite - 1) / $optmaxwrite);
      for (my $cnt = 0; $cnt < $nmessages; $cnt++) {
	  my $pos = $cnt * $optmaxwrite;
	  my $buffer = "";
	  for (my $cnt2 = 0; $cnt2 < min length($message) - $pos, $optmaxwrite; $cnt2++) {
	      $buffer .= sprintf "%02x", ord substr $message, $pos + $cnt2, 1;
	  }
	  push @names, "rn-".random(8).".bf-$buffer.wr-".normalize(8, $pos).".id-$id.$service";
      }
  } else {
      my $nmessages = int((length($message) + 84) / 85);
      for (my $cnt = 0; $cnt < $nmessages; $cnt++) {
	  my $pos = $cnt * 85;
	  my $buffer1 = "";
	  my $buffer2 = "";
	  my $buffer3 = "";
	  for (my $cnt2 = 0; $cnt2 < min length($message) - $pos, 85; $cnt2++) {
	      $buffer1 .= sprintf "%02x", ord substr $message, $pos + $cnt2, 1 if ($cnt2 < 30);
	      $buffer2 .= sprintf "%02x", ord substr $message, $pos + $cnt2, 1 if ($cnt2 >= 30 && $cnt2 < 60);
	      $buffer3 .= sprintf "%02x", ord substr $message, $pos + $cnt2, 1 if ($cnt2 >= 60);
	  }
	  push @names, "rn-".random(8).
	      (length $buffer3 ? ".bf-".$buffer3 : "").
	      (length $buffer2 ? ".bf-".$buffer2 : "").
	      (length $buffer1 ? ".bf-".$buffer1 : "").".wr-".normalize(8, $pos).".id-$id.$service";
      }
  }
  # Process every message requests simultaneously.
  getMultipleINA @names;

  # Wait for a response and get the response buffer length.
  my $retlen;
  for (;;) {
    my $name = "rn-".random(8).".ck-00000000.id-$id.$service";
    my @msgbytes = getINA $name;
    if ($msgbytes[0] ne ord('L') and $msgbytes[0] ne ord('E')) {
	print "$$: protocol error: name=".$name."\n";
	print "$$: protocol error: byte[0]=".$msgbytes[0]."\n";
	die "$$: protocol error";
    }
    if ($msgbytes[0] eq ord('L')) {
      $retlen = ($msgbytes[1] << 16) + ($msgbytes[2] << 8) + $msgbytes[3];
      print STDERR "$$: compressed response buffer length to fetch: ".$retlen."\n" if $optdebug;
      last;
    }
    usleep $optretrydelaymessages;
  }

  # Build a list of queries that can fetch the different parts of the
  # response.
  @names = ();
  my $compressedreply;
  my $debugreply;
  my $nmessages = int(($retlen + $optmaxread - 1) / $optmaxread);
  for (my $cnt = 0; $cnt < $nmessages; $cnt++) {
    my $pos = $cnt * $optmaxread;
    my $len = min $retlen - $pos, $optmaxread;
    push @names, "ln-".normalize(3, $len).($optfast ? (Net::DNS->version <= 0.68 ? ".rx-" : ".ry-") : ".rd-").normalize(8, $pos).".id-$id.$service";
  }

  # Fetch the different parts of the message response simultaneously.
  my @results = $optfast ? getMultipleINTXT @names : getMultipleINA @names;
  
  # Assemble the different parts together in a message response.
  for (my $cnt = 0; $cnt < $nmessages; $cnt++) {
    my $refresult = $results[$cnt];
    my @msgbytes = @$refresult;
    for (my $idx = 1; $idx <= $#msgbytes; $idx++) {
      # IPs replies in RFC-1918 answers may be filtered by some intermediate DNS servers - SHOULD AVOID THIS PATCHING THE PROTOCOL
      die "$$: an intermediate DNS server filtered a part of the message (cnt=$cnt<$nmessages idx=$idx<=$#msgbytes)\n" if !defined $msgbytes[$idx];
      $compressedreply .= chr $msgbytes[$idx];
      $debugreply .= ";".$msgbytes[$idx];
    }
  }

  # Uncompress the message response.
  $compressedreply = decode_base64($compressedreply) if ($optfast && Net::DNS->version > 0.68);
  my $reply;
  $reply = uncompress $compressedreply;
  if (!defined $reply) {
      print "$$: bytes: [$debugreply]\n" if ($optverbose);
      die "$$: uncompress: invalid content";
  }

  # Split the message response parts into distinct buffers.
  my @reply;
  if (!defined $binarypart) {
    utf8::decode $reply;
    $reply = correctbugonserver1 $reply;
    @reply = split $SEP, $reply;
  } else {
    my $replymessagesize = ord substr $reply, 0, 1;
    my $replymessage = substr $reply, 1, $replymessagesize;
    utf8::decode $replymessage;
    $replymessage = correctbugonserver1 $replymessage;
    my $replybinarypart = substr $reply, 1 + $replymessagesize;
    @reply = split $SEP, $replymessage;
    push @reply, $replybinarypart;
  }

  # Acknowledge the reply.
  getINA "rn-".random(8).".ac.id-$id.$service";

  print STDERR "$$: retcode: $reply[0] (".$errstrings[$reply[0]].") / content: ".($#reply >= 1 ? $reply[1] : "")."\n\n" if $optdebug;
  return @reply;
}

# Get personal message from the service.
sub printMessage($) {
  my $uuid = shift;

  my @reply = sendMessage $uuid.$SEP."GetMessage";
  if ($reply[0] != $errstrings{"SRV2CLT_OK"}) {
    printReplyError "$$: GetMessage", @reply;
    exit 1;
  }

  print "\nIMPORTANT MESSAGE FROM VPN-over-DNS SERVICE:\n$reply[1]\n\n" if ($#reply > 0 && $reply[1] ne "");
}

# Listen to a TCP port and redirect data from/to the server.
sub setTunnel($$$$) {
  my ($param, $bindall, $uuid, $loop) = @_;

  my @args = split /:/, $param;

  # Bind the server socket.
  my $bindaddr = $bindall ? INADDR_ANY : INADDR_LOOPBACK;
  if ($#args == 3) {
    $bindaddr = inet_aton($args[0]) or die "$$: invalid address $args[0]: $!\n";
    shift @args;
  }
  my ($port, $host, $hostport) = @args;
  socket SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp') or die "$$: socket: $!";
  setsockopt SERVER, SOL_SOCKET, SO_REUSEADDR, 1 or die "$$: setsockopt: $!";
  my $my_addr = sockaddr_in $port, $bindaddr;
  bind SERVER, $my_addr or die "$$: can not bind to port $port: $!".($optinitialize ? " - try using -p option" : "")."\n";
  listen SERVER, SOMAXCONN or die "$$: can not listen on port $port: $!\n";
  print "$$: listening on port TCP/$port\n" if $loop;

  # Wait for connections.
  while (my $client_addr = accept CLIENT, SERVER) {
    my ($port, $packed_ip) = sockaddr_in($client_addr);
    my $dotted_quad = inet_ntoa $packed_ip;

    # Handle each new connection inside a new process.
    if (!fork) {
      # Child process.

      # This is absolutely mandatory: without this srand, the tickets
      # asked by different subprocess could be exactly the same
      # request, and a caching DNS could give the same answer to those
      # subprocesses, that would thus share the same remote buffer for
      # distincts commands !
      srand $$;
	
      print STDERR "$$: connection from: $dotted_quad:$port\n" if $loop or $optverbose;
      close SERVER;

      printMessage $uuid;

      # Ask the server to create a remote connection to the
      # destination host/port.
      my @reply = sendMessage $uuid.$SEP."ConnectSocket".$SEP.$hostport.$SEP.$host;
      if ($reply[0] != $errstrings{"SRV2CLT_SOCKET_ID"}) {
	printReplyError "ConnectSocket", @reply;
	close CLIENT;
	exit 1;
      }
      my $socketid = $reply[1];
      print STDERR "$$: SOCKETID = ($socketid)\n" if $optdebug;

      binmode CLIENT;
      my $fh = *CLIENT;
      my $select = IO::Select->new;
      if (!$select->add($fh)) {
	print STDERR "$$: error: select: $!\n";
	print "$$: closing $dotted_quad:$port (local error)\n";
	sendMessage $uuid.$SEP."ClosedSocket".$SEP.sprintf "%d", $socketid;
	close CLIENT;
	exit 1;
      }

      # Main loop.
      for (;;) {
	print STDERR "$$: LOOP\n" if $optdebug;

	# If local data is available before reaching a timeout, get a
	# bunch of $optlocalbytesbuffersize bytes.
	my $bytes = "";
	my $canread = $select->can_read($optchanneldelaycheck / 1E6);
	if (defined $canread) {
	  my $ret = sysread $fh, $bytes, $optlocalbytesbuffersize;
	  if (!defined $ret or $ret == 0) {
	    my $errstr = "EOF";
	    $errstr = $! unless defined $ret;
	    print STDERR "$$:  error: sysread: $errstr\n" if $optdebug;
	    print "$$: closing $dotted_quad:$port (local EOF)\n" if $optverbose;
	    sendMessage $uuid.$SEP."ClosedSocket".$SEP.sprintf "%d", $socketid;
	    close CLIENT;
	    exit 1;
	  }
	}

	# Send local data and loop until all data available on the
	# server side has been fetched.
	my @reply;
	do {
	  # Send data if not already done and ask for data from the
	  # server side.
	  my $message = $uuid.$SEP."SocketData".$SEP.$socketid;
	  @reply = sendBinaryMessage $message, $bytes;
	  if ($reply[0] != $errstrings{"SRV2CLT_OK"}) {
	    printReplyError "SocketData", @reply
	      if ($optdebug or $#reply < 1 or $reply[0] != $errstrings{"SRV2CLT_EXCEPTION"} or $reply[1] ne "Error: EOF");
	    print "$$: closing $dotted_quad:$port (remote EOF)\n" if $loop or $optverbose;
	    close CLIENT;
	    exit 1;
	  }

	  # If data has been fetched from the server side, write it to
	  # the local socket.
	  if (length $reply[2] > 0) {
	    my $ret = syswrite $fh, $reply[2];
	    if (!defined $ret or $ret != length $reply[2]) {
	      my $errstr = "invalid byte count";
	      $errstr = $! unless defined $ret;
	      print STDERR "$$: error: syswrite: $errstr\n"
		if ($optdebug or (defined $ret and $ret != length $reply[2]));
	      print "$$: closing $dotted_quad:$port (local EOF)\n" if $loop or $optverbose;
	      sendMessage $uuid.$SEP."ClosedSocket".$SEP.sprintf "%d", $socketid;
	      close CLIENT;
	      exit 1;
	    }
	  }
	  $bytes = "";
	} while length $reply[2] > 0;
      }

    } else {
      close CLIENT;
    }

    last unless $loop;
  }

  close SERVER;
  exit 0;
}

# Get the cached user id from the filesystem.
sub getUUID() {
  open my $in, '<', $conffile or die "$$: can not open file $conffile: $!\nPlease, first launch vpnoverdns.pl using '-i' command line parameter to associate this computer with a registered mobile account, using '-u' if you already know your own uuid number or using '-A' to get an anonymous restricted account.\n";
  die "$$: can not read file $conffile: $!" unless defined(my $uuid = <$in>);
  close $in or die "$$: can not close file $conffile: $!";
  return $uuid;
}

# Set anonymous restricted account mode.
sub setAnonymousUUID() {
  open my $out, '>', $conffile or die "$$: can not open file $conffile: $!";
  print $out $anonymousuuid or die "$$: can not write file $conffile: $!";
  close $out or die "$$: can not close file $conffile: $!";
}

# Set some uuid locally (no SSL/TLS tunnel over DNS needed to set this
# full account uuid).
sub setUUID($) {
  my $uuid = shift;
  open my $out, '>', $conffile or die "$$: can not open file $conffile: $!";
  print $out $uuid or die "$$: can not write file $conffile: $!";
  close $out or die "$$: can not close file $conffile: $!";
}

# Fetch the user id establishing a SSL/TLS over DNS tunnel, and save it on
# the filesystem.
sub getRemoteUUID($$$) {
  my ($username, $password, $verify) = @_;

  print STDERR "$$: warning: a server timeout may occur when setting a low value for parallel requests\n"
    if $optmaxparallelrequests < 10;
  print STDERR "$$: warning: a server timeout may occur when setting a low value for localbuf\n"
    if $optlocalbytesbuffersize < 512;

  # Do not be trashed by the environment.
  undef $ENV{HTTPS_CA_FILE};
  undef $ENV{HTTPS_CA_DIR};

  die "$$: may not be able to verify SSL/TLS certificate over a proxied connection, libwww-perl (LWP) version too old => use -n option to bypass validation or upgrade libwww-perl\n"
      if (LWP::UserAgent->VERSION < 6.02 && $verify == 1);

  push my @opts, (ssl_opts => { verify_hostname => $verify, SSL_verify_mode => $verify }) if LWP::UserAgent->VERSION >= 6.02;

  # Create a single-shot TCP over DNS tunnel with a new process.
  if (!fork) {
    setTunnel("$optinitlistenport:127.0.0.1:".(LWP::UserAgent->VERSION >= 6.02 ? 3130 : 443), 0, $initializeuuid, 0);
    exit 0;
  }

  # Build a SSL/TLS query proxied through the TCP over DNS tunnel.
  my $ua = LWP::UserAgent->new(@opts);
  $ua->agent("VPNoverDNSperl/1.0 ");

  # If LWP::Protocol::connect available, use CONNECT method.
  $ua->proxy('https', ($modCONNECT ? 'connect' : 'http')."://127.0.0.1:$optinitlistenport");
  # Do not be trashed by the environment.
  undef $ENV{HTTPS_PROXY};
  
  # wwwbadname is associated with the same IP as www.vpnoverdns.com on the apache docker container,
  # but it should throw a certificate validation error. This is for validation purpose only.
  # Uncomment this line to check for certification validation error:
  #my $req = HTTP::Request->new('POST', 'https://wwwbadname.vpnoverdns.com/mail4hotspot/app/mobile-get-user');
  # It should display something like "SSL upgrade failed: SSL connect attempt failed with unknown error error:14090086:SSL routines:SSL3_GET_SERVER_CERTIFICATE:certificate".
  my $req = HTTP::Request->new('POST', 'https://www.vpnoverdns.com/mail4hotspot/app/mobile-get-user');
  
  $req->content_type('application/x-www-form-urlencoded');
  $req->content("username=$username&password=$password&info=perl");
  my $response;

  # Try to process the query several times until the tunnel has been
  # used. This loop is needed since the subprocess may have not been
  # fast enough to listen to the local socket before the parent first
  # tries to use it. To avoid this loop, an interprocess communication
  # mechanism should be used, but it may badly wire the code to some
  # specific operating system.
  my $nretries = 0;
  do {
    $response = $ua->request($req);
    if ($response->is_success) {
      print "changing previous preferred parser (".$XML::Simple::PREFERRED_PARSER.")" if ($optdebug && defined $XML::Simple::PREFERRED_PARSER);
      $XML::Simple::PREFERRED_PARSER = 'XML::Parser';

      print "$$: answer from server: {".$response->content."}\n" if $optverbose;

      my $parsed = XMLin($response->content, KeyAttr => {}, ForceArray => []);
      die "$$: can not find status code in server response\n".$response->content."\n"
	unless (defined $parsed->{'statusCode'});

      if ($parsed->{'statusCode'} == 0) {
	if (defined $parsed->{'uuid'}) {
	  print "uuid=".$parsed->{'uuid'}."\nsaving uuid to file $conffile\n";
	  open my $out, '>', $conffile or die "$$: can not open file $conffile: $!";
	  print $out $parsed->{'uuid'} or die "$$: can not write file $conffile: $!";
	  close $out or die "$$: can not close file $conffile: $!";
	  exit 0;
	} else {
	  die "$$: can not find uuid in server response";
	}
      }

      die defined $parsed->{'statusString'} ? "$$: server error: ".$parsed->{'statusString'}."\n" : "$$: can not find error string in server response" if $parsed->{'statusCode'} == 1;

      die "$$: invalid status code in server response".$response->content;
    } else {
      print STDERR "$$: bad response: ".$response->status_line."\nretrying...\n";
      if ($response->status_line =~ m/^500 Connect failed: connect: Operation now in progress.*/) {
	print STDERR "you need to upgrade libwww-perl (LWP): see 'Bug #43719 for libwww-perl: support for nonblocking sockets' at https://rt.cpan.org/Public/Bug/Display.html?id=43719\n";
	print STDERR "either upgrade libwww-perl (LWP) to version 6.06 or higher to use '-i' parameter, or see '-u' and '-A' parameters as an alternative\n";
	exit 0;
      }
      if ($response->status_line =~ m/^403 Forbidden.*/) {
	print STDERR "you may need to upgrade libwww-perl (LWP) to version 6.06 at least or install LWP-Protocol-connect (LWP::Protocol::connect), to use '-i' parameter and get correct support for SSL/TLS query proxied through the TCP over DNS tunnel.\nor see '-u' and '-A' parameters as an alternative\n";
	exit 0;
      }
      if ($response->status_line =~ m/.*routines:SSL3_GET_SERVER_CERTIFICATE:certificate verify failed.*/) {
	print STDERR "you may need to use -n option to bypass certificate validation or to upgrade libwww-perl\nyou may also use '-u' and '-A' parameters as an alternative to '-i'\n";
	exit 0;
      }
      sleep 1;
    }
  } until $response->is_success or $nretries++ == 3;

  die "Problem with LWP::UserAgent perl module => see '-u' and '-A' parameters instead.\n" if !$response->is_success;
}

# Compute the DNS round trip time and the average DNS packet loss ratio.
sub checkrtt($) {
  my $count = shift;
  my $nfailed = 0;
  my $averagertt = 0;
  for (my $len = 1; $len <= $count; $len++) {
    my $name = "rn-".random(8).".cn-".normalize(8, $len).".id-00000000.$service";
    print "$$: >>> send ping request, waiting for $len byte".($len >= 2 ? 's' : '')."\n";
    my $timenow = gettimeofday;
    my @msgbytes = getINA $name;
    $nfailed++ if $msgbytes[0];
    print "$$: >>> ".$msgbytes[0]." lost packet".($msgbytes[0] >= 2 ? 's' : '').($msgbytes[0] ? ' - failed request' : '')."\n" if $msgbytes[0];
    my $delay = gettimeofday - $timenow;
    $averagertt += $delay unless $msgbytes[0];
    print "$$: >>> response received in $delay s\n\n";
  }
  print "$$: failed requests: $nfailed / $count (".(int(100 * $nfailed / $count))."%)\n";
  print "$$: average rtt for non failed requests: ".($averagertt / ($count + 1 - $nfailed))." s\n";
}

# Send a new mail.
sub sendmail($) {
  my $uuid = shift;

  print "To: ";
  my $to = <>;
  chop $to;
  print "Cc: ";
  my $cc = <>;
  chop $cc;
  print "Subject: ";
  my $subject = <>;
  chop $subject;
  print "Enter the body and finish with EOF or a '.' at the start of an empty line\n";

  my $body = "";
  while (my $line = <>) {
    chop $line;
    last if $line =~ m/^.[^a-zA-Z0-9]*$/;
    $body .= $line."\n";
  }

  print "sending mail\n" if $optverbose;
  my @reply = sendMessage $uuid.$SEP."SendMail".$SEP.$to.$SEP.$cc.$SEP.$subject.$SEP.$body;
  if ($reply[0] != $errstrings{"SRV2CLT_MAIL_SAVED"}) {
    printReplyError "CheckMails", @reply;
    exit 1;
  }

  print "mail accepted for delivery\n" if $optverbose;
}

# Check and retrieve new mails.
sub checkmails($) {
  my $uuid = shift;

  print "Ask the server to check mails\n" if $optverbose;
  my @reply = sendMessage $uuid.$SEP."CheckMails";
  if ($reply[0] != $errstrings{"SRV2CLT_START_CHECKING_MAILS"}) {
    printReplyError "CheckMails", @reply;
    exit 1;
  }

  for (;;) {
    @reply = sendMessage $uuid.$SEP."GetNMails";

    if ($reply[0] != $errstrings{"SRV2CLT_CURRENTLY_CHECKING_MAILS"} and $reply[0] != $errstrings{"SRV2CLT_NMAILS"}) {
      printReplyError "GetNMails", @reply;
      exit 1;
    }

    last if $reply[0] == $errstrings{"SRV2CLT_NMAILS"};
    print "The server is currently checking mails\n" if $optverbose;
    sleep 1;
  }
  print "$reply[2] new mail".($reply[2] > 1 ? "s" : "")."\n";

  for (;;) {
    @reply = sendMessage $uuid.$SEP."GetNewMail";

    if ($reply[0] == $errstrings{"SRV2CLT_CURRENTLY_CHECKING_MAILS"}) {
      print "The server is currently checking mails\n" if $optverbose;
      sleep 1;
      next;
    }

    last if ($reply[0] == $errstrings{"SRV2CLT_NO_UNREAD_MAIL"});

    if ($reply[0] == $errstrings{"SRV2CLT_NEW_MAIL"}) {
      print "-------------------------------------------------------------------------------\n";
      print "    From: $reply[2]\n";
      print "      To: $reply[3]\n";
      print "      Cc: $reply[4]\n";
      print " Subject: $reply[6]\n";
      print "    Sent: $reply[7]\n";
      print "Received: $reply[8]\n";
      print "\n";
      print "$reply[9]\n";
      next;
    }

    printReplyError "GetNewMail", @reply;
  }
}

sub launchSsh($$$$) {
  my ($target, $options, $command, $uuid) = @_;
    
  # Create a single-shot TCP over DNS tunnel with a new process.
  if (!fork) {
    setTunnel("$optinitlistenport:$target:22", 0, $uuid, 0);
    exit 0;
  }

  # This sleep is needed since the subprocess may not be fast enough
  # to listen to the local socket before the parent tries to use
  # it. To avoid this sleep, an interprocess communication mechanism
  # should be used, but it may badly wire the code to some specific
  # operating system.
  sleep 1;
  exec "ssh -p $optinitlistenport $options 127.0.0.1 $command" || die "$$: can not launch ssh";
}

# Some LWP::UserAgent behaviours depend on the version.
print "Net::DNS                 version: ".($modNetDNS ? Net::DNS->version : "not installed")."\n" if $optverbose;
print "LWP::UserAgent           version: ".($modLWP ? LWP::UserAgent->VERSION : "not installed")."\n" if $optverbose;
print "LWP::Protocol::https     version: ".($modHTTPS ? LWP::Protocol::https->VERSION : "not installed")."\n" if $optverbose;
print "LWP::Protocol::connect available: ".($modCONNECT ? "true" : "false")."\n" if $optverbose;
    
# Process command line parameters and options.

die "$$: need to select only one parameter among -h, -i, -u, -L, -c, -w, -A, -X, -S and -r\n"
  if $optuuid + $optinitialize + $optanonymous + $optlocal + $optcheckmails + $optsendmail + $optproxy + $optssh + !!$optping != 1;

print "Net::DNS perl module version 1.03: you may encounter this bug: https://rt.cpan.org/Public/Bug/Display.html?id=108745\nDowngrade to Net::DNS module version 1.02 to get rid of this bug.\n\n" if (Net::DNS->version eq '1.03');
print "Faster protocol activated with Net::DNS perl module version ".Net::DNS->version.": downgrade to Net::DNS module version 0.68 to go even faster.\n\n" if ($optfast && Net::DNS->version > 0.68);

# we can use binary content in IN TXT RRs
$optmaxread = 254 if ($optfast && Net::DNS->version <= 0.68);
# we need to use base64 encoding in IN TXT RRs
$optmaxread = 189 if ($optfast && Net::DNS->version > 0.68);

if ($optping) {
  pod2usage 2 if $#ARGV != -1;
  die "$$: error: max $maxrttbufsize requests\n" if $optping > $maxrttbufsize;
  checkrtt $optping;
  exit 0;
}

if ($optanonymous) {
  pod2usage 2 if $#ARGV != -1;
  setAnonymousUUID;
  exit 0;
}

if ($optuuid) {
  pod2usage 2 if $#ARGV != 0;
  setUUID $ARGV[0];
  exit 0;
}

if ($optproxy) {
  pod2usage 2 if $#ARGV != -1;
  my $uuid = getUUID;
  setTunnel "3128:127.0.0.1:".($uuid eq $anonymousuuid ? "3130" : "3129"), $optglobal, $uuid, 1;
  exit 0;
}

if ($optinitialize) {
  die "Parameter '-i' is not available since XML::Simple perl module is not installed.\n  => see '-u' parameter instead.\n  => or install XML::Simple, running 'cpan XML::Simple'\n" if !$modXMLSimple;
  die "Parameter '-i' is not available since LWP::UserAgent perl module is not installed.\n  => see '-u' parameter instead.\n  => or install LWP::UserAgent, running 'cpan LWP::UserAgent'\n" if !$modLWP;
  printMessage $initializeuuid;
  pod2usage 2 if $#ARGV != 1;
  getRemoteUUID $ARGV[0], $ARGV[1], !$optnocheckcert;
  exit 0;
}

printMessage getUUID;

if ($optcheckmails) {
  pod2usage 2 if $#ARGV != -1;
  checkmails getUUID;
  exit 0;
}

if ($optsendmail) {
  pod2usage 2 if $#ARGV != -1;
  sendmail getUUID;
  exit 0;
}

if ($optlocal) {
  pod2usage 2 if $#ARGV != 0;
  setTunnel $ARGV[0], $optglobal, getUUID, 1;
  exit 0;
}

if ($optssh) {
  pod2usage 2 if $#ARGV != 0;
  launchSsh $ARGV[0], $optsshoptions, $optsshcommand, getUUID;
  exit 0;
}

__END__

=head1 NAME

vpnoverdns.pl - a Perl client for the free VPN-over-DNS service
                at https://www.vpnoverdns.com
                version v1

See https://www.vpnoverdns.com

=head1 SYNOPSIS

Docker version manual:

To run vpnoverdns.pl within this docker image, just prepend

    "docker run --rm -t -i fenyoa/vpnoverdns"

to your traditional vpnoverdns.pl command line.
For instance, to connect to host this.host.domain with SSH over DNS, just run:

    "docker run --rm -t -i fenyoa/vpnoverdns vpnoverdns.pl -S this.host.domain"

To associate your client host with a VPN-over-DNS account, in order to use
advanced features, you first need to run this image with the -i option.
This will download you uuid to the image file /root/.vpnoverdns.
To make this file persistent across multiple runs, first create an empty
local uuid file (for instance /tmp/.vpnoverdns) and use the docker -v option
each time you run a container from this image:

 1- create your local uuid file:
    "rm -rf /tmp/.vpnoverdns ; touch /tmp/.vpnoverdns"

 2- initialize /tmp/.vpnoverdns with your uuid:
    "docker run --rm -t -i fenyoa/vpnoverdns \
                -v /tmp/.vpnoverdns:/root/.vpnoverdns \
                fenyoa/vpnoverdns vpnoverdns.pl -i username password"

 3- run vpnoverdns.pl:
    "docker run --rm -t -i fenyoa/vpnoverdns \
                -v /tmp/.vpnoverdns:/root/.vpnoverdns \
                fenyoa/vpnoverdns vpnoverdns.pl -S this.host.domain"


Original manual:

 vpnoverdns.pl [-dvFnsp] [NUMERIC_OPTS] -i username password
 vpnoverdns.pl [-dv]                    -u uuid
 vpnoverdns.pl [-dv]                    -A
 vpnoverdns.pl [-dvFsg]  [NUMERIC_OPTS] -L [bind_address:]port:host:hostport
 vpnoverdns.pl [-dvFsp]  [NUMERIC_OPTS] -S host [-o ssh_options] [-C command]
 vpnoverdns.pl [-dvFsg]  [NUMERIC_OPTS] -X
 vpnoverdns.pl [-dvFs]   [NUMERIC_OPTS] -c
 vpnoverdns.pl [-dvFs]   [NUMERIC_OPTS] -w
 vpnoverdns.pl [-dvFs]   [NUMERIC_OPTS] -r NUM
 vpnoverdns.pl -h

Installation  : https://www.vpnoverdns.com/download.html#cli
User's manual : https://www.vpnoverdns.com/perl.html
Other versions: https://www.vpnoverdns.com
Support       : support@vpnoverdns.com
Contact       : contact@vpnoverdns.com

 General parameters and options:
  --help          -h     displays this help text
  --debug         -d     debug protocol
  --fast          -F     use faster protocol
                         normal protocol: IN A records only
                         faster protocol: IN TXT + IN A records
  --verbose       -v     verbose output
  --silent        -s     avoid bursting - as a consequence, average throughput
                         is decreased
  --initialize    -i     associates with a mobile account on the server farm,
                         call it once at first use
                         the username and password fields are protected with
                         an SSL channel
  --uuid NUM      -u NUM associates with an account uuid,
                         call it once at first use
                         the preferred way is to use "-i" option: use "-u"
                         only if "-i" is unavailable because of a lack
                         of some Perl mandatory modules for SSL communications
  --anonymous     -A     associates with an anonymous restricted account,
                         call it once at first use
  --nocertcheck   -n     do not check server certificate
                         (in case LWP::UserAgent->VERSION < 6)
  --global        -g     allows remote hosts to connect to local forwarded
                         ports - same meaning as -g with SSH(1)
  --local         -L     specifies that the given port on the local (client)
                         host is to be forwarded to the given host and port on
                         the remote side
                         same meaning as -L with SSH(1)
  --ssh           -S     connect to remote host using a DNS tunnel.
  --sshoptions    -o     ssh command options.
                         ex.: vpnoverdns.pl -S mysshserver -o "-l root"
  --sshcommand    -C     optionnal ssh remote command.
                         ex.: vpnoverdns.pl -S mysshserver -C date
  --proxy         -X     listen on local port 3128 and tunnel this port to
                         - an open web proxy (http + https) if a mobile account
                           has been previously configured (see "-i" and
                           "-u" options)
                         - a restricted http only proxy if an anonymous
                           restricted account has been configured (see "-A"
                           option). This proxy can be used to browse
                           http://www.wikipedia.org and a few other sites.
  --checkmails    -c     check for new mails on the mail provider and retrieve
                         any pending mail
  --sendmail      -w     post a new mail
  --rtt NUM       -r NUM compute round trip time sending NUM requests
  --port          -p NUM listening TCP port used to relay SSL/TLS on top of DNS
                         when associating with a mobile account or when
                         tunneling a ssh connection

 Numeric sub options relative to DNS queries behaviour only:
  --maxwrite NUM  -m NUM change the byte count sent in one request
                         the highest possible value is 30 (default value)
                         this parameter is ignored in fast mode
  --maxread NUM   -Y NUM change the byte count received in one request
                         the default value (64) may by increased to speed up
                         the tunnel
                         this parameter is ignored in fast mode
  --delay4msg NUM -M NUM waiting delay before retry (microseconds), only used
                         when the server has not immediately processed a message
                         default value: 200000
  --delay4req NUM -R NUM waiting delay before retrying a DNS request that has
                         been lost (microseconds)
                         note that the applied delay is this value multiplied by
                         the number of tries to send the request
                         default value: 1000000
  --maxdelay NUM  -a NUM maximum waiting delay (seconds) before retrying a DNS
                         request
                         default value: 8
  --parallel NUM  -P NUM maximum number of parallel requests
                         default value: 20
  --localbuf NUM  -b NUM maximum number of local bytes sent before requesting
                         for remote bytes
                         default value: 1024
  --delaychk NUM  -D NUM delay between two checks for remote data for a
                         redirected channel (microseconds); only used when no
                         need to send local data
                         default value: 200000
  --fuzzy NUM     -f NUM add a background noise made of NUM random requests
                         for each protocol request
                         default value: 0

=head1 INSTALLATION

See https://www.vpnoverdns.com/download.html#cli

=head1 MANUAL

See https://www.vpnoverdns.com/perl.html

=head1 AUTHOR

Alexandre Fenyo <support@vpnoverdns.com> - https://www.fenyo.fr
