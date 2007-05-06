#!/usr/bin/perl -w

use strict;

use Module::Build;

my $build = Module::Build->new
    ( module_name => 'Wx::App::Mp3Player',
      author      => 'Mattia Barbon <mbarbon@cpan.org>',
      license     => 'perl',
      requires    => { 'Wx'                    => 0.61,
                       'Wx::DND'               => 0.01,
                       'Wx::Spice'             => 0.01,
                       'Audio::Play::MPG123'   => 0.63,
                       'Class::Accessor'       => 0.27,
                       'Class::Publisher'      => 0.20,
                       'Wx::Perl::ListView'    => 0.01,
                       'Wx::Perl::ListCtrl'    => 0.02,
                       'MP3::Info'             => 1.22,
                       },
      build_requires => { 'Test::UseAllModules' => 0,
                          },
      create_makefile_pl => 'passthrough',
    );

$build->create_build_script;
