#!/usr/local/bin/perl

use strict;
use warnings;

use Data::Dumper;

#----------------------------------
# config table name and fileds here
#----------------------------------

my $camp = "85";

# $do_copy will actually create the file.
my $do_copy = 1;

#@my $table = "client_departments";
#@my $table = "widget_instances";
#@my $table = "widget_entity_types";
#@my $table = "user_role_widget_function_map";
my $table = "role_widget_function_map";

my $pwords;
my $pkg;

#$pwords = "MCF Status Lookup"; # if absent, will be generated from table_name (remove "_", capitalize words)
#$pkg = "MCFStatusLookup"; #Override autogenerated package name (generated by collapsing $pwords)

my $pkgns_root = "Fina::Corp::M::";
my $pkgns      = "Fina::Corp::M::";

my $manage_pkgns_root = "Fina::Corp::Manage::";
my $manage_pkgns      = "Fina::Corp::Manage::";

my $columns = [
	# NOTE 1:
	# 	By deafult 'id' will be created as primary key, with sequence and all
	# 	If there is another primary key, specify that as below with  primary_key => 1
	#	{column_name => 'client_id',				type => 'integer', not_null => 1, primary_key => 1},
	# NOTE 2:
	# 	"foreign_key => 1" will create a foreign key in DDL
	# 	For Model class to have corresponding foreign_keys section, add to the variable $foreign_keys
	# 
	# 
#	{column_name => 'user_id',                  type => 'INTEGER', primary_key => 1, foreign_key_references => 'users(id)', },
#	{column_name => 'widget_tab_id',            type => 'INTEGER', primary_key => 1, foreign_key_references => 'widget_tabs(id)', },
	{column_name => 'role_code',                type => 'VARCHAR', primary_key => 1, },
	{column_name => 'function',                 type => 'VARCHAR', primary_key => 1, },

#	{column_name => 'type',                     type => 'VARCHAR', unique => 1, },
#	{column_name => 'display_label',            type => 'VARCHAR', },
#	{column_name => 'class',                    type => 'VARCHAR', },
#	{column_name => 'order_preference',         type => 'INTEGER', },
#	{column_name => 'unavailable',              type => 'boolean', default => "false" },
#	{column_name => 'inactive',                 type => 'boolean', default => "false" },

#	{column_name => 'client_id',                type => 'integer', not_null => 1, unique => 1, foreign_key_references => "clients(id)", },
#	{column_name => 'dept_code',                type => 'VARCHAR', not_null => 1, unique => 1, },
#	{column_name => 'dept_name',                type => 'VARCHAR', },
#	{column_name => 'address_id',               type => 'integer', not_null => 1, foreign_key_references => "addresses(id)", },
#	{column_name => 'parent_id',                type => 'integer', not_null => 1, foreign_key_references => "$table(id)", },

	#{column_name => 'mcf_status_id',            type => 'integer', foreign_key_references => "mcf_status_lookup(id)", },
	#{column_name => 'manager_id',               type => 'integer', foreign_key_references => "people(id)", },
	#{column_name => 'description',             type => 'VARCHAR', not_null => 1, default => "''"},
	#{column_name => 'sort_order1',             type => 'smallint', not_null => 1, default => 0, unique => 1},
];

#my $insert = [];
my $insert = [
	{
		role_code			=> "_developer",
		function			=> "Document__View",
	},
	{
		role_code			=> "_developer",
		function			=> "Document__Edit",
	},
	{
		role_code			=> "_developer",
		function			=> "Document__Edit",
	},
	{
		role_code			=> "_developer",
		function			=> "Document__Update",
	},
	{
		role_code			=> "_developer",
		function			=> "Document__Delete",
	},
	{
		role_code			=> "_developer",
		function			=> "Document__Deactivate",
	},
	{
		role_code			=> "manager",
		function			=> "Document__View",
	},
	{
		role_code			=> "manager",
		function			=> "Document__Edit",
	},
	{
		role_code			=> "manager",
		function			=> "Document__Update",
	},
	{
		role_code			=> "manager",
		function			=> "Document__Delete",
	},
	{
		role_code			=> "manager",
		function			=> "Document__Deactivate",
	},
	{
		role_code			=> "p2p_reviewer",
		function			=> "Document__View",
	},
	{
		role_code			=> "fans_approver_editor",
		function			=> "Document__View",
	},
	{
		role_code			=> "program_coordinator",
		function			=> "Document__View",
	},
	{
		role_code			=> "program_coordinator",
		function			=> "Document__Edit",
	},
	{
		role_code			=> "program_coordinator",
		function			=> "Document__Update",
	},
	{
		role_code			=> "program_coordinator",
		function			=> "Document__Delete",
	},
	{
		role_code			=> "program_coordinator",
		function			=> "Document__Deactivate",
	},
	{
		role_code			=> "_admin",
		function			=> "Document__View",
	},
	{
		role_code			=> "_admin",
		function			=> "Document__Edit",
	},
	{
		role_code			=> "_admin",
		function			=> "Document__Update",
	},
	{
		role_code			=> "_admin",
		function			=> "Document__Delete",
	},
	{
		role_code			=> "_admin",
		function			=> "Document__Deactivate",
	},
	{
		role_code			=> "fans_approver",
		function			=> "Document__View",
	},
	{
		role_code			=> "fd_user",
		function			=> "Document__View",
	},
	{
		role_code			=> "fd_user",
		function			=> "Document__Edit",
	},
];

#
# Fill in appropriately for foreign_keys in model class
#
#my $foreign_keys = [];
my $foreign_keys = [
	{name			=> 'role',
	 class			=> 'Fina::Corp::M::User::Role',
	 key_columns	=> {role_code => 'code',}
    },
#	{name			=> 'user',
#	 class			=> 'Fina::Corp::M::Users',
#	 key_columns	=> {user_id => 'id',}
#	},
];

#
# Fill in appropriately for relationships in model class
#
my $relationships = [];
#my $relationships = [ # place holder
#	{name			=> 'widget_instances',
#	 type			=> 'one to many',
#	 class			=> 'Fina::Corp::M::Widget::Instance',
#	 column_map		=> {id => 'entity_type_id',},
##	 key_columns	=> {id  => 'widget_id'}, #---
###	 query_args		=> [is_active => 1], #---
#	},
#];

my $sub_prefix; # auto generated
#or
#my $sub_prefix = "usertab";

my $migration_folder_sql = "migrations/pending/sjohn_widgets/sql";

#my $manage_function_return = undef;
my $manage_function_return = '$self->role->manage_description . " | " . $self->function';

#------------+
# config end |
#------------+

#my $pkey_specified;
my @unique;
my @pkey;
my %foreign_key;

for(@$columns) {
	#$pkey_specified++ if exists $_->{primary_key} and $_->{primary_key} > 0;
	push @unique, $_->{column_name} if $_->{unique};
	push @pkey, $_->{column_name} if $_->{primary_key};
	if ($_->{foreign_key_references}) {
		$foreign_key{$_->{column_name}} = $_->{foreign_key_references};
	}
}
my $unique = join ", ", @unique;
my $pkey = join ", ", @pkey;

my @pwords;

if (defined $pwords and length($pwords)) {
	@pwords = split(/\s+/, $pwords);
	print __LINE__. "@pwords: (@pwords)\n";
}

unless (@pwords) {
	my $pkg = $table;
	chop $pkg if $pkg =~ /s$/;
	chop $pkg if $pkg =~ /se$/;
	@pwords = split (/[_]/, $pkg);
	map {s/^(.)/uc $1/e} @pwords;
	#print __LINE__. " \@pwords: (@pwords)\n";
}

#print __LINE__. " \@pwords: (@pwords)\n";
#exit;

unless (defined $pkg and length($pkg)) {
	$pkg = join '', @pwords;
}

my $package = $pkgns . $pkg;
my $packag_wo_root = $package;
$packag_wo_root =~ s/Fina::Corp::M:://;
$packag_wo_root =~ s/\s//g;

#
# pluralize package name to derive manage package name
#
my $manage_pkg = $pkg;
$manage_pkg .= "e" if $manage_pkg =~ /s$/;
$manage_pkg .= "s";
my $manage_package = $manage_pkgns . $manage_pkg;

my $pkgns_path = $pkgns;
$pkgns_path =~ s|::|/|g;

my $manage_pkgns_path = $manage_pkgns;
$manage_pkgns_path =~ s|::|/|g;

my $manage_pkg_pre = $manage_pkgns;
$manage_pkg_pre =~ s/$manage_pkgns_root//;
$manage_pkg_pre =~ s/^:://;
$manage_pkg_pre =~ s/::$//;
if ($manage_pkg_pre) {
	$manage_pkg_pre =~ s/::/__/g;
	$manage_pkg_pre .= "__";
}
my $manage_pkg_code = $manage_pkg_pre . $manage_pkg;
$manage_pkg_code =~ s/\s//g;

#my $manage_pkgns_root = "Fina::Corp::Manage::";
#my $manage_pkgns = "Fina::Corp::Manage::Widgets::";
if (1) {
	printf "%-19s: %s\n", "Line", __LINE__;
	printf "%-19s: %s\n", "\$pkgns", $pkgns;
	printf "%-19s: %s\n", "\$manage_pkgns", $manage_pkgns;
	printf "%-19s: %s\n", "\$manage_pkg_pre", $manage_pkg_pre;
	printf "%-19s: %s\n", "\$manage_pkg_code", $manage_pkg_code;
	printf "%-19s: %s\n", "\$pkg", $pkg;
	printf "%-19s: %s\n", "\$package", $package;
	printf "%-19s: %s\n", "\$packag_wo_root", $packag_wo_root;
	printf "%-19s: %s\n", "\$manage_pkg", $manage_pkg;
	printf "%-19s: %s\n", "\$manage_package", $manage_package;
	printf "%-19s: %s\n", "\$manage_pkgns_path", $manage_pkgns_path;
	printf "%-19s: %s\n", "\@pwords", "@pwords";
}
#exit;

save (
	filename => "create-table-$table.sql",
	data => get_ddl(),
	display_path => $migration_folder_sql,
);
save (
	filename => "insert-table-$table.sql",
	data => get_insert(),
	display_path => $migration_folder_sql,
);
save (
	filename => "$pkg.pm",
	data => get_model(),
	display_path => "interchange/custom/lib/$pkgns_path",
);
save (
	filename => "$manage_pkg.pm",
	data => get_manage(),
	display_path => "interchange/custom/lib/$manage_pkgns_path",
);

unless ($do_copy) {
	print "\n\nIf you are happy with these files, set \$do_copy = 1 to actually copy these files to the shown directories...\n\n";
}

exit;

sub save {
	my %parms = @_;
	my $file = $parms{filename};
	my $data = $parms{data};
	my $display_path = $parms{display_path};
	
	open FILE, "> $file" or die "unable to open file '$file'";
	print FILE $data;
	close FILE or warn "unable to close file '$file'";
    print "file: '$file'";
    #print ", move to /home/sjohn/camp$camp/$display_path" if $display_path;
    if ($display_path) {
    	print "\n\tcp $file /home/sjohn/camp$camp/$display_path";
    	if ($do_copy) {
    		system("cp $file /home/sjohn/camp$camp/$display_path");
    		print "\n\t[ copied ]" if $display_path;
		}
	}
    print "\n";
}


sub get_ddl {

my $ddl = <<DDL_text1;
--
--
--
BEGIN;

\\echo 'Creating $table table ...'

DDL_text1

unless (@pkey) {
$ddl .= <<DDL_text2;
CREATE SEQUENCE ${table}_id_seq;

CREATE TABLE $table (
    id                          INTEGER PRIMARY KEY DEFAULT nextval('${table}_id_seq')
                                CONSTRAINT id_valid CHECK (id > -1),
DDL_text2
} else {
$ddl .= <<DDL_text3;
CREATE TABLE $table (
DDL_text3
}

$ddl .= <<DDL_text4;

    date_created                TIMESTAMP NOT NULL DEFAULT timeofday()::TIMESTAMP,
    created_by                  VARCHAR NOT NULL,
    last_modified               TIMESTAMP NOT NULL,
    modified_by                 VARCHAR NOT NULL,

DDL_text4

for my $column ( @$columns ) {
	if ($column->{primary_key} and @pkey == 1) {
    	$ddl .= sprintf "%4s%-28s%s%s PRIMARY KEY\n", "",
							$column->{column_name},
							uc $column->{type},
							$column->{length} ? "($column->{length})":"";
    	$ddl .= sprintf "%35s CONSTRAINT %s%s,\n", "",
							$column->{column_name} . "_valid",
							" CHECK (length($column->{column_name}) > 0 AND $column->{column_name} = trim($column->{column_name}))";
		next;
	}
    $ddl .= sprintf "%4s%-28s%s%s%s%s", "",
							$column->{column_name},
							uc $column->{type},
							$column->{length} ? "($column->{length})":"",
							$column->{not_null} ? " NOT NULL":"",
							defined $column->{default} ? " DEFAULT $column->{default}":"";
	if ($column->{foreign_key_references}) {
    	#$ddl .= sprintf "%4s%-28s%4sCONSTRAINT %s\n", "", "", "", "", "fk_xxxxxxxxx";
    	$ddl .= sprintf "\n%36sREFERENCES %s\n", "", $column->{foreign_key_references};
    	$ddl .= sprintf "%36sON DELETE RESTRICT\n", "";
    	$ddl .= sprintf "%36sON UPDATE CASCADE", "";
	}
    $ddl .= ",\n";
}

if (@pkey > 1) {
$ddl .= <<DDL_text5_1;

    PRIMARY KEY ($pkey),
DDL_text5_1
}

if (@unique) {
$ddl .= <<DDL_text5;

    UNIQUE ($unique),
DDL_text5
}


# remove last comma
$ddl =~ s/\,$//;

$ddl .= <<DDL_text;
);

CREATE TRIGGER ${table}_last_modified
    BEFORE INSERT OR UPDATE ON $table
    FOR EACH ROW
    EXECUTE PROCEDURE update_last_modified()
;

--ROLLBACK;
COMMIT;

DDL_text
return $ddl;
}

#
#
#
sub get_model {

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
}

sub get_insert {

	my @columns = qw(created_by modified_by);
	push @columns, map {$_->{column_name}} @$columns; 

	my @values;
	my $sql = "BEGIN;\n\n";

	if (@$insert) {
		for my $row (@$insert) {
			@values = qw('schema' 'schema');
			for (@$columns) {
				if ( defined $row->{$_->{column_name}} ) {
					if ($_->{type} =~ /integer/i) {
						push @values, sprintf("%s", $row->{$_->{column_name}});
					} else {
						push @values, sprintf("'%s'", $row->{$_->{column_name}});
					}
				} else {
					push @values, sprintf("null");
				}
			}
			$sql .=  "INSERT INTO $table ( " . join (", ", @columns) . ") VALUES ( " . join (", ", @values) . ");\n";
		}
	} else {
		@columns = qw(created_by modified_by);
		@values = qw(schema schema);
		push @columns, map {$_->{column_name}} @$columns; 
		push @values, map {"XX" . $_->{column_name} . "XX"} @$columns; 
		$sql .= "INSERT INTO $table ( " . join (", ", @columns) . ") VALUES ( '" . join ("', '", @values) . "');\n";
	}
	$sql .= "\n--ROLLBACK;\n";
	$sql .= "COMMIT;\n";

	return $sql;
}

#
#
#
sub get_manage {

my $disp_name = "@pwords";
my $disp_name_plural = $disp_name;
$disp_name_plural .= "e" if $disp_name_plural =~ /s$/;
$disp_name_plural .= "s";

unless ( $sub_prefix ) {
	$sub_prefix = $table;
	$sub_prefix =~ s/[_]//g;
	chop $sub_prefix if $sub_prefix =~ /s$/;
	chop $sub_prefix if $sub_prefix =~ /se$/;
}

my $mange = <<TEXT_END;

#
#
#
#############################################################################
package $manage_package;

use strict;
use warnings;

use $package;

use base qw( Fina::Corp::Manage );

#############################################################################
#
#
#
our \$_meta = {
    _model_class               => __PACKAGE__->_root_model_class().'::$packag_wo_root',
    _model_class_mgr           => __PACKAGE__->_root_model_class().'::${packag_wo_root}::Manager',
    _model_display_name        => '$disp_name',
    _model_display_name_plural => '$disp_name_plural',
    _sub_prefix                => '$sub_prefix',
    _func_prefix               => '${manage_pkg_code}_$sub_prefix',
};

#############################################################################
#
#
#
sub ${sub_prefix}List {
    my \$self = shift;
    return \$self->_common_list_display_all(\@_);
}

#
#
#
sub ${sub_prefix}Add {
    my \$self = shift;
    return \$self->_common_add(\@_);
}

#
#
#
sub ${sub_prefix}Properties {
    my \$self = shift;
    return \$self->_common_properties(\@_);
}

#
#
#
sub ${sub_prefix}Drop {
    my \$self = shift;
    return \$self->_common_drop(\@_);
}

#
#
#
sub ${sub_prefix}DetailView {
    my \$self = shift;
    return \$self->_common_detail_view(\@_);
}

1;

#############################################################################
__END__

TEXT_END

my $mange_func_insert = <<MFI;
COPY manage_functions (code, section_code, developer_only, in_menu, sort_order, display_label, created_by, modified_by) FROM STDIN;
${manage_pkg_code}_${sub_prefix}Add\t_development\tt\tt\t1200\tAdd $disp_name\tschema\tschema
${manage_pkg_code}_${sub_prefix}Properties\t_development\tt\tf\t1201\tEdit $disp_name\tschema\tschema
${manage_pkg_code}_${sub_prefix}Drop\t_development\tt\tf\t1202\tDrop $disp_name\tschema\tschema
${manage_pkg_code}_${sub_prefix}List\tgeneral_maint\tf\tt\t1203\tList $disp_name_plural\tschema\tschema
${manage_pkg_code}_${sub_prefix}DetailView\tgeneral_maint\tf\tf\t1204\t$disp_name Detail View\tschema\tschema
\\.

COPY manage_group_manage_function_map (manage_function_code, manage_group_code, created_by, modified_by) FROM STDIN;
${manage_pkg_code}_${sub_prefix}Add\tsite_developers\tschema\tschema
${manage_pkg_code}_${sub_prefix}Properties\tsite_developers\tschema\tschema
${manage_pkg_code}_${sub_prefix}Drop\tsite_developers\tschema\tschema
${manage_pkg_code}_${sub_prefix}List\tsite_developers\tschema\tschema
${manage_pkg_code}_${sub_prefix}DetailView\tsite_developers\tschema\tschema
\\.
MFI

save (
	#filename => "insert-table-manage-function.sql",
	filename => "insert-table-manage-function-${manage_pkg_code}_${sub_prefix}.sql",
	data => $mange_func_insert,
	display_path => $migration_folder_sql,
);

my $flds = join (", ", map {$_->{column_name}} @$columns);

my $Properties = <<MFI;
[comment]
    - THIS IS JUST AN EXAMPLE
    - EDIT THIS TO ACCEPT THE FIELDS: $flds (and possibly others)
    - ADD APPROPRIATE FOREIGN KEY (IF NEEDED) IN THE HIDDEN FIELD AND UNCOMMENT THE LINE
    - REMOVE THIS COMMENT SECTION WHEN FINAL
[/comment]

[include include/components/_views/itl/manage/function/_common_elements/properties_form.html]

[comment]<input type="hidden" name="client_id" value="[either][value client_id][or][cgi client_id][/either]" />[/comment]

MFI

for (@$columns) {
	my $column_name = $_->{column_name};

	my @label = split (/[_]/, $column_name);
	map {s/^(.)/uc $1/e} @label;

	if ($_->{type} =~ /boolean/i) {

$Properties .= <<MFI;
<tr>
    <td class="manage_form_table_label_cell">@label?</td>
    <td class="manage_form_table_input_cell">
        <input type="radio" name="$column_name" value="1"[checked name=$column_name value=1] /> Yes
        <input type="radio" name="$column_name" value="0"[checked name=$column_name value=0 default=1] /> No
    </td>
</tr>

MFI

	} else {
$Properties .= <<MFI;
<tr>
    <td class="manage_form_table_label_cell">@label:&nbsp;</td>
    <td class="manage_form_table_input_cell"><input type="text" name="$column_name" value="[value $column_name]" size="100" maxlength="100" /></td>
</tr>

MFI
	}

}
#
#$Properties .= <<MFI;
#[comment]
#    - THIS IS JUST AN EXAMPLE
#    - EDIT THIS TO ACCEPT THE FIELDS: $flds (and possibly others)
#    - REMOVE THIS COMMENT SECTION WHEN FINAL
#[/comment]
#
#[include include/components/_views/itl/manage/function/_common_elements/properties_form.html]
#
#<input type="hidden" name="client_id" value="[either][value client_id][or][cgi client_id][/either]" />
#<tr>
#    <td class="manage_form_table_label_cell">Source Code:&nbsp;</td>
#    <td class="manage_form_table_input_cell"><input type="text" name="code" value="[value code]" size="6" maxlength="6" /></td>
#</tr>
#<tr>
#    <td class="manage_form_table_label_cell">Company Name:&nbsp;</td>
#    <td class="manage_form_table_input_cell"><input type="text" name="company_name" value="[value company_name]" size="50" maxlength="50" /></td>
#</tr>
#<tr>
#    <td class="manage_form_table_label_cell">Enable division select box?</td>
#    <td class="manage_form_table_input_cell">
#        <input type="radio" name="has_divisions" value="1"[checked name=has_divisions value=1] /> Yes
#        <input type="radio" name="has_divisions" value="0"[checked name=has_divisions value=0 default=1] /> No
#    </td>
#</tr>
#
#MFI
#
save (
    filename => "${manage_pkg_code}_${sub_prefix}Properties-0.html",
    data => $Properties,
    display_path => "catalogs/core/include/components/_views/itl/manage/function",
);

#print "Create catalogs/core/include/components/_views/itl/manage/function/${manage_pkg}_${sub_prefix}Properties-0.html with fileds: $flds\n";
#print "Create catalogs/core/include/components/_views/itl/manage/function/${manage_pkg}_${sub_prefix}Properties-0.html with fileds: " . join (", ", map {$_->{column_name}} @$columns) . "\n";

return $mange;

}
