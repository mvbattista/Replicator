#!/usr/local/bin/perl

use strict;
use warnings;
use Data::Dumper;
use ReplicatorReader;
use ReplicatorDDL;

my $template_file = shift @ARGV;
open my $in_fh, '<', $template_file or die "Cannot read input file: $!";
my @lines = <$in_fh>;
close $in_fh or die "Cannot close input file: $!";

my @tables = @{ReplicatorReader::replicator_reader(\@lines)};
# print Dumper(@tables);
my $sql_string = ReplicatorDDL::replicator_ddl_generator(@tables);
print $sql_string;