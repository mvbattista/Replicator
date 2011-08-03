#
#
#
#############################################################################
package Fina::Corp::Manage::Clients::Documents::Types;

use strict;
use warnings;

use Fina::Corp::M::Document::Content::Type;

use base qw( Fina::Corp::Manage );

#############################################################################
#
#
#
our $_meta = {
    _model_class               => __PACKAGE__->_root_model_class().'::Document::Content::Type',
    _model_class_mgr           => __PACKAGE__->_root_model_class().'::Document::Content::Type::Manager',
    _model_display_name        => 'Document Content Type',
    _model_display_name_plural => 'Document Content Types',
    _sub_prefix                => 'contenttype',
    _func_prefix               => 'Clients__Documents__Types_contenttype',
};

#############################################################################
#
#
#
sub contenttypeList {
    my $self = shift;
    return $self->_common_list_display_all(\@_);
}

#
#
#
sub contenttypeAdd {
    my $self = shift;
    return $self->_common_add(\@_);
}

#
#
#
sub contenttypeProperties {
    my $self = shift;
    return $self->_common_properties(\@_);
}

#
#
#
sub contenttypeDrop {
    my $self = shift;
    return $self->_common_drop(\@_);
}

#
#
#
sub contenttypeDetailView {
    my $self = shift;
    return $self->_common_detail_view(\@_);
}

1;

#############################################################################
__END__

