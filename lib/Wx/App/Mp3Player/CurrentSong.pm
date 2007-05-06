package Wx::App::Mp3Player::CurrentSong;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(progress title_or_file artist_album) );

use Wx qw(:sizer);
use File::Basename qw(basename);

sub new {
    my( $class, $parent, $player ) = @_;
    my $self = $class->SUPER::new( $parent );

    $self->{progress} = Wx::StaticText->new( $self, -1, '0:00' );
    $self->{title_or_file} = Wx::StaticText->new( $self, -1, 'No title' );
    $self->{artist_album} = Wx::StaticText->new
      ( $self, -1, 'Unknown artist - Unknown album' );

    my $sz = Wx::BoxSizer->new( wxVERTICAL );
    my $r1 = Wx::BoxSizer->new( wxHORIZONTAL );
    my $r2 = Wx::BoxSizer->new( wxHORIZONTAL );

    $r1->Add( $self->progress, 1, wxALL, 3 );
    $r1->Add( $self->title_or_file, 5, wxALL, 3 );
    $r2->Add( $self->artist_album, 1, wxALL, 3 );

    $sz->Add( $r1, 0, wxGROW );
    $sz->Add( $r2, 0, wxGROW );

    $self->SetSizer( $sz );

    $player->add_subscriber( 'new_song', $self, '_start' );
    $player->add_subscriber( 'progress', $self, '_progress' );

    return $self;
}

sub _start {
    my( $self, $player, $event, %params ) = @_;
    my $title_or_file = $params{title} || basename( $params{file} );
    my $artist_album = ( $params{artist} || 'Unknown artist' ) . ' - ' .
                       ( $params{album} || 'Unknown album' );
    $self->progress->SetLabel( '0:00' );
    $self->title_or_file->SetLabel( $title_or_file );
    $self->artist_album->SetLabel( $artist_album );
}

sub _progress {
    my( $self, $player, $event, %params ) = @_;
    my $time = int( $params{elapsed_time} );
    my( $min, $sec ) = ( int( $time / 60 ), $time % 60 );

    $self->progress->SetLabel( sprintf '%d:%02d', $min, $sec );
}

1;
