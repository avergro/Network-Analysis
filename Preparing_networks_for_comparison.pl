#!/usr/bin/perl
use strict;
use warnings;
use List::MoreUtils qw(first_index);

#This is a merge of several script. 
#The script process all .net files in current directory associated with an aligment file.
#So, net files ids should match with aligment file name
#The final result are modied version of .net files that have same nodes ids using a consensus code for that.
#Thus, both netwokrs will have same nodes ids despite having different amount of nodes in original nets





# Script 1: Process .aln files and generate Output 1 and Output 2 files
my @aln_files = glob("*.clustalw2_output");

unless (@aln_files) {
    die "No .aln files found in the current directory.\n";
}

foreach my $input_file (@aln_files) {
    open my $fh, '<', $input_file or die "Error opening $input_file: $!\n";
    
#Code to create Output 1 and Output 2 files

# Initialize variables
    my %sequences;         # Hash to store sequences
    my %seen_ids;           # Hash to track seen sequence IDs
    my @ids;                # Array to store sequence IDs
    my $line_number = 0;    # Line number tracker
    my $found_alignment = 0;    # Flag to indicate if the alignment section is found

    # Read the input file line by line
    while (my $line = <$fh>) {
        chomp $line;
        $line_number++;

        # Check if we've found the alignment section
        if ($line =~ /^CLUSTAL 2\.1/) {
            $found_alignment = 1;
            next;
        }

        # Skip lines until we find the sequence data
        next unless $found_alignment;

        # Process sequence rows
        if ($line =~ /^(\S+)\s+(.*)/) {
            my ($id, $seq) = ($1, $2);

            # Store the sequence in the hash
            $sequences{$id} .= $seq;

            # Track seen sequence IDs
            $seen_ids{$id} = 1;

            # Store IDs in the array
            push @ids, $id;
        }

        # Process the extra row (with "*" or empty space)
        elsif ($line =~ /^[*\s]+$/) {
            # Do nothing for now
        }

        # Otherwise, skip the line
        else {
            next;
        }
    }

    # Output 1: Include column1 and column3
    open my $output1_fh, '>', "replacement_for_$ids[0]_${input_file}_output1.txt" or die "Error creating Output 1 file for $input_file: $!\n";

    # Output 2: Include column2 and column3
    open my $output2_fh, '>', "replacement_for_$ids[1]_${input_file}_output2.txt" or die "Error creating Output 2 file for $input_file: $!\n";

    my $len = length($sequences{$ids[0]});

    # Separate position trackers for each sequence
    my $pos1 = 1;    # Counter for sequence 1
    my $pos2 = 1;    # Counter for sequence 2

    for (my $i = 0; $i < $len; $i++) {
        my $aa1 = substr($sequences{$ids[0]}, $i, 1);
        my $aa2 = substr($sequences{$ids[1]}, $i, 1);

        # Prepare consensus nomenclature for sequence 1
        my $consensus_nomenclature1;

        if ($aa1 eq $aa2) {
            $consensus_nomenclature1 = $aa1 . "_" . $pos1 . "_C";
        } elsif ($aa1 ne '-' && $aa2 eq '-') {
            $consensus_nomenclature1 = $aa1 . "_" . $pos1 . "_" . $ids[0] . "_specific";
        } elsif ($aa2 ne '-' && $aa1 eq '-') {
            $consensus_nomenclature1 = $aa2 . "_" . $pos2 . "_" . $ids[1] . "_specific";
        } elsif ($aa1 eq '-' && $aa2 eq '-') {
            $consensus_nomenclature1 = $aa1 . "_" . $pos1 . "_gap_in_" . $ids[0];
        } else {
            $consensus_nomenclature1 = $aa1 . "_" . $pos1 . "_" . $ids[0] . "_specific";
        }

        # Prepare consensus nomenclature for sequence 2
        my $consensus_nomenclature2;

        if ($aa1 eq $aa2) {
            $consensus_nomenclature2 = $aa2 . "_" . $pos2 . "_C";
        } elsif ($aa1 ne '-' && $aa2 eq '-') {
            $consensus_nomenclature2 = $aa1 . "_" . $pos1 . "_" . $ids[1] . "_specific";
        } elsif ($aa2 ne '-' && $aa1 eq '-') {
            $consensus_nomenclature2 = $aa2 . "_" . $pos2 . "_" . $ids[1] . "_specific";
        } elsif ($aa1 eq '-' && $aa2 eq '-') {
            $consensus_nomenclature2 = $aa2 . "_" . $pos2 . "_gap_in_" . $ids[1];
        } else {
            $consensus_nomenclature2 = $aa2 . "_" . $pos2 . "_" . $ids[1] . "_specific";
        }

        # Output 1: Print and update position for sequence 1, including gaps
        print $output1_fh "$aa1\_$pos1\t";
        $pos1++;

        # Output 2: Print and update position for sequence 2, using numbers from column 2 for gaps
        if ($aa2 ne '-') {
            print $output2_fh "$aa2\_$pos2\t";
            $pos2++;
        } else {
            print $output2_fh "-_$pos2\t";    # Use "-_" followed by the position from column 2 for gaps in column 2
            $pos2++;
        }

        # Print consensus nomenclature for sequence 1
        print $output1_fh "$consensus_nomenclature1\n";

        # Print consensus nomenclature for sequence 2
        print $output2_fh "$consensus_nomenclature2\n";
    }

    # Close the file handles for the current file
    close $fh;
    close $output1_fh;
    close $output2_fh;
}

# Script 2: Process .net files and generate files with "_consensus_names.net" suffix
my @input_files = glob("*.net");

foreach my $input_file (@input_files) {
    # ... (Code from Script 2)

    # Extract the prefix before ".net"
    my ($prefix) = $input_file =~ /^(.+?)\.net$/;

    # Find the corresponding replacement file
    my $replacement_file = find_replacement_file($prefix);

    # Skip processing if no replacement file is found
    next unless $replacement_file;

    # Read the hash from replacement file
    my %repl = do {
        open my $fh, '<', $replacement_file or die $!;
        map { chomp; split ' ', $_, 2; } <$fh>;
    };

    # Build and compile regex pattern
    my $re = join '|', map { "\\b$_\\b" } keys %repl;
    $re = qr/$re/;

    # Open input and output files
    open my $input_fh, '<', $input_file or die $!;
    open my $output_fh, '>', "${prefix}_consensus_names.net" or die $!;

    # Process each line of the input file
    while (<$input_fh>) {
        my @columns = split(/\s+/, $_, 3);  # Split the line into columns (maximum 3 columns)
        if (@columns >= 2) {
            # Apply replacement to column 1 and column 2 (0-based indexing)
            $columns[0] =~ s/($re)/$repl{$1}/g;
            $columns[1] =~ s/($re)/$repl{$1}/g;
            print $output_fh join(' ', @columns);
        } else {
            # If there are less than 2 columns, just print the line as is
            print $output_fh $_;
        }
    }

    # Close input and output files
    close $input_fh;
    close $output_fh;
}

sub find_replacement_file {
    my ($prefix) = @_;

    # Find files matching the replacement pattern
    my @replacement_files = glob("replacement_for_${prefix}*");

    # Return the first matching replacement file
    return $replacement_files[0];
}


# Script 3: Create Pajek net files from files ending with "_consensus_names.net"
my @pajek_input_files = glob("*_consensus_names.net");

foreach my $pairwise_file (@pajek_input_files) {
    # ... (Code from Script 3)

    # Extract necessary strings from input file name
    my ($output_prefix) = $pairwise_file =~ /^(.+)_consensus_names\.net$/;

    unless ($output_prefix) {
        warn "Input file name $pairwise_file does not match the expected pattern. Skipping.\n";
        next;
    }

    # Read pairwise data from file
    open my $fh, '<', $pairwise_file or die "Could not open file $pairwise_file: $!";
    my @data = <$fh>;
    close $fh;

    # Ensure unique node names and maintain order of appearance
    my %unique_node_names;
    my @order_of_appearance;
    foreach my $line (@data) {
        next if $line =~ /^\s*$/;  # Skip empty lines
        my ($node1, $node2, $weight) = split /\s+/, $line;
        unless (exists $unique_node_names{$node1}) {
            push @order_of_appearance, $node1;
            $unique_node_names{$node1} = 1;
        }
        unless (exists $unique_node_names{$node2}) {
            push @order_of_appearance, $node2;
            $unique_node_names{$node2} = 1;
        }
    }

    # Sort nodes based on the numeric part of their names
    @order_of_appearance = sort { extract_number($a) <=> extract_number($b) } @order_of_appearance;

    # Create an empty Pajek file string
    my $pajek_data = "";

    # Add nodes with sequential IDs and preserve names
    my $n_nodes = scalar @order_of_appearance;
    $pajek_data .= "*Vertices $n_nodes\n";
    for my $i (0..$n_nodes-1) {
        my $node_id = $i + 1;
        my $node_name = $order_of_appearance[$i];
        $pajek_data .= "$node_id \"$node_name\"\n";
    }

    # Add edges with weights and IDs, ensuring correct node matching
    my $n_edges = scalar @data;
    $pajek_data .= "\n*Edges $n_edges\n";
    foreach my $line (@data) {
        next if $line =~ /^\s*$/;  # Skip empty lines
        my ($node1, $node2, $weight) = split /\s+/, $line;
        my $node_id1 = first_index { $_ eq $node1 } @order_of_appearance;
        my $node_id2 = first_index { $_ eq $node2 } @order_of_appearance;

        # Check if the nodes are found
        if (defined $node_id1 && defined $node_id2) {
            $node_id1 += 1;
            $node_id2 += 1;
            $pajek_data .= "$node_id1 $node_id2 $weight\n";
        } else {
            warn "Warning: Could not find node IDs for pair ($node1, $node2) in file $pairwise_file\n";
        }
    }

    # Save the Pajek data to a file
    my $output_file = $output_prefix . "_network.net";
    open my $output_fh, '>', $output_file or die "Could not open output file $output_file: $!";
    print $output_fh $pajek_data;
    close $output_fh;

    print "Pajek file created successfully: $output_file\n";
}

sub extract_number {
    my ($string) = @_;
    my ($number) = $string =~ /_(\d+)/;
    return $number // 0;  # Return 0 if no number is found
}

# Remove files starting with "replacement_" after Script 3
unlink glob("replacement_*");


# Script 4: Process .aln files similar to Script 1 with different output file names

# Get a list of all .aln files in the current directory
#my @aln_files = glob("*.clustalw2_output");

# Check if there are any .aln files
unless (@aln_files) {
    die "No .aln files found in the current directory.\n";
}

foreach my $input_file (@aln_files) {
    # Open the input file
    open my $fh, '<', $input_file or die "Error opening $input_file: $!\n";
    # ... (Code from Script 4)


    # Initialize variables
    my %sequences;         # Hash to store sequences
    my %seen_ids;           # Hash to track seen sequence IDs
    my @ids;                # Array to store sequence IDs
    my $line_number = 0;    # Line number tracker
    my $found_alignment = 0;    # Flag to indicate if the alignment section is found

    # Read the input file line by line
    while (my $line = <$fh>) {
        chomp $line;
        $line_number++;

        # Check if we've found the alignment section
        if ($line =~ /^CLUSTAL 2\.1/) {
            $found_alignment = 1;
            next;
        }

        # Skip lines until we find the sequence data
        next unless $found_alignment;

        # Process sequence rows
        if ($line =~ /^(\S+)\s+(.*)/) {
            my ($id, $seq) = ($1, $2);

            # Store the sequence in the hash
            $sequences{$id} .= $seq;

            # Track seen sequence IDs
            $seen_ids{$id} = 1;

            # Store IDs in the array
            push @ids, $id;
        }

        # Process the extra row (with "*" or empty space)
        elsif ($line =~ /^[*\s]+$/) {
            # Do nothing for now
        }

        # Otherwise, skip the line
        else {
            next;
        }
    }

    # Output 1: Include column1 and column3
    open my $output1_fh, '>', "replacement_for_$ids[1]_${input_file}_output1.txt" or die "Error creating Output 1 file for $input_file: $!\n";

    # Output 2: Include column2 and column3
    open my $output2_fh, '>', "replacement_for_$ids[0]_${input_file}_output2.txt" or die "Error creating Output 2 file for $input_file: $!\n";

    my $len = length($sequences{$ids[0]});

    # Separate position trackers for each sequence
    my $pos1 = 1;    # Counter for sequence 1
    my $pos2 = 1;    # Counter for sequence 2

    for (my $i = 0; $i < $len; $i++) {
        my $aa1 = substr($sequences{$ids[0]}, $i, 1);
        my $aa2 = substr($sequences{$ids[1]}, $i, 1);

        # Prepare consensus nomenclature for sequence 1
        my $consensus_nomenclature1;

        if ($aa1 eq $aa2) {
            $consensus_nomenclature1 = $aa1 . "_" . $pos1 . "_C";
        } elsif ($aa1 ne '-' && $aa2 eq '-') {
            $consensus_nomenclature1 = $aa1 . "_" . $pos1 . "_" . $ids[0] . "_specific";
        } elsif ($aa2 ne '-' && $aa1 eq '-') {
            $consensus_nomenclature1 = $aa2 . "_" . $pos2 . "_" . $ids[1] . "_specific";
        } elsif ($aa1 eq '-' && $aa2 eq '-') {
            $consensus_nomenclature1 = $aa1 . "_" . $pos1 . "_gap_in_" . $ids[0];
        } else {
            $consensus_nomenclature1 = $aa1 . "_" . $pos1 . "_" . $ids[0] . "_specific";
        }

        # Prepare consensus nomenclature for sequence 2
        my $consensus_nomenclature2;

        if ($aa1 eq $aa2) {
            $consensus_nomenclature2 = $aa2 . "_" . $pos2 . "_C";
        } elsif ($aa1 ne '-' && $aa2 eq '-') {
            $consensus_nomenclature2 = $aa1 . "_" . $pos1 . "_" . $ids[1] . "_specific";
        } elsif ($aa2 ne '-' && $aa1 eq '-') {
            $consensus_nomenclature2 = $aa2 . "_" . $pos2 . "_" . $ids[1] . "_specific";
        } elsif ($aa1 eq '-' && $aa2 eq '-') {
            $consensus_nomenclature2 = $aa2 . "_" . $pos2 . "_gap_in_" . $ids[1];
        } else {
            $consensus_nomenclature2 = $aa2 . "_" . $pos2 . "_" . $ids[1] . "_specific";
        }

        # Output 1: Print and update position for sequence 1, including gaps
        print $output1_fh "$aa1\_$pos1\t";
        $pos1++;

        # Output 2: Print and update position for sequence 2, using numbers from column 2 for gaps
        if ($aa2 ne '-') {
            print $output2_fh "$aa2\_$pos2\t";
            $pos2++;
        } else {
            print $output2_fh "-_$pos2\t";    # Use "-_" followed by the position from column 2 for gaps in column 2
            $pos2++;
        }

        # Print consensus nomenclature for sequence 1
        print $output1_fh "$consensus_nomenclature1\n";

        # Print consensus nomenclature for sequence 2
        print $output2_fh "$consensus_nomenclature2\n";
    }

    # Close the file handles for the current file
    close $fh;
    close $output1_fh;
    close $output2_fh;
}

# Script 5: Process replacement files and create new files with "nodes_to_add_to_" prefix
my @replacement_files = glob("replacement_for_*");

foreach my $replacement_file (@replacement_files) {
    # ... (Code from Script 5)
  
  # Generate the output file name by replacing "replacement_for_" with "nodes_to_add_to_"
    my $output_file = $replacement_file;
    $output_file =~ s/replacement_for_/nodes_to_add_to_/;

    # Run grep command and save the output to the generated output file using a shell
    system("grep '_specific' $replacement_file | grep -v '^-' > $output_file");

    print "Processed $replacement_file and saved output to $output_file\n";
}

print "Script completed successfully.\n";


# Script 6: Add nodes to network files and create new files with "_network_with_all_nodes.net" suffix
my @network_files = glob("*_network.net");

# Get a list of all files in the current directory
my @files = glob("*");

# Iterate through each file
foreach my $file (@files) {
    # Check if the file ends with "_network.net"
    if ($file =~ /(.+)_network\.net$/) {
        my $sequence_id = $1;  # Extract the sequence ID from the file name

        # Find the corresponding nodes file
        my $nodes_file = "nodes_to_add_to_" . $sequence_id . "_AT";
        my $nodes_file_full = (grep { $_ =~ /^$nodes_file/ } @files)[0];

        # Check if the nodes file exists
        if ($nodes_file_full) {
            # Read nodes to add from the second column
            my @nodes_to_add = ();
            open my $nodes_fh, '<', $nodes_file_full or die "Cannot open $nodes_file_full: $!";
            while (<$nodes_fh>) {
                chomp;
                my @columns = split(/\s+/);
                push @nodes_to_add, $columns[1] if @columns >= 2;
            }
            close $nodes_fh;

            # Read the network file
            my @network_content;
            my $last_row_number;
            my $last_number;
            my $edges_found = 0;
            my $added_nodes_count = 0;

            open my $network_fh, '<', $file or die "Cannot open $file: $!";
            while (<$network_fh>) {
                chomp;
                if (/^\*Vertices\s+(\d+)/) {
                    $last_number = $1;  # Store the number of vertices in the original file
                }
                if (/^\*Edges/) {
                    $edges_found = 1;
                }
                if ($edges_found) {
                    # Add nodes to the end, just above *Edges
                    for my $node (@nodes_to_add) {
                        $last_number++;
                        $added_nodes_count++;
                        my $new_node_line = "$last_number \"$node\"";
                        push @network_content, $new_node_line;
                    }
                    $edges_found = 0;  # Reset the flag after adding nodes
                }
                push @network_content, $_;
                $last_row_number = $.;
            }
            close $network_fh;

            # Remove empty rows from the final output
            @network_content = grep /\S/, @network_content;

            # Replace the number in the first row after "*Vertices" with the total count of original and added nodes
            $network_content[0] =~ s/^\*Vertices\s+\d+/\*Vertices $last_number/;

            # Create a new output file with the added nodes
            my $output_file = $sequence_id . "_network_with_all_nodes.net";
            open my $output_fh, '>', $output_file or die "Cannot open $output_file for writing: $!";
            print $output_fh join("\n", @network_content), "\n";
            close $output_fh;

            print "Nodes added to $file. New file created: $output_file\n";
            print "Total added nodes: $added_nodes_count\n";
            print "Total vertices (original + added): $last_number\n";
        }
    }
}

# Additional Steps: Remove intermediate files 

unlink glob("replacement_*");
unlink glob("nodes_to_add_*");
unlink glob("*_consensus_names.net");
unlink glob("*_network.net");

print "Analysis and file removal completed successfully.\n";
