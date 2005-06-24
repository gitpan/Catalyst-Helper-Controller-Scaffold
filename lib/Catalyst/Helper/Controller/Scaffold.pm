package Catalyst::Helper::Controller::Scaffold;

use strict;
use Path::Class;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Helper::Controller::Scaffold - Helper for Scaffolding

=head1 SYNOPSIS

    # Imagine you want to generate a scaffolding controller MyApp::C::SomeTable
    # for a CDBI table class MyApp::M::CDBI::SomeTable
    script/myapp_create.pl controller SomeTable Scaffold CDBI::SomeTable

=head1 DESCRIPTION

Helper for Scaffolding.

Templates are TT so you'll need a TT View Component and a forward in
your end action too.

Note that you have to add these lines to your CDBI class...

    use Class::DBI::AsForm;
    use Class::DBI::FromForm;

...and these to your application class, to load the FormValidator plugin.

    use Catalyst qw/FormValidator/;

=head1 METHODS

=over 4

=item mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper, $table_class ) = @_;
    $helper->{table_class} = $helper->{app} . '::M::' . $table_class;
    my $file = $helper->{file};
    my $dir = dir( $helper->{base}, 'root', $helper->{prefix} );
    $helper->mk_dir($dir);
    $helper->render_file( 'compclass', $file );
    $helper->render_file( 'add',       file( $dir, 'add.tt' ) );
    $helper->render_file( 'edit',      file( $dir, 'edit.tt' ) );
    $helper->render_file( 'list',      file( $dir, 'list.tt' ) );
    $helper->render_file( 'view',      file( $dir, 'view.tt' ) );
}

=back

=head1 AUTHOR

Sebastian Riedel

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::Base';

__PACKAGE__->config( table_class => '[% table_class %]' );

=head1 NAME

[% class %] - Scaffolding Controller Component

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Scaffolding Controller Component.

=head1 METHODS

=over 4

=item add

Sets a template.

=cut

sub add : Local {
    my ( $self, $c ) = @_;
    $c->stash->{prefix} = '[% uri %]';
    $c->stash->{table_class} = $self->{table_class};
    $c->stash->{template} = '[% prefix %]/add.tt';
}

=item default

Forwards to list.

=cut

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('list');
}

=item destroy

Destroys a row and forwards to list.

=cut

sub destroy : Local {
    my ( $self, $c, $id ) = @_;
    $self->{table_class}->retrieve($id)->delete;
    $c->forward('list');
}

=item do_add

Adds a new row to the table and forwards to list.

=cut

sub do_add : Local {
    my ( $self, $c ) = @_;
    $c->form( optional => [ $self->{table_class}->columns ] );
    $self->{table_class}->create_from_form( $c->form );
    $c->forward('list');
}

=item do_edit

Edits a row and forwards to edit.

=cut

sub do_edit : Local {
    my ( $self, $c, $id ) = @_;
    $c->form( optional => [ $self->{table_class}->columns ] );
    $self->{table_class}->retrieve($id)->update_from_form( $c->form );
    $c->forward('edit');
}

=item edit

Sets a template.

=cut

sub edit : Local {
    my ( $self, $c, $id ) = @_;
    $c->stash->{prefix} = '[% uri %]';
    $c->stash->{item} = $self->{table_class}->retrieve($id);
    $c->stash->{template} = '[% prefix %]/edit.tt';
}

=item list

Sets a template.

=cut

sub list : Local {
    my ( $self, $c ) = @_;
    $c->stash->{prefix} = '[% uri %]';
    $c->stash->{table_class} = $self->{table_class};
    $c->stash->{template} = '[% prefix %]/list.tt';
}

=item view

Fetches a row and sets a template.

=cut

sub view : Local {
    my ( $self, $c, $id ) = @_;
    $c->stash->{prefix} = '[% uri %]';
    $c->stash->{item} = $self->{table_class}->retrieve($id);
    $c->stash->{template} = '[% prefix %]/view.tt';
}

=back

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
__add__
[% TAGS [- -] %]
[% USE table_class = Class(table_class) %]
<form action="[% base _ prefix _ '/do_add' %]" method="post">
    [% FOR column = table_class.columns %]
        [% NEXT IF column == table_class.primary_column %]
        [% column %]<br/>
        [% table_class.to_field(column).as_XML %]<br/>
    [% END %]
    <input type="submit" value="Add"/>
<form/>
<br/>
<a href="[% base _ prefix _ '/list' %]">List</a>
__edit__
[% TAGS [- -] %]
<form action="[% base _ prefix _ '/do_edit/' _ item.id %]"
    method="post">
    [% FOR column = item.columns %]
        [% NEXT IF column == item.primary_column %]
        [% column %]<br/>
        [% item.to_field(column).as_XML %]<br/>
    [% END %]
    <input type="submit" value="Edit"/>
<form/>
<br/>
<a href="[% base _ prefix _ '/list' %]">List</a>
__list__
[% TAGS [- -] %]
[% USE table_class = Class(table_class) %]
<table>
    <tr>
    [% primary = table_class.primary_column %]
    [% FOR column = table_class.columns %]
        [% NEXT IF column == primary %]
        <th>[% column %]</th>
    [% END %]
        <th/>
    </tr>
    [% FOR object = table_class.retrieve_all %]
        <tr>
        [% FOR column = table_class.columns.list %]
            [% NEXT IF column == primary %]
            <td>[% object.$column %]</td>
        [% END %]
            <td>
                <a href="[% base _ prefix _ '/view/' _ object.$primary %]">
                    View
                </a>
                <a href="[% base _ prefix _ '/edit/' _ object.$primary %]">
                    Edit

                </a>
                <a href="[% base _ prefix _ '/destroy/' _ object.$primary %]">
                    Destroy
                </a>
            </td>
        </tr>
    [% END %]
</table>
<a href="[% base _ prefix _ '/add' %]">Add</a>
__view__
[% TAGS [- -] %]
[% FOR column = item.columns %]
    [% NEXT IF column == item.primary_column %]
    <b>[% column %]</b><br/>
    [% item.$column %]<br/><br/>
[% END %]
<a href="[% base _ prefix _ '/list' %]">List</a>
