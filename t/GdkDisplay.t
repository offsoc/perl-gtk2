#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  tests => 21,
  at_least_version => [2, 2, 0, "GdkDisplay is new in 2.2"];

# $Header$

my $display = Gtk2::Gdk::Display -> open($ENV{DISPLAY});
isa_ok($display, "Gtk2::Gdk::Display");
ok(defined($display -> get_name()));

$display = Gtk2::Gdk::Display -> get_default();
isa_ok($display, "Gtk2::Gdk::Display");

like($display -> get_n_screens(), qr/^\d+$/);

isa_ok($display -> get_screen(0), "Gtk2::Gdk::Screen");
isa_ok($display -> get_default_screen(), "Gtk2::Gdk::Screen");

$display -> pointer_ungrab(0);
$display -> keyboard_ungrab(0);
ok(!$display -> pointer_is_grabbed());

# $display -> beep();
$display -> sync();

isa_ok(($display -> list_devices())[0], "Gtk2::Gdk::Device");

$display -> put_event(Gtk2::Gdk::Event -> new("button-press"));
isa_ok($display -> peek_event(), "Gtk2::Gdk::Event");
isa_ok($display -> get_event(), "Gtk2::Gdk::Event");

$display -> set_double_click_time(20);

my ($screen, $x, $y, $mask) = $display -> get_pointer();
isa_ok($screen, "Gtk2::Gdk::Screen");
like($x, qr/^\d+$/);
like($y, qr/^\d+$/);
isa_ok($mask, "Gtk2::Gdk::ModifierType");

# warn $display -> get_window_at_pointer();

SKIP: {
  skip("stuff new in 2.4", 6)
    unless Gtk2 -> CHECK_VERSION(2, 4, 0);

  $display -> flush();
  $display -> set_double_click_distance(5);

  ok(defined($display -> supports_cursor_color()));
  ok(defined($display -> supports_cursor_alpha()));

  like($display -> get_default_cursor_size(), qr/^\d+$/);

  my ($width, $height) = $display -> get_maximal_cursor_size();
  like($width, qr/^\d+$/);
  like($height, qr/^\d+$/);

  isa_ok($display -> get_default_group(), "Gtk2::Gdk::Window");
}

SKIP: {
  skip("new 2.6 stuff", 1)
    unless Gtk2 -> CHECK_VERSION(2, 6, 0);

  if ($display -> supports_selection_notification()) {
    is($display -> request_selection_notification(Gtk2::Gdk::Atom -> intern("text/plain")), TRUE);
  } else {
    ok(1);
  }

  if ($display -> supports_clipboard_persistence()) {
    my $window = Gtk2::Window -> new();
    $window -> realize();

    $display -> store_clipboard($window -> window, 0,
                                Gtk2::Gdk::Atom -> intern("text/plain"),
                                Gtk2::Gdk::Atom -> intern("image/png"));
    $display -> store_clipboard($window -> window, 0);
  }
}

# FIXME: currently segfaults for me.  see #85715.
# $display -> close();

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
