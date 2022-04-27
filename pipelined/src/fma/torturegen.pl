#!/usr/bin/perl -w
# torturegen.pl 
# David_Harris@hmc.edu 19 April 2022
# Convert TestFloat cases into format for fma16 project torture test
# Strip out cases involving denorms

use strict;

my @basenames = ("add", "mul", "mulAdd");
my @roundingmodes = ("rz", "rd", "ru", "rne");
my @names = ();
foreach my $name (@basenames) {
    foreach my $mode (@roundingmodes) {
        push(@names, "f16_${name}_$mode.tv");
    }
}

open(TORTURE, ">work/torture.tv") || die("Can't write torture.tv");
my $datestring = localtime();
print(TORTURE "// Torture tests generated $datestring by $0\n");
foreach my $tv (@names) {
    open(TV, "work/$tv") || die("Can't read $tv");
    my $type = &getType($tv); # is it mul, add, mulAdd
    my $rm = &getRm($tv); # rounding mode
#   if ($rm != 0) { next; } # only do rz
    print (TORTURE "\n////////// Testcases from $tv of type $type rounding mode $rm\n");
    print ("\n////////// Testcases from $tv of type $type rounding mode $rm\n");
    my $linecount = 0;
    my $babyTorture = 0;
    while (<TV>) {
        my $line = $_;
        $linecount++;
        my $density = 10;
        if ($type eq "mulAdd") {$density = 500;}
        if ($babyTorture) {
            $density = 100;
            if ($type eq "mulAdd") {$density = 50000;}
        }
        if ((($linecount + $rm) % $density) != 0) { next }; # too many tests to use
        chomp($line); # strip off newline
        my @parts = split(/_/, $line);
        my ($x, $y, $z, $op, $w, $flags);
        $x = $parts[0];
        if ($type eq "add") { $y = "0000"; } else {$y = $parts[1]};
        if ($type eq "mul") { $z = "3CFF"; } elsif ($type eq "add") {$z = $parts[1]} else { $z = $parts[2]};
        $op = $rm << 4;
        if ($type eq "mul" || $type eq "mulAdd") { $op = $op + 8; }
        if ($type eq "add" || $type eq "mulAdd") { $op = $op + 4; }
        my $opname = sprintf("%02x", $op);
        if ($type eq "mulAdd") {$w = $parts[3];} else {$w = $parts[2]};
        if ($type eq "mulAdd") {$flags = $parts[4];} else {$flags = $parts[3]};
        $flags = substr($flags, -1); # take last character
        if (&fpval($w) eq "NaN") { $w = "7e00"; }
        my $vec = "${x}_${y}_${z}_${opname}_${w}_${flags}";
        my $skip = "";
        if (&isdenorm($x) || &isdenorm($y) || &isdenorm($z) || &isdenorm($w)) {
            $skip = "Skipped denorm";
        }
        my $summary = &summary($x, $y, $z, $w, $type);
        if ($skip ne "") {
            print TORTURE "// $skip $tv line $linecount $line $summary\n"
        }
        else { print TORTURE "$vec // $tv line $linecount $line $summary\n";}
    }
    close(TV);
}
close(TORTURE);

sub fpval {
    my $val = shift;
    $val = hex($val); # convert hex string to number
    my $frac = $val & 0x3FF;
    my $exp = ($val >> 10) & 0x1F;
    my $sign = $val >> 15;

    my $res;
    if ($exp == 31 && $frac != 0) { return "NaN"; }
    elsif ($exp == 31) { $res = "INF"; }
    elsif ($val == 0) { $res = 0; }
    elsif ($exp == 0) { $res = "Denorm"; }
    else { $res = sprintf("1.%011b x 2^%d", $frac, $exp-15); }

    if ($sign == 1) { $res = "-$res"; }
    return $res;
}

sub summary {
    my $x = shift; my $y = shift; my $z = shift; my $w = shift; my $type = shift;

    my $xv = &fpval($x);
    my $yv = &fpval($y);
    my $zv = &fpval($z);
    my $wv = &fpval($w);

    if ($type eq "add") { return "$xv + $zv = $wv"; }
    elsif ($type eq "mul") { return "$xv * $yv = $wv"; }
    else {return "$xv * $yv + $zv = $wv"; }
}

sub getType {
    my $tv = shift;

    if ($tv =~ /mulAdd/) { return("mulAdd"); }
    elsif ($tv =~ /mul/) { return "mul"; }
    else { return "add"; }
}

sub getRm {
    my $tv = shift;

    if ($tv =~ /rz/) { return 0; }
    elsif ($tv =~ /rne/) { return 1; }
    elsif ($tv =~ /rd/) {return 2; }
    elsif ($tv =~ /ru/) { return 3; }
    else { return "bad"; }
}

sub isdenorm {
    my $fp = shift;
    my $val = hex($fp);
    my $expv = $val >> 10;
    $expv = $expv & 0x1F;
    my $denorm = 0;
    if ($expv == 0 && $val != 0) { $denorm = 1;}
 #   my $e0 = ($expv == 0);
 #   my $vn0 = ($val != 0);
 #   my $denorm = 0; #($exp == 0 && $val != 0); # denorm exponent but not all zero
 #   print("Num $fp Exp $expv Denorm $denorm Done\n");
    return $denorm;
}