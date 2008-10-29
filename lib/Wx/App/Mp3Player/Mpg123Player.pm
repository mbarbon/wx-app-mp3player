package Wx::App::Mp3Player::Mpg123Player;

use strict;
use base qw(Wx::EvtHandler Wx::Spice::Service::Base Class::Publisher);

__PACKAGE__->mk_accessors( qw(player playlist iterator _timer) );

use Audio::Play::MPG123;
use Wx::Spice::Plugin qw(:plugin);
use Wx::Event qw(EVT_TIMER);
use Wx::Perl::EntryList::FwBwIterator;

sub service_name { 'player' }

sub new {
    my( $class, $playlist ) = @_;
    my $self = $class->SUPER::new;

    $self->{iterator} = Wx::Perl::EntryList::FwBwIterator->new;
    $self->{playlist} = $playlist;
    $self->{player} = Audio::Play::MPG123->new
      ( mpg123args => [ qw() ] );
    $self->{_timer} = Wx::Timer->new( $self );

    $self->iterator->attach( $self->playlist );

    EVT_TIMER( $self, -1, \&_on_poll );

    return $self;
}

sub _on_poll {
    my( $self, $event ) = @_;

    $self->player->poll( 0 );
    if( $self->player->state ) {
        $self->_notify_first if $self->{_notify_first};
        my $frames = $self->player->frame;
        $self->notify_subscribers( 'progress',
                                   elapsed_time => $frames->[2],
                                   );
    } else {
        $self->next || $self->_timer->Stop;
    }
}

sub _current_entry {
    my( $self ) = @_;

    return $self->playlist->get_entry_at( $self->iterator->current );
}

sub _notify_first {
    my( $self ) = @_;
    delete $self->{_notify_first};

    my $frames = $self->player->frame;
    $self->notify_subscribers( 'new_song',
                               total_time => $frames->[2] + $frames->[3],
                               file       => $self->_current_entry->{file},
                               ( map { $_ => $self->player->$_ }
                                     qw(title artist album year comment
                                        genre samplerate channels extension) ),
                               );
}

sub play {
    my( $self, $index ) = @_;

    if( defined $index ) {
        $self->iterator->current( $index );
    }
    $self->_timer->Start( 200 );
    $self->player->load( $self->_current_entry->{file} );
    $self->{_notify_first} = 1;
}

sub next {
    my( $self ) = @_;
    return if $self->iterator->at_end;
    $self->iterator->next_entry;
    $self->play;
}

sub previous {
    my( $self ) = @_;
    return if $self->iterator->at_start;
    $self->iterator->previous_entry;
    $self->play;
}

sub stop {
    my( $self ) = @_;

    $self->_timer->Stop;
    $self->player->stop;
}

sub pause {
    my( $self ) = @_;

    if( $self->paused ) {
        $self->_timer->Start( 200 );
    } else {
        $self->_timer->Stop;
    }
    $self->player->pause;
}

sub playing {
    my( $self ) = @_;

    return $self->player->state == 2;
}

sub paused {
    my( $self ) = @_;

    return $self->player->state == 1;
}

sub stopped {
    my( $self ) = @_;

    return $self->player->state == 0;
}

sub go_to {
    my( $self, $position ) = @_;

    return unless $self->player->tpf;
    $self->player->jump( $position / $self->player->tpf );
}

sub _my_cmd(&) {
    my( $cmd ) = @_;

    return sub {
        $cmd->( $_[0]->get_service( 'player' ) );
    };
}

sub _at_start { $_[0]->iterator->at_start }
sub _at_end   { $_[0]->iterator->at_end }

sub commands : Command {
    return
      ( player_stop     => { sub    => _my_cmd { $_[0]->stop },
                             active => _my_cmd { !$_[0]->stopped } },
        player_pause    => { sub    => _my_cmd { $_[0]->pause },
                             active => _my_cmd { !$_[0]->stopped } },
        player_previous => { sub    => _my_cmd { $_[0]->previous },
                             active => _my_cmd { !$_[0]->stopped && !$_[0]->_at_start } },
        player_next     => { sub    => _my_cmd { $_[0]->next },
                             active => _my_cmd { !$_[0]->stopped && !$_[0]->_at_end } },
        );
}

1;
