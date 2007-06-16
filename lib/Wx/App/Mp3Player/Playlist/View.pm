package Wx::App::Mp3Player::Playlist::View;

use strict;
use base qw(Wx::Perl::EntryList::VirtualListCtrlView Wx::Spice::Service::Base);

use Wx qw(:listctrl :window WXK_DELETE);
use Wx::Event qw(EVT_SIZE EVT_LIST_KEY_DOWN);

__PACKAGE__->mk_accessors( qw(model) );

sub service_name { 'playlist_view' }

sub new {
    my( $class, $parent, $model ) = @_;
    my $m = Wx::App::Mp3Player::Playlist::Model->new( { data => $model } );
    my $self = $class->SUPER::new( $model, $m, $parent,
                                   wxSUNKEN_BORDER|wxLC_SINGLE_SEL );
    $self->model( $model );
    $self->SetDropTarget( Wx::App::Mp3Player::FileDropper->new( $self ) );
    $self->InsertColumn( 0, "File" );
    $self->InsertColumn( 1, "Duration" );

    EVT_LIST_KEY_DOWN( $self, $self, \&_key_down );
    EVT_SIZE( $self, sub {
                  my $width = $_[1]->GetSize->x - 20;
                  $self->SetColumnWidth( 0, $width - 70 );
                  $self->SetColumnWidth( 1, 70 );
                  $_[1]->Skip;
              } );

    $self->support_dnd;
    $self->refresh;

    return $self;
}

sub _key_down {
    my( $self, $event ) = @_;

    return unless $event->GetKeyCode == WXK_DELETE;
    my $item = $event->GetIndex || $self->GetNextItem( -1, wxLIST_NEXT_ALL,
                                                       wxLIST_STATE_SELECTED );
    return if $item < 0;
    $self->list->delete_entry( $item );
}

sub add_files {
    my( $self, $x, $y, $files ) = @_;
    my $index = $self->_entry( $x, $y );

    return if $index < 0;
    $self->list->add_files_at( $index, $files );
}

sub get_selected_file {
    my( $self ) = @_;
    my $selection = $self->GetSelection;

    return $selection >= 0 ? $selection : 0;
}

package Wx::App::Mp3Player::FileDropper;

use Wx::DND;

use strict;
use base qw(Wx::FileDropTarget Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(playlist_view) );

sub new {
    my( $class, $playlist ) = @_;
    my $self = $class->SUPER::new;

    $self->{playlist_view} = $playlist;

    return $self;
}

sub OnDropFiles {
    my( $self, $x, $y, $files ) = @_;

    utf8::decode( $_ ) foreach @$files;
    $self->playlist_view->add_files( $x, $y, $files );
}

package Wx::App::Mp3Player::Playlist::Model;

use strict;
use base qw(Wx::Perl::ListView::Model Class::Accessor::Fast);

use File::Basename qw();

__PACKAGE__->mk_ro_accessors( qw(data) );

sub get_item {
    my( $self, $row, $column ) = @_;
    my $info = $self->data->get_entry_info( $row );

    if( $column == 0 ) {
        return { string =>    $info->title
                           || File::Basename::basename( $info->file )
                 };
    } elsif( $column == 1 ) {
        return { string => $info->time };
    }
}

sub get_item_count { $_[0]->data->count }

1;
