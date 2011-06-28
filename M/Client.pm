#
#
#
#############################################################################
package Fina::Corp::M::Client;

use strict;
use warnings;

use Fina::Corp::M::Client::Application;
use Fina::Corp::M::Client::Company;
use Fina::Corp::M::Client::FANS::Enhancer;
use Fina::Corp::M::Client::FANS::Factor;
use Fina::Corp::M::Client::FANS::Initiative;

use Fina::Corp::M::Password::ComplexityLevel;

use base qw( Fina::Corp::M );

#############################################################################
#
#
#
__PACKAGE__->meta->setup(
    table => 'clients',
    columns => [
        id                                  => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'clients_id_seq' },

        date_created                        => { type => 'timestamp', not_null => 1, default => 'now' },
        created_by                          => { type => 'varchar', not_null => 1, default => '', length => 32 },
        last_modified                       => { type => 'timestamp', not_null => 1 },
        modified_by                         => { type => 'varchar', not_null => 1, default => '', length => 32 },

        display_label                       => { type => 'varchar', not_null => 1, length => 50 },
        code                                => { type => 'varchar', length => 6 },
        password_expiry_days                => { type => 'integer', not_null => 1, default => 365 },
        minimum_password_complexity_level   => { type => 'smallint', not_null => 1, default => 2 },
    ],
    foreign_keys => [
        minimum_password_complexity => {
            class => 'Fina::Corp::M::Password::ComplexityLevel',
            key_columns => {
                minimum_password_complexity_level => 'level',
            },
        },
    ],

    relationships => [
        active_enhancers => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client::FANS::Enhancer',
            key_columns => {
                id => 'client_id',
            },
            query_args  => [ is_active => 1 ],
        },
        active_factors => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client::FANS::Factor',
            key_columns =>  {
                id => 'client_id',
            },
            query_args  => [ is_active => 1 ],
        },
        active_initiatives => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client::FANS::Initiative',
            key_columns =>  {
                id => 'client_id',
            },
            query_args  => [ is_active => 1 ],
        },
        active_recognition_classes => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client::FANS::RecognitionClass',
            key_columns =>  {
                id => 'client_id',
            },
            query_args  => [ is_active => 1 ],
        },
        active_shipping_modes => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client::FANS::ShippingMode',
            key_columns => {
                id => 'client_id',
            },
            query_args  => [ is_active => 1 ],
        },

        application_mappings => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client::Application',
            key_columns => {
                id => 'client_id',
            },
        },
        language_mappings => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client::Language',
            key_columns => {
                id => 'client_id',
            },
        },
        companies => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client::Company',
            key_columns => {
                id => 'client_id',
            },
        },
        enhancers => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client::FANS::Enhancer',
            key_columns => {
                id => 'client_id',
            },
        },
        factors => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client::FANS::Factor',
            key_columns =>  {
                id => 'client_id',
            }
        },
        initiatives => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client::FANS::Initiative',
            key_columns =>  {
                id => 'client_id',
            }
        },
        recognition_classes => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client::FANS::RecognitionClass',
            key_columns =>  {
                id => 'client_id',
            }
        },
        shipping_modes => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client::FANS::ShippingMode',
            key_columns => {
                id => 'client_id',
            },
        },
        documents => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::Client::Document',
            key_columns => {
                id => 'client_id',
            },
        },
    ],
);

__PACKAGE__->make_manager_package;

#
#
#
sub manage_description {
    my $self = shift;
    return ($self->display_label || $self->id || 'Unknown Client');
}

1;

#############################################################################
__END__
