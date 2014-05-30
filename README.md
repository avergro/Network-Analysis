Network-Analysis
================

Here I am including useful scripts for biological networks analysis

This Script is using module Graph available in CPAN developed by Jarkko Hietaniem

http://search.cpan.org/dist/Graph/lib/Graph.pod
 
For the GO enrichment analysis this script is using Go:TermFinder Perl module available in CPAN developed for Gavin Sherlock, Elizabeth Boyle and Ihab Awad.

http://search.cpan.org/dist/GO-TermFinder/lib/GO/TermFinder.pm

The idea is obtain for a nodes input list its neighbours and then analyze enrichment GO term in these lists.

You need download an association file http://www.geneontology.org/GO.downloads.annotations.shtml from Gene Ontology web site corresponding to your model organism and a Gene Ontology.obo file from http://www.geneontology.org/GO.downloads.ontology.shtml (OBO format)
