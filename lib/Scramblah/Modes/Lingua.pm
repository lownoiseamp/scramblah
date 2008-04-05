#
#===============================================================================
#
#         FILE:  Lingua.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Star Morin (sm), <Star Morin>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  04/02/2008 03:58:42 PM PDT
#     REVISION:  ---
#===============================================================================
package Scramblah::Modes::Lingua;

use strict;
use warnings;
use Lingua::EN::Sentence qw( get_sentences );
use Lingua::EN::Tagger;
use Lingua::En::Victory;
use Lingua::EN::Syllable qw( syllable );

sub new {
    my $class = shift;
	my $dataset = shift;
	my $starter_text = shift;

    my $self = {
        'parse_s'       => \&get_sentences,
		'tagger'		=> new Lingua::EN::Tagger(),
		'victor'		=> new Lingua::En::Victory(),
        'users'  		=> {},
		'tokens'		=> 
    };

    return bless $self;

}


sub smokedope {
	my ($kernel,$sender,$who,$where,$msg) = @_;

}

sub potfree {

}

sub be {

}

sub quote {

}

sub default {

}

1;

