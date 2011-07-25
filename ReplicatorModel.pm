#
#
#
#############################################################################
package ReplicatorModel;

use strict;
use warnings;

use Data::Dumper;

sub replicator_model_generator {
    my @models = @_;
    my %result;
    for my $table (@models){
#        next unless ($table->{create_model_file});
		my $s = <<MODEL_text;

#
#
#
#############################################################################
package $table->{class_name};

use strict;
use warnings;

use base qw( Fina::Corp::M );

#############################################################################
#
#
#
__PACKAGE__->meta->setup(
    table => '$table->{name}',
    columns => [
MODEL_text

		for my $column ( @{$table->{fields}} ) {
	    	$s .= sprintf "%8s%-20s=> { type => '%s', %s%s%s%s%s},\n", "",
				$column->{name},
				lc $column->{type},
				$column->{not_null} ? "not_null => 1, ":"",
				$column->{default} ? ($column->{default} eq "''" ? "default => '', " : "default => '$column->{default}', "):"",
				$column->{length} ? "length => $column->{length}, ":"",
				($column->{primary_key} and scalar @{$table->{primary_key}} == 1) ? "primary_key => 1, ":"",
				$column->{sequence} ? "sequence => $column->{sequence}, ":"",
		}
		$s .= "    ],\n";
		if (scalar @{$table->{primary_key}} > 1) {
			$s .= "    primary_key_columns => ['";
			my $str = join("', '", @{$table->{primary_key}});
			$s .= $str;
			$s .= "']\n";
		}
		if (scalar @{$table->{uniques}}) {
			for my $u (@{$table->{uniques}}) {
				my $unique = join(", ", map {"'$_'"} @{$u});
				$s .= "    unique_key => [ $unique ],\n";
			}
		}
		if (scalar @{$table->{constraints}}) {
			my $t = "    ";
		    $s .= sprintf "%sforeign_keys => [\n", $t x 1;
			for my $fkey (@{$table->{constraints}}) {
		    	$s .= sprintf "%s%s => {\n", $t x 2, $fkey->{model_name};
		    	$s .= sprintf "%sclass => '%s',\n", $t x 3, $fkey->{model_class};
		    	#for my $hash_arg (qw(key_columns)) {
			    #	if ($fkey->{$hash_arg}) {
			    		$s .= sprintf "%s%s => {\n", $t x 3, 'key_columns';
			    		#my @kcol = keys %{$fkey->{$hash_arg}};
			    		#while (my $kcol = shift @kcol) {
			    		#	$model .= sprintf "%s$kcol => '%s'%s\n", $t x 4, $fkey->{$hash_arg}->{$kcol}, @kcol?",":"";
						#}
			    		$s .= sprintf "%s%s => '%s',\n", $t x 4, $fkey->{field}, $fkey->{sql_column};
			    		$s .= sprintf "%s},\n", $t x 3;
				#	}
				#}
		    	$s .= sprintf "%s},\n", $t x 2;
			}
		    $s .= sprintf "%s],\n", $t x 1;
		}
		if (scalar @{$table->{relationships}}) {
 			my $t = "    ";
	   		$s .= sprintf "%srelationships => [\n", $t x 1;
    		for my $rel (@{$table->{relationships}}) {
		    	$s .= sprintf "%s%s => {\n", $t x 2, $rel->{name};
		    	$s .= sprintf "%sclass => '%s',\n", $t x 3, $rel->{class};
		    	$s .= sprintf "%stype => '%s',\n", $t x 3, $rel->{type};
	    		$s .= sprintf "%s%s => {\n", $t x 3, 'key_columns';
 	    		$s .= sprintf "%s%s => '%s',\n", $t x 4, $rel->{column}, $rel->{foreign_column};
	    		$s .= sprintf "%s},\n", $t x 3;
    			$s .= sprintf "%s},\n", $t x 2;
   			}
    		$s .= sprintf "%s],\n", $t x 1;
		}
		$s .= ");\n\n";
	
		$result{$table->{class_name}} = $s;
    }
	return \%result;
}

1;

__END__

my $model = <<MODEL_text;

#
#
#
#############################################################################
package $package;

use strict;
use warnings;

use base qw( Fina::Corp::M );

#############################################################################
#
#
#
__PACKAGE__->meta->setup(
    table => '$table',
    columns => [
MODEL_text

unless (@pkey) {
$model .= <<MODEL_text;
        id                  => { type => 'serial', not_null => 1, primary_key => 1, sequence => '${table}_id_seq' },

MODEL_text
}

$model .= <<MODEL_text;
        date_created        => { type => 'timestamp', not_null => 1, default => 'now' },
        created_by          => { type => 'varchar', not_null => 1, default => '', },
        last_modified       => { type => 'timestamp', not_null => 1 },
        modified_by         => { type => 'varchar', not_null => 1, default => '', },

MODEL_text

for my $column ( @$columns ) {
    $model .= sprintf "%8s%-20s=> { type => '%s', %s%s%s%s},\n", "",
							$column->{column_name},
							lc $column->{type},
							$column->{not_null} ? "not_null => 1, ":"",
							defined $column->{default} ? "default => '$column->{default}', ":"",
							$column->{length} ? "length => $column->{length}, ":"",
							$column->{primary_key} ? "primary_key => 1, ":"",
}

#        field_type          => { type => 'varchar', not_null => 1, length => 100 },
#        value               => { type => 'varchar', not_null => 1, length => 100 },

$model .= <<MODEL_text2;
    ],
MODEL_text2

if(@unique) {
	my $unique = join(", ", map {"'$_'"} @unique);

$model .= <<MODEL_text3;
    unique_key => [ $unique ],
MODEL_text3
}

#print Dumper($foreign_keys);
my $s = "    ";

if(@$foreign_keys) {
    $model .= sprintf "%sforeign_keys => [\n", $s x 1;
	for my $fkey (@$foreign_keys) {
    	$model .= sprintf "%s%s => {\n", $s x 2, $fkey->{name};
    	$model .= sprintf "%sclass => '%s',\n", $s x 3, $fkey->{class};
    	for my $hash_arg (qw(key_columns)) {
	    	if ($fkey->{$hash_arg}) {
	    		$model .= sprintf "%s%s => {\n", $s x 3, $hash_arg;
	    		my @kcol = keys %{$fkey->{$hash_arg}};
	    		while (my $kcol = shift @kcol) {
	    			$model .= sprintf "%s$kcol => '%s'%s\n", $s x 4, $fkey->{$hash_arg}->{$kcol}, @kcol?",":"";
				}
	    		$model .= sprintf "%s},\n", $s x 3;
			}
		}
    	$model .= sprintf "%s},\n", $s x 2;
	}
    $model .= sprintf "%s],\n", $s x 1;
}

if(@$relationships) {
    $model .= sprintf "%srelationships => [\n", $s x 1;
	for my $fkey (@$relationships) {
    	$model .= sprintf "%s%s => {\n", $s x 2, $fkey->{name};
    	$model .= sprintf "%sclass => '%s',\n", $s x 3, $fkey->{class};
    	$model .= sprintf "%stype => '%s',\n", $s x 3, $fkey->{type};
    	for my $hash_arg (qw(column_map key_columns)) {
	    	if ($fkey->{$hash_arg}) {
	    		$model .= sprintf "%s%s => {\n", $s x 3, $hash_arg;
	    		my @kcol = keys %{$fkey->{$hash_arg}};
	    		while (my $kcol = shift @kcol) {
	    			$model .= sprintf "%s$kcol => '%s'%s\n", $s x 4, $fkey->{$hash_arg}->{$kcol}, @kcol?",":"";
				}
	    		$model .= sprintf "%s},\n", $s x 3;
			}
		}
    	for my $list_arg (qw(query_args)) {
	    	if ($fkey->{$list_arg}) {
	    		$model .= sprintf "%s%s => {\n", $s x 3, $list_arg;
	    		my @kcol = @{$fkey->{$list_arg}};
	    		while (my $kcol = shift @kcol) {
	    			my $val = shift @kcol;
	    			$model .= sprintf "%s$kcol => '%s'%s\n", $s x 4, $val, @kcol?",":"";
				}
	    		$model .= sprintf "%s},\n", $s x 3;
			}
		}

    	$model .= sprintf "%s},\n", $s x 2;
	}
    $model .= sprintf "%s],\n", $s x 1;
}

#my $relationships = [

$model .= <<MODEL_text4;
);
MODEL_text4

unless ( $manage_function_return and length($manage_function_return)) {
	$manage_function_return = "\$self->id || 'Unknown @pwords'";
}

$model .= <<MODEL_text2;

__PACKAGE__->make_manager_package;

#
#
#
sub manage_description {
    my \$self = shift;
    return ($manage_function_return);

    # default - may delete
    #return (\$self->id || 'Unknown @pwords');
}

1;

#############################################################################
__END__

MODEL_text2

return $model;
