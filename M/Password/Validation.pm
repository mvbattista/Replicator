package Fina::Corp::M::Password::Validation;

use strict;
use warnings;

use base qw( Fina::Corp::M );

use Fina::Corp::M::Password::ComplexityLevel;

__PACKAGE__->meta->setup(
    table => 'password_complexity_validations',
    columns => [
        id                              => { type => 'serial', primary_key => 1, not_null => 1, sequence => 'password_complexity_validations_id_seq' },

        date_created                    => { type => 'timestamp', default => 'now', not_null => 1 },
        created_by                      => { type => 'varchar', not_null => 1, default => '', },
        last_modified                   => { type => 'timestamp', not_null => 1 },
        modified_by                     => { type => 'varchar', not_null => 1, default => '', },

        password_complexity_level_code  => { type => 'varchar', not_null => 1 },
        sequence                        => { type => 'smallint', not_null => 1, default => 1 },
        validation_method               => { type => 'varchar' },
        arguments                       => { type => 'varchar' },
    ],
    primary_key_columns => 'id',
    foreign_keys => [
        password_complexity => {
            class => 'Fina::Corp::M::Password::ComplexityLevel',
            key_columns => {
                password_complexity_level_code => 'code',
            },
        },
    ],
);

sub manage_description {
    my $self = shift;
    return sprintf("%s (rule %s)", $self->password_complexity->display, $self->sequence);
    #return ($self->id || 'Unknown Password Validation Method');
}


package Fina::Corp::M::Password::Validation::Manager;

use base qw( Fina::Corp::M::Manager );

sub object_class { 'Fina::Corp::M::Password::Validation' };

__PACKAGE__->make_manager_methods('instances');

1;
