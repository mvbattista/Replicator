
#
#
#
#############################################################################
package Fina::Corp::Manage::DocumentHtmlDetails;

use strict;
use warnings;

use Fina::Corp::M::Document::HtmlDetails;

use base qw( Fina::Corp::Manage );

#############################################################################
#
#
#
use Fina::Corp::M::Language;
use HTML::Entities;
use Encode;

my $_language_model_class = 'Fina::Corp::M::Language';
my $_language_manager_class = $_language_model_class.'::Manager';

#############################################################################
#
#
#
our $_meta = {
    _model_class               => __PACKAGE__->_root_model_class().'::Document::HtmlDetails',
    _model_class_mgr           => __PACKAGE__->_root_model_class().'::Document::HtmlDetails::Manager',
    _model_display_name        => 'Document Html Detail',
    _model_display_name_plural => 'Document Html Details',
    _sub_prefix                => 'documenthtml',
    _func_prefix               => 'DocumentHtmlDetails_documenthtml',
};

#############################################################################
#
#
#
sub documenthtmlList {
    my $self = shift;
    return $self->_common_list_display_all(@_);
}

#
#
#
sub documenthtmlAdd {
    my $self = shift;
    return $self->_common_add(@_);
}

#
#
#
sub documenthtmlProperties {
    my $self = shift;
    return $self->_common_properties(@_);
}

#
#
#
sub _properties_form_hook {
    my $self = shift;
    
    my $values = $self->{_controller}->{_values};
    
    my $languages = [
        {
            value => "NULL",
            display => "Generic",
            selected => ( defined $values->{language_code} ? '' : ' selected="selected"' ),
        },
    ];
    
    for my $language_obj ( @ { $_language_manager_class->get_objects() } ) {
        push @$languages, {
            value       => $language_obj->language_code,
            selected    => (
                (defined $values->{language_code} and $values->{language_code} eq $language_obj->language_code) ?
                ' selected="selected"' : 
                ''
            ),
            display     => $language_obj->language_name,
        };
    }
    
    $self->{_controller}->tmp_scratch( _manage_form_language_list => [
        $languages,
        undef,
        [ keys %{ $languages->[0] } ], 
    ]);
}

sub _detail_transform_language_code {
    my $self = shift;
    my $object = shift;
    
    my $language = 'Generic';
    
    if (defined $object->language_code()) {
        my $language_object = $_language_model_class->new( language_code => $object->language_code() );
        
        if ($language_object->load( speculative => 1)) {
            $language = $language_object->language_name();
        }
    }
    
    return $language;
}

sub _properties_action_hook {
    my $self = shift;
    
    my $cgi    = $self->{_controller}->{_cgi};
    my $values = $self->{_controller}->{_values};
    
    #::logDebug("We're here in _properties_action_hook");
    #::logDebug('$cgi: %s', ::uneval($cgi));
    #:::logDebug('$values: %s', ::uneval($values));
    
    if ( defined $cgi->{language_code} and $cgi->{language_code} eq 'NULL' ) {
        $cgi->{language_code} = undef;
    }

    #Entify non-ascii characters, leaving html characters alone.
    my $body = Encode::decode_utf8($cgi->{body});
    $body =~ s/(\w)\-(\w)/_prefixed_$1 _prefixed_$2/g;
    $body = HTML::Entities::encode_entities($body, '^\n\x20-\x25\x27-\x7e');
    $body =~ s/_prefixed_(\w) _prefixed_(\w)/$1-$2/g;
    $cgi->{body} = $body;
    $self->SUPER::_properties_action_hook(@_);
    
    return;
}

#
#
#
sub documenthtmlDrop {
    my $self = shift;
    return $self->_common_drop(@_);
}

#
#
#
sub documenthtmlDetailView {
    my $self = shift;
    return $self->_common_detail_view(@_);
}

1;

#############################################################################
__END__

