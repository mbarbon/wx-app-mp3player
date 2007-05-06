package Wx::App::Mp3Player;

use Wx;

use strict;
use base qw(Wx::Frame Class::Accessor::Fast);

our $VERSION = '0.01';

use Wx qw(:sizer);
use Wx::Event qw(EVT_BUTTON);
use Wx::App::Mp3Player::ProgressBar;
use Wx::App::Mp3Player::CurrentSong;
use Wx::App::Mp3Player::Mpg123Player;
use Wx::App::Mp3Player::Playlist::Data;
use Wx::App::Mp3Player::Playlist::View;

__PACKAGE__->mk_ro_accessors( qw(playlist playlist_view player progress
                                 current) );

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new( undef, -1, 'MyPlayer' );

    $self->{playlist} = Wx::App::Mp3Player::Playlist::Data->new;
    $self->{playlist_view} = Wx::App::Mp3Player::Playlist::View
                                 ->new( $self, $self->playlist );
    $self->{player} = Wx::App::Mp3Player::Mpg123Player->new( $self->playlist );
    $self->{progress} = Wx::App::Mp3Player::ProgressBar
                            ->new( $self, $self->player );
    $self->{current} = Wx::App::Mp3Player::CurrentSong
                            ->new( $self, $self->player );

    my $play = Wx::Button->new( $self, -1, "Play" );
    my $stop = Wx::Button->new( $self, -1, "Stop" );
    my $prev = Wx::Button->new( $self, -1, "<<" );
    my $next = Wx::Button->new( $self, -1, ">>" );

    EVT_BUTTON( $self, $play, \&_on_play );
    EVT_BUTTON( $self, $stop, sub { $self->player->stop } );
    EVT_BUTTON( $self, $prev, sub { $self->player->previous } );
    EVT_BUTTON( $self, $next, sub { $self->player->next } );

    my $sz = Wx::BoxSizer->new( wxVERTICAL );
    my $sz2 = Wx::BoxSizer->new( wxHORIZONTAL );
    $sz2->Add( $play, 0, wxALL, 3 );
    $sz2->Add( $stop, 0, wxALL, 3 );
    $sz2->Add( $prev, 0, wxALL, 3 );
    $sz2->Add( $next, 0, wxALL, 3 );
    $sz->Add( $self->current, 0, wxGROW|wxALL, 3 );
    $sz->Add( $sz2, 0, wxGROW );
    $sz->Add( $self->progress, 0, wxGROW|wxALL, 3 );
    $sz->Add( $self->playlist_view, 1, wxGROW|wxALL, 3 );

    $self->SetSizerAndFit( $sz );

    return $self;
}

sub _on_play {
    my( $self, $event ) = @_;
    my $selection = $self->playlist_view->GetSelection;
    $selection = 0 if $selection < 0;

    $self->player->play( $selection );
}

1;

__DATA__

=head1 NAME

Wx::App::Mp3Player - a simple MP3 player

=cut
