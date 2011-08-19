#
#
#
#############################################################################
package ReplicatorDDL;

use strict;
use warnings;
use Data::Dumper;

sub replicator_ddl_generator {
# For multiple tables. Pass in each table as a scalar
    my @models = @_;
    my $s = "BEGIN;\n\n";
    my @sequences;
    my @fields;
    my @triggers;
#     print Dumper(@models);
    for my $table (@models) {
        push @sequences, @{$table->{sequences}} if (defined @{$table->{sequences}});
        push @triggers, @{$table->{triggers}} if (defined @{$table->{triggers}});
        for my $i (@{$table->{fields}}) {
            push @fields, $i->{name};
        }
    }

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
        $comma_count += scalar @{$table->{uniques}};
        $comma_count += scalar @{$table->{constraints}};
        $comma_count += 1 if (scalar @{$table->{primary_key}} > 1);
        $comma_count--;

        $s .= "CREATE TABLE "; $s .= $table->{name}; $s .= "(\n";

        for my $i (@{$table->{fields}}) {
            $s .= "    $i->{name} ";
            $s .= uc $i->{type};
            $s .= " PRIMARY KEY" if ($i->{primary_key} and scalar @{$table->{primary_key}} == 1);
            $s .= " NOT NULL" if ($i->{not_null});
            if (exists $i->{default}) {
                if ($i->{default} eq "'now'") {
                   $s .= ' DEFAULT timeofday()::TIMESTAMP';
                }
                # elsif ($i->{default} eq '') {
                #     $s .= " DEFAULT ''";
                # }
                else {
                    $s .= " DEFAULT ";
                    if ($i->{type} =~ /^boolean$/i and 
                        $i->{default} =~ /'(false|true)'/i) {
                        $s .= uc $1;
                    }
                    else {
                        $s .= $i->{default};
                    }
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
        	for my $u (@{$table->{uniques}}) {
	            my $a = join ", ",@{$u};
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
        }
        if (scalar @{$table->{primary_key}} > 1) {
        	my $str = "    CONSTRAINT pk_".$table->{name}." PRIMARY KEY ( ";
        	my $f = join(', ', @{$table->{primary_key}});
        	$str .= $f;
        	$str .= " )";
            $s .= $str;
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
                ") REFERENCES ".$i->{sql_table}." (".$i->{sql_column}.") MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT";
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

1;

__END__
