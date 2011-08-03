#
#
#
#############################################################################
package Fina::Corp::Manage::Languages::Translations::Services;

use strict;
use warnings;

use Fina::Corp::M::Language::Translation::Service;

use base qw( Fina::Corp::Manage );

#############################################################################
#
#
#
our $_meta = {
    _model_class               => __PACKAGE__->_root_model_class().'::Language::Translation::Service',
    _model_class_mgr           => __PACKAGE__->_root_model_class().'::Language::Translation::Service::Manager',
    _model_display_name        => 'Language Translation Service',
    _model_display_name_plural => 'Language Translation Services',
    _sub_prefix                => 'languagetranslationservice',
    _func_prefix               => 'Languages__Translations__Services_languagetranslationservice',
};

#############################################################################
#
#
#
sub languagetranslationserviceList {
    my $self = shift;
    return $self->_common_list_display_all(@_);
#    return $self->_common_list(@_);
}

#
#
#
sub languagetranslationserviceAdd {
    my $self = shift;
    return $self->_common_add(@_);
}

#
#
#
sub languagetranslationserviceProperties {
    my $self = shift;
    return $self->_common_properties(@_);
}

#
#
#
sub languagetranslationserviceDrop {
    my $self = shift;
    return $self->_common_drop(@_);
}

#
#
#
sub languagetranslationserviceDetailView {
    my $self = shift;
    return $self->_common_detail_view(@_);
}

1;

#############################################################################
__END__

