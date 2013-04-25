#!/usr/bin/perl
# Select vouchered specimens from a sql database
#
# Copyright (c) 2013, Bryan White, bpcwhite@gmail.com

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#!/usr/bin/perl

# DBI is the standard database interface for Perl
# DBD is the Perl module that we use to connect to the MySQL database
use FindBin;
use lib "$FindBin::Bin/libs/";
use General::Arguments;


use DBI;

use strict;
use warnings;

my $params = General::Arguments->new(	arguments_v => \@ARGV,
										option_defs => {'-database' 	=> '', 				# Database name
														'-location'		=> 'localhost',		# IP address/hostname of database
														'-port'			=> '3306',			# DB port
														'-user'			=> '',				# Username
														'-password'		=> '',				# User password	
														'-table'		=> '',				# Table to input data to
														'-voucher-list'	=> '',				# CSV file to upload
													}
													);

my $database 	=  $params->options->{'-database'};
my $location 	=  $params->options->{'-location'};
my $port		=  $params->options->{'-port'};
my $user 		=  $params->options->{'-user'};
my $password 	=  $params->options->{'-password'};
my $table 		=  $params->options->{'-table'};
my $voucher_file=  $params->options->{'-voucher-list'};

print "Opening $voucher_file \n";
open VOUCHER, "< $voucher_file";
my @voucher_list = <VOUCHER>;
close VOUCHER or die "Couldn't close $voucher_file!\n";

my $dsn = "DBI:mysql:database=$database;host=$location;port=$port";
my $dbh = DBI->connect($dsn, $user, $password);

# my @gene_list = ("COI", "16S", "18S", "28S", "CYTB");
my @gene_list = ("COI", "16S");

my $line_counter = 0;
foreach my $line (@voucher_list) {
	# print $line."\n";
	$line =~ s/\n//g; # Strip newlines
	# print $line."\n";
	my ($query_primary_key, $taxon_query, $taxon_id, $accession,
		$seq_query, $seqs_found, $description, $gene,
		$product, $binom, $tax_hierarchy, $pub_title, $pub_authors,
		$pub_abstract_text, $jrn_name, $jrn_doi, $jrn_so,
		$jrn_volume, $jrn_issue, $jrn_pages, $jrn_pubdate, $nuc_seq,
		$prot_seq, $primers, $codon_start, $collection_date, $voucher_id, 
		$collected_by, $identified_by, $organelle, $location, $lat_lon);

	foreach my $query_gene (@gene_list) {
		my $query = "SELECT * FROM column_names WHERE seq_query LIKE \"\%".$query_gene."\%\" AND voucher_id = \"".$line."\"";
	
		my $statement = $dbh->prepare($query);
		$statement->execute() or die "$@\n";
		# BIND TABLE COLUMNS TO VARIABLES
		$statement->bind_col(1, \$query_primary_key);
		$statement->bind_col(2, \$taxon_query);
		$statement->bind_col(3, \$taxon_id);
		$statement->bind_col(4, \$accession);
		$statement->bind_col(5, \$seq_query);
		$statement->bind_col(6, \$seqs_found);	
		$statement->bind_col(7, \$description);	
		$statement->bind_col(8, \$gene);
		$statement->bind_col(9, \$product);
		$statement->bind_col(10, \$binom);
		$statement->bind_col(11, \$tax_hierarchy);
		$statement->bind_col(12, \$pub_title);
		$statement->bind_col(13, \$pub_authors);	
		$statement->bind_col(14, \$pub_abstract_text);
		$statement->bind_col(15, \$jrn_name);
		$statement->bind_col(16, \$jrn_doi);
		$statement->bind_col(17, \$jrn_so);
		$statement->bind_col(18, \$jrn_volume);	
		$statement->bind_col(19, \$jrn_issue);
		$statement->bind_col(20, \$jrn_pages);
		$statement->bind_col(21, \$jrn_pubdate);	
		$statement->bind_col(22, \$nuc_seq);
		$statement->bind_col(23, \$prot_seq);
		$statement->bind_col(24, \$primers);
		$statement->bind_col(25, \$codon_start);
		$statement->bind_col(26, \$collection_date);
		$statement->bind_col(27, \$voucher_id);
		$statement->bind_col(28, \$collected_by);
		$statement->bind_col(29, \$identified_by);
		$statement->bind_col(30, \$organelle);
		$statement->bind_col(31, \$location);
		$statement->bind_col(32, \$lat_lon);
		
		if($statement->rows == 0) {
			print $query_gene."\n";
			next;
		}
		if(($statement->rows == 0) && ($query_gene eq $gene_list[0])) {
			# Must have first gene.
			last;
		}
		# LOOP THROUGH RESULTS
		while($statement->fetch()) {
		   print ">$query_gene|$voucher_id\n$nuc_seq\n";
		}

	}
	$line_counter++;
}

