#
#
#
#############################################################################
package Fina::Corp::M::User;

use strict;
use warnings;

use Data::Dumper;

use base qw( Fina::Corp::M );

use Fina::Corp::M::ManageGroupUserMap;
use Fina::Corp::M::UserManageFunctionMap;
use Fina::Corp::M::User::Role::UserRoleMap;

use Fina::Corp::M::Client;
#use Fina::Corp::M::UserRoleMap;
use Fina::Corp::M::TimeZone;
use Fina::Corp::M::Client::Company;

use Fina::Corp::M::Password::ComplexityLevel;

my $_client_company_class = 'Fina::Corp::M::Client::Company';

use constant RESTRICTED				=> 'RESTRICTED';
use constant UNRESTRICTED			=> 'UNRESTRICTED';

use constant TRUE					=> 'true';
use constant FALSE					=> 'false';

use constant ADMIN					=> '_admin';
use constant BASIC					=> 'basic';
use constant DEVELOPER				=> '_developer';
use constant FANS_APPROVER			=> 'fans_approver';
use constant FANS_APPROVER_EDITOR	=> 'fans_approver_editor';
use constant FD_MAINT				=> 'fd_maint';
use constant FD_USER				=> 'fd_user';
use constant REC_ASSEMBLY			=> 'rec_assembly';
use constant REPORTS				=> '_reports';
use constant P2P_REVIEWER           => 'p2p_reviewer';
use constant BRANCH					=> 'branch';
use constant DIVISION				=> 'division';

#q/
#{
#	no strict 'refs';
#
#	sub import {
#		{
#			for my $key (qw(RESTRICTED UNRESTRICTED)) {
#				*{caller(0) . '::' .$key} =  *{__PACKAGE__ . '::' . $key};
#			}
#		}
#	}
#}
#/;

#############################################################################
#
#
#
__PACKAGE__->meta->setup(
    table => 'users',
    columns => [
        id                        => { type => 'serial', not_null => 1, primary_key => 1, sequence => 'users_id_seq' },

        date_created              => { type => 'timestamp', not_null => 1, default => 'now' },
        created_by                => { type => 'varchar', not_null => 1, default => '', length => 32 },
        last_modified             => { type => 'timestamp', not_null => 1 },
        modified_by               => { type => 'varchar', not_null => 1, default => '', length => 32 },

        version_id                => { type => 'integer', not_null => 1 },
        status_code               => { type => 'varchar', not_null => 1, length => 30 },
        username                  => { type => 'varchar', not_null => 1, length => 100 },
        email                     => { type => 'varchar', not_null => 1, length => 100 },
        time_zone_code            => { type => 'varchar', not_null => 1, length => 50 },
        password                  => { type => 'varchar', not_null => 1, length => 40 },
        password_expires_on       => { type => 'date', },
        password_force_reset      => { type => 'boolean', not_null => 1, default => 'false' },
        password_failure_attempts => { type => 'smallint', not_null => 1, default => 0 },
        password_hash_kind_code   => { type => 'varchar', not_null => 1, length => 4, default => 'md5' },
        lockout_until             => { type => 'timestamp' },
        language_code             => { type => 'varchar', not_null => 1, default => 'en', length => 2 },
        last_login                => { type => 'timestamp' },
        num_logins                => { type => 'smallint', not_null => 1, default => 0 },
        password_complexity_level => { type => 'smallint', not_null => 1, default => 2 },
    ],
    unique_key => [
        [ 'username' ],
        [ 'email' ],
    ],
    foreign_keys => [
        status => {
            class => 'Fina::Corp::M::UserStatus',
            key_columns => {
                status_code => 'code',
            },
        },
        time_zone => {
            class => 'Fina::Corp::M::TimeZone',
            key_columns => {
                time_zone_code => 'code',
            },
        },
        version => {
            class => 'Fina::Corp::M::UserVersion',
            key_columns => {
                version_id => 'id',
            },
        },
        language => {
            class => 'Fina::Corp::M::Language',
            key_columns => {
                language_code => 'language_code',
            },
        },
        password_complexity => {
            class => 'Fina::Corp::M::Password::ComplexityLevel',
            key_columns => {
                password_complexity_level => 'level',
            },
        },

    ],
    relationships => [
#        roles => {
#            type      => 'many to many',
#            #map_class => 'Fina::Corp::M::UserRoleMap',
#            map_class => 'Fina::Corp::M::User::Role::UserRoleMap',
#        },
        roles_map => {
            type      => 'one to many',
            class => 'Fina::Corp::M::User::Role::UserRoleMap',
            key_columns => {
                id => 'user_id'
            }
        },
        roles => {
            type      => 'many to many',
            map_class => 'Fina::Corp::M::User::Role::UserRoleMap',
            #map_class => 'Fina::Corp::M::UserRoleMap',
        },
        manage_groups => {
            type      => 'many to many',
            map_class => 'Fina::Corp::M::ManageGroupUserMap',
        },
        manage_functions => {
            type      => 'many to many',
            map_class => 'Fina::Corp::M::UserManageFunctionMap',
        },
        fd_user => {
            type      => 'one to one',
            class => 'Fina::Corp::M::FinaDirect::User',
            key_columns => {
                id => 'id',
            },
        },
        login_attempts => {
            type        => 'one to many',
            class       => 'Fina::Corp::M::User::Audit::UserLoginAttempt',
            key_columns => {
                username => 'username',
            },
            add_methods => [ 'count' ],
        },
#        # REMOVE
#        widgets => {
#            type      => 'many to many',
#            map_class => 'Fina::Corp::M::UserWidgetInstanceMap',
#        },
#        # REMOVE END
#        tabs => {
#            type      => 'many to many',
#            map_class => 'Fina::Corp::M::UserTabMap',
#        },
    ],
);

__PACKAGE__->make_manager_package;

#
#
#
sub manage_description {
    my $self = shift;
    return ($self->username || 'Unknown User');
}

#
#
#
sub is_site_manager {
    my $self = shift;

    return (grep { $_->code eq '_admin' } @{ $self->roles }) ? 1 : 0;
}

#
#
#
sub is_developer {
    my $self = shift;

    return (grep { $_->code eq DEVELOPER } @{ $self->roles }) ? 1 : 0;
}

#
#
#
sub is_authorized_reports_user {
    my $self = shift;

    return (grep { $_->code eq '_reports' } @{ $self->roles }) ? 1 : 0;
}

#
#
#
sub authorized_management_functions {
    my $self = shift;

    unless ($self->is_site_manager) {
        Fina::Corp::Exception->throw('User not authorized as site manager');
    }

    my $functions = {};
    for my $function (@{ $self->manage_functions }) {
        $functions->{$function->code} = $function;
    }
    for my $group (@{ $self->manage_groups }) {
        for my $function (@{ $group->manage_functions }) {
            $functions->{$function->code} = $function;
        }
    }

    return (wantarray ? values %$functions : [ values %$functions ]);
}

#
#
#
sub is_authorized {
    my $self = shift;
    my $check_function = shift;

    unless (defined $check_function and $check_function ne '') {
        Vend::Exception::ArgumentMissing->throw( 'check_function' );
    }

    my $privileged_funcs = $self->authorized_management_functions;
    #Vend::Exception::ArgumentMissing->throw( "<pre>".Dumper([[$check_function],sort map {$_->code} @$privileged_funcs])."</pre>");
    return unless (@$privileged_funcs);

    return unless (grep { $_->code eq $check_function } @$privileged_funcs);

    return 1;
}

#
#
#
sub is_fans_approver {
    my $self = shift;
    my $check_function = shift;

    my $role_code = FANS_APPROVER;

	return unless $self->has_role($role_code);

    my $_role_map = $self->_role_map( role_code => $role_code);
    return undef unless $_role_map;
	return 1 unless $_role_map->client_restricted;

    return $self->_role_map( role_code => $role_code)->client_restricted;

    unless (defined $check_function and $check_function ne '') {
        Vend::Exception::ArgumentMissing->throw( 'check_function' );
    }

    my $privileged_funcs = $self->authorized_management_functions;
    return unless (@$privileged_funcs);

    return unless (grep { $_->code eq $check_function } @$privileged_funcs);

    return 1;
}

#
#
#
sub has_role {
    my $self = shift;
    my $check_role = shift;

    unless (defined $check_role and $check_role ne '') {
        Fina::Corp::Exception->throw('Missing argument: role');
    }

    if (grep { $_->code eq $check_role } @{ $self->roles }) {
        return 1;
    }

    return 0;
}

#
#
#
sub _role_map {

    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};

    my $role_map = new Fina::Corp::M::User::Role::UserRoleMap (
        user_id		=> $self->id,
        role_code 	=> $role_code,
    );

    unless ($role_map->load(speculative => 1)) {
		return undef;
		#$self->_throw( { msg => "No user/role mapping found: " . $self->username . "/" . $role_code} ) if $debug;
    }

    return $role_map;
}

sub get_stringified_entitlements {
    my $self				= shift;
	my %parms				= @_;
    my $role_code			= $parms{role_code};
    my $debug				= $parms{debug} // shift;

	my $entitlements = $self->get_entitlements;
	if (defined $role_code and $role_code =~ /\w+/) {
		my @role_codes = split(/[,]/, $role_code);
		for my $role (keys %$entitlements) {
			delete $entitlements->{$role} unless grep {$_ eq $role} @role_codes;
		}
	}
	my @ents;
	for my $role (keys %$entitlements) {
		unless ($entitlements->{$role}->{client_restricted}) {
			push @ents, "$role:all_clients";
			next;
		}
		for my $client (keys %{ $entitlements->{$role}->{client_maps} } ) {
			unless ( $entitlements->{$role}->{client_maps}->{$client}->{company_restricted} ) {
				push @ents, "$role:$client:all_companies";
				next;
			}
			for my $company (keys %{ $entitlements->{$role}->{client_maps}{$client}->{company_maps} } ) {
				unless ( $entitlements->{$role}->{client_maps}->{$client}->{company_maps}->{$company}->{further_restricted} ) {
					push @ents, "$role:$client:$company:no_further_restriction";
					next;
				}
				for my $further (keys %{ $entitlements->{$role}->{client_maps}{$client}->{company_maps}->{$company}->{restriction_map} } ) {
					push @ents, "$role:$client:$company:$further(" . join(",", (@{ $entitlements->{$role}->{client_maps}{$client}->{company_maps}->{$company}->{restriction_map}->{$further} } )) . ")";
				}
			}

		}
	}

	return join "; ", @ents;

}

#
# sub get_entitlements() returns the complete entitlements of the current user.
#
# $entitlemnet->{$role_code}->{client_restricted} = 1 | 0
# $entitlemnet->{$role_code}->{client_maps} = {} when client_restricted = 0
# $entitlemnet->{$role_code}->{client_maps}->{$client_id}->{company_restricted} = 1 | 0
# $entitlemnet->{$role_code}->{client_maps}->{$client_id}->{company_maps} = {} when company_restricted = 0
# $entitlemnet->{$role_code}->{client_maps}->{$client_id}->{company_maps}->{$company_code}->{further_restricted} = 1 | 0
# $entitlemnet->{$role_code}->{client_maps}->{$client_id}->{company_maps}->{$company_code}->{restriction_map} = {} when further_restricted = 0
# $entitlemnet->{$role_code}->{client_maps}->{$client_id}->{company_maps}->{$company_code}->{restriction_map}->{$restriction_code} = [value,value]
#
# Example:
#
#  $entitlement = {
#	'_admin' => {
#		'client_restricted' => 0
#		'client_maps' => {},
#	},
#	'_reports' => {
#		'client_restricted' => 1
#		'client_maps' => {
#			'3' => {
#				'company_restricted' => 1,
#				'company_maps' => {
#					'UAL9' => {
#						'further_restricted' => 0,
#						'restriction_map' => {}
#					}
#				}
#			},
#			'791' => {
#				'company_restricted' => 1,
#				'company_maps' => {
#					'UAN3' => {
#						'further_restricted' => 1,
#						'restriction_map' => {
#							'branch' => [
#								'SFO*'
#							]
#						}
#					}
#				}
#			},
#		},
#	},
#	'fans_approver' => {
#		'client_restricted' => 1
#		'client_maps' => {
#			'3' => {
#				'company_restricted' => 1,
#				'company_maps' => {
#					'UAL9' => {
#						'further_restricted' => 1,
#						'restriction_map' => {
#							'branch' => [
#								'SFOSW'
#							]
#						}
#					}
#				}
#			},
#		},
#	},
#	'fd_user' => {
#		'client_maps' => {
#			'67' => {
#				'company_restricted' => 1,
#					'company_maps' => {
#						'REN3' => {
#							'further_restricted' => 0,
#							'restriction_map' => {}
#						}
#					}
#			},
#		},
#	},
#  }
#
sub get_entitlements {

    my $self				= shift;
	my %parms				= @_;
    my $debug				= $parms{debug} // shift;

	my $entitlemnet = {};

	for my $role_map (@{ $self->roles_map }) {
		my $role_code = $role_map->role_code;
		my $client_restricted = $entitlemnet->{$role_code}->{client_restricted} = $role_map->client_restricted;
		my $client_maps = $client_restricted ? $role_map->user_role_client_maps : [];
		if ($client_restricted and @$client_maps) {
			for my $client_map (@$client_maps) {
				my $client_id = $client_map->client_id;
				my $company_restricted = $entitlemnet->{$role_code}->{client_maps}->{$client_id}->{company_restricted} = $client_map->company_restricted;
				my $company_maps = $company_restricted ?  $client_map->user_role_client_company_maps : [];
				if ($company_restricted and @$company_maps) {
					for my $company_map (@$company_maps) {
						my $company_code = $company_map->company_code;
						my $further_restricted = $entitlemnet->{$role_code}->{client_maps}->{$client_id}->{company_maps}->{$company_code}->{further_restricted} = $company_map->further_restricted;
						my $restriction_maps = $further_restricted ? $company_map->user_role_client_company_restriction_maps : [];
						if ($further_restricted and @$restriction_maps) {
							for my $restriction_map (@$restriction_maps) {
								my $restriction_code = $restriction_map->restriction_code;
								push @{$entitlemnet->{$role_code}->{client_maps}->{$client_id}->{company_maps}->{$company_code}->{restriction_map}->{$restriction_code}}, $restriction_map->value;
							}
						} else {
							$entitlemnet->{$role_code}->{client_maps}->{$client_id}->{company_maps}->{$company_code}->{restriction_map} = {};
						}
					}
				} else {
					$entitlemnet->{$role_code}->{client_maps}->{$client_id}->{company_maps} = {};
				}
			}
		} else {
			$entitlemnet->{$role_code}->{client_maps} = {};
		}
	}

    ::logDebug( sprintf ("user_id %s, username %s, \$entitlement: %s", $self->id, $self->username, ::uneval($entitlemnet) ) ) if $debug;

	return $entitlemnet;
}

#
#
#
sub is_fans_super_approver {

    my $self				= shift;
	my %parms				= @_;
    my $debug				= $parms{debug} // shift;

	return grep { $_ == $self->id } @{ $self->get_fans_super_approvers(@_) };
}

#
#
#
sub get_fans_super_approvers {

    my $self				= shift;
	my %parms				= @_;
    my $debug				= $parms{debug} // shift;

	return $self->_get_fans_approvers(
					client_restricted => FALSE,
					debug => $debug
				);
}

#
#
#
sub _get_fans_approvers {

    my $self				= shift;
	my %parms				= @_;
    my $client_restricted	= $parms{client_restricted} || FALSE;
    my $debug				= $parms{debug} || '';

	return $self->_get_entitled_user_ids_for_role(
					role_code => FANS_APPROVER,
					client_restricted => $client_restricted,
					debug => $debug
				);
}

#
#
#
sub _get_entitled_user_ids_for_role {

    my $self				= shift;
	my %parms				= @_;
    my $role_code			= $parms{role_code};
    my $debug				= $parms{debug} || '';
    my $client_restricted	= $parms{client_restricted};

    my $maps = Fina::Corp::M::User::Role::UserRoleMap::Manager->get_objects (
					query => [
        				role_code			=> $role_code,
        				client_restricted	=> $client_restricted,
					]
    );

	my @user_ids = sort {$a <=> $b} map {$_->user_id} @$maps;

    if ($debug) {
    	my $msg = sprintf ("user_id '%s', username '%s', role: '%s', client_restricted '%s'", $self->id, $self->username, $role_code, $client_restricted);
    	my @users = sort {$a cmp $b} map {$_->user->username.':'.$_->user->id} @$maps;
    	::logDebug( sprintf ("L%s: $msg: found user_ids (%s), username:user_id (%s)", __LINE__, "@user_ids", "@users") );
	}

    return [@user_ids];
}

#
#
#
sub get_client_approvers {
	return shift->get_client_fans_approvers(@_);
}

#
#
#
sub get_client_fans_approvers {

    my $self			= shift;
	my %parms			= @_;
    my $client_id		= $parms{client_id};
    my $debug			= $parms{debug} || '';

	return $self->_get_client_fans_approvers(
					client_id => $client_id,
					client_restricted => TRUE,
					company_restricted => FALSE,
					debug => $debug
				);
}

#
#
#
sub _get_client_fans_approvers {

    my $self				= shift;
	my %parms				= @_;
    my $debug				= $parms{debug} || '';
    my $client_id			= $parms{client_id};
    my $client_restricted	= $parms{client_restricted};
    my $company_restricted	= $parms{company_restricted};

	return $self->_get_entitled_user_ids_for_client(
					role_code => FANS_APPROVER,
					client_id => $client_id,
					client_restricted => $client_restricted,
					company_restricted => $company_restricted,
					debug => $debug
				);
}

#
#
#
sub _get_entitled_user_ids_for_client {
    my $self				= shift;
	my %parms				= @_;
    my $role_code			= $parms{role_code};
    my $client_id			= $parms{client_id};
    my $client_restricted	= $parms{client_restricted};
    my $company_restricted	= $parms{company_restricted};
    my $debug				= $parms{debug} || '';

    my $maps = Fina::Corp::M::User::Role::UserRoleMap::Manager->get_objects (
					require_objects => ['user_role_client_maps'],
					query => [
        				role_code			=> $role_code,
        				client_restricted	=> $client_restricted,
        				'user_role_client_maps.client_id' => $client_id,
        				'user_role_client_maps.company_restricted' => $company_restricted,
					]
    );

	my @user_ids = map {$_->user_id} @$maps;

	$self->_throw( {type =>'client', record_count=>(scalar @$maps), user_ids=>\@user_ids, maps=>$maps} ) if $debug eq 'client1';

    return [@user_ids];
}


#
#
#
sub get_company_approvers {
	return shift->get_client_company_fans_approvers(@_);
}

#
#
#
sub get_client_company_fans_approvers {

    my $self			= shift;
	my %parms			= @_;
    my $debug			= $parms{debug} || '';
    my $client_id		= $parms{client_id};
    my $company_code	= $parms{company_code};

	return $self->_get_client_company_fans_approvers(
					client_id => $client_id,
					company_code => $company_code,
					client_restricted => TRUE,
					company_restricted => TRUE,
					further_restricted => FALSE,
					debug => $debug
				);
}

#
#
#
sub _get_client_company_fans_approvers {

    my $self				= shift;
	my %parms				= @_;
    my $debug				= $parms{debug} || '';
    my $client_id			= $parms{client_id};
    my $company_code		= $parms{company_code};
    my $client_restricted	= $parms{client_restricted};
    my $company_restricted	= $parms{company_restricted};
    my $further_restricted	= $parms{further_restricted};

	return $self->_get_entitled_user_ids_for_company(
					role_code => FANS_APPROVER,
					client_id => $client_id,
					company_code => $company_code,
					client_restricted => $client_restricted,
					company_restricted => $company_restricted,
					further_restricted => $further_restricted,
					debug => $debug
				);
}

#
#
#
sub _get_entitled_user_ids_for_company {
    my $self				= shift;
	my %parms				= @_;
    my $role_code			= $parms{role_code};
    my $client_id			= $parms{client_id};
    my $company_code		= $parms{company_code};
    my $client_restricted	= $parms{client_restricted};
    my $company_restricted	= $parms{company_restricted};
    my $further_restricted	= $parms{further_restricted};
    my $debug				= $parms{debug} || '';

    my $maps = Fina::Corp::M::User::Role::UserRoleMap::Manager->get_objects (
					require_objects => ['user_role_client_maps.user_role_client_company_maps'],
					query => [
        				role_code			=> $role_code,
        				client_restricted	=> $client_restricted,
        				'user_role_client_maps.client_id' => $client_id,
        				'user_role_client_maps.company_restricted' => $company_restricted,
        				'user_role_client_maps.user_role_client_company_maps.company_code' => $company_code,
        				'user_role_client_maps.user_role_client_company_maps.further_restricted' => $further_restricted,
					],
					multi_many_ok => 1,
    );

	my @user_ids = map {$_->user_id} @$maps;

	$self->_throw( {type => 'company', record_count=>(scalar @$maps), user_ids=>\@user_ids, maps=>$maps, parms => \%parms} ) if $debug eq 'cmp1';

    return [@user_ids];
}

#
#
#
sub get_branch_approvers {
	return shift->get_client_company_branch_fans_approvers(@_);
}

#
#
#
sub get_client_company_branch_fans_approvers {

    my $self				= shift;
	my %parms				= @_;
    my $debug				= $parms{debug} || '';
    my $client_id			= $parms{client_id};
    my $company_code		= $parms{company_code};
    my $branch				= $parms{branch};

	return $self->_get_entitled_user_ids_for_restriction(
					role_code => FANS_APPROVER,
					client_id => $client_id,
					company_code => $company_code,
					restriction_code => BRANCH,
					restriction_value => $branch,
					client_restricted => TRUE,
					company_restricted => TRUE,
					further_restricted => TRUE,
					debug => $debug
				);
}

#
#
#
sub _get_client_company_branch_fans_approvers {

    my $self				= shift;
	my %parms				= @_;
    my $debug				= $parms{debug} || '';
    my $client_id			= $parms{client_id};
    my $company_code		= $parms{company_code};
    my $branch				= $parms{branch};
    my $client_restricted	= $parms{client_restricted};
    my $company_restricted	= $parms{company_restricted};
    my $further_restricted	= $parms{further_restricted};

	return $self->_get_entitled_user_ids_for_restriction(
					role_code => FANS_APPROVER,
					client_id => $client_id,
					company_code => $company_code,
					restriction_code => BRANCH,
					restriction_value => $branch,
					client_restricted => $client_restricted,
					company_restricted => $company_restricted,
					further_restricted => $further_restricted,
					debug => $debug
				);
}

#
#
#
sub _get_entitled_user_ids_for_restriction {
    my $self				= shift;
	my %parms				= @_;
    my $role_code			= $parms{role_code};
    my $client_id			= $parms{client_id};
    my $company_code		= $parms{company_code};
    my $restriction_code	= $parms{restriction_code};
    my $restriction_value	= $parms{restriction_value};
    my $client_restricted	= $parms{client_restricted};
    my $company_restricted	= $parms{company_restricted};
    my $further_restricted	= $parms{further_restricted};
    my $debug				= $parms{debug} || '';

	# relations
	my $CLIENT_MAPS			= 'user_role_client_maps';
	my $COMPANY_MAPS		= 'user_role_client_company_maps';
	my $RESTRICTION_MAPS	= 'user_role_client_company_restriction_maps';

    my $maps = Fina::Corp::M::User::Role::UserRoleMap::Manager->get_objects (
					require_objects => ['user_role_client_maps.user_role_client_company_maps.user_role_client_company_restriction_maps'],
					query => [
        				role_code			=> $role_code,
        				client_restricted	=> $client_restricted,
        				"$CLIENT_MAPS.client_id" => $client_id,
        				"$CLIENT_MAPS.company_restricted" => $company_restricted,
        				"$CLIENT_MAPS.$COMPANY_MAPS.company_code" => $company_code,
        				"$CLIENT_MAPS.$COMPANY_MAPS.further_restricted" => $further_restricted,
        				"$CLIENT_MAPS.$COMPANY_MAPS.$RESTRICTION_MAPS.restriction_code" => $restriction_code,
        				"$CLIENT_MAPS.$COMPANY_MAPS.$RESTRICTION_MAPS.value" => $restriction_value,
					],
					multi_many_ok => 1,
    );

	my @user_ids = map {$_->user_id} @$maps;

	$self->_throw( {type => "$restriction_code:$restriction_value", record_count=>(scalar @$maps), user_ids=>\@user_ids, maps=>$maps, parms => \%parms} ) if $debug eq 'restriction';

    return [@user_ids];
}

sub _throw {
    my $self			= shift;
	my @parms 			= @_;

	my ($pkg, $path, $lno) = caller();

    Fina::Corp::Exception->throw(sprintf("<pre>%s[%s]%s</pre>", $path, $lno, Dumper(\@parms)));
}


#
#
#
sub _role_client_map {
    
    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};
    my $client_id		= $parms{client_id};
    my $company_code    = $parms{company_code};

    my $role_map = $self->_role_map( role_code => $role_code);

    if(!$client_id) {
        my $company_object = $_client_company_class->new( code => $company_code );        
        unless( $company_object->load( speculative => 1 ) ) {
            Fina::Corp::FinaDirect::Exception->throw("Unknown company code : $company_code");
        }
        $client_id = $company_object->client_id;
    }


    my $role_client_map = new Fina::Corp::M::User::Role::UserRoleClientMap (
        user_role_map_id		=> $role_map->id,
        client_id			 	=> $client_id,
    );
    #::logDebug( '$role_client_map before load: ' . ::uneval($role_client_map->see_obj) );
    unless ($role_client_map->load(speculative => 1)) {
        #Fina::Corp::FinaDirect::Exception->throw("No user/role/client mapping found: " . $self->username . "/$role_code/$client_id");
        return 0;
    }

    return $role_client_map;
}

#
#
#
sub _role_client_company_map {
    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};
    my $client_id		= $parms{client_id};
    my $company_code	= $parms{company_code};

    my $role_client_map = $self->_role_client_map( role_code => $role_code, client_id => $client_id, company_code => $company_code);

    return 0 unless $role_client_map;

    my $role_client_company_map = new Fina::Corp::M::User::Role::UserRoleClientCompanyMap (
        	user_role_client_map_id		=> $role_client_map->id,
        	company_code			 	=> $company_code,
	);

    unless ($role_client_company_map->load(speculative => 1)) {
        return 0;
#        Fina::Corp::FinaDirect::Exception->throw("No user/role/client/company mapping found: " .
#			$self->username . "/$role_code/$client_id/$company_code");
    }

    return $role_client_company_map;
}

#
#
#
sub _role_client_company_restriction_maps {
    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};
    my $client_id		= $parms{client_id};
    my $company_code	= $parms{company_code};
    my $restriction_code	= $parms{restriction_code};

    my $role_client_company_map = $self->_role_client_company_map( role_code => $role_code, client_id => $client_id, company_code => $company_code);

#    my $role_client_company_restrictions = new Fina::Corp::M::User::Role::UserRoleClientCompanyRestrictionMap::Manager->get_objects (
    my $role_client_company_restrictions = Fina::Corp::M::User::Role::UserRoleClientCompanyRestrictionMap::Manager->get_objects (
        	user_role_client_company_map_id		=> $role_client_company_map->id,
        	restriction_code				 	=> $restriction_code,
	);

    return $role_client_company_restrictions;
}

#
#
#
sub is_client_restricted {
    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};

    return $self->_role_map( role_code => $role_code)->client_restricted;
}

#
#
#
sub role_entitled {
    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};
    my $debug			= $parms{debug} || '';

    my $res = $self->role_entitlement( role_code => $role_code, debug => $debug );

	if ($res->{entitled} eq UNRESTRICTED) {
		return 1;
	} elese {
		return 0;
	}
}

#
#
#
sub role_entitlement {
    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};
    my $debug			= $parms{debug} || '';

	# default return value when there is no role map record for this user 
	my $this_res = {
		entitled					=> undef, 
		obj							=> undef,
		obj_type					=> undef,
		entitlement_type			=> 'role',
		entitlement_value_checked	=> "role_code:$role_code",
		username					=> $self->username,
	};

    my $_role_map =  $self->_role_map( role_code => $role_code);

	if ($_role_map) {
		$this_res->{obj}      = $_role_map;
		$this_res->{obj_type} = 'role_map';
	
		if ($_role_map->client_restricted) {
			$this_res->{entitled} = RESTRICTED;
		} else {
			$this_res->{entitled} = UNRESTRICTED;
		}
	}

	$self->_throw( $this_res  ) if $debug eq 'role';

	return $this_res;
}

#
#
#
sub client_entitled {
    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};
    my $client_id		= $parms{client_id};
    my $debug			= $parms{debug} || '';

	my $res = $self->client_entitlement(role_code => $role_code, client_id => $client_id, debug => $debug);

	if ($res->{entitled} eq UNRESTRICTED) {
		return 1;
	} elese {
		return 0;
	}
}

#
#
#
sub client_entitlement {
    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};
    my $client_id		= $parms{client_id};
    my $debug			= $parms{debug} || '';

    my $res = $self->role_entitlement( role_code => $role_code, debug => $debug );

	if ($res->{entitled} eq RESTRICTED) {
		my $_role_map = $res->{obj};
		my $_client_map = $_role_map->user_role_client_map(client_id => $client_id);

		$res->{entitlement_type}			= 'client';
		$res->{entitlement_value_checked}	= "role_code:$role_code, client_id:$client_id";

		if ($_client_map) {
			$res->{obj}							= $_client_map;
			$res->{obj_type}					= 'client_map';
			#$res->{entitlement_type}			= 'client';
			#$res->{entitlement_value_checked}	= "role_code:$role_code, client_id:$client_id";

			if ($_client_map->company_restricted) {
				$res->{entitled} = RESTRICTED;
			} else {
				$res->{entitled} = UNRESTRICTED;
			}
		} else {
			$res->{entitled} = undef;
    		#Fina::Corp::Exception->throw(__LINE__."<pre>user '" . $self->username . "' has client restriction for role '$role_code', however no clients are configured yet<pre>");
		}
	}

	$self->_throw( $res  ) if $debug eq 'client';

	# either original $res or modified in this sub
	return $res;
}

#
#
#
sub company_entitled {
    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};
    my $client_id		= $parms{client_id};
    my $company_code	= $parms{company_code};
    my $debug			= $parms{debug} || '';

	my $res = $self->company_entitlement(role_code => $role_code, client_id => $client_id, company_code => $company_code, debug => $debug);

	if ($res->{entitled} eq UNRESTRICTED) {
		return 1;
	} elese {
		return 0;
	}
}

#
#
#
sub company_entitlement {
    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};
    my $client_id		= $parms{client_id};
    my $company_code	= $parms{company_code};
    my $debug			= $parms{debug} || '';

    if(!$client_id) {
        my $company_object = $_client_company_class->new( code => $company_code );        
        unless( $company_object->load( speculative => 1 ) ) {
            Fina::Corp::FinaDirect::Exception->throw("Unknown company code : $company_code");
        }
        $client_id = $company_object->client_id;
    }

	my $res = $self->client_entitlement(role_code => $role_code, client_id => $client_id, debug => $debug);

	$self->_throw( $res  ) if $debug eq 'company1';

	$res->{entitlement_type}			= 'company';
	$res->{entitlement_value_checked}	= "role_code:$role_code, client_id:$client_id, company_code:$company_code";

	if ($res->{entitled} eq RESTRICTED) {
		my $_client_map = $res->{obj};
		my $_company_map = $_client_map->user_role_client_company_map(company_code => $company_code);
		if ($_company_map) {
			$res->{obj}							= $_company_map;
			$res->{obj_type}					= 'company_map';
			if ($_company_map->further_restricted) {
				$res->{entitled} = RESTRICTED;
			} else {
				$res->{entitled} = UNRESTRICTED;
			}
		} else {
			$res->{entitled} = undef;
		}
	}

	$self->_throw( $res  ) if $debug eq 'company2';

	# either original $res or modified in this sub
	return $res;
}

#
#
#
sub branch_entitled {
    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};
    my $client_id		= $parms{client_id};
    my $company_code	= $parms{company_code};
    my $branch			= $parms{branch};
    my $debug			= $parms{debug} || '';

	my $res = $self->company_entitlement(role_code => $role_code, client_id => $client_id, company_code => $company_code, debug => $debug);
	$self->_throw( {res=>$res,parms=>\%parms}  ) if $debug eq "b1";

	if ($res->{entitled} eq RESTRICTED) {

		my $_company_map = $res->{obj};
		my $further_entitled = $_company_map->user_role_client_company_further_entitled(restriction_code => BRANCH, value => $branch, debug => $debug);
		$self->_throw( {res=>$res,parms=>\%parms, further_entitled=>$further_entitled}  ) if $debug eq "b2";

		if ( $further_entitled ) {
			return 1;
		} else {
			return 0;
		}
	}

	if ($res->{entitled} eq UNRESTRICTED) {
		return 1;
	} else {
		return 0;
	}
}

#
#
#
sub division_entitled {
    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};
    my $client_id		= $parms{client_id};
    my $company_code	= $parms{company_code};
    my $value			= $parms{branch};

	my $res = $self->company_entitlement(role_code => $role_code, client_id => $client_id, company_code => $company_code);
	if ($res->{entitled} eq RESTRICTED) {
		my $_company_map = $res->{obj};
		if ( $_company_map->user_role_client_company_further_entitled(restriction_code => 'division', value => $value)) {
			return 1;
		} else {
			return 0;
		}
	}

	if ($res->{entitled} eq UNRESTRICTED) {
		return 1;
	} else {
		return 0;
	}
}

#
# Checks entitlement for the supplied parameters, that is,
# if only client_id is provided, return if this user has unrestricted entitlement for that client.
# if client_id & company are provided,  return if this user has unrestricted entitlement for that company.
# if client_id, company & branch are provided,  return if this user has unrestricted entitlement for that company branch.
# if no parameter provided, return if this user has unrestricted entitlement for all clients
#
sub is_fans_approver_editor {
    my $self				= shift;

	return $self->is_entitled(
						@_,
						role_code => FANS_APPROVER_EDITOR,
					);
}

#
# May be superfluous, use is_fans_approver_editor
#
sub _is_fans_approver_editor {
    my $self				= shift;
	my %parms				= @_;
    my $client_id			= $parms{client_id};
    my $company_code		= $parms{company_code};
    my $company_id			= $parms{company_id};
    my $restriction_code	= $parms{restriction_code};
    my $restriction_value	= $parms{restriction_value};
    my $debug				= $parms{debug} || '';

	return $self->is_entitled(
						role_code => FANS_APPROVER_EDITOR,
						client_id => $client_id,
						company_code => $company_code,
						company_id => $company_id,
						restriction_code => $restriction_code,
						value => $restriction_value,
						debug => $debug,
					);
}

#
#
#
sub is_entitled {
    my $self				= shift;
	my %parms				= @_;
    my $role_code			= $parms{role_code};
    my $client_id			= $parms{client_id};
    my $company_code		= $parms{company_code};
    my $company_id			= $parms{company_id};
    my $restriction_code	= $parms{restriction_code};
    my $restriction_value	= $parms{restriction_value};
    my $debug				= $parms{debug} || '';

	my $res = $self->check_entitlement(
						role_code => $role_code,
						client_id => $client_id,
						company_code => $company_code,
						company_id => $company_id,
						restriction_code => $restriction_code,
						value => $restriction_value,
						debug => $debug,
					);

	if ($res->{entitled} eq UNRESTRICTED) {
		return 1;
	} else {
		return 0;
	}
}

#
# Generic
#
sub check_entitlement {
    my $self				= shift;
	my %parms				= @_;
    my $role_code			= $parms{role_code};
    my $client_id			= $parms{client_id};
    my $company_code		= $parms{company_code};
    my $company_id			= $parms{company_id};
    my $restriction_code	= $parms{restriction_code};
    my $value				= $parms{value};
    my $debug				= $parms{debug} || '';

	unless ( defined $role_code and length($role_code)) {
		$self->_throw( "username=".$self->username.": missing role_code for checking entitlement"  );
	}
	if (defined $company_id and length($company_id)) {
    	$company_code		= $company_code || $_client_company_class->get_company_code_from_client_company_id(company_id => $company_id);
	}

	# if the request is to check further restrictions like branch, division
	if (defined $restriction_code and length($restriction_code)) {
		unless ( $value && ($client_id || $company_code) ) {
    		$self->_throw( "username=".$self->username." \$restriction_code=[$restriction_code]: missing one of (client_id, company_code, company_id) or value: \$role_code=[$role_code] \$client_id=[$client_id] \$company_code=[$company_code] \$company_id=[$company_id] \$restriction_code=$restriction_code" );
		}

		my $res = $self->company_entitlement(role_code => $role_code, client_id => $client_id, company_code => $company_code, debug => $debug);

		$res->{entitlement_type}			= $restriction_code;
		my @checked = qw(role_code client_id company_code restriction_code value);
		$res->{entitlement_value_checked}	= join (", ", map {sprintf("%s:%s", $_, $parms{$_})} @checked);

		$self->_throw( $res  ) if $debug eq 'check1';

		if ($res->{entitled} eq RESTRICTED) {
			my $_company_map = $res->{obj};
			if ( $_company_map->user_role_client_company_further_entitled(restriction_code => $restriction_code, value => $value )) {
				$res->{entitled} = UNRESTRICTED;
			} else {
				$res->{entitled} = RESTRICTED;
			}
		}

		$self->_throw( $res  ) if $debug eq 'check';
	
		return $res;
	}
	if (defined $company_code and length($company_code)) {
		my $res = $self->company_entitlement(role_code => $role_code, client_id => $client_id, company_code => $company_code, debug => $debug);
		$self->_throw( $res  ) if $debug eq 'check';
		return $res;
	}
	if (defined $client_id and length($client_id)) {
		my $res = $self->client_entitlement(role_code => $role_code, client_id => $client_id, debug => $debug);
		$self->_throw( $res  ) if $debug eq 'check';
		return $res;
	}

	my $res = $self->role_entitlement( role_code => $role_code, debug => $debug );
	$self->_throw( $res  ) if $debug eq 'check';
	return $res;
}

sub check_approver {
	my $self = shift;
	my %args = @_;

	my $all				= $args{all}       // 0; #/
	my $debug			= $args{debug}     // 0; #/
	my $client_id		= $args{client_id};
	my $company_code	= $args{company_code};
	my $branch			= $args{branch};

	my $user_id    = $self->id;

    my $msg = sprintf ("user '%s,%s', client '%d', company '%s', branch '%s', all '%s'", $self->id, $self->username, $client_id, $company_code, $branch, ($all?'yes':'no'));

	my @approvers = $self->get_approvers(
								debug => $debug,
								all => $all,
								client_id => $client_id,
								company_code => $company_code,
								branch => $branch,
						);

	my $ret = grep {$_ == $user_id} @approvers;

    ::logDebug( sprintf ("line %s, $msg: user '%s' %s an approver", __LINE__, $self->id, ($ret?"is":"is not"))) if $debug;

	$self->_throw( { user_id=>$user_id, args=>\%args, approvers=>\@approvers, ret => $ret}   ) if $debug eq 'ca1';
	$self->_throw( { user_id=>$user_id, args=>\%args, approvers=>\@approvers, ret => $ret}   ) if $debug eq 'ca2' and grep {$_ == $user_id} @approvers;

	return $ret;
	#return scalar grep {$_ == $user_id} @approvers;
}

sub get_approvers {
	my $self = shift;
	my %args = @_;

	my $all					= $args{all}       // 0; #/
	my $debug				= $args{debug}     // 0; #/
	my $client_id			= $args{client_id};
	my $company_code		= $args{company_code};
	my $branch				= $args{branch};
	my $super_approvers_ok	= $args{super_approvers_ok};

    my $msg = sprintf ("user '%s,%s', client '%d', company '%s', branch '%s', all '%s'",
						$self->id, $self->username, $client_id, $company_code, $branch, ($all?'yes':'no'));

	my $approvers = $self->get_branch_approvers(
								debug => $debug,
								client_id => $client_id,
								company_code => $company_code,
								branch => $branch,
						);

	$self->_throw( { args=>\%args, approvers=>$approvers, }   ) if $debug eq 'ga1';
    ::logDebug( sprintf ("line %s, $msg: branch_approvers (%s)", __LINE__, "@$approvers") ) if $debug;

	#if (!@$approvers or ($all == 1))
	unless (scalar @$approvers and ($all == 0)) {
		my $this_approvers = $self->get_company_approvers(
								debug => $debug,
								client_id => $client_id,
								company_code => $company_code,
							);
    	::logDebug( sprintf ("line %s, $msg: company_approvers (%s)", __LINE__, "@$this_approvers") ) if $debug;
		push @$approvers, @$this_approvers;
	} else {
    	::logDebug( sprintf ("line %s, $msg: company_approvers not checked", __LINE__ ) ) if $debug;
	}
	$self->_throw( { args=>\%args, approvers=>$approvers, }   ) if $debug eq 'ga2';

	unless (scalar @$approvers and ($all == 0)) {
		my $this_approvers = $self->get_client_approvers(
								debug => $debug,
								client_id => $client_id,
							);
		push @$approvers, @$this_approvers;
    	::logDebug( sprintf ("line %s, $msg: client_approvers (%s)", __LINE__, "@$this_approvers") ) if $debug;
	} else {
    	::logDebug( sprintf ("line %s, $msg: client_approvers not checked", __LINE__ ) ) if $debug;
	}

	if ($super_approvers_ok) {
		unless (scalar @$approvers and ($all == 0)) {
			my $this_approvers = $self->get_fans_super_approvers(
									debug => $debug,
								);
			push @$approvers, @$this_approvers;
	    	::logDebug( sprintf ("line %s, $msg: super (%s)", __LINE__, "@$this_approvers") ) if $debug;
		} else {
	    	::logDebug( sprintf ("line %s, $msg: super_approvers not checked", __LINE__ ) ) if $debug;
		}
	}

    ::logDebug( sprintf ("line %s, $msg: final_approvers (%s)", __LINE__, "@$approvers") ) if $debug;
	$self->_throw( { args=>\%args, approvers=>$approvers, }   ) if $debug eq 'ga3';

	return @$approvers;
}

#
#
#
sub is_company_restricted {
    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};
    my $client_id		= $parms{client_id};
    my $company_code	= $parms{company_code};

	return 0 unless $self->is_client_restricted(role_code => $role_code);

	if (!$client_id) {
        $client_id = Fina::Corp::M::Client::Company->get_client_id_from_company_code( $company_code );
	}

    my $poss_role_client_map = $self->_role_client_map(role_code => $role_code, client_id => $client_id);

    if(!$poss_role_client_map) {
        return 0;
    }
    else {
        return $poss_role_client_map->company_restricted;
    }
}

#
#
#
sub is_further_restricted {
    my $self			= shift;
	my %parms			= @_;
    my $role_code		= $parms{role_code};
    my $client_id		= $parms{client_id};
    my $company_code	= $parms{company_code};
    my $restriction_code	= $parms{restriction_code};

    #Fina::Corp::FinaDirect::Exception->throw(__LINE__." \$role_code=$role_code \$client_id=$client_id \$company_code=$company_code \$restriction_code=$restriction_code");
	return 0 unless $self->is_company_restricted(role_code => $role_code, client_id => $client_id, company_code => $company_code);

	my $role_client_company_map = $self->_role_client_company_map(
				role_code => $role_code,
				client_id => $client_id,
				company_code => $company_code,
	);
    #warn 'found a $role_client_company_map: ' . ::uneval($role_client_company_map->see_obj);
    #Fina::Corp::FinaDirect::Exception->throw(__LINE__." \$role_client_company_map=<pre>".Dumper($role_client_company_map)."</pre>");
    #Fina::Corp::FinaDirect::Exception->throw(__LINE__. Dumper([$role_client_company_map->further_restricted, $role_client_company_map->company_code]));
    #Fina::Corp::FinaDirect::Exception->throw(__LINE__. Dumper([$role_client_company_map->meta->columns]));

	return 0 unless ref $role_client_company_map and $role_client_company_map->further_restricted;
    #Fina::Corp::FinaDirect::Exception->throw(__LINE__. Dumper([$role_client_company_map->further_restricted]));

	unless ($restriction_code =~ /\w/) {
		return $role_client_company_map->further_restricted;
	}

    my $_mgr = "Fina::Corp::M::User::Role::UserRoleClientCompanyRestrictionMap::Manager";
    my $role_client_company_restrictions = $_mgr->get_objects (
        query => [
        	user_role_client_company_map_id		=> $role_client_company_map->id,
        	restriction_code				 	=> $restriction_code,
        ]
	);

    #warn 'is_further_restricted() ';
    #warn 'scalar @$role_client_company_restrictions: ' . scalar @$role_client_company_restrictions;
#    for (@$role_client_company_restrictions) {
#        warn '1 $role_client_company_restriction:' . ::uneval($_->see_obj);
#    }

	return unless $role_client_company_restrictions and ref $role_client_company_restrictions eq 'ARRAY';
	return scalar @$role_client_company_restrictions;
}

sub clients {
    my $self = shift;
    my $entitlements = $self->get_entitlements;
    my %clients;
    my $result = [];

    # Store all clients in a hash to remove duplicates.
    for my $role (keys %$entitlements) {
        for my $client (keys %{ $entitlements->{$role}->{client_maps} } ) {
            $clients{$client} = 1;
        }
    }
    for my $client_id (keys %clients) {
        my $c = Fina::Corp::M::Client->new(id => $client_id);
        push @{$result}, $c;
    }

    return $result;
}

sub most_restrictive_client {
    my $self = shift;
    my @clients = @{$self->clients};
    return 0 unless (scalar @clients);
    my $max = $clients[0];
    for my $i (@clients) {
        $max = $i if ($i->minimum_password_complexity_level > $max->minimum_password_complexity_level);
    }
    return $max;
}

sub password_level_ok {
    my $self = shift;
    my $max = $self->most_restrictive_client;
    return ($self->password_complexity_level >= $max->minimum_password_complexity_level);
}

sub minimum_password_expiration_days {
    my $self = shift;
    my @clients = @{$self->clients};
    return 0 unless (scalar @clients);
    my $min = $clients[0]->password_expiry_days;
    for my $i (@clients) {
        $min = $i->password_expiry_days if ($i->password_expiry_days < $min);
    }
    return $min;
}

1;

#############################################################################
__END__
