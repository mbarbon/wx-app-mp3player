package Wx::App::Mp3Player::Configuration;

use strict;
use base qw(Wx::Spice::Service::Configuration::Base);
use Wx::Spice::Plugin qw(:plugin);

sub service_name : Service { 'configuration' }

sub directory_name { 'wx_mp3player' }
sub file_name      { 'global.ini' }

1;
