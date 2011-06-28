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
    $class = $base_class.'::M::Client::Group';
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
    client_id
    owner_id
    name
    display_label
    display_image_url
    description
    group_type_id
    value
    group_display_type_id
    start_date
    end_date
);

my @foreign_keys = qw(
    client
    owner
    group_type
    group_display_type
);

my @relationships = qw(
    ancestor_group
    descendant_group
    group_person_map
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

my $group_type = Fina::Corp::M::Client::Group::Type->new( name => 'test', display_label => 'Testing Group Type' );
$group_type->save;

my $group_display_type = Fina::Corp::M::Client::Group::DisplayType->new( name => 'test', display_label => 'Testing Group Display Type' );
$group_display_type->save;

my $client_objects = Fina::Corp::M::Client::Manager->get_objects(
    sort_by => "random()",
    limit   => 1,
);
my $client_obj = @{$client_objects}[0];
$client_obj->load;

my $client_person_objects = Fina::Corp::M::Client::ClientPerson::Manager->get_objects(
    sort_by => "random()",
    limit   => 1,
);
my $client_person_obj = @{$client_person_objects}[0];
$client_person_obj->load;

my %new_item = (
    created_by              => 'test',
    modified_by             => 'test',
    client_id               => $client_obj->id,
    owner_id                => $client_person_obj->id,
    name                    => 'Test name',
    display_label           => 'Testing Group',
    group_type_id           => $group_type->id,
    group_display_type_id   => $group_display_type->id,
); 

for my $column (@columns) {
    $obj->$column($new_item{$column});
}

eval {$obj->save};

$@ ? fail("Object Save failed.\n$@") : pass("Object Save passed.");


$db->dbh->rollback;

__END__
