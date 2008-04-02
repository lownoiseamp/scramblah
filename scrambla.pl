#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  ubot.pl
#
#        USAGE:  ./ubot.pl 
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Star Morin (sm), <Star Morin>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  03/27/2008 05:07:49 PM PDT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;


  # A simple Rot13 'encryption' bot

  use strict;
  use warnings;
  use POE qw(Component::IRC);
  use Algorithm::MarkovChain;

  my $nickname = 'scramblah';
  my $ircname = 'scramblah';
  my $ircserver = 'irc.freenode.net';
  my $port = 6667;

  my @channels = ( '#boingboing' );

    our $chain = Algorithm::MarkovChain->new;
    our $head = int(rand(13231));
    our $starter = `cat scramble_text.single_sentences`;
    our @tokens = split(/\s+/, $starter);
    $chain->seed(symbols => \@tokens, longest => 10);


  # We create a new PoCo-IRC object and component.
  my $irc = POE::Component::IRC->spawn( 
        nick => $nickname,
        server => $ircserver,
        port => $port,
        ircname => $ircname,
  ) or die "Oh noooo! $!";

  POE::Session->create(
        package_states => [
                'main' => [ qw(_default _start irc_001 irc_public) ],
        ],
        heap => { irc => $irc },
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # We get the session ID of the component from the object
    # and register and connect to the specified server.
    my $irc_session = $heap->{irc}->session_id();
    $kernel->post( $irc_session => register => 'all' );
    $kernel->post( $irc_session => connect => { } );
    undef;
  }

  sub irc_001 {
    my ($kernel,$sender) = @_[KERNEL,SENDER];

    # Get the component's object at any time by accessing the heap of
    # the SENDER
    print "Connected.\n";

    # In any irc_* events SENDER will be the PoCo-IRC session
    $kernel->post( $sender => join => $_ ) for @channels;
    undef;
  }

  sub irc_public {
    my ($kernel,$sender,$who,$where,$msg) = @_[KERNEL,SENDER,ARG0,ARG1,ARG2];

	return 0 if ($msg =~ m/(nick|slash|nick|msg|nickserv|msg|nickserv)/);

    @$where == 1 or return 0; # Confuses me when a msg is to >1 channel

    my ($nick, undef) = split(/!/, $who, 2);
    my $channel = $where->[0];

    my $direct = 0;

    if ($msg =~ s/^scramblah[:,]\s*//i or $msg =~ s/scramblah//i) {
        $direct = 1;
    }

    ($who) = split(/\!/, $who);

    $msg =~ s/[^A-Za-z0-9,\.\?\-_!\'\"\s]//g;

    if ($direct) {

        print "Spewing...\n";
        $msg =~ s/\bspew\b/ /g;
        my @tokens = split(/\s+/, $msg);

        my @new = $chain->spew(
            'length' => rand(15) + 10,
            complete => [ @tokens ],
        );

		my $data  = "";
		foreach (@new) {
			$data .= " " . $_;
			last if $data =~ m/\./g;
		} 
	
        #my $data = join(' ', @new);
        $data =~ s/\s*scramblah\s*/ /ig;
        print "Spew output is $data\n";
	    $kernel->post( $sender => privmsg => $channel => "well, $who, imma guessing $data." );
        return 1;

    }

    @tokens = split(/\s+/, $msg);

    $chain->seed(symbols => \@tokens, longest => 10);

    return 0; 
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
    print STDOUT join ' ', @output, "\n";
    return 0;
  }

