package Wx::App::Mp3Player::Playlist::Data;

use strict;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(files current) );

use MP3::Info;

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new
                   ( { files   => [],
                       current => 0,
                       } );

    return $self;
}

sub get_entry_info {
    my( $self, $index ) = @_;
    my $entry = $self->files->[$index];

    $entry->{mp3info} ||= MP3::Info->new( $entry->{file} );
    return $entry->{mp3info};
}

sub get_entry_at {
    my( $self, $index ) = @_;

    return $self->files->[$index]->{file};
}

sub add_entries_at {
    my( $self, $index, $files ) = @_;

    if( $self->current >= $index ) {
        $self->current( $self->current + @$files );
    }
    splice @{$self->files}, $index, 0, map { file => $_ }, @$files;
}

sub _delete_entries {
    my( $self, $index, $count ) = @_;

    if( $self->current >= $index ) {
        if( $self->current < $index + $count ) {
            $self->current( 0 );
        } else {
            $self->current( $self->current - $count );
        }
    }
    return splice @{$self->files}, $index, $count;
}

sub delete_entry {
    my( $self, $index ) = @_;

    $self->_delete_entries( $index, 1 );
}

sub next_entry {
    my( $self ) = @_;
    return if $self->at_end;

    $self->current( $self->current + 1 );
}

sub previous_entry {
    my( $self ) = @_;
    return if $self->at_start;

    $self->current( $self->current - 1 );
}

sub move_entry {
    my( $self, $from, $to ) = @_;
    my $move_current = $self->current == $from;
    my( $entry ) = $self->_delete_entries( $from, 1 );
    $self->add_entries_at( $to, [ $entry->{file} ] );
    $self->current( $to ) if $move_current;
}

sub at_start { $_[0]->current == 0 }
sub at_end   { $_[0]->current > @{$_[0]->files} }
sub current_entry { $_[0]->get_entry_at( $_[0]->current ) }
sub count    { scalar @{$_[0]->files} }

1;
