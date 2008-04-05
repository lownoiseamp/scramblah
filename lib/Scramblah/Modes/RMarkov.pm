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
	my $starter_text = shift;

	my $self = {
		'chain'			=> new Algorithm::MarkovChain,
		'start_tokens'	=> [],
		'starter'		=> $starter_text,
	}

	return bless $self;
}

sub scramble {
    my ($kernel,$sender,$who,$where,$msg, $tokens) = @_;

    $self->{chain} = new Algorithm::MarkovChain;
    my @tokens_shuffled = shuffle(@tokens);
    $chain->seed(symbols => \@tokens_shuffled, longest => int(rand(15) + 10));

    return "";

}

sub reload {
    my ($kernel,$sender,$who,$where,$msg, $tokens) = @_;

    @tokens = split(/\s+/, $starter);
    $chain->seed(symbols => \@tokens, longest => int(rand(15) + 10));

    return "";
}

sub smokedope {
	my ($kernel,$sender,$who,$where,$msg,$tokens) = @_;
	$self->{save_on_exit} = 0;
	return "";
}

sub potfree {
	my ($kernel,$sender,$who,$where,$msg,$tokens) = @_;
	$self->{save_on_exit} = 1;
	return "";
}

sub default {
	my ($kernel,$sender,$who,$where,$msg,$tokens) = @_;

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
    @tokens = split(/\s+/, $msg);
    $self->{chain}->seed(symbols => \@tokens, longest => 40);

    return "well, $who, imma guessing $data..";

}
