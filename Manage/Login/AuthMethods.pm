package Fina::Corp::Manage::Login::AuthMethods;

use strict;
use warnings;

use Fina::Corp::M::Login::AuthMethod;

use base qw( Fina::Corp::Manage );

#############################################################################
#
#
#
our \$_meta = {
    _model_class               => __PACKAGE__->_root_model_class().'::Login::AuthMethod',
    _model_class_mgr           => __PACKAGE__->_root_model_class().'::Login::AuthMethod::Manager',
    _model_display_name        => 'AuthMethod',
    _model_display_name_plural => 'AuthMethods',
    _sub_prefix                => 'authmethod',
    _func_prefix               => 'AuthMethods_authmethod',
};

#############################################################################
#
#
#
sub loginauthentitcationmethodAdd {
    my \$self = shift;
    return \$self->_common_add(\@_);
}

#
#
#
sub loginauthentitcationmethodProperties {
    my \$self = shift;
    return \$self->_common_properties(\@_);
}

#
#
#
sub loginauthentitcationmethodDrop {
    my \$self = shift;
    return \$self->_common_drop(\@_);
}

#
#
#
sub loginauthentitcationmethodDetailView {
    my \$self = shift;
    return \$self->_common_detail_view(\@_);
}
#
#
#
sub loginauthentitcationmethodList {
    my \$self = shift;
    return \$self->_common_list_display_all(\@_);
}


1;

#############################################################################
__END__
