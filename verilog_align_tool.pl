#!/usr/bin/perl
# melvin. alvarado

use strict;
use warnings;

#use Getopt::Long;
#my $opt_param = 1;
#GetOptions (
#   'opt_param' => \$opt_param, 
#);

open(OUT, ">>/tmp/testappend"); 
my @buffer=<>; 
print OUT ("@buffer\n"); 
close(OUT); 


# ===================================================
# 1st parsing
# read length of diff parts of the statement
my $param_w_p=0;    # parameter def
my $param_w_v=0;    # parameter value

my $sig_w_io = 0;   # signal input/output
my $sig_w_t  = 0;   # signal type
my $sig_w_r = 0;    # signal range
my $sig_w_n = 0;    # signal name

foreach(@buffer) {
    my $l = $_;
    if($l=~/(parameter|localparam)[ type]+(\w+)\s+=\s+(.*)/){
        my $w = length($2);
        $param_w_p = $w if($w>$param_w_p);
        if( $3=~/(.*)\s+\/\//) {
            my $v = length($1);
            $param_w_v = $v if($v>$param_w_v);
        }
        else{
            my $v = length($3);
            $param_w_v = $v if($v>$param_w_v);
        }
    }
    if( $l=~/^\s+(input|output)/ || $l=~/^\s?logic/ || $l=~/^\s?.*_T/ ){
        my %hash;
        my %w;
        &process_signal($l,\%hash,\%w);
        $sig_w_io = $w{'io'} if($w{'io'}>$sig_w_io);
        $sig_w_t = $w{'type'} if($w{'type'}>$sig_w_t);
        $sig_w_r = $w{'range'} if($w{'range'}>$sig_w_r);
        $sig_w_n = $w{'name'} if($w{'name'}>$sig_w_n);
    }
}
#print "DEBUG IO:$sig_w_io $sig_w_t $sig_w_r $sig_w_n\n";
#print "DEBUG PARAM: $param_w_p $param_w_v\n";


# ===================================================
# 2nd parsing
# apply format
foreach(@buffer) {
    my $l = $_;

    # parameter
    if($l=~/(parameter|localparam)/) {
        print &parameter_format($l);
    }
    # signal
    elsif( $l=~/^(\s+)(input|output)/ || $l=~/^\s?logic/ || $l=~/^\s?.*_T/ ){
        my %h;
        my %w;
        &process_signal($l,\%h);
        foreach my $k (keys %h){
            $w{$k} = length($h{$k});
        };
        if( length($1) ){
            print "    $h{'io'}";
        }
        else {
            print "$h{'io'}";
        }
        for(1..($sig_w_io-$w{'io'})) {print " "};
        print " " if( $l=~/(input|output)/);
        print "$h{'type'}";
        for(1..($sig_w_t-$w{'type'})) {print " "};
        print " $h{'range'}";
        for(1..($sig_w_r-$w{'range'})) {print " "};
        my $name = $h{'name'};
        $name =~ s/,_/, /g;
        print " $name";
        if($h{'comment'} ne ''){
            for(1..($sig_w_n-$w{'name'})) {print " "};
            print "  // $h{'comment'}";
        }
        print "\n";
    }
    # comment
    elsif($l=~/^\s+\/\//) {
        $l =~ s/^\s+//;
        $l =~ s/\r//;
        print "    ".$l;
    }
    else{
        $l =~ s/\r//;
        print $l;
    };

}


# ===================================================
# subroutines
sub parameter_format(){
    my ($l) = @_;
    if($l=~/(parameter|localparam)([ type]+)([A-Z_0-9]+)\s+=\s+(.*)/){
        my $p = $3;
        my $w = length($p);
        my $v = $4;
        my $param = $1;
        chomp($v);
        my $pad1 = $param_w_p-$w;
        my $r = "    $param      $p";
        $r = "    $param type $p" if($2=~/type/);
        $r =~ s/^\s+// if($param eq "localparam");
        for(1..$pad1) {$r .= " "};
        if($v=~/\/\//){
            my $v_only = $v;
            $v_only =~ s/\s+\/\/.*//;
            my $c = length($v_only);
            my $pad2 = $param_w_v-$c;
            my $tab2 = "  ";
            for(1..$pad2) {$tab2 .= " "};
            $v =~ s/\s+\/\//$tab2\/\//;
        };
        $r .= " = $v\n";
        $r =~ s/\r//;
        return $r;
    };
    return $l;
};


sub process_signal() {
    my($l,$ref,$ref_w) = @_;

    $ref->{'io'} = '';
    $ref->{'type'} = '';
    $ref->{'range'} = '';
    $ref->{'name'} = '';
    $ref->{'comment'} = '';

    if($l=~/([^\/\/]+)\/\/(.*)$/){
        $l = $1;
        my $c = $2;
        chop($c);
        $c =~ s/^\s+//;
        $ref->{'comment'} = $c;
    }
    $l =~ s/,\s+/,_/g;
    my @array = split(/\s+/,$l);
    my $name = pop(@array);
    $ref->{'name'} = $name;
    $l =~ s/\s+$name//;
    if($l=~/(\[.*\])/){
        my $r = $1;
        $l =~ s/\[.*\]//;
        $ref->{'range'}=$r;
    }
    if($l=~/^\s+(input|output)(.*)/) {
        $ref->{'io'} = $1;
        $l = $2;
    }
    $l =~ s/\s+//g;
    $ref->{'type'} = $l if($l=~/\w+/);

    foreach my $k (keys %{$ref}){
        $ref_w->{$k} = length($ref->{$k});
    }
};

