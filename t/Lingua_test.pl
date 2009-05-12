#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  Lingua_test.pl
#
#        USAGE:  ./Lingua_test.pl 
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
#      CREATED:  04/07/2008 05:58:38 AM PDT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use lib "../lib";
use Scramblah::Modes::Lingua;

my $l = new Scramblah::Modes::Lingua("", $ARGV[0]);

my $res = $l->dump();
print $res . "\n" if $res =~ m/[a-z0-9]+/i;
