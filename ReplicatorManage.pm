#
#
#
#############################################################################
package ReplicatorManage;

use strict;
use warnings;

use Data::Dumper;

sub replicator_manage_generator {
    my @models = @_;
    my %result;
    for my $table (@models){
#        next unless ($table->{create_manage_file});
    }

	return \%result;
}

1;

__END__


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

#############################################################################
#
# Hooks
#

sub _detail_generic_hook {
    my \$self = shift;
    my \$object = shift;
    my \$content = shift;

    \$self->SUPER::_detail_generic_hook(\@_);
    return;
}

#############################################################################
#
#
sub _properties_form_hook {
    my \$self = shift;
    my \$values = \$self->{_controller}->{_values};

    \$self->SUPER::_properties_form_hook(\@_);
    return;
}


#############################################################################
#
#
sub _properties_action_hook {
    my \$self = shift;
    my \$cgi    = \$self->{_controller}->{_cgi};
    my \$values = \$self->{_controller}->{_values};

    \$self->SUPER::_properties_action_hook(\@_);
    return;
}

1;

#############################################################################
__END__

