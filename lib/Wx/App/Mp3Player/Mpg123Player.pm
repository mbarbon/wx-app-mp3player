package Wx::App::Mp3Player::Mpg123Player;

use strict;
use base qw(Wx::EvtHandler Class::Accessor::Fast Class::Publisher);

__PACKAGE__->mk_accessors( qw(player playlist iterator _timer) );

use Audio::Play::MPG123;
use Wx::Event qw(EVT_TIMER);
use Wx::Perl::EntryList::FwBwIterator;

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
        $self->next;
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

sub playing {
    my( $self ) = @_;

    return $self->player->state == 2;
}

sub go_to {
    my( $self, $position ) = @_;

    return unless $self->player->tpf;
    $self->player->jump( $position / $self->player->tpf );
}

1;
