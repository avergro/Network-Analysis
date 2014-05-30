#!/usr/bin/perl -w

use strict;
use Graph::Undirected;
use warnings;
use diagnostics;
use GO::TermFinder;
use GO::AnnotationProvider::AnnotationParser;
use GO::OntologyProvider::OboParser;
use GO::TermFinderReport::Text;
use GO::Utils::File qw (GenesFromFile);

unless( @ARGV == 2)
{ die "You have to provide the file with the interactions and a vertices list\n\ningresa el file name de las interacciones y el file name de los ids de los vertices de interes\n\n";
 }

my $file = shift @ARGV;
my $idFile = shift @ARGV;

open IN1, $file or die "Can't read $file: $!\n";

open IN2, $idFile or die "Can't read $idFile: $!\n";

my $graph = Graph::Undirected->new;

while( my $ids = <IN2> ){

my @ids = split(/\n/, $ids);

while( my $relation = <IN1> ){

chomp $relation;
my @line = split(/\,/, $relation);
$graph->add_edge( $line[0] , $line[1] );

}
foreach $ids (@ids) {
my @n = $graph->neighbours($ids);


my $vecinos = @n;
my @vecinos = split(/\n/, $vecinos);


print "###Neighborhood analysis of $ids \n";

my $ontologyFile = 'gene_ontology_ext.obo';

chomp $ontologyFile;


my $aspect = 'P';
chomp $aspect;


my $annotationFile = 'gene_association.tair';
chomp $annotationFile;

my @genes = @n;

my $totalNum = '27000';
chomp $totalNum;

#print "Finding terms...\n";

my $ontology   = GO::OntologyProvider::OboParser->new(ontologyFile => $ontologyFile,
                                                      aspect       => $aspect);

my $annotation = GO::AnnotationProvider::AnnotationParser->new(annotationFile=>$annotationFile);

my $termFinder = GO::TermFinder->new(annotationProvider => $annotation,
                                     ontologyProvider   => $ontology,
                                     totalNumGenes      => $totalNum,
                                     aspect             => $aspect);


my @pvalues    = $termFinder->findTerms(genes        => \@genes,
                                        calculateFDR => 1);

my $report = GO::TermFinderReport::Text->new();

my $cutoff = 0.05;

my $numHypotheses = $report->print(pvalues  => \@pvalues,
                                   numGenes => scalar(@genes),
                                   totalNum => $totalNum,
                                   cutoff   => $cutoff);

##if they had no significant P-values

if ($numHypotheses == 0){

    print "No terms were found for this aspect with a corrected P-value <= $cutoff.\n";
                       }
         }
}


