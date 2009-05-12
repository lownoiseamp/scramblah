#!/usr/bin/perl
#!/usr/bin/perl -w
use strict;
use Test::Simple tests => 5;

use Scramblah::Modes::RMarkov;

eval {
  my $rm = new Scramblah::Modes::RMarkov("", 'test.txt');
};
ok(!defined($@), "filename constructor");

eval {
  my $rm_d = new Scramblah::Modes::RMarkov(\['one', 'two', 'three', 'four']);
};
ok(!defined($@), "array refcontructor");

ok($rm->scramble() == 1, "scramble works");
ok($rm->reload() == 1, "reload works");
ok(ref($rm->default()) eq "SCALAR", "default POE method works");

