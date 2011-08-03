#
#
#
#############################################################################
package Fina::Corp::Manage::Clients::Documents::AuthoredDocuments;

use strict;
use warnings;

use Fina::Corp::M::Client::Document::Authored;

use Fina::Corp::Manage::Clients::Documents::Contents;

use base qw( Fina::Corp::Manage );

#############################################################################
#
#
#
our $_meta = {
    _model_class               => __PACKAGE__->_root_model_class().'::Client::Document::Authored',
    _model_class_mgr           => __PACKAGE__->_root_model_class().'::Client::Document::Authored::Manager',
    _model_display_name        => 'Client Authored Document',
    _model_display_name_plural => 'Client Authored Documents',
    _sub_prefix                => 'authdoc',
    _func_prefix               => 'Clients__Documents__AuthoredDocuments_authdoc',
};

#############################################################################
#
#
#
sub authdocList {
    my $self = shift;
    return $self->_common_list_display_all(\@_);
}

#
#
#
sub authdocAdd {
    my $self = shift;
    return $self->_common_add(\@_);
}

#
#
#
sub authdocProperties {
    my $self = shift;
    return $self->_common_properties(\@_);
}

#
#
#
sub authdocDrop {
    my $self = shift;
    return $self->_common_drop(\@_);
}

#
#
#
sub authdocDetailView {
    my $self = shift;
    return $self->_common_detail_view(\@_);
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

    #$self->_usage_hook($object,$content);
    $self->_document_content_details($object,$content);
    #$self->_document_html_detail($object,$content) if $object->document_type->description eq 'HTML';

    return;
}

#############################################################################
#
#
sub _document_content_details {
    my $self = shift;
    my $object = shift;
    my $content = shift;

    $self->_document_related_block(
        object => $object,
        content => $content,
        manage_class => 'Fina::Corp::Manage::Clients::Documents::Contents',
        accessor => "document_content_details", # Name of relationship in model (one to many).
        title => "Document Content Details",
        add_link_label => "Document Content",
    );

    return;
}
    
#############################################################################
#
#
sub _document_related_block {
    my $self = shift;
    my $parms			= { @_};
    my $object			= $parms->{object};
    my $content			= $parms->{content};
	my $manage_class	= $parms->{manage_class};
	my $accessor		= $parms->{accessor};
	my $title			= $parms->{title};
	my $add_link_label	= $parms->{add_link_label};

    my ($left, $right, $bottom, $links) = @$content{ qw(left right bottom) };
    
    my $block_params = {
        title => $title,
        actions => [
            $manage_class->manage_function_link(
                method      => 'Add',
                click_text  => "[&nbsp;Add&nbsp;$add_link_label&nbsp;]",
                query       => {
                    document_id => $object->id,
                },
                user        => $self->{_user},
            ),
        ],
        items => [],
    };

    #$self->error_exit(__LINE__, "block_params: %s", Dumper([$manage_class, $block_params]));

    my $items = $object->$accessor;
    my @items = ref $items eq 'ARRAY' ? @{ $items } : ( $items );

    #$self->error_exit(__LINE__, "\@items: %s", Dumper([@items, scalar(@items), $items[0]->manage_description]));

    for my $item ( @items ) {
        next unless defined $item and ref $item;
        push @{$block_params->{items}}, {
            name    => $item->manage_description,
            actions => [
                $manage_class->manage_function_link(
                    method      => 'DetailView',
                    click_text  => '[&nbsp;Details&nbsp;]',
                    query       => {
                        _pk_id  => $item->id,
                    },
                    user        => $self->{_user},
                ),
                $manage_class->manage_function_link(
                    method      => 'Properties',
                    click_text  => '[&nbsp;Edit&nbsp;]',
                    query       => {
                        _pk_id  => $item->id,
                    },
                    user        => $self->{_user},
                ),
                $manage_class->manage_function_link(
                    method      => 'Drop',
                    click_text  => '[&nbsp;Drop&nbsp;]',
                    query       => {
                        _pk_id  => $item->id,
                    },
                    user        => $self->{_user},
                ),
            ],
        };
    }

    #
    #
    push @$bottom, (
        '<table class="detail_sub_table">',
        $self->related_item_block($block_params),
        '<tr><td>&nbsp;</td></tr>',
    );

    return;
}

#############################################################################
#
#
sub _properties_form_hook {
    my $self = shift;
    my $values = $self->{_controller}->{_values};

    for my $field qw( start_date end_date approval_date ) {
        @$values{ $field.'_yyyy', $field.'_mm', $field.'_dd' } = split /-/, $values->{$field};
    }

    return;
}


#############################################################################
#
#
sub _properties_action_hook {
    my $self = shift;
    my $cgi    = $self->{_controller}->{_cgi};
    my $values = $self->{_controller}->{_values};
#   die $::Tag->dump();
#   die ::uneval($cgi, $values);
    for my $field qw( start_date end_date approval_date ) {
        if (
            (defined $values->{$field.'_yyyy'} and $values->{$field.'_yyyy'} ne '')
            and
            (defined $values->{$field.'_mm'} and $values->{$field.'_mm'} ne '')
            and
            (defined $values->{$field.'_dd'} and $values->{$field.'_dd'} ne '')
        ) {
            $values->{$field} = join '-', delete @$values{ $field.'_yyyy', $field.'_mm', $field.'_dd' };
        }
        else {
            $values->{$field} = '';
        }
    }

    $self->SUPER::_properties_action_hook(@_);
    return;
}



1;

#############################################################################
__END__

