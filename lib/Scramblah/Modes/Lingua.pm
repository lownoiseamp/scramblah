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
use XML::Simple;
use Data::Dumper;
use List::Util 'shuffle';

sub new {
    my $class = shift;
	my $dataset = shift;
	my $starter_text = shift;
	my $debug = shift;

    my $self = {
		'save'			=> 1,
        'parse_s'       => \&get_sentences,
		'tagger'		=> new Lingua::EN::Tagger(relax => 1, stem => 1, unknown_word_tag => "slang"),
		'victor'		=> new Lingua::En::Victory(),
		'xmlp'			=> new XML::Simple(),
        'users'  		=> {},
		'tokens'		=> {
			'txt'	=> [],
			'users'	=> [],
			'index'	=> {},
		},
		'starter_text'  => $starter_text,
		'debug'			=> $debug,
    };

    bless $self, $class;

	if ($starter_text) {
		$self->load("","","","","",[undef, $starter_text]);
	}

	return $self;
}
#===============================================================================
# command handlers

# default when someone talks to scramblah without explicit command
sub default {
	my ($self,$kernel,$sender,$who,$where,$msg,$tokens) = @_;
	print STDERR "::default called: " . Dumper($tokens) . "\n" if $self->{debug};

	# add the current message.
	$self->load($kernel,$sender,$who,$where,$msg,$tokens);
	# parse the sentense or phrase
	
	# match a previous sentence with noun and verb
	# make a match on dataset with the same
	# randomise a response based on the inbound data
	# -- select least-seen reponse symbols from db
	# -- update "seen" for the random items selected and users associated
	# select a random gramatical form for response
	# return results.

	# hack for now....
	my $grammarForm = $self->genGrammaticalForm();
	my @words = ();
	my $res;
	my $punc;

	foreach (@{$grammarForm}) {
		@words = keys(%{$self->{tokens}->{index}->{$_}});
		$res .= $words[int(rand($#words))];
	}

	$punc = (keys(%{$self->{tokens}->{index}->{pp}}))[int(rand(scalar(%{$self->{tokens}->{pp}})))];

	return $res . $punc;
}

# don't save state on exit
sub smokeDope {

	my ($self) = shift;
	$self->{save} =  0;
	return "Uuhm, whuuUUuut? i can't remember....";

}

# save state one exit
sub potFree {

	my ($self) = shift;
	$self->{save} =  1;
	return "i have put the pipe down now.  suddenly i remember stuff! (well, dreams mostly...)";

}

# become a irc person (ala perlbot)
sub be {
	my ($self,$kernel,$sender,$who,$where,$msg,$tokens) = @_;
	print STDERR "::be called: " . Dumper($tokens) . "\n" if $self->{debug};

	# find a sentence by given user that matches the most
	# tokens, reconstruct and return.

	return "";
}

# quote a irc person with given words used or random if none
sub quote {
	my ($self,$kernel,$sender,$who,$where,$msg,$tokens) = @_;
	print STDERR "::quote called: " . Dumper($tokens) . "\n" if $self->{debug};

	return "";
}

# fun toy for penut galley-ing a competiion
sub wins {
	my ($self,$kernel,$sender,$who,$where,$msg,$tokens) = @_;
	print STDERR "::wins called: " . Dumper($tokens) . "\n" if $self->{debug};

	return "";
}

# generate a random hiku from the text db
sub hiku {
	my ($self,$kernel,$sender,$who,$where,$msg,$tokens) = @_;
	print STDERR "::hiku called: " . Dumper($tokens) . "\n" if $self->{debug};

	return "";
}

#===============================================================================
# utility functions

sub dump {
	my ($self) = shift;
	print Dumper($self->{tokens});
	exit(0);
}

sub load {
	my ($self,$kernel,$sender,$who,$where,$msg,$tokens) = @_;
	print STDERR "::load called: " . Dumper($tokens) . "\n" if $self->{debug};

	# is this a txt load or a irc communication?
	my $store = "";
	my $full_text = "";

	if (($tokens->[2]) && ($tokens->[2] eq "file")) {

		# sanitize file path
		if (($tokens->[1] =~ m/^\//g)) {
			return "no can do buddy-o.";
		}

		# skip non-existant files
		return "whatchu talking bout willis." unless (-f $tokens->[1]);

		$store = "txt";
		if (open(IF, "< " . $tokens->[1])) {
			local $/;
			$full_text = <IF>;
			close(IF);
		} else {
            print STDERR "failed to open " . $tokens->[1] . ": $!";
		}

	} else {
		# it's just a sentence to add
		$store = $who;
		$full_text = $msg;
	}
 
	# parse it up, index and store.
	my $tt = "";
	my $pt = "";
	my %w_type = ();
	my %idx_seen = ();
	my $s = "";
	my $idx = 0;
	my @sentences = $self->{'parse_s'}->($full_text);

	# don't know why Lingua::EN:Sentence returns this way, but whatever.
	foreach $s (@{$sentences[0]}) {

		# clean up
		$s =~ s/\ ?\n/\ /g;
		$s =~ s/\ {2,}/\ /g;

		$tt = $self->{'tagger'}->add_tags($s);
		$pt = $self->{xmlp}->XMLin("<sentence>$tt</sentence>");

		# add tokenized by occurrence and source
		push(@{$self->{tokens}->{$store}}, {'raw' => $s, 'parsed' => $pt});

		# create an index of words and the number of times seen and where
		foreach my $type (keys(%{$pt})) {
			if (ref($pt->{$type}) eq "ARRAY") {

				for  ($idx =0,$idx <= $#{$pt->{$type}}, $idx++) { 
					$self->{tokens}->{index}->{$type}->{$pt->{$type}->[$idx]}++;
				}

			} else {
				$self->{tokens}->{index}->{$type}->{$pt->{$type}}++;
			}
		}
    }
	return 1;
}

sub genGrammticalForm {
	my ($self) = shift;

	my @forms = [
		['rb', 'jj', 'nn', 'md', 'jj', 'vbp', 'in'],
	];
	my @shuffled = shuffle(@forms);
	return pop(@shuffled);

}

sub DESTROY {
    my ($self) = shift;
	my $file = "scramblah.m.out";

	if ($self->{save} != 0) {
		print STDERR "Destroy called with save active\n";
    	if (open (OF, ">$file")) {
			for my $base ('txt', 'users') {
				foreach (@{$self->{tokens}->{$base}}) {
					print OF $_->{raw} . "\n";
				}
			}
    	    close(OF);
    	} else {
    	    print STDERR "error opening save file: $!";
    	}
	}
	return 1;
}

1;
