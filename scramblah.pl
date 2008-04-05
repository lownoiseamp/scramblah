#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  scramblah.pl
#
#        USAGE:  ./scramblah.pl server channel[,channel,channel.channel]
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  shift8
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  03/27/2008 05:07:49 PM PDT
#     REVISION:  ---
#===============================================================================
use strict;
use warnings;
use List::Util 'shuffle';
use POE qw(Component::IRC);

use lib "./lib";
use Scramblah::Modes::RMarkov;
use Scramblah::Modes::Lingua;

#===============================================================================
# IRC params and POE IRC session

my ($ircserver, $port) = split(/:/, $ARGV[0]);
my @channels = split(/,/, $ARGV[1]);

my $nickname = 'scramblah';
my $ircname = 'scramblah';

$ircserver = 'irc.freenode.net' if (!$ircserver);
$port = 6667 if (!$port);
@channels = ('#scramtest') if ($#channels == 0);

my $irc = POE::Component::IRC->spawn( 
      nick    => $nickname,
      server  => $ircserver,
      port    => $port,
      ircname => $ircname,
) or die "oh nos: $!";

POE::Session->create(
      package_states => [
              'main' => [ qw(_default _start irc_001 irc_public) ],
      ],
      heap => { irc => $irc },
);

our $mode = 'markov';

our $modes = {
	'markov'	=> {
		'dispatch' => {
			'source'	=> \&show_source,
			'quit'		=> sub{ exit; },
		},
		'instance'	=> new Scramblah::Modes::RMarkov("", "scramble_text.single_sentences"),
	},
	'lingua'	=> {
		'dispatch' => {
			'source'	=> \&show_source,
			'quit'		=> sub { exit; },
		},
		'instance'	=> new Scramblah::Modes::Lingua("", "scramble_text.single_sentences"),
	},
};

#===============================================================================
# main

$poe_kernel->run();
exit 0;

#===============================================================================
# local command functions

sub show_source {
	return "my guts are all splayed out @ " . 
			"http://github.com/lownoiseamp/scramblah/tree/master/scramblah.pl " . 
			"- bring a mop."
}

sub demand_load {
	my ($who, $msg) = @_;
	return 1;
}

#===============================================================================
# functionality

sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $irc_session = $heap->{irc}->session_id();
    $kernel->post( $irc_session => register => 'all' );
    $kernel->post( $irc_session => connect => { } );

    return undef;
}

sub irc_001 {
    my ($kernel,$sender) = @_[KERNEL,SENDER];

    print "Connected.\n";
    $kernel->post( $sender => join => $_ ) for @channels;
    return undef;
}

sub irc_public {
    my ($kernel,$sender,$who,$where,$msg) = @_[KERNEL,SENDER,ARG0,ARG1,ARG2];

	return 0 if ($msg =~ m/(nick|slash|nick|msg|nickserv)/);

    @$where == 1 or return 0; # Confuses me when a msg is to >1 channel

    my ($nick, undef) = split(/!/, $who, 2);
    my $channel = $where->[0];

    my $direct = 0;

    if ($msg =~ s/^scramblah[:,]\s*//i or $msg =~ s/^scramblah//i) {
        $direct = 1;
    }

    ($who) = split(/\!/, $who);

    $msg =~ s/[^A-Za-z0-9,\.\?\-_!\'\"\s]//g;

    if ($direct) {

        my @tokens = split(/\s+/, $msg);

		# set mode if need be
		if (exists($modes->{lc($tokens[0])})) {

			print STDOUT "***  Changing to mode \"$tokens[0]\".\n";
			eval { $modes->{$tokens[0]}->{'instance'} = new $modes->{'package'}(); };

			if (!$@) {
				$kernel->post($sender => privmsg => $channel => "sybil's forground personality is now " . $tokens[0] . ".  Enjoy!");
				$mode = $tokens[0];
			} else {
				$kernel->post($sender => privmsg => $channel => "sybil's '" . $tokens[0] . "' personality isn't here Mrs Torrence.");
			}

		}

		# check if this mode has been given a command
		if (exists($modes->{$mode}->{'commands'}->{$tokens[0]})) {

			print STDOUT "***  Running local command $tokens[0]...\n";
			$kernel->post($sender => privmsg => $channel => "rog-wilco, $who: " . $modes->{$tokens[0]}($kernel,$sender,$who,$where,$msg,\@tokens) );

		} else {
			my $res = $modes->{$mode}->{'instance'}->{'default'}($kernel,$sender,$who,$where,$msg,\@tokens);
		}


    } else {
		$kernel->post($sender => privmsg => $channel => "/me $who?...");
		return 1;
	}

	# update markov
    my @tokens = split(/\s+/, $msg);
    $modes->{'markov'}->{'instance'}->seed(symbols => \@tokens, longest => 40);

	# update lingua
	$modes->{'lingua'}->{'instance'}->add($msg, $who, $where);

    return 1;

}


# We registered for all events, this will produce some debug info.
sub _default {
    my ($event, $args) = @_[ARG0 .. $#_];
    my @output = ( "$event: " );

    foreach my $arg ( @$args ) {
        if ( ref($arg) eq 'ARRAY' ) {
                push( @output, "[" . join(" ,", @$arg ) . "]" );
        } else {
                push ( @output, "'$arg'" );
        }
    }

	return 0 unless $output[0] =~ m/irc_snotice/g;

    print STDOUT join ' ', @output, "\n";
    return 0;
}

