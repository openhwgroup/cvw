#!/usr/bin/perl -w

# exe2memfile.pl
# David_Harris@hmc.edu 26 November 2020
# Converts an executable file to a series of 32-bit hex instructions
# to read into a Verilog simulation with $readmemh

use File::stat;
use IO::Handle;

if ($#ARGV == -1) {
    die("Usage: $0 executable_file");
}

# array to hold contents of memory file
my @memfilebytes = (0)*16384*4;
my $maxaddress = 0;

STDOUT->autoflush(1);
# *** Ross Thompson I think there is a bug here needs to be +1
<<<<<<< HEAD
print ("Processing $#ARGV memfiles: \n");
=======
print ("Processing $#ARGV memfiles: ");
>>>>>>> icache_bp_bug
my $frac = $#ARGV/10;
for(my $i=0; $i<=$#ARGV; $i++) {
    if ($i < 10 || $i % $frac == 0) { print ("$i ") };
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
	my $section = "";
	my $data = "";
        my $address;
	my $first = 0;
	my $firstAddress;

    # initialize to all zeros;
	# *** need to fix the zeroing range.  Not always 64K
        for (my $i=0; $i < 65536*4; $i++) {
            $memfilebytes[$i] = "00";
        }

        while(<FILE>) {
	    # objdump fill is divided into several .sections of which only some we want to actually process.
	    # In general we want everything except the .comment and .*attributes
	    if (/Disassembly of section (.*):/) {
		$section = $1;
		print ("setting section to $section\n");
	    } else {
		# now check if the section is one we are interested in processing.
		#if ($section ne ".comment" && $section ne ".riscv.attributes" && $section =~ /\.debug.*/) {
		if ($section =~ "\.init|\.text|\..*data|\..*bss") {
		    # the structure is: possible space(s) hex number: possible space(s) hex number space(s) junk
		    # there are also lines we need to skip: possible  space(s) hex number <string>:
		    if (/^\s*([0-9A-Fa-f]{1,16}):\s+([0-9A-Fa-f]+).*$/) {
			$address = &fixadr($1);			
			if ($first == 0) {
			    $first = 1;
			    $firstAddress = $address;
			}
			$data = $2;
			&emitData($address, $data);
			# my $len = length($data);
			# for (my $i=0; $i<$len/2; $i++) {
			#     $memfilebytes[$address+$i] = substr($data, $len-2-2*$i, 2);
			# }
#			print ("Addr $address $data\n");
#		    } elsif (/^\s*\.\.\./) {
#			print ("Got ...\n");
#		    } else {
#			print ("No match\n");
		    }
		}
	    }
# 	    # *** this mode stuff does not work if a section is missing or reordered.
#             if ($mode == 0) { # Parse code
# #	    print("Examining $_\n");
# 		if (/^\s*(\S{1,16}):\s+(\S+)\s+/) {
#                     $address = &fixadr($1);
#                     my $instr = $2;
#                     my $len = length($instr);
#                     for (my $i=0; $i<$len/2; $i++) {
#                         $memfilebytes[$address+$i] = substr($instr, $len-2-2*$i, 2);
#                     }
#                     print ("address $address $instr\n");
# 		}
# 		if (/Disassembly of section .data:/) { $mode = 1;}
#             } elsif ($mode == 1) { # Parse data segment
#                 if (/^\s*(\S{1,16}):\s+(.*)/) {
#                     $address = &fixadr($1);
# #		        print "addresss $address maxaddress $maxaddress\n";
# 		    if ($address > $maxaddress) { $maxaddress = $address; }
#                     my $line = $2;
#                     # merge chunks with spaces
# 		    # *** might need to change
#                     $line =~ s/(\S)\s(\S)/$1$2/g;
#                     # strip off comments
#                     $line =~ /^(\S*)/;
#                     $payload = $1;
#                     &emitData($address, $payload);
#                 }
#                 if (/Disassembly of section .comment:/) { $mode = 2; }
# 	    } elsif ($mode == 2) { # parse the comment section
#                 if (/Disassembly of section .riscv.attributes:/) { $mode = 3; }
#             }
        }
        close(FILE);
        $maxaddress = $address + 32; # pad some zeros at the end

        # print to memory file
	# *** this is a problem
        if ($fname =~ /rv32/) {
        open(MEMFILE, ">$memfile") || die("Can't write $memfile");
        for (my $i=$firstAddress; $i<= $maxaddress; $i = $i + 4) {
            for ($j=3; $j>=0; $j--) {
		no warnings 'uninitialized';
		my $value = $memfilebytes[$i+$j];
		if ($value eq ""){
		    print MEMFILE "00";
		} else {
		    print MEMFILE "$memfilebytes[$i+$j]";
		}
            }
            print MEMFILE "\n";
        }
        close(MEMFILE);
        } else {
        open(MEMFILE, ">$memfile") || die("Can't write $memfile");
        for (my $i=$firstAddress; $i<= $maxaddress; $i = $i + 8) {
            for ($j=7; $j>=0; $j--) {
		no warnings 'uninitialized';
		my $value = $memfilebytes[$i+$j];
		if ($value eq ""){
		    print MEMFILE "00";
		} else {
		    print MEMFILE "$memfilebytes[$i+$j]";
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

#    print("Emitting data.  address = $address payload = $payload\n");

    my $len = length($payload);
    if ($len <= 8) { 
        # print word or halfword
        for(my $i=0; $i<$len/2; $i++) {
            my $adr = $address+$i;
            my $b = substr($payload, $len-2-2*$i, 2);
            $memfilebytes[$adr] = $b;
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
    # if the leading 8 is not present don't remove.
    my $adr = shift;
    #print "addr $adr\n";
    return hex($adr);
}
