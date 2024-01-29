#!/bin/perl -W

###########################################
## derivgen.pl
##
## Written: David_Harris@hmc.edu 
## Created: 29 January 2024
## Modified: 
##
## Purpose: Read config/derivlist.txt and generate config/deriv/*/config.vh
##          derivative configurations from the base configurations
##
## A component of the CORE-V-WALLY configurable RISC-V project.
## https://github.com/openhwgroup/cvw
## https://github.com/openhwgroup/cvw
##
## Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
##
## SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
##
## Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
## except in compliance with the License, or, at your option, the Apache License version 2.0. You 
## may obtain a copy of the License at
##
## https:##solderpad.org/licenses/SHL-2.1/
##
## Unless required by applicable law or agreed to in writing, any work distributed under the 
## License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
## either express or implied. See the License for the specific language governing permissions 
## and limitations under the License.
################################################################################################


use strict;
use warnings;
import os;

my $curderiv = "";
my @derivlist = ();
my %derivs;
my %basederiv;

if ($#ARGV != -1) {
    die("Usage: $0")
}
my $derivlist = "$ENV{WALLY}/config/derivlist.txt";
open(my $fh, $derivlist) or die "Could not open file '$derivlist' $!";
foreach my $line (<$fh>) {
    chomp $line;
    my @tokens = split('\s+', $line);
    if ($#tokens < 0 || $tokens[0] =~ /^#/) {   # skip blank lines and comments
        next;
    }
    if ($tokens[0] =~ /deriv/) {   # start of a new derivative
        &terminateDeriv();
        $curderiv = $tokens[1];
        $basederiv{$curderiv} = $tokens[2];
#        print("Found deriv $curderiv based on $basederiv{$curderiv}\n");
        @derivlist = ();
        if ($#tokens > 2) {
#            print("  with $tokens[3]\n");
            my $inherits = $derivs{$tokens[3]};
#            &printref($inherits);
            @derivlist = @{$inherits};
#            foreach my $entry (@derivlist) {
#                print("  Entry: @$entry\n");
#            }
#            print ("  dt3 = $inherits as array @derivlist\n");
#            print("  derivlist = @derivlist\n"); */
        }
    } else {   # add to the current derivative
        my @entry = ($tokens[0], $tokens[1]);
#        print("  Read Entry: @entry\n");
        push(@derivlist, \@entry);
    }
}
&terminateDeriv();
close($fh);
#system("mkdir $ENV{WALLY}/config/deriv");
foreach my $key (keys %derivs) {
    my $dir = "$ENV{WALLY}/config/deriv/$key";
    system("mkdir -p $dir");
    my $configunmod = "$dir/config_unmod.vh";
    my $config = "$dir/config.vh";
    my $base = "$ENV{WALLY}/config/$basederiv{$key}/config.vh";
    system("cp $base $configunmod");
    open(my $unmod, $configunmod) or die "Could not open file '$configunmod' $!";
    open(my $fh, '>>', $config) or die "Could not open file '$config' $!";

    my $datestring = localtime();
    print $fh "// Config $key automatically derived from $basederiv{$key} on $datestring usubg derivgen.pl\n";
    foreach my $line (<$unmod>) {
        foreach my $entry (@{$derivs{$key}}) {    
            my @ent = @{$entry};
            my $param = @ent[0];
            my $value = @ent[1];
            print(" In $config replace $param with $value\n");
#            $line =~ s/^\s*`define\s+$param\s+.*$/`define $param $value/;
            $line =~ s/$param\s*=\s*.*;/$param = $value;/;
        }
        print $fh $line;
    }
    close($fh);
    close($unmod);



}

#print("#######################\nKeys: ", join(' ', keys %derivs), "\n");
#foreach my $key (keys %derivs) {
#    print("  $key: $basederiv{$key} = ");
#    &printref($derivs{$key});
#}

sub terminateDeriv {
    if ($curderiv ne "") { # close out the previous derivative
        my @dl = @derivlist;
        $derivs{$curderiv} = \@dl;
#        print("Finished: $curderiv = $derivs{$curderiv} ");
#        &printref($derivs{$curderiv});
    }
};

sub printref {
    my $ref = shift;
    my @array = @{$ref};
#    print("  ## Printing ref $ref\n ");
    foreach my $entry (@array) {
        print join('_', @{$entry}), ', ';
    }
    print("\n");
}