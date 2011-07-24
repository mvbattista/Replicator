#
#
#
#############################################################################
package ReplicatorTest;

use strict;
use warnings;

use Data::Dumper;

sub replicator_test_generator {
    my @models = @_;
    my %result;
    my $file_count = 9000;
    for my $table (@models){
#        next unless ($table->{create_test_file});
        my $file_name = $table->{class_name};
        $file_name =~ s/::/_/g;
        $file_name = $file_count.'-'.$file_name.'.t';
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
is_deeply([$class->meta->column_names], @columns, "Columns Defined as Expected");
is_deeply([ sort (map { $_->name } @{$class->meta->foreign_keys}) ], [sort @foreign_keys], "Foreign Keys Defined as Expected");
is_deeply([ sort (map { $_->name } @{$class->meta->relationships}) ], [sort @relationships], "Relationships Defined as Expected");

TEST2
	$result{$file_name} = $s;
	$file_count++;
    }
	return \%result;
}



1;

__END__
