package Wx::App::Mp3Player;

use Wx;

use strict;
use base qw(Wx::Frame Class::Accessor::Fast);

our $VERSION = '0.01';

use Wx qw(:sizer);
use Wx::Event qw(EVT_BUTTON EVT_CLOSE);
use Wx::Spice::Plugin qw(:plugin);
use Wx::Spice::ServiceManager;
use Wx::Spice::ServiceManager::Holder;
use Wx::Spice::Service::SizeKeeper;
use Wx::Spice::Service::CommandManager;
use Wx::Spice::UI::Events qw(EVT_SPICE_BUTTON EVT_SPICE_UPDATE_UI);
use Wx::App::Mp3Player::Configuration;
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

    my $sm = $self->service_manager( Wx::Spice::ServiceManager->new );
    $self->service_manager->initialize;
    $self->service_manager->load_configuration;

    $self->{playlist} = Wx::App::Mp3Player::Playlist::Data->new;
    $self->{playlist_view} = Wx::App::Mp3Player::Playlist::View
                                 ->new( $self, $self->playlist );
    $self->{player} = Wx::App::Mp3Player::Mpg123Player->new( $self->playlist );
    $self->{progress} = Wx::App::Mp3Player::ProgressBar
                            ->new( $self, $self->player );
    $self->{current} = Wx::App::Mp3Player::CurrentSong
                            ->new( $self, $self->player );

    $sm->add_service( $self->playlist_view );
    $sm->add_service( $self->player );

    my $play = Wx::Button->new( $self, -1, "Play" );
    my $stop = Wx::Button->new( $self, -1, "Stop" );
    my $prev = Wx::Button->new( $self, -1, "<<" );
    my $next = Wx::Button->new( $self, -1, ">>" );

    EVT_SPICE_BUTTON( $self, $play, $sm, 'play_song' );
    EVT_SPICE_BUTTON( $self, $stop, $sm, 'player_stop' );
    EVT_SPICE_BUTTON( $self, $prev, $sm, 'player_previous' );
    EVT_SPICE_BUTTON( $self, $next, $sm, 'player_next' );
    EVT_SPICE_UPDATE_UI( $self, $stop, $sm, 'player_stop' );
    EVT_SPICE_UPDATE_UI( $self, $prev, $sm, 'player_previous' );
    EVT_SPICE_UPDATE_UI( $self, $next, $sm, 'player_next' );
    EVT_CLOSE( $self, \&_on_close );

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
    $self->window_size_keeper_service->register_window( 'frame', $self );

    return $self;
}

sub commands : Command {
    return
      ( play_song    => { sub => \&_on_play },
        );
}

sub _on_play {
    my( $self, $sm ) = @_;
    my $selection = $sm->get_service( 'playlist_view' )->get_selected_file;

    $sm->get_service( 'player' )->play( $selection );
}

sub _on_close {
    my( $self, $event ) = @_;

    $self->service_manager->finalize;
    $self->Destroy;
}

1;

__DATA__

=head1 NAME

Wx::App::Mp3Player - a simple MP3 player

=cut
