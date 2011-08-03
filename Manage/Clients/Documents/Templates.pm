#
#
#
#############################################################################
package Fina::Corp::Manage::Clients::Documents::Templates;

use strict;
use warnings;

use Fina::Corp::M::Document::Content::Template;

use base qw( Fina::Corp::Manage );

#############################################################################
#
#
#
our $_meta = {
    _model_class               => __PACKAGE__->_root_model_class().'::Document::Content::Template',
    _model_class_mgr           => __PACKAGE__->_root_model_class().'::Document::Content::Template::Manager',
    _model_display_name        => 'Document Content Template',
    _model_display_name_plural => 'Document Content Templates',
    _sub_prefix                => 'contenttemplate',
    _func_prefix               => 'Clients__Documents__Templates_contenttemplate',
};

#############################################################################
#
#
#
sub contenttemplateList {
    my $self = shift;
    return $self->_common_list_display_all(\@_);
}

#
#
#
sub contenttemplateAdd {
    my $self = shift;
    return $self->_common_add(\@_);
}

#
#
#
sub contenttemplateProperties {
    my $self = shift;
    return $self->_common_properties(\@_);
}

#
#
#
sub contenttemplateDrop {
    my $self = shift;
    return $self->_common_drop(\@_);
}

#
#
#
sub contenttemplateDetailView {
    my $self = shift;
    return $self->_common_detail_view(\@_);
}

1;

#############################################################################
__END__

