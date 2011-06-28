#!/usr/local/bin/perl
#
#
#
use strict;
use warnings;

use Test::More tests => 9;

our $class;
BEGIN {
    my $base_class = 'Fina::Corp';
    $class = $base_class.'::M::Client::Group::Type';
    use_ok( $class);
}

isa_ok($class, 'Rose::DB::Object');
my $class_mgr = $class. '::Manager';
isa_ok($class_mgr, 'Rose::DB::Object::Manager');

my @columns = qw(
    id
    date_created
    created_by
    last_modified
    modified_by
    name
    display_label
);

my @foreign_keys = qw(
);

my @relationships = qw(
    groups
    groups_map
);
push @relationships, @foreign_keys;

my @methods = qw{
    manage_description
};

can_ok($class, ( @methods ));
is_deeply([$class->meta->column_names], \@columns, "Columns Defined as Expected");
is_deeply([ sort (map { $_->name } @{$class->meta->foreign_keys}) ], [sort @foreign_keys], "Foreign Keys Defined as Expected");
is_deeply([ sort (map { $_->name } @{$class->meta->relationships}) ], [sort @relationships], "Relationships Defined as Expected");

my $obj = new_ok($class);
my $db = $class->init_db();
$db->dbh->begin_work;

$obj->db($db);

my %new_item = (
    created_by      => 'test',
    modified_by     => 'test',
    name            => 'test',
    display_label   => 'Testing Group Type',
); 

for my $column (@columns) {
    $obj->$column($new_item{$column});
}

eval {$obj->save};

$@ ? fail("Object Save failed.\n$@") : pass("Object Save passed.");


$db->dbh->rollback;

__END__
