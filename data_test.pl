#!/usr/local/bin/perl
use strict;
use warnings;
use Data::Dumper;

sub test_generation {
    my @models = @_;
    my $file_count = 9000;
    for my $table (@models){
        my $file_name = $table->{class_name};
        $file_name =~ s/::/_/g;
        $file_name = $file_count.$file_name.'.t';
#        my @fields;
#        for my $i (@{$table->{fields}}) {
#            push @fields, $i->{name};
#        }
        $table->{class_name} =~ /^Fina::Corp::(.+)$/;
        my $class_name = $1;
        my $s = <<"TEST1";
#!/usr/local/bin/perl
#
#
#
use strict;
use warnings; 

use Test::More tests => 6;

our \$class;
BEGIN {
    my \$base_class = 'Fina::Corp';
    \$class = \$base_class.'::$class_name';
    use_ok(\$class);
}

isa_ok(\$class, 'Rose::DB::Object');

my \@columns = qw(
TEST1
        for my $col (@{$table->{fields}}) {
            $s .= '    ';
            $s .= $col->{name};
            $s .= "\n";
        }
        $s .= ");\n\nmy \@foreign_keys = qw(\n";
        for my $col (@{$table->{constraints}}) {
            $s .= '    ';
            $s .= $col->{model_name};
            $s .= "\n";
        }
        $s .= ");\n\nmy \@relationships = qw(\n";
        for my $col (@{$table->{relationships}}) {
            $s .= '    ';
            $s .= $col->{name};
            $s .= "\n";
        }
        $s .= <<'TEST2';
);
push @relationships, @foreign_keys;

my @methods = qw{
    manage_description
};

can_ok($class, ( @methods ));
is_deeply([$class->meta->column_names], \@columns, "Columns Defined as Expected");
is_deeply([ sort (map { $_->name } @{$class->meta->foreign_keys}) ], [sort @foreign_keys], "Foreign Keys Defined as Expected");
is_deeply([ sort (map { $_->name } @{$class->meta->relationships}) ], [sort @relationships], "Relationships Defined as Expected");

TEST2
    return $s;
    }

}

sub sql_generation {
# For multiple tables. Pass in each table as a scalar
    my @models = @_;
    my $s = "BEGIN;\n\n";
    my @sequences;
    my @fields;
    my @triggers;
    for my $table (@models) {
        push @sequences, @{$table->{sequences}} if (defined @{$table->{sequences}});
        push @triggers, @{$table->{triggers}} if (defined @{$table->{triggers}});
        for my $i (@{$table->{fields}}) {
            push @fields, $i->{name};
        }
    }
#    print "Hi there\n\n";
    
#    print Dumper(\@sequences, \@triggers, \@fields);

    if ( @sequences ) {
        $s .= "\\echo Creating sequences.\n\n";
        for my $i (@sequences) {
            $s .= "CREATE SEQUENCE $i;\n";
        }
        $s .= "\n";
        $s .= "\\echo Sequence creation complete.\n\n";
    }

    $s .= "\\echo Creating tables.\n\n";
    for my $table (@models) {

#       Count the number of lines first, determine the comma count, and set a line limit.

        my $comma_count = scalar @{$table->{fields}};
        $comma_count++ if (scalar @{$table->{uniques}});
        $comma_count += scalar @{$table->{constraints}};
        $comma_count--;

        $s .= "CREATE TABLE "; $s .= $table->{name}; $s .= "(\n";

        for my $i (@{$table->{fields}}) {
            $s .= "    $i->{name} ";
            $s .= uc $i->{type};
            $s .= " PRIMARY KEY" if ($i->{primary_key});
            $s .= " NOT NULL" if ($i->{not_null});
            if (exists $i->{default}) {
                if ($i->{default} eq 'now') {
                   $s .= ' DEFAULT timeofday()::TIMESTAMP';
                }
                elsif ($i->{default} eq '') {
                	$s .= " DEFAULT \'\'";
                }
                else {
                    $s .= " DEFAULT ";
                    $s .= $i->{default};
                }
            }
            unless ($comma_count == 0) {
                $s .= ",\n";
                $comma_count--;
            }
            else {
                $s .= "\n";
            }
        }
        if (scalar @{$table->{uniques}}) {
            my $a = join ", ",@{$table->{uniques}};
            $s .= "     UNIQUE(";
            $s .= $a;
            $s .= ")";
            unless ($comma_count == 0) {
                $s .= ",\n";
                $comma_count--;
            }
            else {
                $s .= "\n";
            }
        }
        for my $i (@{$table->{constraints}}) {
            my $str = "    CONSTRAINT fk_".$i->{field}." FOREIGN KEY (".$i->{field}.
                ") REFERENCES ".$i->{sql_table}." (".$i->{sql_column}.") MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE";
            unless ($comma_count == 0) {
                $str .= ",\n";
                $comma_count--;
            }
            else {
                $str .= "\n";
            }
            $s .= $str;
        }
        $s .= ");\n\n";
    }
    $s .= "\\echo Table creation complete.\n\n";

    if (scalar @triggers > 0) {
#        print "\n\nThis is a trigger!\n\n";
        $s .= "\\echo Creating triggers.\n\n";
        for my $i (@triggers) {
            my $str = "CREATE TRIGGER ".$i->{name}."\n    BEFORE INSERT OR UPDATE ON "
                .$i->{table}."\n    FOR EACH ROW\n    EXECUTE PROCEDURE update_last_modified()\n;\n";
            $s .= $str;
        }
        $s .= "\n";
        $s .= "\\echo Trigger creation complete.\n\n";
    }
    $s .= "\n--ROLLBACK;\nCOMMIT;\n";

    return $s;

}

my %table;
$table{name} = 'alerts';
$table{class_name} = 'Fina::Corp::M::Alert';
$table{fields} = [];
$table{uniques} = [];
$table{triggers} = [];
$table{constraints} = [];
$table{relationships} = [];
my $id = {
    name => 'id', type => 'SERIAL', primary_key => 1, not_null => 1, sequence => $table{name}.'_id_seq', 
#    default => 'nextval(\''.$table{name}.'_id_seq\') CONSTRAINT id_valid CHECK (id > -1)',
    };
push @{$table{fields}}, $id;
push @{$table{fields}}, {name => 'date_created', type => 'TIMESTAMP', not_null => 1, default => 'now'};
push @{$table{fields}}, {name => 'created_by', type => 'VARCHAR', not_null => 1, default => '', };
push @{$table{fields}}, {name => 'last_modified', type => 'TIMESTAMP', not_null => 1 };
push @{$table{fields}}, {name => 'modified_by', type => 'VARCHAR', not_null => 1, default => '', };
push @{$table{fields}}, {name => 'alert_level_id', type => 'INTEGER', not_null => 1 };
push @{$table{fields}}, {name => 'application_name', type => 'VARCHAR', not_null => 1 };
push @{$table{fields}}, {name => 'action', type => 'BOOLEAN', not_null => 1, default => 'false', };
push @{$table{fields}}, {name => 'message', type => 'VARCHAR', not_null => 1 };

push @{$table{constraints}}, {field => 'alert_level_id', sql_column => 'id',
    sql_table => 'alert_levels', model_name => 'Fina::Corp::M::Alert::Level', model_name => 'alert_levels'
    };
push @{$table{triggers}}, {name => 'alerts_last_modified', table => 'alerts'};

#print Dumper(\%table);
my $sql_string = sql_generation(\%table);
my $test_str = test_generation(\%table);

print "Here is the SQL string: $sql_string";

#open my $out_fh, '>', "data_test_out.sql" or die "Cannot create output file: $!";
#print $out_fh $sql_string;
#close $out_fh or die "Cannot close output file: $!";

print $test_str;