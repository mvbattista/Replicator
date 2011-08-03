#
#
#
#############################################################################
package Fina::Corp::Manage;

use strict;
use warnings;
#use Data::Dumper;
use Encode;

use base qw( Vend::Object );

use File::MimeInfo::Magic qw();
use File::Path qw( );
use File::Spec qw( );
use IO::Scalar;

use Module::Load;
use Module::Loaded;

use Fina::Corp::Config;
use Fina::Corp::M::File;
use Fina::Corp::M::FileResource;

use Fina::Corp::M::User::Role::UserRoleMap;

#############################################################################
#
#
#
our $_meta = { 
    _model_class                     => undef,
    _model_class_mgr                 => undef,
    _model_display_name              => undef,
    _model_display_name_plural       => undef,
    _sub_prefix                      => undef,
    _func_prefix                     => undef,
    _list_all_cols                   => undef,
    _list_cols                       => undef,
    _list_page_count                 => undef,
    _upload_target_directory         => undef,
    _upload_requires_object          => undef,
    _properties_referrer_no_override => undef,
    _parent_manage_class             => undef,
    _parent_model_link_field         => undef,
};
sub _root_model_class { return 'Fina::Corp::M'; }

my $_user_class = __PACKAGE__->_root_model_class . '::User';

my $_file_model_class              = __PACKAGE__->_root_model_class . '::File';
my $_file_resource_model_class     = __PACKAGE__->_root_model_class . '::FileResource';
my $_file_resource_model_class_mgr = $_file_resource_model_class . '::Manager';

my $_icon_path = '/controlled/images/icons/file.png';

my $iteration = 0; 

#############################################################################
#
# Using an AUTOLOAD for accessing a set of meta attributes in the specific
# Function class
#
our $AUTOLOAD;
{
    my %_methods = ( 
        _root_class                      => undef,
        _model_class                     => undef,
        _model_class_mgr                 => undef,
        _model_display_name              => undef,
        _model_display_name_plural       => undef,
        _sub_prefix                      => undef,
        _func_prefix                     => undef,
        _func_base_methods               => undef,
        _list_all_cols                   => undef,
        _list_cols                       => undef,
        _list_page_count                 => undef,
        _upload_target_directory         => undef,
        _upload_requires_object          => undef,
        _properties_referrer_no_override => undef,
        _parent_manage_class             => undef,
        _parent_model_link_field         => undef,
    );
    sub _autoloaded_method { 
        return exists $_methods{ $_[1] };
    }
}

{
    my %_mapped_methods = (
        Add             => '_common_add',
        DetailView      => '_common_detail_view',
        Drop            => '_common_drop',
        Properties      => '_common_properties',
        List            => '_common_list',
    );
    
    sub AUTOLOAD {
        my $self = shift;
        no strict 'refs';
        my $_autoload = $AUTOLOAD;
        return if $_autoload =~ /::DESTROY$/;

        if ($_autoload =~ /.*::(\w+)$/ and $self->_autoloaded_method($1)) {
            my $method_name = $1;
    
            # cache the method call in the symbol table for efficiency
            # of method lookup
            *{$_autoload} = sub {
                #print STDERR "Cached method call\n";
                my $class = ref $_[0] ? ref $_[0] : $_[0];
                {
                    return ${"$class\::_meta"}->{$method_name};
                }
            };
    
            return $self->$method_name();
        }
        elsif ( $_autoload =~ /.*::(?<methodname>\w+)$/ and grep { $+{methodname} =~ m/$_/ } keys %_mapped_methods ) {
            my $method =  $+{methodname};
#            ::logDebug('$method: %s', $method);
            my ($method_key) = grep { $self->_sub_prefix . $_ eq $method } @{$self->_func_base_methods};
#            ::logDebug('$method_key: %s', $method_key);
            if ($method_key and exists $_mapped_methods{$method_key}) {
                my $tr_method = $_mapped_methods{$method_key};
                *{$_autoload} = sub {
                    die if 5 < $iteration++;
#                    ::logDebug('$tr_method: %s, %s', $tr_method, $iteration);
                    my $self = shift;
                    $self->$tr_method(@_);
                };
#                ::logDebug('$method: %s', $method);
#                ::logDebug('*{$_autoload}: %s', *{$_autoload});
                return $self->$method(@_);
            }
        }
    
        # Must have been a mistake...
        Vend::Exception::UnknownMethod->throw( error => $AUTOLOAD );
    }
}

#############################################################################
#
#
#
sub _init {
    my $self = shift;
    my %args = @_;

    $self->SUPER::_init(%args);

    unless (defined $self->{_class}) {
        Vend::Exception::ArgumentMissing->throw( error => 'class' );
    }
    unless (defined $self->{_method}) {
        Vend::Exception::ArgumentMissing->throw( error => 'method' );
    }
    unless (defined $self->{_controller}) {
        Vend::Exception::ArgumentMissing->throw( error => 'controller' );
    }
    unless (defined $self->{_user}) {
        Vend::Exception::ArgumentMissing->throw( error => 'user' );
    }
    $self->{_function} = "$self->{_class}\_$self->{_method}";

    return;
}

#
#
#
sub execute {
    #::logDebug('Manage.pm::execute()');
    my $self = shift;
    my %args = @_;

    my $method = $self->{_method};

#    unless ($self->can( $method )) {
#        Fina::Corp::Exception::ManageFunctionMethodUnknown->throw( error => $method );
#    }

    # run the method of the function object, that will
    # set response parameters in the object, which 
    # can then be retrieved to generate a response object
    $self->$method(%args);

    my $response_params = $self->response;
    #::logDebug("Manage.pm $method \$response_params: " . Dumper($response_params));
    unless (defined $response_params and ref $response_params eq 'HASH') {
        # TODO: exception
    }

    if (defined $response_params->{chain} and $response_params->{chain} ne '') {
    }
    elsif (defined $response_params->{class} and $response_params->{class} ne '') {
        return $response_params->{class}->new( %{$response_params->{args}} );
    }
    else {
    }

    return;
}

#
#
#
sub response {
    my $self = shift;
    my %args = @_;

    if (%args) {
        unless (defined $args{type} and $args{type} ne '') {
            # TODO: exception
        }

        if ($args{type} eq 'itl') {
            $self->{_response}->{class} = 'Fina::Corp::V::ITL';
            unless (defined $args{file} and $args{file} ne '') {
                # TODO: exception
            }

            $self->{_response}->{args} = { file => $args{file} };
        }
        elsif ($args{type} eq 'redirect') {
            $self->{_response}->{class} = 'Vend::Response::Redirect';

            unless (defined $args{url} and $args{url} ne '') {
                # TODO: exception
            }

            $self->{_response}->{args} = { _url => $args{url} };
        }
        elsif ($args{type} eq 'file') {
            $self->{_response}->{class} = 'Vend::Response::File';
        }
        elsif ($args{type} eq 'controller') {
            my $class = $args{controller};
    
            $self->{_response}->{class} = 'Fina::Corp::V::ITL';
            
            unless (is_loaded($class)) {
                load $class;
            }
            
            my $file;
            
            if (my $method = $class->can($args{'subroutine'})) {
               $file = $class->$method();
            }
            
            $self->{_response}->{args} = { file => $file };
        }
        else {
            # TODO: exception
        }
    }

    return $self->{_response};
}

#
#
#
sub set_title {
    my $self = shift;
    my ($action, @objects) = @_;

    my $desc = '';
    for my $object (@objects) {
        $desc .= ' : ' . encode_utf8($object->manage_description);
    }

    $self->{_controller}->scratch( _manage_title_content => "$action$desc" );

    return;
}

#
#
#
sub manage_function_uri {

    my $invocant = shift;
    my $args = { @_ };


     #Fina::Corp::Exception->throw( __LINE__.' <pre>' . Dumper({ invocant=> $invocant, map {$_ => $args->{$_}} qw(function class method click_text query debug)}) . "</pre>") if $args->{debug};
     #Fina::Corp::Exception->throw( __LINE__.' ' . Dumper($args) ) if $args->{debug};

#    my $debug = 1 if( defined $args->{ function } and $args->{ function } =~ /program/i );
#
#    if($debug) {
#        warn 'manage_function_uri():';
#        for( keys %$args ) {
#            unless( $_ eq 'user' ) {
#                warn "        \$args->{ $_ } : " . ::uneval($args->{ $_ });
#            }
#        }
#    }

    if (defined $args->{function}) {
        # do nothing they passed exactly what we want
    }
    elsif (defined $args->{class} and defined $args->{method}) {
        $args->{function} = "$args->{class}\_$args->{method}";
    }
    elsif (defined $args->{method}) {
        $args->{function} = $invocant->_func_prefix.$args->{method};
    }
    elsif (ref $invocant) {
        # in this case pull the class, method, and potentially the step
        # from the object instance
        $args->{function} = "$invocant->{_class}\_$invocant->{_method}";
    }
    else {
        Fina::Corp::Exception->throw( "Can't determine function for manage_function_uri" );
    }
    for my $key ( keys %$args ) {
#        warn("manage_function_uri \$key:$key \t\t\$args->{$key}: " . $args->{$key}) if($debug);
    }

    #Fina::Corp::Exception->throw( __LINE__.' <pre>' . Dumper({ invocant=> $invocant, map {$_ => $args->{$_}} qw(function class method click_text query debug)}) . "</pre>") if $args->{debug};

    # perform privilege check unless they pass the arg and it is turned off
    # aka default to on, a failing priv check results in no link rather than
    # throwing an exception

    unless (defined $args->{priv_check} and ! $args->{priv_check}) {
        my $func_name = $args->{function};
    	#Fina::Corp::Exception->throw( __LINE__.' <pre>' . Dumper({ invocant=> $invocant, func_name=>$func_name,map {$_ => $args->{$_}} qw(function class method click_text query debug)}) . "</pre>") if $args->{debug};
        if (defined $args->{user} and UNIVERSAL::isa($args->{user}, $_user_class)) {
    		#Fina::Corp::Exception->throw( __LINE__.' <pre>' . Dumper({ auth=>[$args->{user}->is_authorized($func_name)], invocant=> $invocant, func_name=>$func_name,map {$_ => $args->{$_}} qw(function class method click_text query debug)}) . "</pre>") if $args->{debug};
            return '' unless $args->{user}->is_authorized($func_name);
        }
        elsif (ref $invocant and UNIVERSAL::isa($invocant, __PACKAGE__) and defined $invocant->{_user}) {
            return '' unless $invocant->{_user}->is_authorized($func_name);
        }
        else {
            my ($package, $filename, $line) = caller(1);
            warn "$package called manage_function_uri as class method without 'user' argument at line $line\n";
            return '';
        }
    }

    $args->{step} ||= 0;

    my $url = $::Tag->area(
        {
            href => "handler/Manage/Function/params/$args->{function}/$args->{step}",
            form => (join "\n", map { "$_=$args->{query}->{$_}" } keys %{$args->{query}}),
        },
    );
    return $url;
}

#
#
#
sub manage_function_link {
    my $invocant = shift;
    my $args = { @_ };

     #Fina::Corp::Exception->throw( __LINE__.' ' . $invocant ) if $args->{debug};
     #Fina::Corp::Exception->throw( __LINE__.' <pre>' . Dumper({ map {$_ => $args->{$_}} qw(method click_text query debug)}) . "</pre>") if $args->{debug};

    unless (defined $args->{click_text} and $args->{click_text} ne '') {
        Vend::Exception::ArgumentMissing->throw( error => 'click_text' );
    }
    my $click_text = delete $args->{click_text};
    my $url = $invocant->manage_function_uri( %$args );

    if ($url ne '') {
        return "<a class=\"manage_function_link\" href=\"$url\">$click_text</a>";
    }

    return '';
}

#
# TODO: This needs a much better name, but I suck at naming
# TODO: This is a decent start, but needs to be recursive.
#
sub related_item_block {
    my $self = shift;
    my $item_block = shift;
    
    my @return;
    
    push @return, (
        '<tr>',
        '<td class="detail_table_title_cell">',
        $item_block->{title},
        '</td>',
        '<td class="detail_table_subtitle_cell" style="text-align: right;">',
        @{$item_block->{actions}},
        '</td>',
        '</tr>',
    ); 

    for my $item (@{ $item_block->{items} }) {
        push @return, (
            '<tr>',
            '<td class="detail_table_datum_cell">',
            $item->{name},
            '&nbsp;</td>',
            '<td class="detail_table_datum_cell" align="right">&nbsp;',
            @{$item->{actions}},
            '</td>',
            '</tr>',
        ); 
    }

    return @return;        
}
#############################################################################
#
#
#
sub _common_implied_object {
    my $self = shift;

    my $_model_class = $self->_model_class;
    my $_object_name = $self->_model_display_name;
    my $cgi = $self->{_controller}->{_cgi};

    my @pk_fields  = @{ $_model_class->meta->primary_key_columns };
    my @_pk_fields = map { "_pk_$_" } @pk_fields;

    for my $_pk_field (@_pk_fields) {
        unless (defined $cgi->{$_pk_field}) {
            Vend::Exception::MissingValue->throw( "PK argument ($_pk_field): Unable to retrieve object" );
        }
    }

    my %object_params = map { $_ => $cgi->{"_pk_$_"} } @pk_fields;
    my $object = new $_model_class ( %object_params );
    unless (defined $object) {
        Fina::Corp::Exception::ModelInstantiateFailure->throw( $_object_name );
    }
    unless ($object->load(speculative => 1)) {
        Fina::Corp::Exception::ModelLoadFailure->throw( "Unrecognized $_object_name: " . (join ' => ', %object_params) );
    }

    return $object;
}

#
#
#
sub _object_manage_function_link {
    my $self   = shift;
    my $action = shift;
    my $object = shift;
    my $args   = { @_ };

    # set some defaults
    $args->{label}      ||= '';
    $args->{url_only}   ||= 0;
    $args->{addtl_cgi}  ||= {};
    $args->{addtl_keys} ||= {};

    my $invocant;
    if (ref $object) {
        $invocant  = $object;
    }
    else {
        $invocant = $self->_model_class;
    }

    my %method_params = (
        function => $self->_func_prefix . $action,
        query    => {
            (
                map { 
                    my $val;
                    if ($invocant->can($_)) {
                        $val = $invocant->$_;
                    }
                    elsif (exists $args->{addtl_keys}->{$_}) {
                        $val = $args->{addtl_keys}->{$_};
                    }
                    else {
                        Fina::Corp::Exception->throw( "No value found for pk field: $_" );
                    }
    
                    "_pk_$_" => $val
                } @{ $invocant->meta->primary_key_columns }
            ),
            %{$args->{addtl_cgi}},
        },
    );
    if (defined $args->{step}) {
        $method_params{step} = $args->{step};
    }
    if (defined $args->{priv_check}) {
        $method_params{priv_check} = $args->{priv_check};
    }
    if (defined $args->{user}) {
        $method_params{user} = $args->{user};
    }

    if ($args->{url_only}) {
        return $self->manage_function_uri(%method_params);
    }
    else {
        return $self->manage_function_link(
            %method_params,
            click_text => '[&nbsp;' . ($args->{label} || $action) . '&nbsp;]',
        );
    }
}

#
#
#
sub _referer_redirect_response {
    my $self = shift;

    my $cgi = $self->{_controller}->{_cgi}; 

    $self->response(
        type => 'redirect',
        url  => (defined $cgi->{redirect_referer} ?  $cgi->{redirect_referer} : $::Tag->area( { href => 'handler/Manage/Menu' } ) ),
    );

    return;
}

#
#
#
sub _properties_action_hook {
    my $self = shift;

    {
        local $Vend::admin = 1;
        Vend::Dispatch::update_values();
    }

    return;
}

#
# each element of the search by value contains a single
# query element specification as,
#
#   field = operator
#
# where field matches a field in the model class being
# queried, and the operator matches a query operator
# the model class field understands
#
sub _process_search_by {
    my $self = shift;
    my $cgi = shift;

    my @return;

    for my $search_by (split /\0/, $cgi->{search_by}) {
        if ($search_by =~ /\A(.*)=(.*)\z/) {
            my $field    = $1;
            my $operator = $2;

            # confirm operator and field is recognized
            unless (grep $operator eq $_, qw( ilike like eq ne lt gt le ge )) {
                Vend::Exception::FeatureNotImplemented->throw( "Common list search operator: $operator" );
            }

            my $value = $cgi->{$field};
            if ($operator eq 'like' or $operator eq 'ilike') {
                $value = '%' . $cgi->{$field} . '%';
            }

            push @return, ( 
                $field => {
                    $operator => $value,
                },
            );
        }
    }

    return @return;
}

#############################################################################
#
#
#
sub _common_list {

    my $self = shift;

    my $_model_class          = $self->_model_class;
    my $_model_class_mgr      = $self->_model_class_mgr;
    my $_object_name          = $self->_model_display_name;
    my $_plural_name          = $self->_model_display_name_plural;

    my $content = [];
    $self->set_title( "List $_plural_name" );
        my $cgi = $self->{_controller}->{_cgi};

    #Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({_step=>$self->{_step},cgi=>$self->{_controller}->{_cgi}, _model_class=>$_model_class, _model_class_mgr=>$_model_class_mgr,_object_name=>$_object_name,_plural_name=>$_plural_name,self=>ref($self)}) . "</pre>");

    if ($self->{_step} == 0) {
        push @$content, "<table id=\"list_table\">";

        my $total = $_model_class_mgr->get_objects_count();
        #Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({total=>$total,_step=>$self->{_step},cgi=>$self->{_controller}->{_cgi}, _model_class=>$_model_class, _model_class_mgr=>$_model_class_mgr,_object_name=>$_object_name,_plural_name=>$_plural_name,self=>ref($self)}) . "</pre>");
        if ($total) {
            if ($self->can('_list_0_hook')) {
                my $result = $self->_list_0_hook($content);
                if ($result) {
                    # still need or throw exception from hook?
                    Fina::Corp::Exception->throw( "Hook returned error: $result" );
                }
            }

            push @$content, "<tr>";
            push @$content, "<td class=\"list_table_title_cell\">List All</td>";
            push @$content, "<td class=\"list_table_datum_cell_centered\">";
            push @$content, $self->manage_function_link(
                step       => $self->{_step} + 1, 
                click_text => $total,
                query      => {
                    mode => 'listall',
                },
            );
            push @$content, "</td>";
            push @$content, "</tr>";

            if ($_model_class->can('statuses')) {
                push @$content, "<tr>";
                push @$content, "<td class=\"list_table_title_cell\">List by Status</td>";
                push @$content, "<td class=\"list_table_title_cell_centered\">Count</td>";
                push @$content, "</tr>";
                while (my ($key, $name) = each %{ $_model_class->statuses }) {
                    my $count = $_model_class_mgr->get_objects_count( query => [ status => $key ] );
                    if ($count) {
                        push @$content, "<tr>";
                        push @$content, "<td class=\"list_table_datum_cell\">";
                        push @$content, $self->manage_function_link(
                            step       => $self->{_step} + 1, 
                            click_text => $name,
                            query      => {
                                mode    => 'list',
                                list_by => 'status',
                                status  => $key,
                            },
                        );
                        push @$content, "</td>";
                        push @$content, "<td class=\"list_table_datum_cell_centered\">$count</td>";
                        push @$content, "</tr>";
                    }
                }
            }
        }
        else {
            push @$content, "<tr><td class=\"list_table_datum_cell\">No " . lc $_plural_name . " to list.</td></tr>\n";
        }
        push @$content, "</table>\n";

        $self->{_controller}->tmp_scratch( _manage_content => join '', @$content );
        $self->response( type => 'itl', file => 'manage/function/generic' );
    }
    elsif ($self->{_step} == 1) {
        my $cgi = $self->{_controller}->{_cgi};

        unless (defined $cgi->{mode} and $cgi->{mode} ne '') {
            Vend::Exception::MissingValue->throw( 'mode' );
        }

        my $query = [];
		my @with_objects = ();

        if (lc $cgi->{mode} eq 'list') {
            unless (defined $cgi->{list_by} and $cgi->{list_by} ne '') {
                Vend::Exception::MissingValue->throw( 'list_by' );
            }
            for my $list_by (split /\0/, $cgi->{list_by}) {
                unless (defined $cgi->{$list_by} and $cgi->{$list_by} ne '') {
                    Vend::Exception::MissingValue->throw( "$list_by->value" );
                }
                push @$query, $list_by => $cgi->{$list_by};
            }
        }
        elsif (lc $cgi->{mode} eq 'search') {
            # search_by holds the search specification, which is required
            unless (defined $cgi->{search_by} and $cgi->{search_by} ne '') {
                Vend::Exception::MissingValue->throw( 'search_by' );
            }

            push @$query, $self->_process_search_by( $cgi );
        }
        elsif (lc $cgi->{mode} eq 'search_by_relation') {

    		#Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({_step=>$self->{_step},cgi=>$self->{_controller}->{_cgi}, _model_class=>$_model_class, _model_class_mgr=>$_model_class_mgr,_object_name=>$_object_name,_plural_name=>$_plural_name,self=>ref($self)}) . "</pre>");

            # search_by holds the search specification, which is required
            unless (defined $cgi->{search_by} and $cgi->{search_by} ne '') {
                Vend::Exception::MissingValue->throw( 'search_by' );
            }

			for my $search_by_field (split(/\0/, $cgi->{search_by})) {

				unless (defined $cgi->{$search_by_field} and $cgi->{$search_by_field} ne '') {
					Vend::Exception::MissingValue->throw( "$search_by_field->value" );
				}
	
				if (defined $cgi->{list_delimiter} and $cgi->{list_delimiter} ne '' and $cgi->{$search_by_field} =~ /$cgi->{list_delimiter}/) {
					my $delim = $cgi->{list_delimiter};
					my $or = [];
					for my $val (split /\s*[$delim]\s*/, $cgi->{$search_by_field}) {
						if (defined $val and $val ne '') {
			           		push @$or, $search_by_field => {ilike => uc $val};
			           		#push @$or, $field => uc $val;
						}
					}
					if (@$or) {
			           	push @$query, or => $or;
					} else {
						Vend::Exception::MissingValue->throw( "$search_by_field->value" );
					}
				} else {
					if ($cgi->{$search_by_field} =~ /\S/) {
			           	push @$query, $search_by_field => { ilike => $cgi->{$search_by_field}};
			           	#push @$query, $search_by_field => uc $cgi->{$search_by_field};
					} else {
						Vend::Exception::MissingValue->throw( "$search_by_field->value" );
					}
				}

			} # for

			if ($cgi->{with_objects} and $cgi->{with_objects} ne '') {
				my $with_objects = [ split(/\0/, $cgi->{with_objects}) ];
				@with_objects = (with_objects => $with_objects);
			}

			if ($cgi->{query} and $cgi->{query} ne '') {
				for my $this_query (split(/\0/, $cgi->{query})) {
					my ($field, $value) = $this_query =~ /(.*)=(.*)/;
					unless (defined $field and defined $value) {
						next;
					}
					push @$query, $field => $value;
				}
			}

    		#Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({query=>$query, with_objects=>\@with_objects}) . "</pre>");
        }

# This is now not necessary, because it uses the relation search, may DELETE later
#        elsif (lc $cgi->{mode} eq 'user_client_search') {
#
#    		Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({_step=>$self->{_step},cgi=>$self->{_controller}->{_cgi}, _model_class=>$_model_class, _model_class_mgr=>$_model_class_mgr,_object_name=>$_object_name,_plural_name=>$_plural_name,self=>ref($self)}) . "</pre>");
#
#            # search_by holds the search specification, which is required
#            unless (defined $cgi->{search_by} and $cgi->{search_by} ne '') {
#                Vend::Exception::MissingValue->throw( 'search_by' );
#            }
#
#			my $search_by = $cgi->{search_by}; # client_id
#
#			unless (defined $cgi->{$search_by} and $cgi->{$search_by} ne '') {
#				Vend::Exception::MissingValue->throw( "$search_by->value" );
#			}
#			if ($cgi->{$search_by} == -1) {
#				Vend::Exception::MissingValue->throw( "Select a Client from Drop Down List" );
#			}
#			my $client_id = $cgi->{$search_by};
#
#			my $with_objects = [];
#			push @$with_objects, "roles_map";
#			push @$with_objects, "roles_map.user_role_client_maps";
#
#			@with_objects = (with_objects => $with_objects);
#
#            push @$query, (
#								"roles_map.client_restricted" => 'true',
#								"roles_map.user_role_client_maps.client_id" => $client_id,
#						  );
#        }
#
#        elsif (lc $cgi->{mode} eq 'user_company_search') {
#
#            unless ($_object_name eq 'User') {
#    			Fina::Corp::Exception->throw(__LINE__."<pre>" . "Search mode '$cgi->{mode}' is allowed only when searching for 'User'" . "</pre>");
#            }
#    		#Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({_step=>$self->{_step},cgi=>$self->{_controller}->{_cgi}, _model_class=>$_model_class, _model_class_mgr=>$_model_class_mgr,_object_name=>$_object_name,_plural_name=>$_plural_name,self=>ref($self)}) . "</pre>");
#
#            # search_by holds the search specification, which is required
#            unless (defined $cgi->{search_by} and $cgi->{search_by} ne '') {
#                Vend::Exception::MissingValue->throw( 'search_by' );
#            }
#
#			my $search_by = $cgi->{search_by}; # company
#
#			unless (defined $cgi->{$search_by} and $cgi->{$search_by} ne '') {
#				Vend::Exception::MissingValue->throw( "$search_by->value" );
#			}
#
#			if ($cgi->{$search_by} =~ /super/i) {
#				my $with_objects = [];
#				push @$with_objects, "roles_map";
#	
#				@with_objects = (with_objects => $with_objects);
#	
#	            push @$query, (
#									"roles_map.client_restricted" => 'false',
#							);
#			} else {
#
#				my $with_objects = [];
#				push @$with_objects, "roles_map";
#				push @$with_objects, "roles_map.user_role_client_maps";
#				push @$with_objects, "roles_map.user_role_client_maps.user_role_client_company_maps";
#	
#				@with_objects = (with_objects => $with_objects);
#	
#	            push @$query, (
#									"roles_map.client_restricted" => 'true',
#									"roles_map.user_role_client_maps.company_restricted" => 'true',
#							);
#	
#				$cgi->{$search_by} =~ s/^\s*//;
#				$cgi->{$search_by} =~ s/\s*$//;
#	
#		        my $field = "roles_map.user_role_client_maps.user_role_client_company_maps.company_code";
#
#				if ($cgi->{$search_by} =~ /,/) {
#					my $or = [];
#					for my $val (split /\s*,\s*/, $cgi->{$search_by}) {
#						if (defined $val and $val ne '') {
#		            		push @$or, $field => {ilike => uc $val};
#		            		#push @$or, $field => uc $val;
#						}
#					}
#					if (@$or) {
#		            	push @$query, or => $or;
#					} else {
#						Vend::Exception::MissingValue->throw( "$search_by->value" );
#					}
#				} else {
#					if ($cgi->{$search_by} =~ /\S/) {
#		            	push @$query, $field => { ilike => uc $cgi->{$search_by}};
#		            	#push @$query, $field => uc $cgi->{$search_by};
#					} else {
#						Vend::Exception::MissingValue->throw( "$search_by->value" );
#					}
#				}
#			}
#
#	    	#Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval($query) . "</pre>");
#
#        	#my $users2 = $_model_class_mgr->get_objects(
#			#						query => $query,
#			#						@with_objects,
#			#);
#	    	#my $out = $self->_user_entitlement_stringify($users2);
#	    	#Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval($out) . "</pre>");
#
#        }

        elsif (lc $cgi->{mode} eq 'listall') {
            # listing all objects so no query parameters
        }
        else {
            Fina::Corp::Exception->throw( "Unrecognized mode: $cgi->{mode}" );
        }

        #::logDebug('About to get_objects_count with query => ' . ::uneval($query));
        #Fina::Corp::Exception->throw('About to get_objects_count with query => ' . ::uneval($query));

        my $total = $_model_class_mgr->get_objects_count( query => $query, @with_objects );
        #::logDebug("\$total objects:$total\n");
    	#Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({total=>$total,_step=>$self->{_step},cgi=>$self->{_controller}->{_cgi}, _model_class=>$_model_class, _model_class_mgr=>$_model_class_mgr,_object_name=>$_object_name,_plural_name=>$_plural_name,self=>ref($self)}) . "</pre>");

        if ($total) {
            my $prefix = $self->_func_prefix;

            my @pk_fields  = @{ $_model_class->meta->primary_key_columns };

            $self->{_controller}->scratch(_manage_list_1_page_count => ($self->_list_page_count || 25));
    	#Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({pk_fields=>scalar(@pk_fields),prefix=>$prefix,total=>$total,_step=>$self->{_step},cgi=>$self->{_controller}->{_cgi}, _model_class=>$_model_class, _model_class_mgr=>$_model_class_mgr,_object_name=>$_object_name,_plural_name=>$_plural_name,self=>ref($self)}) . "</pre>");

            my $_list_cols = $self->_list_cols;
            unless (defined $_list_cols and ref $_list_cols eq 'ARRAY' and @$_list_cols) {
                $_list_cols = [
                    { 
                        display => 'Description',
                        method  => 'manage_description',
                    },
                    {
                        display => 'Date Created',
                        method  => 'date_created',
                    },
                    {
                        display => 'Last Modified',
                        method  => 'last_modified',
                    },
                ];
            }

            my ($headers, $fields) = ([] , []);
            for my $col (@$_list_cols) {
                push @$fields, $col->{method};
                push @$headers, {
                    method    => $col->{method},
                    display   => $col->{display},
                    class_opt => $col->{class_opt},
                };
            }
            $self->{_controller}->scratch(_manage_list_1_headers => [ $headers, undef, [ keys %{$headers->[0]} ] ] ); 
            $self->{_controller}->scratch(_manage_list_1_fields => $fields );

            my $functions = { 
                $prefix.'Properties' => { display => 'Edit' },
                $prefix.'Drop'       => { display => 'Drop' },
                $prefix.'DetailView' => { display => 'Detail' },
            };

    	#Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({headers=>$headers,fields=>$fields,pk_fields=>scalar(@pk_fields),prefix=>$prefix,total=>$total,_step=>$self->{_step},cgi=>$self->{_controller}->{_cgi}, _model_class=>$_model_class, _model_class_mgr=>$_model_class_mgr,_object_name=>$_object_name,_plural_name=>$_plural_name,self=>ref($self)}) . "</pre>");
            my $list = [];
            for my $object (@{ $_model_class_mgr->get_objects( query => $query, @with_objects ) }) {
    	#Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({object=>$object->see_obj,headers=>$headers,fields=>$fields,pk_fields=>scalar(@pk_fields),prefix=>$prefix,total=>$total,_step=>$self->{_step},cgi=>$self->{_controller}->{_cgi}, _model_class=>$_model_class, _model_class_mgr=>$_model_class_mgr,_object_name=>$_object_name,_plural_name=>$_plural_name,self=>ref($self)}) . "</pre>");
                my $details = {};
                push @$list, $details;

                for my $col (@$_list_cols) {
                    no strict 'refs';
                    my $method = $col->{method};
                    $details->{ $col->{method} } = $object->$method();
                    $details->{ "$col->{method}\_class_opt" } = $col->{class_opt};
                }
    	#Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({list=>$list,object=>$object->see_obj,headers=>$headers,fields=>$fields,pk_fields=>scalar(@pk_fields),prefix=>$prefix,total=>$total,_step=>$self->{_step},cgi=>$self->{_controller}->{_cgi}, _model_class=>$_model_class, _model_class_mgr=>$_model_class_mgr,_object_name=>$_object_name,_plural_name=>$_plural_name,self=>ref($self)}) . "</pre>");

                my %_pk_params = map { '_pk_'.$_ => $object->$_() } @pk_fields;
    	#Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({_pk_params=>\%_pk_params,object=>$object->see_obj,headers=>$headers,fields=>$fields,pk_fields=>scalar(@pk_fields),prefix=>$prefix,total=>$total,_step=>$self->{_step},cgi=>$self->{_controller}->{_cgi}, _model_class=>$_model_class, _model_class_mgr=>$_model_class_mgr,_object_name=>$_object_name,_plural_name=>$_plural_name,self=>ref($self)}) . "</pre>");

                my $details_functions = [];
                for my $key qw(DetailView Properties Drop) {
                    my $name = "$prefix$key";
                    push @$details_functions, __PACKAGE__->manage_function_link(
                        function   => $name,
                        query      => {
                            %_pk_params,
                        },
                        click_text => "[&nbsp;$functions->{$name}->{display}&nbsp;]",
                        user       => $self->{_user},
                    );
                }
                $details->{function_options} = $details_functions;
    	#Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({list=>$list,_pk_params=>\%_pk_params,object=>$object->see_obj,headers=>$headers,fields=>$fields,pk_fields=>scalar(@pk_fields),prefix=>$prefix,total=>$total,_step=>$self->{_step},cgi=>$self->{_controller}->{_cgi}, _model_class=>$_model_class, _model_class_mgr=>$_model_class_mgr,_object_name=>$_object_name,_plural_name=>$_plural_name,self=>ref($self)}) . "</pre>");
            }
            if (@$list) {
                $self->{_controller}->scratch( _manage_list_1_rows => [ $list, undef, [ keys %{$list->[0]} ] ] ); 
            }

            $self->{_controller}->scratch( _manage_list_class => ref $self );

            $self->response( type => 'itl', file => 'manage/function/list_1' );
        }
        else {
            $self->{_controller}->tmp_scratch( _manage_content => "No $_plural_name to list." );
            $self->response( type => 'itl', file => 'manage/function/generic' );
        }
    }
    else {
        Fina::Corp::Exception->throw( "common list: unrecognized step" );
    }

    return;
}

#
# Useful when the number of objects will remain quite small and only
# a one step list process is needed usually without pagination
#
sub _common_list_display_all {
    my $self = shift;
    my %args = @_;

    my $_model_class     = $self->_model_class;
    my $_model_class_mgr = $self->_model_class_mgr;
    my $_plural_name     = $self->_model_display_name_plural;

    $self->set_title("List $_plural_name");

    my $objects = $_model_class_mgr->get_objects();
    if (@$objects) {
        my $_object_name = $self->_model_display_name;
        my $prefix       = $self->_func_prefix;

        my $_list_all_cols = $self->_list_all_cols;
        unless (defined $_list_all_cols and ref $_list_all_cols eq 'ARRAY' and @$_list_all_cols) {
            $_list_all_cols = [ 
                { 
                    display => 'Description',
                    method  => 'manage_description',
                },
                {
                    display => 'Date Created',
                    method  => 'date_created',
                },
                {
                    display => 'Last Modified',
                    method  => 'last_modified',
                },
            ];
        }

        my ($headers, $fields) = ([] , []);
        for my $col (@$_list_all_cols) {
            push @$fields, $col->{method};
            push @$headers, {
                method    => $col->{method},
                display   => $col->{display},
                class_opt => $col->{class_opt},
            };
        }
        $self->{_controller}->scratch( _manage_list_display_all_headers => [ $headers, undef, [ keys %{$headers->[0]} ] ] ); 
        $self->{_controller}->scratch( _manage_list_display_all_fields  => $fields );

        my @pk_fields  = @{ $_model_class->meta->primary_key_columns };

        my $functions = { 
            $prefix.'Properties' => { display => 'Edit' },
            $prefix.'Drop'       => { display => 'Drop' },
            $prefix.'DetailView' => { display => 'Detail' },
        };

        my $list = [];
        for my $object (@$objects) {
            my $details = {};
            push @$list, $details;

            for my $col (@$_list_all_cols) {
                no strict 'refs';
                my $method = $col->{method};
                $details->{ $col->{method} } = $object->$method();
                $details->{ "$col->{method}\_class_opt" } = $col->{class_opt};
            }

            my %_pk_params = map { '_pk_'.$_ => $object->$_() } @pk_fields;

            my $details_functions = [];
            for my $key qw(DetailView Properties Drop) {
                my $name = "$prefix$key";
                push @$details_functions, __PACKAGE__->manage_function_link(
                    function   => $name,
                    query      => {
                        %_pk_params,
                    },
                    click_text => "[&nbsp;$functions->{$name}->{display}&nbsp;]",
                    user       => $self->{_user},
                );
            }
            #::logDebug(Dumper($details_functions));
            $details->{function_options} = $details_functions;
        }
        if (@$list) {
            $self->{_controller}->scratch( _manage_list_display_all_rows => [ $list, undef, [ keys %{$list->[0]} ] ] ); 
        }

        $self->{_controller}->scratch( _manage_list_class => ref $self );

        $self->response( type => 'itl', file => 'manage/function/list_display_all' );
    }
    else {
        $self->{_controller}->tmp_scratch( _manage_content => "No $_plural_name to list." );
        $self->response( type => 'itl', file => 'manage/function/generic' );
    }

    return;
}

#
#
#
sub _common_add {
    my $self = shift;

    $self->{_controller}->{_cgi}->{_properties_mode} = 'add';

    my $sub = $self->_sub_prefix.'Properties';
    return $self->$sub(@_);
}

#
#
#
sub _common_properties {
    my $self = shift;

    my $values = $self->{_controller}->{_values};
    my $cgi    = $self->{_controller}->{_cgi};

    $cgi->{_properties_mode} ||= 'edit';

    if ($cgi->{_properties_mode} eq 'upload') {
        $self->_common_properties_upload;
        return;
    }

    if ($cgi->{_properties_mode} eq 'drop') {
        $self->_common_properties_drop;
        return;
    }

    my $_model_class     = $self->_model_class;
    my $_model_class_mgr = $self->_model_class_mgr;
    my $_object_name     = $self->_model_display_name;

    #Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({_step=>$self->{_step},cgi=>$self->{_controller}->{_cgi}, model_class=>$_model_class, _model_class_mgr=>$_model_class_mgr,_object_name=>$_object_name,self=>ref($self)}) . "</pre>");

    my @pk_fields  = @{ $_model_class->meta->primary_key_columns };
    my @_pk_fields = map { "_pk_$_" } @pk_fields;
    my @fields     = @{ $_model_class->meta->columns };

    if ($self->{_step} == 0) {
        my %hook_params = ();
        if ($cgi->{_properties_mode} eq 'edit') {
            my $object = $self->_common_implied_object;

            $self->set_title("Edit $_object_name Properties", $object);

            for my $field (@fields) {
                #$values->{$field} = $object->$field;
                $values->{$field} = encode_utf8($object->$field);
            }
            my $_pk_form_elements = [];
            for my $_pk_field (@_pk_fields) {
                push @$_pk_form_elements, { name => $_pk_field, value => $cgi->{$_pk_field} };
            }
            $self->{_controller}->tmp_scratch( _manage_form_pk_elements => [ $_pk_form_elements, undef, [ keys %{$_pk_form_elements->[0]} ] ] );

            $hook_params{object} = $object;
        }
        else {
            $self->set_title("Add $_object_name");

            @{ $values }{ @_pk_fields, @fields } = ();
        }

        if ($self->can('_properties_form_hook')) {
            $self->_properties_form_hook(%hook_params);
        }

        $values->{_step}     = $self->{_step} + 1;
        $values->{_function} = $self->{_function};

        #
        # originally didn't want to make this smart, but I've
        # since decided that creating the symlink every time
        # we need an add doesn't make sense, so making this
        # smart to recognize when Add exists to use it, otherwise
        # fall back to Properties
        #
        my $include = "$self->{_function}-$self->{_step}";
        if ($cgi->{_properties_mode} ne 'edit') {
            my $path = Fina::Corp::Config->file_relative_to_camp_root("catalogs/core/include/components/_views/itl/manage/function/$include\.html");
            unless (-e $path) {
                $include = $self->_func_prefix . 'Properties-' . $self->{_step};
            }
        }

        $self->{_controller}->tmp_scratch( _manage_form_include => $include );
        $self->{_controller}->tmp_scratch( _manage_form_referer => $ENV{HTTP_REFERER} );

        $self->response( type => 'itl', file => 'manage/function/form' );
    }
    elsif ($self->{_step} == 1) {
        my $result = $self->_properties_action_hook;
        if ($result) {
            # TODO: have the properties action hook handle the profile
            #       processing of old, since we are no longer in a FormAction
            #       so need to have a return that will redirect back to
            #       where we were
        }

        my %params;
        @params{ @fields } = @$values{ @fields };
        $params{modified_by} = $self->{_user}->id;

        for my $field (@fields) {
            # clear empty dates so they become a NULL
            if (($field->type eq 'date') or ($field->type eq 'timestamp') or ($field->type eq 'integer')) {
                if ("$params{$field}" eq '') {
                    $params{$field} = undef;
                }
            }
        }

        # start a transaction, need this so that things
        # happening in the post action hook will be within
        # the same transaction, in case of an exception
        my $db = $_model_class->init_db;
        $db->begin_work;

        my $object;
        if ($cgi->{_properties_mode} eq 'edit') {
            my %pk_params;
            for my $_pk_field (@_pk_fields) {
                my ($key, $val) = ($_pk_field, $values->{$_pk_field});
                $key =~ s/^_pk_//;

                $pk_params{$key} = $val;
            }

            # TODO: do we still need to do things this way?

            my $save_object = $_model_class->new(
                db => $db,
                %pk_params,
            );
            
            unless ($save_object->load(speculative => 1)) {
                Fina::Corp::Exception->throw( 
                    sprintf(
                        'could not load a record from the database based on the PK values: %s', 
                        join(", ", map { sprintf("%s = %s", $_, $pk_params{$_}) } keys %pk_params)
                    )
                );
            }
            
            while ( my ($field, $value) = each %params ) {
                $save_object->$field($value);
            }
            
#            Fina::Corp::Exception->throw( printf("%s: <pre>%s</pre>", __LINE__, Dumper($save_object));
            $save_object->save( changes_only=> 1 );
#            my $num_rows_updated = $_model_class_mgr->update_objects(
#                db           => $db,
#                set          => { %params },
#                where        => [ %pk_params ],
#            );
#            unless ($num_rows_updated > 0) {
#                Fina::Corp::Exception->throw( 'Unable to update record based on PK values.' );
#            }
#            if ($num_rows_updated > 1) {
#                Fina::Corp::Exception->throw( 'Multiple rows updated when single primary key should match. SPEAK TO DEVELOPER!' );
#            }

            my %new_pk_params;
            for my $field (@pk_fields) {
                $new_pk_params{$field} = $values->{$field};
            }

            # instantiate the object with new primary key a) to make
            # sure everything is good, b) to use the object to redirect
            # to the new detail record
            
            # TODO: set a message that the record was updated
            #       to be displayed on the detail view
            
            $object = $_model_class->new(
                db => $db,
                %new_pk_params,
            );
            $object->load;
        }
        elsif ($cgi->{_properties_mode} eq 'add') {
            $params{created_by} = $self->{_user}->id;

            $object = $_model_class->new(
                db => $db,
                %params,
            );
            unless ($object) {
                Fina::Corp::Exception::ModelInstantiateFailure->throw( $_object_name );
            }
            $object->save;

            # TODO: set a message that the record was created
            #       to be displayed on the detail view
            
            # see if this load is needed when adding
            $object->load;
        }
        else {
            Fina::Corp::Exception->throw( "Unrecognized properties mode: $cgi->{_properties_mode}" );
        }

        if ($self->can('_properties_post_action_hook')) {
            $self->_properties_post_action_hook($object);
        }

        $db->commit;

        delete @$values{ @_pk_fields, @fields };

        unless ($self->_properties_referrer_no_override) {
            my $detail_url = $self->_object_manage_function_link( 'DetailView', $object, url_only => 1 );
            if ($detail_url) {
                $cgi->{redirect_referer} = $detail_url;
            }
        }

        $self->_referer_redirect_response;

        return;
    }
    else {
        Fina::Corp::Exception->throw( "Unrecognized step: $self->{_step}" );
    }

    return;
}

#
#
#
sub _common_properties_upload {
    my $self = shift;

    my $values = $self->{_controller}->{_values};
    my $cgi    = $self->{_controller}->{_cgi};

    my $_model_class     = $self->_model_class;
    my $_model_class_mgr = $self->_model_class_mgr;
    my $_object_name     = $self->_model_display_name;

    my @pk_fields  = @{ $_model_class->meta->primary_key_columns };
    my @_pk_fields = map { "_pk_$_" } @pk_fields;

    my $object = $self->_common_implied_object;

    # TODO: this needs to be improved to handle tree structure specification of resource handle
    unless (defined $cgi->{resource} and $cgi->{resource} ne '') {
        Fina::Corp::Exception->throw('Required argument missing: resource');
    }

    my $attr_refs;

    my $file_resource_obj = $_file_resource_model_class->new(
        id => $cgi->{resource},
    );
    unless ($file_resource_obj->load( speculative => 1 )) {
        Fina::Corp::Exception->throw("Can't load file resource obj: $cgi->{resource}");
    }

    my $attrs = $file_resource_obj->attrs;
    if (@$attrs) {
        $attr_refs = [];

        my $properties;

        my $file = $file_resource_obj->get_file_for_object( $object );
        if (defined $file) {
            $properties = $file->properties;
        }

        for my $attr (@$attrs) {
            my $ref = {
                id            => $attr->id,
                code          => $attr->code,
                kind          => $attr->kind_code,
                display_label => $attr->display_label,
            };

            if ($self->{_step} == 0) {
                if (defined $properties) {
                    for my $property (@$properties) {
                        if ($property->file_resource_attr_id == $attr->id) {
                            $ref->{value} = $property->value;
                            last;
                        }
                    }
                }
            }
            elsif ($self->{_step} == 1) {
                # retrieve attribute value from CGI space
                $ref->{value} = $cgi->{'_attr_' . $attr->id};
            }
            elsif ($self->{_step} == 2) {
                # retrieve attribute value from Session
                $ref->{value} = $self->{_controller}->{_scratch}->{_manage_upload_confirm_attrs}->{$attr->id};
            }

            push @$attr_refs, $ref;
        }
    }

    if ($self->{_step} == 0 or $self->{_step} == 1) {
        my $_pk_form_elements = [];
        for my $_pk_field (@_pk_fields) {
            push @$_pk_form_elements, { name => $_pk_field, value => $cgi->{$_pk_field} };
        }
        $self->{_controller}->tmp_scratch( _manage_form_pk_elements => [ $_pk_form_elements, undef, [ keys %{$_pk_form_elements->[0]} ] ] );

        if (defined $attr_refs) {
            $self->{_controller}->tmp_scratch(
                _manage_form_attributes_itl => [ $attr_refs, undef, [ keys %{ $attr_refs->[0] } ], ],
            );
        }
    }

    my $temporary_relative_path;
    my $temporary_path;
    if ($self->{_step} == 1 or $self->{_step} == 2) {
        $temporary_relative_path = File::Spec->catfile(
            'uncontrolled',
            '_manage_properties_upload',
            $object->meta->table,
            $object->serialize_pk,
            $file_resource_obj->sub_path( '_manage_properties_upload' ),
        );
        $temporary_path = File::Spec->catfile(
            $_file_model_class->_htdocs_path,
            $temporary_relative_path,
        );
    }

    if ($self->{_step} == 0) {
        #
        # TODO: check resource is required, already has file, has children descendents, etc.
        #
        $self->set_title("Upload $_object_name File ($cgi->{resource})", $object);

        if ($self->can('_properties_upload_form_hook')) {
            $self->_properties_upload_form_hook(
                object            => $object,
                file_resource_obj => $file_resource_obj,
            );
        }

        $values->{_step}     = $self->{_step} + 1;
        $values->{_function} = $self->{_function};

        $self->{_controller}->tmp_scratch( manage_function_form_enctype => 'multipart/form-data' );
        $self->{_controller}->tmp_scratch( _manage_form_include => "_common_properties_upload-$self->{_step}" );
        $self->{_controller}->tmp_scratch( _manage_form_referer => $ENV{HTTP_REFERER} );

        $self->response( type => 'itl', file => 'manage/function/form' );
    }
    elsif ($self->{_step} == 1) {
        my $file_contents = $::Tag->value_extended(
            {
                name          => 'uploaded_file',
                file_contents => 1,
            },
        );
        unless (length $file_contents) {
            Fina::Corp::Exception->throw('File has no contents');
        }

        my $contents_io = IO::Scalar->new(\$file_contents);
        my $mime_type   = File::MimeInfo::Magic::magic($contents_io);
        unless ($mime_type ne '') {
            Fina::Corp::Exception->throw('Unable to determine MIME type from file contents');
        }
        my $extension   = File::MimeInfo::extensions($mime_type);
        unless ($extension ne '') {
            Fina::Corp::Exception->throw("Unable to determine file extension from mimetype: $mime_type");
        }

        my $temporary_filename      = "tmp.$$.$extension";
        my $temporary_file          = File::Spec->catfile($temporary_path, $temporary_filename);
        my $temporary_relative_file = File::Spec->catfile($temporary_relative_path, $temporary_filename);

        umask 0002;

        File::Path::mkpath($temporary_path);

        open my $OUTFILE, ">$temporary_file" or die "Can't open file for writing: $!\n";
        binmode $OUTFILE;
        print $OUTFILE $file_contents;
        close $OUTFILE or die "Can't close written file: $!\n";

        if ($mime_type =~ /\Aimage/) {
            $self->{_controller}->tmp_scratch( _manage_upload_confirm_file => qq{<img src="/$temporary_relative_file" />} );
        }
        else {
            $self->{_controller}->tmp_scratch( _manage_upload_confirm_file => qq{<a href="/$temporary_relative_file"><img src="$_icon_path" /></a>} );
        }

        # store the attribute refs to the session for retrieval in step 2 for storage to the DB
        if (defined $attr_refs) {
            my $attr_values = {};
            for my $attr_ref (@$attr_refs) {
                $attr_values->{$attr_ref->{id}} = $attr_ref->{value};
            }

            $self->{_controller}->scratch( _manage_upload_confirm_attrs => $attr_values );
        }

        # TODO: need to walk children determining which need to be generated, etc.
        #       and provide back a list to allow them to choose to have them override

        $values->{_step}     = $self->{_step} + 1;
        $values->{_function} = $self->{_function};

        $self->{_controller}->tmp_scratch( _manage_upload_tmp_filename => $temporary_filename );
        $self->{_controller}->tmp_scratch( _manage_form_include        => "_common_properties_upload-$self->{_step}" );
        $self->{_controller}->tmp_scratch( _manage_form_referer        => $cgi->{redirect_referer} );

        $self->response( type => 'itl', file => 'manage/function/form' );
    }
    elsif ($self->{_step} == 2) {
        unless (defined $cgi->{tmp_filename} and $cgi->{tmp_filename} ne '') {
            Fina::Corp::Exception->throw('Required argument missing: tmp_filename');
        }

        my $tmp_filename_extension;
        if ($cgi->{tmp_filename} =~ /\A.+\.\d+\.(.+)\z/) {
            $tmp_filename_extension = $1;
        }
        else {
            Fina::Corp::Exception->throw("Unable to determine file extension from temporary filename: $cgi->{tmp_filename}");
        }

        my $db = $object->db;
        eval {
            $db->begin_work;

            my $user_id = $self->{_user}->id;

            my $file = $file_resource_obj->get_file_for_object( $object );
            if (defined $file) {
                $file->modified_by( $user_id );
                $file->save;
            }
            else {
                $file_resource_obj->add_files(
                    {
                        db          => $db,
                        object_pk   => $object->serialize_pk,
                        created_by  => $user_id,
                        modified_by => $user_id,
                    },
                );
                $file_resource_obj->save;

                $file = $file_resource_obj->get_file_for_object( $object );
            }

            if (defined $attr_refs) {
                # TODO: make this more advanced to do updates when possible

                my $new_properties = [];
                for my $attr_ref (@$attr_refs) {
                    push @$new_properties, {
                        file_resource_attr_id => $attr_ref->{id},
                        value                 => $attr_ref->{value} || '',
                        created_by            => $user_id,
                        modified_by           => $user_id,
                    };
                }
                $file->properties($new_properties);
                $file->save;
            }

            my $temporary_file = File::Spec->catfile($temporary_path, $cgi->{tmp_filename});
            $file->store( $temporary_file, extension => $tmp_filename_extension );
        };
        if ($@) {
            my $exception = $@;

            $db->rollback;

            die $exception;
        }

        $db->commit;

        $self->_referer_redirect_response;

        return;
    }
    else {
        Fina::Corp::Exception->throw( "Unrecognized step: $self->{_step}" );
    }

    return;
}

#
# TODO: add handling of file resources to drop files if the mixin is present
#
sub _common_drop {
    my $self = shift;
    
    my $_object_name = $self->_model_display_name;
    my $_model_class = $self->_model_class;
    my @pk_fields    = @{ $_model_class->meta->primary_key_columns };
    my @_pk_fields   = map { "_pk_$_" } @pk_fields;
    my $_controller  = $self->{_controller};
    my $cgi          = $_controller->{_cgi};
    my $values       = $_controller->{_values};

    my $object       = $self->_common_implied_object;

    $self->set_title("Drop $_object_name", $object);

    if ($self->{_step} == 0) {
        my $_pk_form_elements = [];
        for my $_pk_field (@_pk_fields) {
            push @$_pk_form_elements, { name => $_pk_field, value => $cgi->{$_pk_field} };
        }
        $_controller->tmp_scratch( _manage_form_pk_elements => [ $_pk_form_elements, undef, [ keys %{$_pk_form_elements->[0]} ] ] );

        if ($self->can('_drop_form_hook')) {
            $self->_drop_form_hook($object);
        }

        $values->{_step}     = $self->{_step} + 1;
        $values->{_function} = $self->{_function};

        $_controller->tmp_scratch( _manage_form_custom_object_name => $object->manage_description );
        $_controller->tmp_scratch( _manage_form_custom_object_type => $self->_model_display_name );
        $_controller->tmp_scratch( _manage_form_include            => "_common_drop-$self->{_step}" );
        $_controller->tmp_scratch( _manage_form_referer            => $ENV{HTTP_REFERER} );

        $self->response( type => 'itl', file => 'manage/function/form' );
    }
    elsif ($self->{_step} == 1) {
        if ($self->can('_drop_action_hook')) {
			$object->db->begin_work;
            $self->_drop_action_hook($object);
        }

        $values->{_step}     = $self->{_step} + 1;
        unless ($object->delete) {
            Fina::Corp::Exception->throw( "Failed to delete object: " . $object->error );
        }
		$object->db->commit;

        $self->_referer_redirect_response;
    }
    else {
        Fina::Corp::Exception->throw( "Unrecognized step: $self->{_step}" );
    }

    return;
}

#
#
#
sub _common_detail_view {
    my $self = shift;

    my $_model_class = $self->_model_class;
    my $_object_name = $self->_model_display_name;
    my @pk_fields    = @{ $_model_class->meta->primary_key_columns };
    my @fields       = @{ $_model_class->meta->columns };
    my $_controller  = $self->{_controller};

    my $object = $self->_common_implied_object;

    #Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({cgi=>$self->{_controller}->{_cgi}, _model_class=>$_model_class, pk_fields=>[map {ref} @pk_fields], _object_name=>$_object_name,self=>ref($self), object=>ref($object)}) . "</pre>");

    $self->set_title("$_object_name Detail", $object);

    # TODO: test to see if we still need to do stringification
    
    my $pk_settings = [];
    for my $pk_field (@pk_fields) {
        push @$pk_settings, { 
            # the following forces stringification
            # which was necessary to prevent an issue
            # where viewing the detail page caused 
            # the user to get logged out
            field => "$pk_field", 
            value => $object->$pk_field,
        };
    }
    if (@$pk_settings) {
        $_controller->tmp_scratch( _manage_detail_pk_settings => [ $pk_settings, undef, [ keys %{ $pk_settings->[0] } ] ] );
    }
     
    #Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({ cgi => $self->{_controller}->{_cgi}, _model_class => $_model_class, pk_settings => $pk_settings, _object_name=>$_object_name,self=>ref($self), object=>ref($object)}) . "</pre>");

    my @auto_fields = qw(date_created last_modified created_by modified_by);
    my $auto_settings = [];
    for my $field (@auto_fields) {
        my $value = $object->$field;
        if (($field eq 'created_by' or $field eq 'modified_by') and $value =~ /^\d+$/) {
            my $update_user = $_user_class->new( id => $value );
            if ($update_user and $update_user->load(speculative => 1)) {
                $value = $update_user->username;
            }
        }
        push @$auto_settings, { 
            # the following forces stringification
            # which was necessary to prevent an issue
            # where viewing the detail page caused 
            # the user to get logged out
            field => "$field", 
            value => $value,
        };
    }
    if (@$auto_settings) {
        $_controller->tmp_scratch( _manage_detail_auto_settings => [ $auto_settings, undef, [ keys %{ $auto_settings->[0] } ] ] );
    }

    #Fina::Corp::Exception->throw( Dumper($object) );
    my $other_settings = [];
    for my $field (sort @fields) {
        next if grep { $field eq $_ } @pk_fields, @auto_fields;
        
        my $value = ( ($object->isa('Fina::Corp::M::ContentItem::Value') and $field eq "value") ? "<pre>" . encode_utf8($object->$field) . "</pre>" : $object->$field );
        my $transform = "_detail_transform_$field"; 
        if ($self->can($transform)) {
            $value = $self->$transform($object);
        }
        push @$other_settings, { 
            # the following forces stringification
            # which was necessary to prevent an issue
            # where viewing the detail page caused 
            # the user to get logged out
            field => "$field", 
            #value => $object->$field,
            value => $value,
			}
    }
    if (@$other_settings) {
        $_controller->tmp_scratch( _manage_detail_other_settings => [ $other_settings, undef, [ keys %{ $other_settings->[0] } ] ] );
    }

    my $object_display_name = $self->_model_display_name;

    my $action_links = [];

    if (defined $self->_parent_manage_class) {
        unless (defined $self->_parent_model_link_field) {
            Fina::Corp::Exception->throw('_parent_manage_class defined without _parent_model_link_field set');
        }
        
        my $package = $self->_parent_manage_class;
        eval "use $package";
        if ($@) {
            warn "Can't load $package to generate parent link in common detail view\n";
        }
        else {
            my $method  = $self->_parent_model_link_field;

            push @$action_links, {
                html_link => $package->_object_manage_function_link(
                    'DetailView',
                    $object->$method,
                    label => 'Go to Parent',
                    user  => $self->{_user},
                ),
            };
        }
    }

    push @$action_links, { html_link => $self->_object_manage_function_link('Properties', $object, label => "Edit $object_display_name") };
    push @$action_links, { html_link => $self->_object_manage_function_link('Drop', $object, label => "Drop $object_display_name") };

    if ($self->can('_detail_generic_hook')) {
        my $content = { 
            highest_left => [],
            left         => [],
            right        => [],
            bottom       => [],
            action_links => $action_links,
        };
        my $result = $self->_detail_generic_hook($object, $content);
        if ($result) {
            Fina::Corp::Exception->throw("Hook returned error: $result");
        }
        $_controller->tmp_scratch( _manage_detail_generic_hook_top_left_content     => join '', @{$content->{left}} );
        $_controller->tmp_scratch( _manage_detail_generic_hook_highest_left_content => join '', @{$content->{highest_left}} );
        $_controller->tmp_scratch( _manage_detail_generic_hook_top_right_content    => join '', @{$content->{right}} );
        $_controller->tmp_scratch( _manage_detail_generic_hook_content              => join '', @{$content->{bottom}} );
    }

    # turn list of links into loop ready list
    if (@$action_links) {
        $_controller->tmp_scratch( _manage_detail_action_links => [ $action_links, undef, [ keys %{$action_links->[0]} ] ] );
    }
    else {
        $_controller->tmp_scratch( _manage_detail_action_links => undef );
    }

	#my $xx = { file_resource_objs => [$object->get_file_resource_objs] };
    #unless (UNIVERSAL::can($object, 'get_file')) {
    	#Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({ cgi => $self->{_controller}->{_cgi}, _model_class => $_model_class, pk_settings => $pk_settings, _object_name=>$_object_name,self=>ref($self), object=>ref($object), xx => $xx}) . "</pre>");
	#}

    if (UNIVERSAL::can($object, 'get_file')) {
        my $has_privs = 0;
        $has_privs = 1 if $self->{_user}->is_authorized( $self->_func_prefix . 'Properties' );

        my $file_resources_itl = [];


        my $file_resource_objs = $object->get_file_resource_objs;
        for my $file_resource_obj (@$file_resource_objs) {
            my $file_resource_itl = {
                id      => $file_resource_obj->id,
                display => $file_resource_obj->lookup_value,
            };

            my $file = $file_resource_obj->get_file_for_object( $object );

    		#Fina::Corp::Exception->throw(__LINE__."<pre>" . ::uneval({ object => $self->_obj($object), file_resource_obj => $self->_obj($file_resource_obj), file => $self->_obj($file), file_url => $file->url_path}) . "</pre>");

            my $properties;
            if (defined $file) {
                $properties = $file->properties;
            }

            my $attr_refs;
            for my $attr (@{ $file_resource_obj->attrs }) {
                my $attr_ref = {
                    display_label => $attr->display_label,
                };
                if (defined $properties) {
                    for my $property (@$properties) {
                        if ($property->file_resource_attr_id == $attr->id) {
                            $attr_ref->{value} = $property->value;
                        }
                    }
                }

                push @$attr_refs, $attr_ref;
            }
            if (defined $attr_refs) {
                $file_resource_itl->{attrs_itl} = [ $attr_refs, undef, [ keys %{ $attr_refs->[0] } ] ];
            }

            my $link_text;
            if (defined $file) {
                my $url_path = $file->url_path;
                if ($file->get_mimetype =~ /\Aimage/) {
                    $file_resource_itl->{url}  = qq{<img src="$url_path" />};
                }
                else {
                    $file_resource_itl->{url}  = qq{<a href="$url_path"><img src="$_icon_path" /></a>};
                }

                $link_text = 'Replace';


                if ($has_privs) {
                    $file_resource_itl->{drop_link} = $self->_object_manage_function_link(
                        'Properties',
                        $object,
                        label     => 'Drop',
                        addtl_cgi => {
                            _properties_mode => 'drop',
                            resource         => $file_resource_itl->{id},
                        },
                    );
            }
            }
            else {
                $link_text = 'Upload';
            }

            if ($has_privs) {
                $file_resource_itl->{link} = $self->_object_manage_function_link(
                    'Properties',
                    $object,
                    label     => $link_text,
                    addtl_cgi => {
                        _properties_mode => 'upload',
                        resource         => $file_resource_itl->{id},
                    },
                );
            }



            push @$file_resources_itl, $file_resource_itl;
        }

        $_controller->tmp_scratch( _manage_detail_file_resources => [ $file_resources_itl, undef, [ keys %{ $file_resources_itl->[0] } ] ] );
    }

    $self->response( type => 'itl', file => 'manage/function/detail_view' );

    return 1;
}

##########################################################################################################
# Input  : Rose object
# Action : Strip off all 'Rosy' attributes (those starting with _*, and those that are other objects)
# Output : just the table field values after removing all the bells and whistles + the class anme
#
sub _obj {
    my $self = shift;

    my $obj = shift;

	return {
		class => ref($obj),
		attributes => {map {$_ => $obj->{$_}} grep {!ref $obj->{$_}} grep {! /^_/} keys %$obj}
	};
}

#
#
#
sub _common_properties_drop {
    my $self = shift;

    my $values = $self->{_controller}->{_values};
    my $cgi    = $self->{_controller}->{_cgi};

    my $_model_class     = $self->_model_class;
    my $_model_class_mgr = $self->_model_class_mgr;
    my $_object_name     = $self->_model_display_name;

    my @pk_fields  = @{ $_model_class->meta->primary_key_columns };
    my @_pk_fields = map { "_pk_$_" } @pk_fields;

    my $object = $self->_common_implied_object;

    # TODO: this needs to be improved to handle tree structure specification of resource handle
    unless (defined $cgi->{resource} and $cgi->{resource} ne '') {
        Fina::Corp::Exception->throw('Required argument missing: resource');
    }

    my $attr_refs;

    my $file_resource_obj = $_file_resource_model_class->new(
        id => $cgi->{resource},
    );
    unless ($file_resource_obj->load( speculative => 1 )) {
        Fina::Corp::Exception->throw("Can't load file resource obj: $cgi->{resource}");
    }
    my $file = $file_resource_obj->get_file_for_object( $object );

    if ($self->{_step} == 0 or $self->{_step} == 1) {
        my $_pk_form_elements = [];
        for my $_pk_field (@_pk_fields) {
            push @$_pk_form_elements, { name => $_pk_field, value => $cgi->{$_pk_field} };
        }
        $self->{_controller}->tmp_scratch( _manage_form_pk_elements => [ $_pk_form_elements, undef, [ keys %{$_pk_form_elements->[0]} ] ] );
    }

    if ($self->{_step} == 0) {
        $self->set_title("Drop $_object_name File ($cgi->{resource})", $object);

        $values->{_step}     = $self->{_step} + 1;
        $values->{_function} = $self->{_function};

        if (defined $file) {
            my $url_path = $file->url_path;
            if ($file->get_mimetype =~ /\Aimage/) {
                $self->{_controller}->tmp_scratch( manage_drop_file  => qq{<img src="$url_path" />} );
            }
            else {
                $self->{_controller}->tmp_scratch( manage_drop_file  => qq{<a href="$url_path"><img src="$_icon_path" /></a>} );
            }
        }

        $self->{_controller}->tmp_scratch( manage_function_form_enctype => 'multipart/form-data' );
        $self->{_controller}->tmp_scratch( _manage_form_include => "_common_properties_drop-$self->{_step}" );
        $self->{_controller}->tmp_scratch( _manage_form_referer => $ENV{HTTP_REFERER} );

        $self->response( type => 'itl', file => 'manage/function/form' );
    }
    elsif ($self->{_step} == 1) {
        my $db = $object->db;
        eval {
            $db->begin_work;

            my $user_id = $self->{_user}->id;

            my $file = $file_resource_obj->get_file_for_object( $object );
            if (defined $file) {
                my $properties = $file->properties;
                for my $property (@$properties) {
                    $property->delete;
                }
                $file->delete;
            }
            else {
                Fina::Corp::Exception->throw('Can\'t find file-object ' . $object->id . ' for resource ' . $file_resource_obj->id);
            }

        };
        if ($@) {
            my $exception = $@;
            $db->rollback;
            die $exception;
        }
        $db->commit;
        $self->_referer_redirect_response;
        return;
    }
    else {
        Fina::Corp::Exception->throw( "Unrecognized step: $self->{_step}" );
    }

    return;
}

sub tmp_scratch {
    my $self = shift;
    
    return $self->{_controller}->tmp_scratch(@_); 
}

sub _log_caller {
    my %caller;
        
    @caller{qw(
        package 
        filename 
        line 
        subroutine 
        hasargs 
        wantarray 
        evaltext 
        is_require 
        hints 
        bitmask 
        hinthash)} = caller(1);

    my $pkg = (ref $_[0] || $_[0]);
    
    if ( $caller{subroutine} =~ m/^$pkg/ ) {
        shift;
    }     
    
    $_[0] ||= 'Started';
    
    #::logDebug('%s %s', $caller{subroutine}, join(", ", @_)); 
}

#
#
#
sub _user_entitlement_stringify {
    my $self = shift;

	my $users = shift;

	my $fmt = "%4s %7s %-32s %-22s %6s %-7s %6s %6s";
	my $out = sprintf("<br>$fmt<br>", qw(slno user_id user_name role client company branch location));

	my $n;
	my %seen;

	USER:
	for my $user (@$users) {
		$n++;
		my $roles_map;
		unless ($roles_map = $user->roles_map) {
			$out .= sprintf("$fmt<br>", $n, $user->id, $user->username, "NONE");
			next USER;
		}
		for my $role_map (@$roles_map) {
			my $role_code = $role_map->role_code;

			unless ($role_map->client_restricted) {
				$out .= sprintf("$fmt<br>", $n, $user->id, $user->username, $role_map->role_code, "ALL");
				next USER;
			}

			my $user_role_client_maps;
			unless ($user_role_client_maps = $role_map->user_role_client_maps) {
				$out .= sprintf("$fmt<br>", $n, $user->id, $user->username, $role_map->role_code, "ERROR - No entitled clients");
				next USER;
			}
			for my $user_role_client_map (@$user_role_client_maps) {
				unless ($user_role_client_map->company_restricted) {
					$out .= sprintf("$fmt<br>", $n, $user->id, $user->username, $role_map->role_code, $user_role_client_map->client_id, "ALL");
					next USER;
				}

				my $user_role_client_company_maps;
				unless ($user_role_client_company_maps = $user_role_client_map->user_role_client_company_maps) {
					$out .= sprintf("$fmt<br>", $n, $user->id, $user->username, $role_map->role_code, $user_role_client_map->client_id, "ERROR - No entitled companies");
					next USER;
				}
				for my $user_role_client_company_map (@$user_role_client_company_maps) {
					if ($seen{$user->id}++) {
						$out .= sprintf("$fmt<br>", "", "", "", $role_map->role_code, $user_role_client_map->client_id, $user_role_client_company_map->company_code);
					} else {
						$out .= sprintf("$fmt<br>", $n, $user->id, $user->username, $role_map->role_code, $user_role_client_map->client_id, $user_role_client_company_map->company_code);
					}
				}

			}

		}
	}

	return $out;
}

#
#
#
sub _make_scratch_drop_down {
    my $self = shift;
    my %parms = @_;

	my $class_mgr			= $parms{_class_mgr};
	my $scratch_key			= $parms{_scratch_key};
	my $get_value_method	= $parms{_get_value_method}		|| "id";
	my $get_display_method	= $parms{_get_display_method}	|| "dropdown_display";
	my $select_fk			= $parms{_select_fk};
	my $eq					= $parms{_eq}					|| "==";
	my $sort_by				= $parms{_sort_by}				|| ''; # key|display
	my $get_object_parms	= $parms{_get_object_parms}		|| {};

    
	# Example:
	#
	# $class_mgr			= "Fina::Corp::M::Client::Company::Configuration::Subroutine::Manager";
	# $scratch_key			= "_manage_form_CCC_Subroutine_list"; #ITL
	# $get_value_method		= "id";
	# $get_display_method	= "name";
	# $select_fk			= "subroutine_id";
	# $eq					= "eq";
	# $sort_by				= "key";
	# $get_object_parms		= {sort_by => 'name'};
    
    my $values = $self->{_controller}->{_values};
    
    # ::logDebug($class_mgr->get_objects_sql(%$get_object_parms));

    my $_scratch_array = [];
    for my $_obj ( @{ $class_mgr->get_objects(%$get_object_parms) }) {
       	my $selected;
        if ($eq eq "==") {
        	$selected = (defined $values->{$select_fk} and $values->{$select_fk} == $_obj->$get_value_method) ? 1 : 0;
		} else {
        	$selected = (defined $values->{$select_fk} and $values->{$select_fk} eq $_obj->$get_value_method) ? 1 : 0;
		}
        push @$_scratch_array, {
            value       => $_obj->$get_value_method,
            selected    => ( $selected ?  ' selected="selected"' : '' ),
            display     => $_obj->$get_display_method,
        };
    }

	if ($sort_by and length($sort_by)) {
        $sort_by = "value" if $sort_by eq 'key';
        my $non_numeric = grep { /\D/ } map {$_->{$sort_by}} @$_scratch_array;
        if ( $non_numeric ) {
        	@$_scratch_array = sort { $a->{$sort_by} cmp $b->{$sort_by} } @$_scratch_array;
		} else {
        	@$_scratch_array = sort { $a->{$sort_by} <=> $b->{$sort_by} } @$_scratch_array;
		}
	}

    $self->{_controller}->tmp_scratch( $scratch_key => [
        $_scratch_array,
        undef,
        [ keys %{ $_scratch_array->[0] } ],
    ]);
    
    return;
}

sub make_loop_list {
    my $self = shift;
    my $array = shift;
    return Fina::Corp::C->make_loop_list($array);
}

1;

__END__
