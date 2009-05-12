#===============================================================================
#
#         FILE:  RMarkov.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Star Morin (sm), <Star Morin>
#      COMPANY:  
#      VERSION:  0.02
#      CREATED:  04/02/2008 03:36:58 PM PDT
#     REVISION:  ---
#===============================================================================
package Scramblah::Modes::RMarkov;

use strict;
use warnings;
use Algorithm::MarkovChain;
use Data::Dumper;
use List::Util 'shuffle';

my $debug = 1;

# constructor
sub new {

  my ($class, $dataset, $starter_text) = @_;

  print Dumper(@_) if $debug;

  # internal storage is a hash
  my $self = {
    'chain'     => new Algorithm::MarkovChain,
    'start_tokens'  => [],
    'starter'   => $starter_text,
    'save'      => '0',
  };

  # load from file into the markov chain
  if ($starter_text) {
    print "loading $starter_text...\n" if $debug;
    open(IF, "< " . $self->{starter}) || print STDERR "starter text does not exist: $starter_text\n";
    local $/;
    my $t = <IF>;
    $self->{raw} = $t;
    my @tokens = split(/\s+/, $t);
    $self->{chain}->seed(symbols => \@tokens, longest => int(rand(15) + 10));
    close(IF);
    $self->{start_tokens} = \@tokens;
    print Dumper($self->{start_tokens});
  }


  # an array ref of data into markov chain
  if ($dataset ne "") { 
    $self->{chain}->seed(symbols => $dataset, longest => int(rand(15) + 10));
    $self->{start_tokens} = $dataset;
  }

  # return on object reference to my new instance
  return bless $self;
}

# mix up the data in the internal storage to create a new chain
sub scramble {
  my ($self) = @_;

  $self->{chain} = new Algorithm::MarkovChain;
  my @tokens_shuffled = shuffle($self->{start_tokens});
  $self->{chain}->seed(symbols => \@tokens_shuffled, longest => int(rand(15) + 10));

  return 1;
}

# reload the data in the instance in it's original form
sub reload {
  my ($self) = @_;

  $self->{chain} = new Algorithm::MarkovChain;
  $self->{chain}->seed(symbols => $self->{start_tokens}, longest => int(rand(15) + 10));

  return 1;
}

# don't save on exit
sub beForgetful {
  my ($self) = @_;
  $self->{save} = 0;
  return "";
}

# save on exit
sub beMindful {
  my ($self) = @_;
  $self->{save} = 1;
  return 1;
}

# add to the markov chain
sub store {
  my ($self, $msg, $who, $where, $tokens) = @_;

  $self->{'chain'}->seed(symbols => $tokens, longest => 40);

  return 1;

}

# default response method to POE events.
sub default {
  my ($self,$kernel,$sender,$who,$where,$msg,$tokens) = @_;

  print "default called" if $debug;

  my @new = $self->{chain}->spew(
      'length'   => rand(15) + 10,
      'complete' => [ @{$tokens} ],
    );

  my $data  = "";
  foreach (@new) {
    $data .= " " . $_;
    last if $data =~ m/\./g;
  }

  $data =~ s/^\ //g;
  $data =~ s/\s*scramblah\s*//ig;
  $self->{raw} .= "$msg\n";

  my @prefixes = ('well', 'now that you mention it', 'actually', 
                  'frankly', "i've heard");

  return $prefixes[int(rand($#prefixes))] . ", $who, $data";
}

sub error {
  my ($self, $msg) = @_;
  print STDERR __PACKAGE__ . " -> $msg \n";
  return 1;
}

# destructor to handle state saving
sub DESTROY {
  my ($self) = shift;
  my $file;

  if ($self->{starter_text}) {
    $file = $self->{starter_text};
  } else {
    $file = "scramblah.m.out";
  }

  if (open (OF, ">$file")) {
    print OF $self->{raw};
    close(OF);
  } else {
    print STDERR "error opening save file: $!";
  }
}

1;

=head1 NAME

Scramblah::Modes::RMarkov

=head1 SYNOPSIS

    my $markov_mode = new Scramblah::Modes::RMarkov($dataset_ref, $starter_filename);
    
    $response = $type->default($kernel,$sender,$who,$where,$msg,\@tokens);
    print "scramblah said: $response\n";
    
    # add it to the chain
    $markov_mode->store($msg, $who, $where,$tokens);

    # mix up the dataset
    $markov_mode->scramble();

    # remember data
    $markov_mode->beMindful();

    # forget new inbound data
    $markov_mode->beForgetful();

 
=head1 DESCRIPTION

This is a conversational mode implimentation for the Scramblah IRC bot.  
It is based on Algorythm::Markov, and basicly uses inbound text to create a chain 
of response text tokens, effectivly scrambling and regurgitating data in the
dataset.

=head2 Methods

=over 4

=item * scramble() - scramble the given text in the array hash and restore.

=item * reload() - reload the data in the instance variable $self->start_tokens

=item * beForgetful() - accessor that sets the save instance variable to true

=item * beMindful() - accessor that sets the save instance variable to false

=item * store($msg, $who, $where,$tokens) - add the text given in $tokens (parsed) and $msg (normal) to the storage

=item * default($kernel,$sender,$who,$where,$msg,$token) - default response method called by POE::Component::IRC

=item * error($msg) - print an error message to STDOUT

=back

=head1 SEE ALSO

L<Scramblah::Modes::Lingua>, L<scramblah.pl>, L<Algorithm::MarkovChain>.

=head1 COPYRIGHT

Copyright 2008. Star Morin <shift8@digitrash.com>

Permission is granted to copy, distribute and/or modify this 
document under the terms of the GNU Free Documentation 
License, Version 1.2 or any later version published by the 
Free Software Foundation; with no Invariant Sections, with 
no Front-Cover Texts, and with no Back-Cover Texts.

=cut

