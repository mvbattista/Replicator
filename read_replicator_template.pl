#!/usr/local/bin/perl
use strict;
use warnings;
use List::MoreUtils qw(first_index any);

use Data::Dumper;

my $template_file = shift @ARGV;
open my $in_fh, '<', $template_file or die "Cannot read input file: $!";
my @lines = <$in_fh>;
close $in_fh or die "Cannot close input file: $!";
chomp(@lines);
@lines = grep {$_ !~ /^$/} @lines;
my @tables;
while (scalar (@lines) > 0) {
    die "Input file not in correct format." if ($lines[0] !~ /^CREATE\s+(\w+)\s+(\S+)\s*$/i);
    my $table_name = $1;
    my $class_name = $2;
    my $end = first_index {$_ =~ /^ENDTABLE$/i} @lines;
    my @a = splice(@lines, 0,$end);
    $a[0] = $table_name.' '.$class_name;
    shift @lines;
    push @tables, \@a;
}
for (my $arr = 0; $arr < scalar(@tables); $arr++) {
    my @a = @{$tables[$arr]};
    my %table;
    my @names = split(/\s+/, $a[0]);
    shift @a;
    $table{name} = $names[0];
    $table{class_name} = $names[1];
    $table{fields} = [];
    $table{uniques} = [];
    $table{primary_key} = [];
    $table{constraints} = [];
    $table{relationships} = [];
    if (any {$_ =~ /^ID$/i} @a) {
        my $i = first_index {$_ =~ /^ID$/i} @a;
        splice(@a, $i, 1);
        my $id = { 
            name => 'id', type => 'SERIAL', primary_key => 1, not_null => 1, sequence => $table{name}.'_id_seq',
        };
        push @{$table{fields}}, $id;
        push @{$table{primary_key}}, 'id';
    }
    if (any {$_ =~ /^FF$/i} @a) {
        my $i = first_index {$_ =~ /^FF$/i} @a;
        splice(@a, $i, 1);
        push @{$table{fields}}, {name => 'date_created', type => 'TIMESTAMP', not_null => 1, default => 'now'};
        push @{$table{fields}}, {name => 'created_by', type => 'VARCHAR', not_null => 1, default => '', };
        push @{$table{fields}}, {name => 'last_modified', type => 'TIMESTAMP', not_null => 1 };
        push @{$table{fields}}, {name => 'modified_by', type => 'VARCHAR', not_null => 1, default => '', };
    }
    my @r_lines = grep(/^RELATIONSHIP /, @a);
    for my $r_line (@r_lines) {
        my @rel = split(/\s+/, $r_line);
        shift @rel;
        if ($rel[1] eq '11') { $rel[1] = 'one to one';
        }elsif ($rel[1] eq '1*') { $rel[1] = 'one to many';
        }elsif ($rel[1] eq '**') { $rel[1] = 'many to many';
        }else { die "Improper formatting in RELATIONSHIP line." }
        my $r_obj = {
            name => $rel[0],
            type => $rel[1],
            class => $rel[2],
            column => $rel[3],
            foreign_column => $rel[4],
        };
        push @{$table{relationships}}, $r_obj;
    }
    @a = grep(!/^RELATIONSHIP /, @a);
    my @single_uniques;
    for my $line (@a) {
        my @b = split(/\s+/, $line);
        my $field_name = shift @b;
        my $field_type = uc shift @b;
        my $not_null;
        my $default;
        while (scalar (@b) > 0) {
            if (any {$_ =~ /^NN$/i} @b) {
                my $i = first_index {$_ =~ /^ID$/i} @b;
                splice(@b, $i, 1);
                $not_null = 1;
            } else { $not_null = 0; }
            if (any {$_ =~ /^D=(.+)$/i} @b) {
                my $i = first_index {$_ =~ /^D=$/i} @b;
                splice(@b, $i, 1);
                $default = $1;
            } else { $default = undef; }
            if (any {$_ =~ /^P$/i} @b) {
                my $i = first_index {$_ =~ /^P$/i} @b;
                splice(@b, $i, 1);
                push @{$table{primary_key}}, $field_name;
            } 
            if (any {$_ =~ /^FK/i} @b) {
                my $i = first_index {$_ =~ /^FK/i} @b;
                splice(@b, $i, 1);
                my @fk = split(/-/, $_);
                shift @fk;
                my $z = {
                    field => $field_name,
                    sql_table => $fk[0],
                    sql_column => $fk[1],
                    model_class => $fk[2],
                    model_name => $fk[3],
                };
                push @{$table{constraints}}, $z;
            } 
            while (any {$_ =~ /^U(\d*)$/i} @b) {
                my $i = first_index {$_ =~ /^U/i} @b;
                splice(@b, $i, 1);
                if ($1) {
                    my $index = $1 - 1;
                    push @{$table{uniques}->[$index]}, $field_name;
                } else {
                    push @single_uniques, [$field_name];
                }
            } 
        }
        push @{$table{uniques}}, @single_uniques;
        my %s = ('name', $field_name, 'type', $field_type);
        $s{not_null} = 1 if ($not_null);
        $s{default} = $default if (defined($default));
        push @{$table{fields}}, \%s;

#       push @{$table{fields}}, {name => 'last_modified', type => 'TIMESTAMP', not_null => 1 };
    }
    $" = "\n";
    print "@a\n\n";
    $tables[$arr] = \%table;
}
print Dumper(\@tables);
