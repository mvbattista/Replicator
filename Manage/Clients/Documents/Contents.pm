#
#
#
#############################################################################
package Fina::Corp::Manage::Clients::Documents::Contents;

use strict;
use warnings;

use Fina::Corp::M::Document::Content;

use Fina::Corp::M::Document::Content::Type;
use Fina::Corp::M::Language;

use base qw( Fina::Corp::Manage );

my $_content_details_type_class_mgr = 'Fina::Corp::M::Document::Content::Type::Manager';
my $_language_class_mgr = 'Fina::Corp::M::Language::Manager';

#############################################################################
#
#
#
our $_meta = {
    _model_class               => __PACKAGE__->_root_model_class().'::Document::Content',
    _model_class_mgr           => __PACKAGE__->_root_model_class().'::Document::Content::Manager',
    _model_display_name        => 'Document Content',
    _model_display_name_plural => 'Document Contents',
    _sub_prefix                => 'content',
    _func_prefix               => 'Clients__Documents__Contents_content',
};

#############################################################################
#
#
#
sub contentList {
    my $self = shift;
    return $self->_common_list_display_all(\@_);
}

#
#
#
sub contentAdd {
    my $self = shift;
    return $self->_common_add(\@_);
}

#
#
#
sub contentProperties {
    my $self = shift;
    return $self->_common_properties(\@_);
}

#
#
#
sub contentDrop {
    my $self = shift;
    return $self->_common_drop(\@_);
}

#
#
#
sub contentDetailView {
    my $self = shift;
    return $self->_common_detail_view(\@_);
}

#############################################################################
#
# Hooks
#
sub _properties_form_hook {
    my $self = shift;

    my $values = $self->{_controller}->{_values};

    my $type_options = [];
    for my $type_obj (@{ $_content_details_type_class_mgr->get_objects }) {
        push @$type_options, { 
            value    => $type_obj->id,
            selected => ((defined $values->{content_type_id} and $values->{content_type_id} eq $type_obj->id) ? ' selected="selected"' : ''),
            display  => $type_obj->name,
        };
    }
    $self->{_controller}->tmp_scratch( _manage_form_custom_content_details_type_option_list => [ $type_options, undef, [ keys %{ $type_options->[0] } ] ] );

    my $language_options = [];
    for my $language_obj (@{ $_language_class_mgr->get_objects( sort_by => 'sort_order' ) }) {
        push @$language_options, { 
            value    => $language_obj->language_code,
            selected => ((defined $values->{language_code} and $values->{language_code} eq $language_obj->language_code) ? ' selected="selected"' : ''),
            display  => $language_obj->language_name,
        };
    }
    $self->{_controller}->tmp_scratch( _manage_form_custom_content_language_option_list => [ $language_options, undef, [ keys %{ $language_options->[0] } ] ] );

    return;
}



1;

#############################################################################
__END__

