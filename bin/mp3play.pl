#!/usr/bin/perl -w

use strict;
use lib 'lib';

use Wx::App::Mp3Player;

my $app = Wx::SimpleApp->new;
my $frame = Wx::App::Mp3Player->new;
$frame->Show;
$app->MainLoop;
