#!/usr/bin/perl -w

# vclean.pl
# David_Harris@hmc.edu 7 December 2023
# Identifies unused signals in Verilog files
#   verilator should do this, but it also reports partially used signals

for (my $i=0; $i<=$#ARGV; $i++) {
    my $fname = $ARGV[$i];
    printf ("$fname\n");
}
