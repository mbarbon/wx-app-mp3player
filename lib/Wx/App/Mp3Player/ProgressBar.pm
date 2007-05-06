package Wx::App::Mp3Player::ProgressBar;

use strict;
use base qw(Wx::Slider Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(player _moving _skip) );

use Wx qw(:slider);
use Wx::Event qw(EVT_SCROLL_THUMBTRACK EVT_SCROLL_THUMBRELEASE);

sub new {
    my( $class, $parent, $player ) = @_;
    my $self = $class->SUPER::new( $parent, -1, 0, 0, 1,
                                   [-1, -1], [-1, -1], wxSL_HORIZONTAL );

    $self->{player} = $player;
    $self->player->add_subscriber( 'new_song', $self, '_start' );
    $self->player->add_subscriber( 'progress', $self, '_on_poll' );

    EVT_SCROLL_THUMBTRACK( $self, sub { $self->_moving( 1 ) } );
    EVT_SCROLL_THUMBRELEASE( $self,
                             sub { $self->_moving( 0 );
                                   $self->player->go_to( $_[1]->GetPosition );
                                   $self->_skip( 2 );
                                   $_[1]->Skip;
                             } );

    return $self;
}

sub _start {
    my( $self, $player, $event, %params ) = @_;

    $self->SetRange( 0, $params{total_time} );
}

sub _on_poll {
    my( $self, $player, $event, %params ) = @_;
    return if $self->_moving;
    $self->_skip( $self->_skip - 1 ), return if $self->_skip;

    $self->SetValue( $params{elapsed_time} );
}

1;
