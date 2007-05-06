package Wx::App::Mp3Player::Playlist::View;

use strict;
# FIXME hack!
use base qw(Wx::Perl::ListView Wx::Perl::ListCtrl Class::Accessor::Fast);

use Wx qw(:listctrl :window WXK_DELETE);
use Wx::Event qw(EVT_SIZE EVT_LIST_BEGIN_DRAG EVT_LIST_KEY_DOWN
                 EVT_LEFT_UP);

__PACKAGE__->mk_accessors( qw(model) );

sub new {
    my( $class, $parent, $model ) = @_;
    my $m = Wx::App::Mp3Player::Playlist::Model->new( { data => $model } );
    my $self = $class->SUPER::new( $m, $parent, -1, [-1, -1], [-1, -1],
                                   wxSUNKEN_BORDER|wxLC_SINGLE_SEL );
    $self->model( $model );
    $self->SetDropTarget( Wx::App::Mp3Player::FileDropper->new( $self ) );
    $self->InsertColumn( 0, "File" );
    $self->InsertColumn( 1, "Duration" );
    $self->refresh;

    EVT_LIST_BEGIN_DRAG( $self, $self, \&_begin_drag );
    EVT_LIST_KEY_DOWN( $self, $self, \&_key_down );
    EVT_SIZE( $self, sub {
                  my $width = $_[1]->GetSize->x - 20;
                  $self->SetColumnWidth( 0, $width - 70 );
                  $self->SetColumnWidth( 1, 70 );
                  $_[1]->Skip;
              } );

    return $self;
}

sub _begin_drag {
    my( $self, $event ) = @_;
    $self->{dragging} = 1;
    $self->{drag_index} = $event->GetIndex;
    EVT_LEFT_UP( $self, \&_end_drag );
}

sub _end_drag {
    my( $self, $event ) = @_;
    EVT_LEFT_UP( $self, undef );

    return unless $self->{dragging};
    $self->{dragging} = 0;
    my $to = $self->_entry( $event->GetX, $event->GetY );
    return if $to < 0;

    $self->move_entry( $self->{drag_index}, $to );
}

sub _key_down {
    my( $self, $event ) = @_;

    return unless $event->GetKeyCode == WXK_DELETE;
    my $item = $event->GetIndex || $self->GetNextItem( -1, wxLIST_NEXT_ALL,
                                                       wxLIST_STATE_SELECTED );
    return if $item < 0;
    $self->model->delete_entry( $item );
    $self->refresh;
}

sub _entry {
    my( $self, $x, $y ) = @_;
    my( $item, $flags ) = $self->HitTest( [$x, $y] );

    if( $item < 0 || $flags & wxLIST_HITTEST_NOWHERE ) {
        return $self->GetItemCount;
    } elsif( $flags & wxLIST_HITTEST_ONITEM ) {
        return $item;
    } else {
        return -1;
    }
}

sub move_entry {
    my( $self, $from, $to ) = @_;

    $self->model->move_entry( $from, $to );
    my( $start, $end ) = sort { $a <=> $b } $from, $to;
    $end = $self->GetItemCount - 1 if $end >= $self->GetItemCount;
    $self->refresh( $start, $end );
}

sub add_files_at {
    my( $self, $index, $files ) = @_;

    $self->model->add_entries_at( $index, $files );
    $self->refresh;
}

sub add_files {
    my( $self, $x, $y, $files ) = @_;
    my $index = $self->_entry( $x, $y );

    return if $index < 0;
    $self->add_files_at( $index, $files );
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
