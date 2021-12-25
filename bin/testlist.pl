#!/bin/perl -W
# testlist.pl
# David_Harris@hmc.edu 25 December 2021
# Read the work directories from riscv-arch-test or imperas-riscv-tests
# and generate a list of tests and signature addresses for tests.vh

use strict;
use warnings;
import os;

if ($#ARGV != 0) {
    die("Usage: $0 workpath [e.g. $0 ~/riscv-wally/addins/riscv-arch-test/work")
}
my $mypath = $ARGV[0];
my @dirs = glob($mypath.'/*/*');
foreach my $dir (@dirs) {
    $dir =~ /.*\/(.*)\/(.*)/;
    my $arch = $1;
    my $ext = $2;
    my $contents = `grep --with-filename "<begin_signature>:" $dir/*.objdump`;
    my @lines = split('\n', $contents);
    print "$arch/$ext";
    foreach my $line (@lines) {
        $line =~ /.*\/(.*)\.elf.objdump:(\S*)/;
        my $fname = $1;
        my $adr = $2;
        my $partialaddress = substr($adr, -6);
        print ",\n\t\t\"$arch/$ext/$fname\", \"$partialaddress\"";
    }
    print("\n\n");
}
