#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  tests => 1, noinit => 1,
  at_least_version => [2, 6, 0, "GtkCellRendererCombo is new in 2.6"];

# $Header$

my $text = Gtk2::CellRendererCombo -> new();
isa_ok($text, "Gtk2::CellRendererCombo");

__END__

Copyright (C) 2004 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
