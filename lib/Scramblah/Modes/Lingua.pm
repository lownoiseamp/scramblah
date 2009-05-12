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
no strict "vars";
use warnings;
use lib "../../../lib/";
use Scramblah::Util;
use Lingua::EN::Sentence qw( get_sentences );
use Lingua::EN::Tagger;
use Lingua::En::Victory;
use Lingua::EN::Syllable qw( syllable );
use XML::Simple;
use Data::Dumper;
use List::Util 'shuffle';

sub new {
  my ($class,$debug) = @_;

  my $self = {
	   'save'	 => 1,
       'parse_s' => \&get_sentences,
	   'tagger'	 => new Lingua::EN::Tagger(relax => 1, stem => 1),
	   'victor'	 => new Lingua::En::Victory(),
	   'xmlp'	 => new XML::Simple(),
	   'util'	 => new Scramblah::Util(),
       'users'   => {},
	   'storage' => {},

	   'debug'   => $debug,

       'public_commands' => {
          'be' => &be,
          'quote' => &quote,
        },
        'index' 
  };

  #HASH OF words.
  #is hash key is hash w/ keys for neighbors
  #each neighbor is a ref and has value for distance
  #each neighbor as count of seen;

  bless $self, $class;
}

#===============================================================================
# command handlers

# default
sub default {
	my ($self, $who, $msg) = @_;

	# parse the sentense or phrase
	# make a match on dataset with the same
	# randomise a response based on the inbound data
	# -- select least-seen reponse symbols from db
	# -- update "seen" for the random items selected and users associated
	# select a random gramatical form for response
	# return results.

	# hack for now....
	my $grammarForm = $self->genGrammticalForm();
	my @words;
	my $res;
	my @puncs;
    my $pp = "";

    if (($grammarForm->[0] eq 'wdt') || ($grammarForm->[0] eq 'md')
        || ($grammarForm->[0] eq 'wp') || ($grammarForm->[0] eq 'wrd')) {
      $pp = "?";
    }

	foreach my $tag (@{$grammarForm}) {
        print "$tag | ";
		@words = keys(%{$self->{storage}->{$tag}->{words}});
		$res .= lc($words[int(rand($#words))]) . " ";
	}

    $res =~ s/\ $//;

	#@puncs = keys(%{$self->{storage}->{"pp"}->{words}});
    if ($pp eq "") {
      $pp = ".";
    }
	return "$who: $res" . $pp . "\n";
}

# save state?
sub save {
	my ($self, $save) = @_;
    return 0 unless ($save =~m/^[0,1]$/);
	$self->{save} = $save;
    return 1;
}

# become an irc person (ala perlbot)
sub be {
	my ($self,$who) = @_;
    #return 0 unless exists($self->{storage}->{users}->{$who});
    #$self->{be} = $who;
    return 1;
}

# quote an irc person with given words used or random if none
sub quote {
	my ($self,$who, $word) = @_;
}

# fun toy for penut galley-ing a competiion
sub wins {
	my ($self,$kernel,$sender,$who,$where,$msg,$tokens) = @_;
	$self->{util}->error("::wins called: " . Dumper($tokens) . "\n", __PACKAGE__) if $self->{debug};
	return $self->{'victor'}->rand_exp($tokens->[1], $tokens->[2]);
}

# generate a random hiku from the text db
sub hiku {
	my ($self,$kernel,$sender,$who,$where,$msg,$tokens) = @_;
	$self->{util}->error("::hiku called: " . Dumper($tokens) . "\n", __PACKAGE__) if $self->{debug};

	return "";
}

#===============================================================================
# utility functions

sub dump {
	my ($self) = shift;
	print Dumper($self->{storage});
	exit(0);
}


sub store {
  my ($self, $who, $msg) = @_;
  my $idx = 0;	
  my $tt;
  my $pt;

  print "store called $who : " . substr($msg, 0, 10) . "\n";

  my $data_ref;
  my $storage_ref;
  my @data = $self->{'parse_s'}->($msg);

#  print Dumper(\@data);

  foreach my $s (@{$data[0]}) {

    # clean up
	$s =~ s/\ ?\n/\ /g;
	$s =~ s/\ {2,}/\ /g;
	$tt = $self->{'tagger'}->add_tags($s);
	$pt = $self->{xmlp}->XMLin("<sentence>$tt</sentence>") || die("$s ... $!");
    #print $s . "\n";
	$data_ref = {'time' => time(), "sentence" => $s, 'who' => $who, 'parsed' => $pt};

	foreach my $type (keys(%{$pt})) {
	  if (ref($pt->{$type}) eq "ARRAY") {
        for  ($idx =0,$idx <= $#{$pt->{$type}}, $idx++) {

          if (ref($self->{storage}->{$type}->{words}->{$pt->{$type}->[$idx]}) ne 'ARRAY') {
            $self->{storage}->{$type}->{words}->{$pt->{$type}->[$idx]} = [];
          }
          $storage_ref = $self->{storage}->{$type}->{words}->{$pt->{$type}->[$idx]};
          
          push(@{$storage_ref}, $data_ref)
            unless $storage_ref->[$#{$storage_ref}] eq $data_ref;

          $self->{storage}->{histo}->{$pt->{$type}->[$idx]}++;
		}

	  } else {
        if (ref($self->{storage}->{$type}->{words}->{$pt->{$type}}) ne 'ARRAY') {
          $self->{storage}->{$type}->{words}->{$pt->{$type}} = [];
        }
        $storage_ref = $self->{storage}->{$type}->{words}->{$pt->{$type}};
        push(@{$storage_ref}, $data_ref)
          unless $storage_ref->[$#{$storage_ref}] eq $data_ref;
        $self->{storage}->{histo}->{$pt->{$type}}++;
	  }
	}
  }

  print Dumper($self->{storage}) if $self->{debug};

  #foreach my $t (%{$self->{storage}}) {
  #  next if ref($t) eq 'HASH';
  #  print "type: $t\n";
  #  my @words = keys(%{$self->{storage}->{$t}->{words}});
  #  for (1..5) {
  #    print "   " . $words[int(rand($#words))] . "\n";
  #  }
  #}
  return 1;
}

sub load_file {
	my ($self, $file) = @_;

    print "loading file: \"$file\"\n" if $self->{debug};

	my $text = "";
	
	# sanitize file path
	if ($file) {

	  if ($file =~ m/^\//g) {
	    return "no can do buddy-o.";
	  }

	  # skip non-existant files
	  return "whatchu talking bout willis." unless (-f $file);

    } else {
      return "load what?";
    }

	if (open(IF, "< " . $file)) {
		local $/;
		$text = <IF>;
		close(IF);
	} else {
    	print STDERR "failed to open " . $$file . ": $!";
	}
 
	# parse it up, index and store.
	my $tt = "";
	my $pt = "";
	my %w_type = ();
	my %idx_seen = ();
	my $s = "";
	my $idx = 0;

    $self->store($file, $text) || print STDERR "store failed in load\n";

	return 1;
}

sub genGrammticalForm {
	my ($self) = shift;

	my @forms = (
		['jjr', 'nns', 'to', 'vb', 'to', 'prps', 'cd', 'nns'],
		['wdt', 'jj', 'nn', 'vbz', 'vbp'],
		['wrb', 'prps', 'vbz', 'vb', 'nn', 'ppc','vb','in','jj','nn'],
        ['vb', 'jj', 'nns', 'wdt', 'vb','jjr', 'nns'],
        ['wp','nns','jjr','in','nns','in','vbz'],
        ['rb','cd','nns','vb','det','nn','nns','vbp'],
        ['nns', 'vb','jj','nn','rb'],
        ['prps', 'jj','nn','vbz','rb','rb'],
        ['jj','nn','vbz','rb'],
        ['vbg','to','det','nns','jjr','nns','vbz','jjs']
	);
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
