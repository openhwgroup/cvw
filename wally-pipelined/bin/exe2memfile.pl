#!/usr/bin/perl -w

# exe2memfile.pl
# David_Harris@hmc.edu 26 November 2020
# Converts an executable file to a series of 32-bit hex instructions
# to read into a Verilog simulation with $readmemh

if ($#ARGV == -1) {
    die("Usage: $0 executable_file");
}

# array to hold contents of memory file
my @memfilebytes = (0)*16384*4;
my $maxaddress = 0;

for(my $i=0; $i<=$#ARGV; $i++) {
    my $fname = $ARGV[$i];
#    print "fname = $fname";
    my $ofile = $fname.".objdump";
    my $memfile = $fname.".memfile";

    open(FILE, $ofile) || die("Can't read $ofile");
    my $mode = 0; # parse for code
    my $address;

 # initialize to all zeros;
    for (my $i=0; $i < 65536*4; $i++) {
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
            if (/^\s*(\S\S\S\S\S\S\S\S):\s+(.*)/) {
                $address = &fixadr($1);
#		print "addresss $address maxaddress $maxaddress\n";
		if ($address > $maxaddress) { $maxaddress = $address; }
                my $line = $2;
                # merge chunks with spaces
                $line =~ s/(\S)\s(\S)/$1$2/g;
                # strip off comments
                $line =~ /^(\S*)/;
                $payload = $1;
                &emitData($address, $payload);
            }
            if (/Disassembly of section .riscv.attributes:/) { $mode = 2; }
        }
    }
    close(FILE);
    $maxaddress += 32; # pad some zeros at the end

    # print to memory file
    if ($fname =~ /rv32/) {
	open(MEMFILE, ">$memfile") || die("Can't write $memfile");
	for (my $i=0; $i<= $maxaddress; $i = $i + 4) {
	    for ($j=3; $j>=0; $j--) {
		print MEMFILE "$memfilebytes[$i+$j]";
	    }
	    print MEMFILE "\n";
	}
	close(MEMFILE);
    } else {
	open(MEMFILE, ">$memfile") || die("Can't write $memfile");
	for (my $i=0; $i<= $maxaddress; $i = $i + 8) {
	    for ($j=7; $j>=0; $j--) {
		print MEMFILE "$memfilebytes[$i+$j]";
	    }
	    print MEMFILE "\n";
	}
	close(MEMFILE);
    }
}

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
    my $adr = shift;
    if ($adr =~ s/^8/0/) { return hex($adr); }
    else { die("address $adr lacks leading 8\n"); }
}
