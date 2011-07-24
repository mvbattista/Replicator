#!/usr/local/bin/perl

use strict;
use warnings;
use Data::Dumper;
use ReplicatorReader;
use ReplicatorDDL;
use ReplicatorTest;

my $template_file = shift @ARGV;
open my $in_fh, '<', $template_file or die "Cannot read input file: $!";
my @lines = <$in_fh>;
close $in_fh or die "Cannot close input file: $!";

my @tables = @{ReplicatorReader::replicator_reader(\@lines)};
# print Dumper(@tables);
my $sql_string = ReplicatorDDL::replicator_ddl_generator(@tables);
#print $sql_string;
my $test_result = ReplicatorTest::replicator_test_generator(@tables);
for my $i (sort keys %{$test_result}) {
	print "FILE: $i\n".$test_result->{$i}."\n\n";
}
#print Dumper($test_result);