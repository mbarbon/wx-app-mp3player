package Wx::App::Mp3Player::Playlist::Data;

use strict;
use base qw(Wx::Perl::EntryList);

use MP3::Info;

sub get_entry_info {
    my( $self, $index ) = @_;
    my $entry = $self->entries->[$index];

    $entry->{mp3info} ||= MP3::Info->new( $entry->{file} );
    return $entry->{mp3info};
}

sub add_files_at {
    my( $self, $index, $files ) = @_;

    $self->add_entries_at( $index, [ map { file => $_ }, @$files ] );
}

1;
