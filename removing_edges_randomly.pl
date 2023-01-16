#!/usr/bin/perl -w

#This script remove randomly rows of an input file. So you have to provide the amount of rows (edges) to remove and the input network file.

use strict;
use warnings;

unless( @ARGV == 2 ){

   die "\n\nHere the idea is remove some amount of edges of an input network. \n\n So after the script name provide the amount of rows to remove and after this the input net (space separated)\n\n";
}

# Variables
my $num_rows;
my $file;
my @lines;

# Reading the arguments
$num_rows = $ARGV[0];
$file = $ARGV[1];

# Opening the file
open(INFILE, "<$file") or die "Can't open the file: $!";

# Reading each row (edges) into an array
while (my $line = <INFILE>) {
    push(@lines, $line);
}

# Close the file
close INFILE;

# Shuffle the edges
@lines = shuffle(@lines);

# Print the first n lines where n is the total number of lines - num_rows
for (my $i = 0; $i < @lines - $num_rows; $i++) {
    print $lines[$i];
}

# Shuffle function to process the array
sub shuffle {
    my @array = @_;
    my $i = @array;
    while ( --$i ) {
        my $j = int rand( $i+1 );
        @array[$i,$j] = @array[$j,$i];
    }
    return @array;
}
