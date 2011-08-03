#
#
#
#############################################################################
package Fina::Corp::Manage::Clients;

use strict;
use warnings;

use Data::Dumper;

use base qw( Fina::Corp::Manage );

use Fina::Corp::M::Client;
use Fina::Corp::Manage::Clients::Companies;
use Fina::Corp::Manage::Clients::FANS::Enhancers;
use Fina::Corp::Manage::Clients::FANS::Enhancers::PrintoutFields;
use Fina::Corp::Manage::Clients::FANS::Factors;
use Fina::Corp::Manage::Clients::FANS::Initiatives;
use Fina::Corp::Manage::Clients::FANS::Initiatives::Illustrations;
use Fina::Corp::Manage::Clients::FANS::RecognitionClasses;
use Fina::Corp::Manage::Clients::FANS::ShippingModes;
use Fina::Corp::Manage::Clients::FANS::Initiatives::Illustrations::CertificateFields;
use Fina::Corp::Manage::Documents;
use Fina::Corp::Manage::Clients::Documents::AuthoredDocuments;

use Fina::Corp::M::Password::ComplexityLevel;
use Fina::Corp::M::Login::AuthMethod;

my $ci_container_model_class          = __PACKAGE__->_root_model_class().'::ContentItemContainer';
my $ci_container_model_class_mgr      = $ci_container_model_class.'::Manager';
my $_authentication_method_class_mgr = 'Fina::Corp::M::Login::AuthMethod::Manager';

#############################################################################
#
#
#
our $_meta = { 
    _model_class               => __PACKAGE__->_root_model_class().'::Client',
    _model_class_mgr           => __PACKAGE__->_root_model_class().'::Client::Manager',
    _model_display_name        => 'Client',
    _model_display_name_plural => 'Clients',
    _sub_prefix                => 'client',
    _func_prefix               => 'Clients_client',
};

my $_companies_manage_class        = 'Fina::Corp::Manage::Clients::Companies';

my $_fans_factors_manage_class     = 'Fina::Corp::Manage::Clients::FANS::Factors';
my $_fans_initiatives_manage_class = 'Fina::Corp::Manage::Clients::FANS::Initiatives';

my $_document_manage_class        = 'Fina::Corp::Manage::Documents';

my $_application_class     = __PACKAGE__->_root_model_class . '::Application';
my $_application_class_mgr = $_application_class . '::Manager';

my $_language_class     = __PACKAGE__->_root_model_class . '::Language';
my $_language_class_mgr = $_language_class . '::Manager';

my $_document_class       = __PACKAGE__->_root_model_class . '::Document';
my $_document_class_mgr   = $_document_class . '::Manager';

my $_authentication_method_class        = __PACKAGE__->_root_model_class().'::Login::AuthMethod';
my $_authentication_method_class_mgr    = $_authentication_method_class . '::Manager';

#
#
#
sub clientList {
    my $self = shift;

    return $self->_common_list(@_);
}

#
#
#
sub _list_0_hook {
    my $self = shift;
    my $content = shift;

    push @$content, $self->_search_by_form( as_title => 1, field => 'display_label' );

    return;
}

#
#
#
sub _search_by_form {
    my $self = shift;
    my $args = { @_ };
    
    my $_func_prefix = $self->_func_prefix;
    
    my @html;

    push @html, "<tr>\n";
    push @html, "<td class=\"list_table_" . (defined $args->{as_title} && $args->{as_title} ? 'title' : 'datum') . "_cell\"> Search on Display Label: </td>\n";
    push @html, "<td class=\"list_table_datum_cell\">\n";
    push @html, "<form action=\"";
    push @html, $self->manage_function_uri(
        method => 'List',
        step   => 1,
    );
    push @html, "\">\n";
    push @html, "<input type=\"hidden\" name=\"mode\" value=\"search\" />\n";
    push @html, "<input type=\"hidden\" name=\"search_by\" value=\"$args->{field}=ilike\" />\n";
    push @html, "<input type=\"text\" name=\"$args->{field}\" size=\"20\" maxlength=\"50\" />\n";
    push @html, "<input type=\"submit\" value=\"Search\" />";
    push @html, "</form>\n";
    push @html, "<br />\n";
    push @html, "</td>\n";
    push @html, "</tr>\n";

    return @html;
}

#
#
#
sub clientAdd {
    my $self = shift;
    return $self->_common_add(@_);
}

#
#
#
sub clientProperties {
    my $self = shift;
    return $self->_common_properties(@_);
}

#
#
#
sub clientDrop {
    my $self = shift;
    return $self->_common_drop(@_);
}

#
#
#
sub clientDetailView {
    my $self = shift;
    return $self->_common_detail_view(@_);
}

#
#
#
sub _detail_generic_hook {
    my $self = shift;
    my $object = shift;
    my $content = shift;

    my ($left, $right, $bottom, $links) = @$content{ qw(left right bottom) };

	# $addtl_cgi must be provided a sa basis for searching for content items
	my $addtl_cgi = {
                    	#company_code => $object->code,
                    	client_id => $object->id,
					};
	$self->{_controller}->tmp_scratch( _content_item_search_keys => $addtl_cgi );

    for ($left) {
        push @$_, '<table class="detail_sub_table">';
        push @$_, '<tr>';
        push @$_, '<td class="detail_table_title_cell">';
        push @$_, 'Documents';
        push @$_, '</td>';
        push @$_, '<td class="detail_table_subtitle_cell" style="text-align: right;">';
        push @$_, $self->_object_manage_function_link( 'SetDocuments', $object, label => '&nbsp;Set&nbsp;Documents&nbsp;' );
        push @$_, '</td>';
        push @$_, '</tr>';
        for my $document ( @{ $object->documents } ) {
            my $document_obj = $document->document ;
            push @$_, '<tr><td class="detail_table_datum_cell">';
            push @$_, $document_obj->manage_description;
            push @$_, '</td><td class="detail_table_datum_cell" align="right">';
            push @$_, $_document_manage_class->manage_function_link(
                method      => 'DetailView',
                click_text  => '[&nbsp;Details&nbsp;]',
                query       => {
                    _pk_id => $document_obj->id,
                },
                user        => $self->{_user}
            );
            push @$_, '</tr></td>';
        }
        push @$_, '<tr><td>&nbsp;</td></tr>';

        #----------------ASSIGN CLIENT AUTHORED DOCUMENTS BEING ---------------------------

        $self->_client_authored_documents($object,$content);

        #----------------ASSIGN CLIENT AUTHORED DOCUMENTS END -----------------------------

        push @$_, '<tr>';
        push @$_, '<td class="detail_table_title_cell">';
        push @$_, 'Applications';
        push @$_, '&nbsp;';
        push @$_, '</td>';
        push @$_, '<td class="detail_table_title_cell" style="text-align: right;">';
        push @$_, $self->_object_manage_function_link('SetApplications', $object, label => 'Assign&nbsp;Applications');
        push @$_, '</td>';
        push @$_, '</tr>';
        my $application_mappings = $object->application_mappings;
        if (@$application_mappings) {
            for my $application_map (@{ $object->application_mappings }) {
                push @$_, '<tr>';
                push @$_, '<td class="detail_table_datum_cell" colspan="2">';
                push @$_, $application_map->application->manage_description;
                push @$_, '</td>';
                push @$_, '</tr>';
            }
        }
        else {
            push @$_, '<tr>';
            push @$_, '<td class="detail_table_datum_cell" colspan="2">No mappings assigned yet.</td>';
            push @$_, '</tr>';
        }
        #push @$_, '</table>';
        push @$_, '<br />';

		#--------------- ASSIGN LANGUAGES BEGIN -------------------

        push @$_, '<tr><td>&nbsp;</td></tr>';
        push @$_, '<tr>';
        push @$_, '<td class="detail_table_title_cell">';
        push @$_, 'Languages';
        push @$_, '</td>';
        push @$_, '<td class="detail_table_title_cell" style="text-align: right;">';
        push @$_, $self->_object_manage_function_link('SetLanguages', $object, label => 'Assign&nbsp;Languages');
        push @$_, '</td>';
        push @$_, '</tr>';
        my $application_mappings = $object->language_mappings;
        if (@$application_mappings) {
            for my $application_map (@{ $object->language_mappings }) {
                push @$_, '<tr>';
                push @$_, '<td class="detail_table_datum_cell" colspan="2">';
                push @$_, $application_map->language->manage_description;
                push @$_, '</td>';
                push @$_, '</tr>';
            }
        }
        else {
            push @$_, '<tr>';
            push @$_, '<td class="detail_table_datum_cell" colspan="2">No mappings assigned yet.</td>';
            push @$_, '</tr>';
        }
        push @$_, '</table>';
        push @$_, '<br />';


		#--------------- ASSIGN LANGUAGES END ---------------------
    }

	#--------------- CONTENT ITEM CONTAINERS

    for ($right) {
        my $ci_containers = $ci_container_model_class_mgr->get_objects();
        push @$_, '<table class="detail_sub_table">';
        push @$_, '<tr>';
        push @$_, '<td class="detail_table_title_cell">';
        push @$_, 'Content Items';
        push @$_, '</td>';
        push @$_, '</tr>';
        push @$_, '<br />';
        if (@$ci_containers) {
        	for my $container (sort {$a->display_label cmp $b->display_label} @$ci_containers) {
        		push @$_, '<tr>';
				push @$_, '<td class="detail_table_datum_cell">';
            	#push @$_, $container->display_label;
                push @$_, Fina::Corp::Manage::ContentItemContainers->_object_manage_function_link(
                    'DetailView',
                    $container,
                    #label => 'Details',
                    #label => $container->display_label,
                    label => sprintf("%s (%d)", $container->display_label, scalar @{$container->content_items}),
                    user  => $self->{_user},
					#addtl_cgi => {
                    #	company_code => $object->code,
                    #	client_id => $object->client_id,
					#},
					addtl_cgi => $addtl_cgi,
                );
        		push @$_, '</td>';
        		push @$_, '</tr>';
			}
        }
        push @$_, '</table>';
    }

	#--------------- CONTENT ITEM CONTAINERS END

    for ($bottom) {
        push @$_, '<table class="detail_sub_table">';
        push @$_, '<tr>';
        push @$_, '<td class="detail_table_title_cell">';
        push @$_, 'Source Codes';
        push @$_, '</td>';
        push @$_, '<td class="detail_table_subtitle_cell" style="text-align: right;">';
        push @$_, $_companies_manage_class->manage_function_link(
            method     => 'Add',
            click_text => '[&nbsp;Add&nbsp;Source&nbsp;Code&nbsp;]',
            query      => {
                client_id => $object->id,
            },
            user       => $self->{_user},
        );
        push @$_, '</td>';
        push @$_, '</tr>';
        for my $company (@{ $object->companies }) {
            push @$_, '<tr>';
            push @$_, '<td class="detail_table_datum_cell">';
            push @$_, $company->code;
            push @$_, '</td>';
            push @$_, '<td class="detail_table_datum_cell">';
            push @$_, $_companies_manage_class->_object_manage_function_link(
                'DetailView',
                $company,
                label => 'Details',
                user  => $self->{_user},
            );
            push @$_, $_companies_manage_class->_object_manage_function_link(
                'Properties',
                $company,
                label => 'Edit',
                user  => $self->{_user},
            );
            push @$_, $_companies_manage_class->_object_manage_function_link(
                'Drop',
                $company,
                user  => $self->{_user},
            );
            push @$_, '</td>';
            push @$_, '</tr>';
        }
        push @$_, '</table>';
        push @$_, '<br />';

        if (grep { $_->application_code eq 'FANS' } @{ $object->application_mappings }) {
            my $fans_elements = [
                {
                    type              => 'Factor',
                    sub_object_method => 'factors',
                    manage_class      => 'Fina::Corp::Manage::Clients::FANS::Factors',
                },
                {
                    type              => 'Initiative',
                    sub_object_method => 'initiatives',
                    manage_class      => 'Fina::Corp::Manage::Clients::FANS::Initiatives',
                    relations         => [
                        {
                            type              => 'Illustration',
                            sub_object_method => 'illustrations',
                            manage_class      => 'Fina::Corp::Manage::Clients::FANS::Initiatives::Illustrations',
                            parent_key_col    => 'client_fans_initiative_id',
							relations         => [
								{
									type              => 'Certficate Field',
									sub_object_method => 'certificate_fields', # in Fina/Corp/M/Client/FANS/Initiative/Illustration.pm
									manage_class      => 'Fina::Corp::Manage::Clients::FANS::Initiatives::Illustrations::CertificateFields',
								},
							],
                        },
                    ],
                },
                {
                    type              => 'Recognition Class',
                    sub_object_method => 'recognition_classes',
                    manage_class      => 'Fina::Corp::Manage::Clients::FANS::RecognitionClasses',
                },
                {
                    type              => 'Enhancer',
                    sub_object_method => 'enhancers',
                    manage_class      => 'Fina::Corp::Manage::Clients::FANS::Enhancers',
                        relations     => [
                            {
                                type              => 'Printout Field',
                                sub_object_method => 'printout_fields', # in Fina/Corp/M/Client/FANS/Enhancer.pm
                                manage_class      => 'Fina::Corp::Manage::Clients::FANS::Enhancers::PrintoutFields',
                                parent_key_col    => 'client_fans_enhancer_id',
                            },
                        ],
                },
                {
                    type              => 'Shipping Mode',
                    sub_object_method => 'shipping_modes',
                    manage_class      => 'Fina::Corp::Manage::Clients::FANS::ShippingModes',
                },
            ];

            push @$_, '<br />';
            push @$_, '<table class="detail_sub_table" border="0">';
            push @$_, '<tr>';
            push @$_, '<td class="detail_table_title_cell" colspan="2" style="text-align: center;">';
            push @$_, 'FANS Elements';
            push @$_, '</td>';
            push @$_, '</tr>';

            for my $element (@$fans_elements) {
                push @$_, '<tr>';
                push @$_, '<td class="detail_table_title_cell">';
                if ($element->{type} =~ /s\z/) {
                    push @$_, $element->{type} . 'es';
                }
                else {
                    push @$_, $element->{type} . 's';
                }
                push @$_, '</td>';
                push @$_, '<td class="detail_table_subtitle_cell" style="text-align: right;">';
                push @$_, $element->{manage_class}->manage_function_link(
                    method     => 'Add',
                    click_text => "[&nbsp;Add&nbsp;$element->{type}&nbsp;]",
                    query      => {
                        client_id => $object->id,
                    },
                    user       => $self->{_user},
                );
                push @$_, '</td>';
                push @$_, '</tr>';
                my $method = $element->{sub_object_method};
                for my $sub_object (@{ $object->$method }) {
                    my $display_style = '';
                    $display_style = 'color: #CCCCCC;' if not $sub_object->is_active;

                    push @$_, '<tr>';
                    push @$_, qq{<td class="detail_table_datum_cell" style="$display_style">};
                    push @$_, $sub_object->display_label;
                    push @$_, '</td>';
                    push @$_, '<td class="detail_table_datum_cell" style="text-align: right;">';
                    push @$_, $element->{manage_class}->_object_manage_function_link(
                        'DetailView',
                        $sub_object,
                        label => 'Details',
                        user  => $self->{_user},
                    );
                    push @$_, $element->{manage_class}->_object_manage_function_link(
                        'Properties',
                        $sub_object,
                        label => 'Edit',
                        user  => $self->{_user},
                    );
                    push @$_, $element->{manage_class}->_object_manage_function_link(
                        'Drop',
                        $sub_object,
                        user  => $self->{_user},
                    );
                    if (defined $element->{relations}) {
                        for my $relation (@{$element->{relations}}) {
                            push @$_, $relation->{manage_class}->manage_function_link(
                                method     => 'Add',
                                click_text => "[&nbsp;Add&nbsp;$relation->{type}&nbsp;]",
                                query      => {
                                    $relation->{parent_key_col} => $sub_object->id,  # Generalized to accomodate enhancer print fields
                                },
                                user       => $self->{_user},
                            );
                        }
                    }
                    push @$_, '</td>';
                    push @$_, '</tr>';

                    if (defined $element->{relations}) {
                        my $alo = 0;
                        for my $relation (@{$element->{relations}}) {
                            my $relation_method = $relation->{sub_object_method};
                            for my $relation_sub_object (@{ $sub_object->$relation_method }) {
                                $alo++;

                                my $relation_display_style = '';
                                $relation_display_style = 'color: #CCCCCC;' if (UNIVERSAL::can($relation_sub_object, 'is_active') and !$relation_sub_object->is_active);

                                push @$_, '<tr>';
                                push @$_, qq{<td class="detail_table_datum_cell" style="padding-left: 20px; $relation_display_style">};
                                push @$_, ( 
                                    UNIVERSAL::can($relation_sub_object, 'display_label') ? 
                                    $relation_sub_object->display_label : 
                                    $relation_sub_object->field_name # For Enhancer::PrintoutFields
                                );
                                push @$_, '</td>';
                                push @$_, '<td class="detail_table_datum_cell" style="text-align: right;">';
                                push @$_, $relation->{manage_class}->_object_manage_function_link(
                                    'DetailView',
                                    $relation_sub_object,
                                    label => 'Details',
                                    user  => $self->{_user},
                                );
                                push @$_, $relation->{manage_class}->_object_manage_function_link(
                                    'Properties',
                                    $relation_sub_object,
                                    label => 'Edit',
                                    user  => $self->{_user},
                                );
                                push @$_, $relation->{manage_class}->_object_manage_function_link(
                                    'Drop',
                                    $relation_sub_object,
                                    user  => $self->{_user},
                                );
								if (defined $relation->{relations} ) {
                        			for my $sub_relation (@{$relation->{relations}}) {
                    			        push @$_, $sub_relation->{manage_class}->manage_function_link(
                               				method     => 'Add',
                                			click_text => "[&nbsp;Add&nbsp;$sub_relation->{type}&nbsp;]",
                                			query      => {
                                    			client_fans_initiative_illustration_id => $relation_sub_object->id,
                                			},
                                			user       => $self->{_user},
                            			);
                        			}
								}
                                push @$_, '</td>';
                                push @$_, '</tr>';
								if (defined $relation->{relations} ) {
                        			my $alo1 = 0;
                        			for my $sub_relation (@{$relation->{relations}}) {
                            			my $sub_relation_method = $sub_relation->{sub_object_method};
                            			for my $sub_relation_sub_object (@{ $relation_sub_object->$sub_relation_method }) {
                                			$alo++;

                                			my $relation_display_style = '';
                                			#$relation_display_style = 'color: #CCCCCC;' if not $relation_sub_object->is_active;

                                			push @$_, '<tr>';
                                			push @$_, qq{<td class="detail_table_datum_cell" style="padding-left: 40px; $relation_display_style">};
											push @$_, $sub_relation_sub_object->field_name;
                            			    push @$_, '</td>';
                                			push @$_, '<td class="detail_table_datum_cell" style="text-align: right;">';
                                			push @$_, $sub_relation->{manage_class}->_object_manage_function_link(
                                    			'DetailView',
                                    			$sub_relation_sub_object,
                                    			label => 'Details',
                                    			user  => $self->{_user},
                                			);
                                			push @$_, $sub_relation->{manage_class}->_object_manage_function_link(
                                    			'Properties',
                                    			$sub_relation_sub_object,
                                    			label => 'Edit',
                                    			user  => $self->{_user},
                                			);
                                			push @$_, $sub_relation->{manage_class}->_object_manage_function_link(
                                    			'Drop',
                                    			$sub_relation_sub_object,
                                    			user  => $self->{_user},
                                			);

                                			push @$_, '</td>';
                                			push @$_, '</tr>';
										}
									}
								}
                            }
                        }
                        push @$_, '<tr><td colspan="2"><br /></td></tr>' if $alo;
                    }
                }
                push @$_, '<tr><td colspan="2"><br /></td></tr>';
            }
            push @$_, '</table>';
            push @$_, '<br />';
        }
    }

    return;
}

#
#
#
sub clientSetApplications {
    my $self = shift;

    my $values = $self->{_controller}->{_values};
    my @_pk_fields = map { "_pk_$_" } @{ $self->_model_class->meta->primary_key_columns };

    my $object = $self->_common_implied_object;

    my $all_possible_items = $_application_class_mgr->get_objects(
        sort_by => 'display_label, code',
    );
    my $current_items = [];
    for my $item ($object->application_mappings) {
        push @$current_items, $item->application->code;
    }

    if ($self->{_step} == 0) {
        my $_pk_form_elements = [];
        for my $_pk_field (@_pk_fields) {
            push @$_pk_form_elements, { name => $_pk_field, value => $CGI::values{$_pk_field} };
        }
        $self->{_controller}->tmp_scratch( _manage_form_pk_elements => [ $_pk_form_elements, undef, [ keys %{$_pk_form_elements->[0]} ] ] );

        my $option_list = [];

        for my $item (@$all_possible_items) {
            my $code = $item->code;
            my $option = {
                value    => $code,
                display  => $item->display_label,
                checked  => ((grep { $_ eq $code } @$current_items) ? 1 : 0),
            };
            push @$option_list, $option;
        }
        $self->{_controller}->tmp_scratch(
            _manage_form_custom_application_option_list => [
                $option_list,
                undef,
                [ keys %{ $option_list->[0] } ],
            ],
        );

        $values->{_step}     = $self->{_step} + 1;
        $values->{_function} = $self->{_function};

        $self->{_controller}->tmp_scratch( _manage_form_include => "$self->{_function}-$self->{_step}" );
        $self->{_controller}->tmp_scratch( _manage_form_referer => $ENV{HTTP_REFERER} );

        $self->{_controller}->tmp_scratch( _manage_subtitle_content => '' );
        $self->set_title('Set Client Application Mappings', $object);
        $self->response( type => 'itl', file => 'manage/function/form' );
    }
    elsif ($self->{_step} == 1) {
        $self->SUPER::_properties_action_hook;

        my $values      = $self->{_controller}->{_values};
        my $update_user = $self->{_user}->id;

        my @clear_values;

        my $desired_relations = [];
        for my $item (@$all_possible_items) {
            my $code = $item->code;
            if ($values->{"application-$code"})  {
                push @$desired_relations, {
                    application_code => $code,
                    created_by       => $update_user,
                    modified_by      => $update_user,
                };
                push @clear_values, "application-$code";
            }
        }

        for my $current (@{ $object->application_mappings }) {
            unless (grep { $current->application_code eq $_->{application_code} } @$desired_relations) {
                $current->delete;
            }
        }
        $object->save;

        for my $desired (@$desired_relations) {
            unless (grep { $desired->{application_code} eq $_->application_code } @{ $object->application_mappings }) {
                $object->add_application_mappings( $desired );
                $object->save;
            }
        }

        delete @{$values}{ @_pk_fields,  @clear_values };

        $self->_referer_redirect_response;
    }
    else {
        Fina::Corp::FinaDirect::Exception->throw( "Unrecognized step: $self->{_step}" );
    }

    return;
}

#
#
#
sub clientSetLanguages {
    my $self = shift;

	$self->_clientSet (
		{
			sort_by			=> 'sort_order',					# interchange/custom/lib/Fina/Corp/M/Language.pm - table column
			entity			=> 'language',						# interchange/custom/lib/Fina/Corp/M/Client/Language.pm  - foreign_key
			mappings		=> 'language_mappings',				# interchange/custom/lib/Fina/Corp/M/Client.pm - relation
			pkey			=> 'language_code',					# interchange/custom/lib/Fina/Corp/M/Language.pm - table column
			display_column	=> 'language_name',					# interchange/custom/lib/Fina/Corp/M/Language.pm - table column
			page_title		=> 'Set Client Language Mappings',
		}
	);
}

#
#
#
sub _clientSet {
    my $self = shift;
	my $args = shift;
	my $sort_by			= $args->{sort_by};			# e.g: sort_order
	my $entity			= $args->{entity};			# e.g: language
	my $mappings		= $args->{mappings};		# e.g: language_mappings
	my $pkey			= $args->{pkey};			# e.g: language_code
	my $display_column	= $args->{display_column};	# e.g: language_name
	my $page_title		= $args->{page_title};		# e.g: Set Client Language Mappings

    my $values = $self->{_controller}->{_values};
    my @_pk_fields = map { "_pk_$_" } @{ $self->_model_class->meta->primary_key_columns };

    my $object = $self->_common_implied_object;

    #Fina::Corp::Exception->throw( __LINE__."<pre>".Dumper($object)."<pre>");

    my $all_possible_items = $_language_class_mgr->get_objects(
        $sort_by ? (sort_by => $sort_by) : (),
    );

    #Fina::Corp::Exception->throw( __LINE__."<pre>".Dumper($all_possible_items)."<pre>");

    my $current_items = [];
    for my $item ($object->$mappings) {
        push @$current_items, $item->$entity->$pkey;
    }

    #Fina::Corp::Exception->throw( __LINE__."<pre>".Dumper($current_items)."<pre>");

    if ($self->{_step} == 0) {
        my $_pk_form_elements = [];
        for my $_pk_field (@_pk_fields) {
            push @$_pk_form_elements, { name => $_pk_field, value => $CGI::values{$_pk_field} };
        }
        $self->{_controller}->tmp_scratch( _manage_form_pk_elements => [ $_pk_form_elements, undef, [ keys %{$_pk_form_elements->[0]} ] ] );

        my $option_list = [];

        for my $item (@$all_possible_items) {
            my $code = $item->$pkey;
            my $option = {
                value    => $code,
                display  => $item->$display_column,
                checked  => ((grep { $_ eq $code } @$current_items) ? 1 : 0),
            };
            push @$option_list, $option;
        }

    	#Fina::Corp::Exception->throw( __LINE__."<pre>".Dumper($option_list)."<pre>");

        $self->{_controller}->tmp_scratch(
            "_manage_form_custom_${entity}_option_list" => [
                $option_list,
                undef,
                [ keys %{ $option_list->[0] } ],
            ],
        );

        $values->{_step}     = $self->{_step} + 1;
        $values->{_function} = $self->{_function};

        $self->{_controller}->tmp_scratch( _manage_form_include => "$self->{_function}-$self->{_step}" );
        $self->{_controller}->tmp_scratch( _manage_form_referer => $ENV{HTTP_REFERER} );

        $self->{_controller}->tmp_scratch( _manage_subtitle_content => '' );
        $self->set_title($page_title, $object);
        $self->response( type => 'itl', file => 'manage/function/form' );
    }
    elsif ($self->{_step} == 1) {
        $self->SUPER::_properties_action_hook;

        my $values      = $self->{_controller}->{_values};
        my $update_user = $self->{_user}->id;

        my @clear_values;

        my $desired_relations = [];
        for my $item (@$all_possible_items) {
            my $code = $item->$pkey;
            if ($values->{"$entity-$code"})  {
                push @$desired_relations, {
                    $pkey            => $code,
                    created_by       => $update_user,
                    modified_by      => $update_user,
                };
                push @clear_values, "$entity-$code";
            }
        }

        for my $current (@{ $object->$mappings }) {
            unless (grep { $current->$pkey eq $_->{$pkey} } @$desired_relations) {
                $current->delete;
            }
        }
        $object->save;

        for my $desired (@$desired_relations) {
            unless (grep { $desired->{$pkey} eq $_->$pkey } @{ $object->$mappings }) {
                my $add_mappings = "add_$mappings";
                $object->$add_mappings( $desired );
                $object->save;
            }
        }

        delete @{$values}{ @_pk_fields,  @clear_values };

        $self->_referer_redirect_response;
    }
    else {
        Fina::Corp::FinaDirect::Exception->throw( "Unrecognized step: $self->{_step}" );
    }

    return;
}

# TODO: rewrite this to take advantage of : _clientSet (with approprite args)
#
#
#
sub clientSetDocuments {
    my $self = shift;
    
    my $values = $self->{_controller}->{_values};
    my @_pk_fields = map { "_pk_$_" } @{ $self->_model_class->meta->primary_key_columns };
    
    my $object = $self->_common_implied_object;
    
    my $all_possible_items = $_document_class_mgr->get_objects(
        with_objects => ['document_type'],
        sort_by      => 'document_type.description, name',
        debug        => 1,
    );
    
    my $current_items = [];
    for my $item ($object->documents) {
        push @$current_items, $item->document_id;
    }
    
    if ( $self->{_step} == 0 ) {
        my $_pk_form_elements = [];
        for my $_pk_field (@_pk_fields) {
            push @$_pk_form_elements, { name => $_pk_field, value => $CGI::values{$_pk_field} };
        }
        $self->{_controller}->tmp_scratch( _manage_form_pk_elements => [
            $_pk_form_elements,
            undef,
            [ keys %{ $_pk_form_elements->[0] } ],
        ] );
        
        my $option_list = [];
        
        for my $item (@$all_possible_items) {
            my $option = {
                value       => $item->id,
                display     => $item->manage_description,
                checked     => ( ( grep { $_ == $item->id } @$current_items ) ? 1 : 0 ),
            };
            push @$option_list, $option;
        }
        $self->{_controller}->tmp_scratch(
            _manage_form_document_list => [
                $option_list,
                undef,
                [ keys %{ $option_list->[0] }],
            ]
        );
        
        $values->{_step}        = 1;
        $values->{_function}    = $self->{_function};
        
        $self->{_controller}->tmp_scratch( _manage_form_include => "$self->{_function}-$self->{_step}" );
        $self->{_controller}->tmp_scratch( _manage_form_referer => $ENV{HTTP_REFERER} );
        
        $self->{_controller}->tmp_scratch( _manage_subtitle_content => '' );
        $self->set_title('Set Document', $object);
        $self->response( type => 'itl', file => 'manage/function/form' ); 
    }
    elsif ( $self->{_step} == 1 ) {
        $self->SUPER::_properties_action_hook;
        
        my $values      = $self->{_controller}->{_values};
        my $update_user = $self->{_user}->id;
        
        my @clear_values;
        
        my $desired_relations = [];
        for my $item (@$all_possible_items) {
            my $id = $item->id;
            if ( $values->{"document-$id"} ) {
                push @$desired_relations, {
                    document_id     => $id,
                    created_by      => $update_user,
                    modified_by     => $update_user,
                };
                push @clear_values, "document-$id";
            }
        }
        
        for my $current (@{ $object->documents }) {
            unless ( grep { $current->{document_id} == $_->{document_id} } @$desired_relations ) {
                $current->delete;
            }
        }
        
        $object->save;
        
        for my $desired (@$desired_relations) {
            unless ( grep { $desired->{document_id} == $_->document_id } @{ $object->documents } ) {
                $object->add_documents($desired);
                $object->save;
            }
        }
        
        delete @{$values}{ @_pk_fields, @clear_values };
        
        $self->_referer_redirect_response;
    }
    else {
        Fina::Corp::FinaDirect::Exception->throw( "Unrecognized step: $self->{_step}" );
    }
    return;
    
}

sub _get_authentication_methods {
    my $self = shift;

    return $_authentication_method_class_mgr->get_authentication_methods( @_);
}

sub _detail_transform_authentication_methods {
    my $self = shift;
    my $client = shift;
    my $methods_string = $client->authentication_methods;
    my @methods = split /,\s*/, $methods_string;
    my %all_methods = $self->_get_authentication_methods(0);

    my $result = join(', ', map {$all_methods{$_}} @methods);
    return $result;
}

sub _build_auth_method_dropdowns {
    my $self = shift;
    my $values = $self->{_controller}->{_values};
    my $methods_string = $values->{authentication_methods};

#    my $client = shift;
#    my $methods_string = $client->authentication_methods;

    my @a = split /,\s*/, $methods_string;
    my @methods = $self->_get_authentication_methods(1);
    for my $x (0..4) {
        my $options = [];
        push @$options, { value => '', display => 'None Chosen', selected => '', };
        for my $y (@methods) {
            push @$options, {
                value    => $y->{id},
                display  => $y->{description},
                selected => (defined $a[$x] and $a[$x] == $y->{id}) ? ' selected="selected"' : '',
            };
        }
        $self->{_controller}->tmp_scratch( '_manage_form_authentication_method_'.$x => $self->make_loop_list($options) );
        
    }
    return;
}

sub _build_password_complexity_level_dropdowns {
    my $self = shift;
    my $values = $self->{_controller}->{_values};
    my $password_level_options = [];
    for my $password_level_obj (@{ Fina::Corp::M::Password::ComplexityLevel::Manager->get_objects }) {
        push @$password_level_options, { 
            value    => $password_level_obj->level,
            selected => ((defined $values->{minimum_password_complexity_level} and $values->{minimum_password_complexity_level} == $password_level_obj->level) ? ' selected="selected"' : ''),
            display  => $password_level_obj->display,
        };
    }
    $self->{_controller}->tmp_scratch( _manage_form_custom_client_minimum_password_complexity_level_option_list => $self->make_loop_list($password_level_options) );
    return;
}

sub _properties_form_hook {
    my $self = shift;
    my $object = $self->_common_implied_object;
    $self->_build_password_complexity_level_dropdowns;
    $self->_build_auth_method_dropdowns;
    return;
}

sub _properties_action_hook {
    my $self = shift;
    my $cgi = $self->{_controller}->{_cgi};
    my $s = join( ',', split(/\0/, $cgi->{authentication_method_ids}));
    $cgi->{authentication_methods} = $s;
    delete $cgi->{authentication_method_ids};
    $self->SUPER::_properties_action_hook(@_);
    return;
}

#############################################################################
#
#
sub _client_authored_documents {
    my $self = shift;
    my $object = shift;
    my $content = shift;

    $self->_document_related_block(
        object => $object,
        content => $content,
        manage_class => 'Fina::Corp::Manage::Clients::Documents::AuthoredDocuments',
        accessor => "authored_documents", # Name of relationship in model (one to many).
        title => "Client Authored Documents",
        add_link_label => "Client Authored Document",
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
                    client_id => $object->id,
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
    push @$left, (
        '<table class="detail_sub_table">',
        $self->related_item_block($block_params),
        '<tr><td>&nbsp;</td></tr>',
    );

    return;
}




1;

#############################################################################
__END__
