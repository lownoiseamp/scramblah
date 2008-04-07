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
@channels = ('#scramtest') if (scalar(@channels) == 0);

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
	'markov'	=> new Scramblah::Modes::RMarkov("", "scramble_text.single_sentences"),
	'lingua'	=> new Scramblah::Modes::Lingua("", "scramble_text.single_sentences"),
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

	# skip server messages
	return 0 if ($msg =~ m/(nick|slash|msg|nickserv)/);

	# return if multiple channels at once
    @$where == 1 or return 0;

    my ($nick, undef) = split(/!/, $who, 2);
    my $channel = $where->[0];
	my $type = $modes->{$mode};
    my $direct = 0;
	my $skip_save = 0;

    $msg =~ s/[^A-Za-z0-9,\.\?\-_!\'\"\s]//g;
    my @tokens = split(/\s+/, $msg);

	# someone's talking to me
    if ($msg =~ s/^scramblah[:,]\s*//i or $msg =~ s/^scramblah//i) {
        $direct = 1;
    	($who) = split(/\!/, $who);
    }

    if ($direct) {

		if (($who eq 'shift8') && ($tokens[0] eq 'quit') {
			$kernel->post($sender => privmsg => $channel => "ok. audi 9000!");
			exit(0);
		}

		if ($tokens[0] eq 'source') {
			$kernel->post($sender => privmsg => $channel => show_source());
			return 1;
		}

		# change mode if requested
		if ($token[0] eq "think") {
			if (exists($modes->{lc($tokens[1])})) {
				print STDOUT "***  Changing to mode \"$tokens[1]\".\n";
				$mode = $tokens[1];
				$type = $modes->{$mode};
				$kernel->post($sender => privmsg => $channel => "/me sybil forground personality is now '$mode',  Enjoy!");
			} else {
				$kernel->post($sender => privmsg => $channel => "/me sybil '$mode' personality isn't here Mrs Torrence.");
			}
			$skip_save = 1;
			
		}

		# check if we've been given a direct command
		if (exists($modes->{$mode}->{'commands'}->{$tokens[0]})) {
			$kernel->post($sender => privmsg => $channel => "rog-wilco, $who: " . &{$type->{$token[0]}}($kernel,$sender,$who,$where,$msg,\@tokens) );
			$skip_save = 1;
		} else {
			$kernel->post($sender => privmsg => $channel => $type->default($kernel,$sender,$who,$where,$msg,\@tokens) );
		}
    } 

	# update markov
    $modes->{'markov'}->{'instance'}->seed(symbols => \@tokens, longest => 40) unless ($skip_save);

	# update lingua
	$modes->{'lingua'}->{'instance'}->add($msg, $who, $where) unless ($skip_save);

    return 1;
}

# We registered for all events, this will produce some debug info.c
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

