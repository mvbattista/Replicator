
#
#
#
#############################################################################
package Fina::Corp::Manage::Languages;

use strict;
use warnings;

use base qw( Fina::Corp::Manage );

use Fina::Corp::M::Language;
use Fina::Corp::Manage::Languages::Translations::Services;

#############################################################################
#
#
#
our $_meta = {
    _model_class               => __PACKAGE__->_root_model_class().'::Language',
    _model_class_mgr           => __PACKAGE__->_root_model_class().'::Language::Manager',
    _model_display_name        => 'Language',
    _model_display_name_plural => 'Languages',
    _sub_prefix                => 'language',
    _func_prefix               => 'Languages_language',
};

#############################################################################
#
#
#
sub languageList {
    my $self = shift;
    return $self->_common_list_display_all(@_);
}

#
#
#
sub languageAdd {
    my $self = shift;
    return $self->_common_add(@_);
}

#
#
#
sub languageProperties {
    my $self = shift;
    return $self->_common_properties(@_);
}

#
#
#
sub languageDrop {
    my $self = shift;
    return $self->_common_drop(@_);
}

#
#
#
sub languageDetailView {
    my $self = shift;
    return $self->_common_detail_view(@_);
}

#############################################################################
#
# Hooks
#
sub _detail_generic_hook {
    my $self = shift;
    my $object = shift;
    my $content = shift;

    #my ($left, $right, $bottom, $links) = @$content{ qw(left right bottom) };
    
	#$self->error_exit(__LINE__, "%s", Dumper({self=>ref($self),object=>ref($object),content=>$content,document_type=>$object->document_type->description}));

#    $self->_usage_hook($object,$content);
    return;
}

sub _properties_form_hook {
    my $self = shift;

    my $values = $self->{_controller}->{_values};

    my $translation_service_options = [];
    for my $translation_service_obj (@{ Fina::Corp::M::Language::Translation::Service::Manager->get_objects }) {
        push @$translation_service_options, { 
            value    => $translation_service_obj->id,
            selected => ((defined $values->{translation_service} and $values->{translation_service} eq $translation_service_obj->id) ? ' selected="selected"' : ''),
            display  => $translation_service_obj->service_code,
        };
    }
    $self->{_controller}->tmp_scratch( _manage_form_custom_user_translation_service_option_list => [ $translation_service_options, undef, [ keys %{ $translation_service_options->[0] } ] ] );

    return;
}

sub _detail_transform_translation_service {
    my $self = shift;
    my $object = shift;

    if (defined $object->translation_service) {
        return Fina::Corp::Manage::Languages::Translations::Services->manage_function_link (
            method      => 'DetailView',
            click_text  => $object->translator->service_code,
            user        => $self->{_user},
            query       => { _pk_id => $object->translation_service },
        )
    }
    else { return 'None selected'; }
}


#sub _usage_hook {
#	my $self = shift;
#	my $object = shift;
#	my $content = shift;
#	my ($left, $right, $bottom, $links) = @$content{ qw(left right bottom action_links) };

#    for ($right) {
#            push @$_, '<br />';
#            push @$_, '<table class="detail_sub_table">';
#            push @$_, '<tr>';
#            push @$_, '<td class="detail_table_title_cell">';
#            push @$_, sprintf("Language&nbsp;Translation&nbsp;Services");
#            push @$_, '</td>';
#            push @$_, '<td class="detail_table_title_cell" style="text-align: right;">';
#            push @$_, "&nbsp;";
#            push @$_, $self->_object_manage_function_link('SetTranslationService', $object, label => "Set&nbsp;Language&nbsp;Translation&nbsp;Services");
#            push @$_, '<br />';
#            push @$_, '</td>';
#            push @$_, '</tr>';

#            for my $usage (@{ $object->services }) {
#				push @$_, '<tr><td class="detail_table_datum_cell">';
#                my $show = $usage->manage_description;
#				$show =~ s/ /&nbsp;/g;
#                push @$_, $show;
#				push @$_, '</td>';
#				push @$_, '</tr>';
#            }
#            push @$_, '</td>';
#            push @$_, '</tr>';
#            push @$_, '</table>';
#    }

#}

#
#
#
#sub languageSetTranslationService {
#    my $self = shift;


#    my $values = $self->{_controller}->{_values};
#    my @_pk_fields = map { "_pk_$_" } @{ $self->_model_class->meta->primary_key_columns };


#    my $object = $self->_common_implied_object;

#    my $all_items = Fina::Corp::M::Language::Translation::Service::Manager->get_objects(
#        sort_by => 'service_code',
#    );

#	my $cur_item_method     = "services";
#	my $item_key            = "service_code";
#    my $item_display_method = "manage_description";
#    my $set_function_name   = "languageSetTranslationService";  # This goes to ITL
#    my $checkbox_prefix     = "manage_service_name";            # This goes to ITL

#    if ($self->{_step} == 0) {
#        my $_pk_form_elements = [];
#        for my $_pk_field (@_pk_fields) {
#            push @$_pk_form_elements, { name => $_pk_field, value => $CGI::values{$_pk_field} };
#        }
#        $self->{_controller}->tmp_scratch( _manage_form_pk_elements => [ $_pk_form_elements, undef, [ keys %{$_pk_form_elements->[0]} ] ] );

#        my $current_items = [];
#        for my $item ($object->$cur_item_method) {
#            push @$current_items, $item->$item_key;
#        }

#        my $items_option_list = [];

#        for my $item (@$all_items) {
#            my $item_key_value = $item->$item_key;
#            my $option = {
#                value    => $item->$item_key,
#                display  => $item->$item_display_method,
#                checked  => ((grep { $_ eq $item_key_value } @$current_items) ? 1 : 0),
#            };
#            push @$items_option_list, $option;
#        }

#        $self->{_controller}->tmp_scratch(
#            "_manage_form_custom_manage_${set_function_name}_option_list" => [
#                $items_option_list,
#                undef,
#                [ keys %{ $items_option_list->[0] } ],
#            ],
#        );

#        $values->{_step}     = $self->{_step} + 1;
#        $values->{_function} = $self->{_function};

#        $self->{_controller}->tmp_scratch( _manage_form_include => "$self->{_function}-$self->{_step}" );
#        $self->{_controller}->tmp_scratch( _manage_form_referer => $ENV{HTTP_REFERER} );

#        $self->{_controller}->tmp_scratch( _manage_subtitle_content => '' );
#        $self->set_title('Set Language Translation Services', $object); # TODO: EDIT
#        $self->response( type => 'itl', file => 'manage/function/form' );
#    }
#    elsif ($self->{_step} == 1) {
#        $self->SUPER::_properties_action_hook;

#        my $values      = $self->{_controller}->{_values};
#        my $update_user = $self->{_user}->id;

#        my @clear_values;

#        my $items = [];
#        for my $item (@$all_items) {
#            my $item_key_value = $item->$item_key;
#            if ($values->{"$checkbox_prefix-$item_key_value"})  {
#                push @$items, {
#                    $item_key   => $item_key_value, # key
#                    created_by  => $update_user,
#                    modified_by => $update_user,
#                };
#                push @clear_values, "$checkbox_prefix-$item_key_value";
#            }
#        }


#        $object->$cur_item_method( $items );	# Rose Model relation

#        $object->save;

#        delete @{$values}{ @_pk_fields,  @clear_values };

#        $self->_referer_redirect_response;
#    }
#    else {
#        Fina::Corp::FinaDirect::Exception->throw( "Unrecognized step: $self->{_step}" );
#    }

#    return;
#}


1;

#############################################################################
__END__

