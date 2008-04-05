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
#      VERSION:  1.0
#      CREATED:  04/02/2008 03:36:58 PM PDT
#     REVISION:  ---
#===============================================================================
package Scramblah::Modes::RMarkov;

use strict;
use warnings;
use Algorithm::MarkovChain;
use Data::Dumper;
use List::Util 'shuffle';

sub new {

	my $class = shift;
	my $dataset = shift;
	my $starter_text = shift;

	my $self = {
		'chain'			=> new Algorithm::MarkovChain,
		'start_tokens'	=> [],
		'starter'		=> $starter_text,
	};

	if ($starter_text) {
		open(IF, "< " . $self->{'starter'}) || print STDERR "starter text does not exist: $starter_text\n";
		local $/;
		my $t = <IF>;
		my @tokens = split(/\s+/, $t);
    	$self->{chain}->seed(symbols => \@tokens, longest => int(rand(15) + 10));
		close(IF);
		$self->{start_tokens} = \@tokens;
	}

	if ($dataset) {	
    	$self->{chain}->seed(symbols => $dataset, longest => int(rand(15) + 10));
		$self->{start_tokens} = $dataset;
	}

	return bless $self;
}

sub scramble {
    my ($self, $kernel,$sender,$who,$where,$msg, $tokens) = @_;

    $self->{chain} = new Algorithm::MarkovChain;
    my @tokens_shuffled = shuffle($self->{start_tokens});
    $self->{chain}->seed(symbols => \@tokens_shuffled, longest => int(rand(15) + 10));

    return "";

}

sub reload {
    my ($self,$kernel,$sender,$who,$where,$msg, $tokens) = @_;

    $self->{chain} = new Algorithm::MarkovChain;
    $self->{chain}->seed(symbols => $self->{start_tokens}, longest => int(rand(15) + 10));

    return "";
}

sub smokedope {
	my ($self,$kernel,$sender,$who,$where,$msg,$tokens) = @_;
	$self->{save_on_exit} = 0;
	return "";
}

sub potfree {
	my ($self,$kernel,$sender,$who,$where,$msg,$tokens) = @_;
	$self->{save_on_exit} = 1;
	return "";
}

sub default {
	my ($self,$kernel,$sender,$who,$where,$msg,$tokens) = @_;

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

	# add it to the chains
    my @tokens = split(/\s+/, $msg);
    $self->{chain}->seed(symbols => \@tokens, longest => 40);

    return "well, $who, imma guessing $data..";

}

1;

