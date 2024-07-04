#!/usr/bin/env -S perl -w

###########################################
## exe2memfile.pl
##
## Written: David_Harris@hmc.edu 
## Created: 26 November 2020
## Modified: 
##
## Purpose: Converts an executable file to a series of 32-bit hex instructions
##          to read into a Verilog simulation with $readmemh
##
## A component of the CORE-V-WALLY configurable RISC-V project.
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

# 
# 

use File::stat;
use IO::Handle;

if ($#ARGV == -1) {
    die("Usage: $0 executable_file");
}

# array to hold contents of memory file
my $maxmemfilesize = 1000000;
my @memfilebytes = (0)*$maxmemfilesize*4;
my $maxaddress = 0;

STDOUT->autoflush(1);
my $numfiles = $#ARGV+1;
if ($numfiles > 1) { 
    print ("Processing $numfiles memfiles: ");
}
my $frac = $#ARGV/10;
for(my $i=0; $i<=$#ARGV; $i++) {
    if ($i > 0 && ($i < 10 || $i % $frac == 0)) { print ("$i ") };
    my $fname = $ARGV[$i];
#    print "fname = $fname";
    my $ofile = $fname.".objdump";
    my $memfile = $fname.".memfile";

    my $needsprocessing = 0;
    if (!-e $memfile) { $needsprocessing = 1; } # create memfile if it doesn't exist
    else {
        my $osb = stat($ofile) || die("Can't stat $ofile");
        my $msb = stat($memfile) || die("Can't stat $memfile");
        my $otime = $osb->mtime;
        my $mtime = $msb->mtime;
        if ($otime > $mtime) { $needsprocessing = 1; } # is memfile out of date?
    }

    if ($needsprocessing == 1) {
        open(FILE, $ofile) || die("Can't read $ofile");
        my $mode = 0; # parse for code
        my $address;

    # initialize to all zeros;
        for (my $i=0; $i < $maxmemfilesize*4; $i++) {
            $memfilebytes[$i] = "00";
        }

        while(<FILE>) {
            if ($mode == 0) { # Parse code
    #	    print("Examining $_\n");
            if (/^\s*(\S\S\S\S\S\S\S\S):\s+(\S+)\s+/) {
                    $address = &fixadr($1);
                    my $instr = $2;
                    my $len = length($instr);
                    for (my $i=0; $i<$len/2; $i++) {
                        $memfilebytes[$address+$i] = substr($instr, $len-2-2*$i, 2);
                    }
    #                print ("address $address $instr\n");
            }
                if (/Disassembly of section .data:/) { $mode = 1;}
            } elsif ($mode == 1) { # Parse data segment
#                if (/^\s*(\S\S\S\S\S\S\S\S):\s+(.*)/) { # changed to \t 30 Oct 2021 dmh to fix parsing issue in d_fmadd_b17
                if (/^\s*(\S\S\S\S\S\S\S\S):\s+(.*)/) {
                    $address = &fixadr($1);
    #		        print "addresss $address maxaddress $maxaddress\n";
                    if ($address > $maxaddress) { $maxaddress = $address; }
                    #print "test $address $1 $2\n";
                    my $lineorig = $2;
                    my $line = $2;
                    # strip off leading 0x
                    $line =~ s/^0x//;
                    # merge chunks with spaces
                    $line =~ s/(\S)\s(\S)/$1$2/g;
                    my $linemerge = $line;
                    # strip off comments
                    $line =~ /^(\S*)/;
                    $payload = $1;
#                    if ($address >= 17520 && $address <= 17552) { # was 12304
#                        print "Address: $address\n  orig: $lineorig \n  merge: $linemerge \n  line: $line \n  payload: $payload\n";
#                    }
                    &emitData($address, $payload);
                } 
                if (/Disassembly of section .riscv.attributes:/) { $mode = 2; }
            }
        }
        close(FILE);
#        print("maxaddress: $maxaddress\n");
        $maxaddress += 32; # pad some zeros at the end
#        print("maxaddress: $maxaddress\n");

        # print to memory file
        if ($fname =~ /rv32/) {
            open(MEMFILE, ">$memfile") || die("Can't write $memfile");
            for (my $i=0; $i<= $maxaddress; $i = $i + 4) {
                for ($j=3; $j>=0; $j--) {
            if (defined($memfilebytes[$i+$j])) {
                print MEMFILE "$memfilebytes[$i+$j]";
            } else {
                print MEMFILE "00";
            }
                }
                print MEMFILE "\n";
            }
            close(MEMFILE);
        } else {
            open(MEMFILE, ">$memfile") || die("Can't write $memfile");
            for (my $i=0; $i<= $maxaddress; $i = $i + 8) {
                for ($j=7; $j>=0; $j--) {
                    my $loc = $i+$j;
#                    if ($loc >= 17520 && $loc <= 17552) {
#                        print "loc: $loc  val $memfilebytes[$loc]\n";
#                    }
                    if (defined($memfilebytes[$loc])) {
                        print MEMFILE "$memfilebytes[$loc]";
                    } else {
                        print MEMFILE "00";
                    }
                }
                print MEMFILE "\n";
            }
            close(MEMFILE);
        }
    }
}
print("\n");

sub emitData {
    # print the data portion of the ELF into a memroy file, including 0s for empty stuff
    # deal with endianness
    my $address = shift;
    my $payload = shift;

#    if ($address > 17520 && $address < 17552) { # was 12304
#        print("Emitting data.  address = $address payload = $payload\n");
#    }

    my $len = length($payload);
    if ($len <= 8) { 
        # print word or halfword
        for(my $i=0; $i<$len/2; $i++) {
            my $adr = $address+$i;
            my $b = substr($payload, $len-2-2*$i, 2);
            $memfilebytes[$adr] = $b;
#            if ($address >= 17520 && $address <= 17552) {
#                print("  Wrote $b to $adr\n");
#            }
#            print(" $adr $b\n");
        }
    }  elsif ($len == 12) {
        # weird case of three halfwords on line
        &emitData($address, substr($payload, 0, 4));
        &emitData($address+2, substr($payload, 4, 4));
        &emitData($address+4, substr($payload, 8, 4));
    } else {
        &emitData($address, substr($payload, 0, 8));
        &emitData($address+4, substr($payload, 8, $len-8));
    }
}

sub fixadr {
    # strip off leading 8 from address and convert to decimal
    my $adr = shift;
    if ($adr =~ s/^8/0/) { return hex($adr); }
    else { die("address $adr lacks leading 8\n"); }
}
