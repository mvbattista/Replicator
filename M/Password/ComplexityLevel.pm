package Fina::Corp::M::Password::ComplexityLevel;

use strict;
use warnings;

use base qw( Fina::Corp::M );

use Fina::Corp::M::User;
use Fina::Corp::M::Client;
use Fina::Corp::M::Password::Validation;
use Fina::Corp::C::Password::Validation;

__PACKAGE__->meta->setup(
    table => 'password_complexity_levels',
    columns => [
        code            => { type => 'varchar', primary_key => 1, not_null => 1 },

        date_created    => { type => 'timestamp', default => 'now', not_null => 1 },
        created_by      => { type => 'varchar', not_null => 1, default => '', },
        last_modified   => { type => 'timestamp', not_null => 1 },
        modified_by     => { type => 'varchar', not_null => 1, default => '', },

        level           => { type => 'smallint', not_null => 1 },
        display         => { type => 'varchar' },
        comment         => { type => 'varchar' },
    ],
    primary_key_columns => 'code',
    unique_key => [ qw/
        level
    / ],
    relationships => [
        clients => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client',
            key_columns => {
                level  => 'minimum_password_complexity_level',
            },
        },
        users => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::User',
            key_columns => {
                level  => 'password_complexity_level',
            },
        },
        validations => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Password::Validation',
            key_columns => {
                code  => 'password_complexity_level_code',
            },
        },
    ],
);

sub password_complexity_ok{
    my $self = shift;
    my $password = shift;
    my @parameters = @{ Fina::Corp::M::Password::Validation::Manager->get_objects( query => [
        password_complexity_level_code => $self->code, ] ) };
    for my $i (@parameters) {
        return 0 unless (Fina::Corp::C::Password::Validation->password_complexity_validation($i->validation_method, $password, $i->arguments));
    }
    return 1;

}

sub manage_description {
    my $self = shift;
    return ($self->code || 'Unknown Password Complexity Level');
}


package Fina::Corp::M::Password::ComplexityLevel::Manager;

use base qw( Fina::Corp::M::Manager );

sub object_class { 'Fina::Corp::M::Password::ComplexityLevel' };

__PACKAGE__->make_manager_methods('instances');

1;