# General Fasta tools
#
# Copyright (c) 2013, Bryan White

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
use strict;
use warnings;
use Math::Random;

use Exporter;

our @ISA= qw( Exporter );
our @EXPORT_OK = qw( 	fix_fasta 
						clean_file_name 
						bootstrap_alignment 
						random_splice_alignment 
						fisher_yates_shuffle
						);

sub fix_fasta {
	my ( $f ) = shift;
	open F, "< $f" or die "Can't open $f : $!";
	my @fasta = <F>;
	close F;

	foreach my $line (@fasta) {
		if($line =~ /^>/) {
			$line =~ s/ /_/g; # replace whitespace with _
		}
	}
	
	unlink $f;
	open (MYFILE, '>>'.$f);
	foreach my $line(@fasta) {
		print MYFILE $line;
	}
	close(MYFILE);
}

sub clean_file_name {
	# Takes a filename and strips its extension off, and returns the file name
	my ($file_name) = @_;
	my @split_file_name = split(/\./,$file_name);
	my $new_file_name = $split_file_name[0];

	return $new_file_name;
}

sub alignment_coverage {
# Reduces an alignment to only positions that are covered by a certain percentage
	my $alignment 		= shift;
	my $coverage_pcnt 	= shift;
	
	my %position_counter = ();
	my $min_coverage = 0;
	my $current_seq = 0;
	my $num_seqs = scalar($alignment->each_seq);
	foreach my $seq ($alignment->each_seq) {
		my $seq_string = $seq->seq;
		if($current_seq == 0) {
			$min_coverage = int $num_seqs*$coverage_pcnt;
		}
		my @unpacked_seq = unpack("C*", $seq_string);
		my $current_position = 0;
		foreach my $letter (@unpacked_seq) {
			if($letter != 45) {
				$position_counter{$current_position}++;
				$current_position++;
			} else {
				$current_position++;
			}
		}
		$current_seq++;
	}
	my @valid_positions = ();
	for my $position ( sort keys %position_counter ) {
		if ($position_counter{$position} >= $min_coverage) {
			push(@valid_positions, $position);
		}
	}
	foreach my $seq ($alignment->each_seq) {
		my $new_seq = '';
		my @split_seq = split("",$seq->seq);
		my $letter_i = 0;
		foreach my $valid (@valid_positions) {
			$new_seq .= $split_seq[$valid];
		}
		$seq->seq($new_seq);
	}
	print "Reducing alignment to ".($coverage_pcnt*100)."% covered positions only.\n";
	print scalar(@valid_positions)." positions remain.\n";
	return $alignment;
}

sub random_splice_alignment {
	my $alignment_ref	= shift;
	my $splice_min 		= shift;
	my $splice_max		= shift;
	
	my $splice_size = abs int rand ($splice_max);
	while($splice_size < $splice_min) {
		$splice_size = abs int rand ($splice_max);
	}
	
	my $splice_start = abs int rand ($splice_max);
	$splice_start = ($splice_max - $splice_size) if ($splice_start + $splice_size) > $splice_max;
	$splice_start = 1 if $splice_start < 1;
	
	my $splice_end = $splice_size + $splice_start;
	
	print "Splicing Size: $splice_size => Start: $splice_start => End: $splice_end\n";
	foreach my $seq (@$alignment_ref) {
		my $new_seq = $seq->subseq($splice_start,$splice_end);
		$seq->seq($new_seq);
	}
	return ($alignment_ref, $splice_start, $splice_end);
}

sub specific_splice_alignment {
	my $alignment_ref	= shift;
	my $splice_start 	= shift;
	my $splice_end		= shift;
	
	my $splice_size = $splice_end - $splice_start;
	print "Splicing Size: $splice_size => Start: $splice_start => End: $splice_end\n";
	foreach my $seq (@$alignment_ref) {
		my $new_seq = $seq->subseq($splice_start,$splice_end);
		$seq->seq($new_seq);
	}
	return $alignment_ref;
}

sub splice_one_string_normal_dist {
	my $seq_string		 = shift;
	my $splice_mean_size = shift;
	my $splice_std_dev 	 = shift;
	my $start_mean		 = shift;
	my $start_std_dev	 = shift;
	my $prob_short		 = shift;
	
	my $ran_length = int random_normal(1, $splice_mean_size, $splice_std_dev);
	$ran_length = 1 if $ran_length < 0;
	my $ran_start = int random_normal(1, $start_mean, $start_std_dev);
	$ran_start = 0 if $ran_start < 0;
	$ran_length = $ran_length - $ran_start;

	my $short_roll = int rand 100;
	if($short_roll <= $prob_short) {
		my $spliced_seq = ('-' x $ran_start).substr($seq_string, $ran_start, $ran_length);
		return $spliced_seq;
	} else {
		my $spliced_seq = substr($seq_string, 0, $splice_mean_size);
		return $spliced_seq;
	}	
}

sub bootstrap_alignment {
# Resample alignment with replacement
	my $alignment_ref	= shift;
	my $sample_size		= shift;
	
	my $num_sequences = scalar @$alignment_ref;
	my @subsampled_alignment = ();
	my @rand_numbers = ();
	for(my $i = 0; $i < $sample_size; $i++) {
		my $random_number = int(rand($num_sequences));
		push(@rand_numbers, $random_number);
	}
	foreach my $random_number (@rand_numbers) {
		# print $alignment_ref->[$random_number]->seq."\n";
		push(@subsampled_alignment, $alignment_ref->[$random_number]);
	}
	
	my $subsampled_alignment_ref = \@subsampled_alignment;
	return $subsampled_alignment_ref;
	
}

sub fisher_yates_shuffle {
# Shuffle alignment
    my $array_ref = shift;
    my $i = @$array_ref;
    while ( --$i ) {
        my $j = int rand( $i+1 );
        @$array_ref[$i,$j] = @$array_ref[$j,$i];
    }
}

1;