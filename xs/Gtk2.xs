/*
 * Copyright (c) 2003-2004 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
 * Boston, MA  02110-1301  USA.
 *
 * $Id$
 */

#include "gtk2perl.h"

static gboolean
gtk2perl_init_add_callback_invoke (GPerlCallback * callback)
{
	GValue return_value = {0,};
	gboolean retval;
	g_value_init (&return_value, callback->return_type);
	gperl_callback_invoke (callback, &return_value);
	retval = g_value_get_boolean (&return_value);
	g_value_unset (&return_value);

	/* according to the gtk source, init callbacks are forgotten
	 * immediately after use; thus, we need to destroy the callback
	 * object to avoid a leak. */
	gperl_callback_destroy(callback);
	
	return retval;
}

static guint
gtk2perl_quit_add_callback_invoke (GPerlCallback * callback)
{
	GValue return_value = {0,};
	guint retval;
	g_value_init (&return_value, callback->return_type);
	gperl_callback_invoke (callback, &return_value);
	retval = g_value_get_uint (&return_value);
	g_value_unset (&return_value);
	return retval;
}

static gint
gtk2perl_key_snoop_func (GtkWidget *grab_widget,
                         GdkEventKey *event,
                         gpointer func_data)
{
	gint ret;
	GValue retval = {0,};
	g_value_init (&retval, G_TYPE_INT);
	gperl_callback_invoke ((GPerlCallback*)func_data, &retval,
	                       grab_widget, event);
	ret = g_value_get_int (&retval);
	g_value_unset (&retval);
	return ret;
}

/*
 * we must track the key snoopers ourselves so we can destroy
 * the callback objects properly.
 */
static GHashTable * key_snoopers = NULL;

static guint
install_key_snooper (SV * func, SV * data)
{
	guint id; 
	GPerlCallback * callback;
	GType param_types[2];
	param_types[0] = GTK_TYPE_WIDGET;
	param_types[1] = GDK_TYPE_EVENT;
	if (!key_snoopers)
		key_snoopers =
			g_hash_table_new_full (g_direct_hash,
			                       g_direct_equal,
			                       NULL,
			                       (GDestroyNotify)
			                           gperl_callback_destroy);
	callback = gperl_callback_new (func, data, 2, param_types, G_TYPE_INT);
	id = gtk_key_snooper_install (gtk2perl_key_snoop_func, callback);
	g_hash_table_insert (key_snoopers, GUINT_TO_POINTER (id), callback);
	return id;
}

static void
remove_key_snooper (guint id)
{
	g_return_if_fail (key_snoopers != NULL);
	gtk_key_snooper_remove (id);
	g_hash_table_remove (key_snoopers, GUINT_TO_POINTER (id));
}

MODULE = Gtk2		PACKAGE = Gtk2		PREFIX = gtk_

##
## don't allow any unhidden autogenerated pods to fall into the Gtk2
## namespace, or the pod from Gtk2.pm will be overridden.
##

BOOT:
	{
	/* include some files autogenerated by Makefile.PL. */
	/* register Gtk/Gdk/Atk/Pango classes as perl packages.
	 * be sure to include this autogenerated set first, so that the
	 * hand-written boot code functions called by the next include
	 * can override the registrations if necessary. */
#include "register.xsh"
	/* call the boot code for all the various other modules */
#include "boot.xsh"
	/* route Gtk+ log messages through perl's warn() and croak() */
	gperl_handle_logs_for ("Gtk");
	gperl_handle_logs_for ("Gdk");
	gperl_handle_logs_for ("GdkPixbuf");

	/* make sure that we're running/linked against a version at least as 
	 * new as we built against, otherwise bad things can happen. */
	if ((((int)gtk_major_version) < GTK_MAJOR_VERSION)
	    ||
	    (gtk_major_version == GTK_MAJOR_VERSION && 
	     ((int)gtk_minor_version) < GTK_MINOR_VERSION)
	    ||
	    (gtk_major_version == GTK_MAJOR_VERSION && 
	     gtk_minor_version == GTK_MINOR_VERSION &&
	     ((int)gtk_micro_version) < GTK_MICRO_VERSION))
		warn ("*** This build of Gtk2 was compiled with gtk+ %d.%d.%d,"
		      " but is currently running with %d.%d.%d, which is too"
		      " old.  We'll continue, but expect problems!\n",
		      GTK_MAJOR_VERSION, GTK_MINOR_VERSION, GTK_MICRO_VERSION,
		      gtk_major_version, gtk_minor_version, gtk_micro_version);
	}

#############################################################################
#############################################################################

=for object Gtk2::version Library Version Information
=cut

=head1 SYNOPSIS

  use Gtk2 '1.023';  # require at least version 1.023 of the bindings

  if ($Gtk2::VERSION >= 1.040 and Gtk2->CHECK_VERSION (2, 4, 0)) {
     # the GtkFileChooser, new in gtk+ 2.4.0 and first supported in
     # Gtk2-Perl at 1.040, is available
  } else {
     # GtkFileChooser is not available, fall back to GtkFileSelection
  }

=head1 DESCRIPTION

Since the Gtk2 Perl module is a bridge to an external library with its own
versions and API revisions, we have three different versions available for
inspection.  Which one you need to use at which time depends entirely on
the situation.  Gtk2 uses the same scheme as Glib and the underlying gtk+
C library; that is, the standard
C<$Gtk2::VERSION> for the version of the bindings, all-caps
(MAJOR|MINOR|MICRO)_VERSION functions for the bound version, and
lower-case (major|minor|micro)_version functions for the runtime version.
See L<Glib::version> and
L<http://developer.gnome.org/doc/API/2.0/gtk/gtk-Feature-Test-Macros.html>
for more information.

Note also that gtk_check_version() and GTK_CHECK_VERSION() have different
semantics in C, and we have preserved those faithfully.

=cut

=for see_also Glib::version
=cut

  # we have no use for these in perl.
 ##GTKMAIN_C_VAR const guint gtk_binary_age;
 ##GTKMAIN_C_VAR const guint gtk_interface_age;

=for apidoc
=for signature (major, minor, micro) = Gtk2->get_version_info
Shorthand to fetch as a list the gtk+ version against which Gtk2 is linked.
See C<Gtk2::major_version>, etc.
=cut
void
gtk_get_version_info (class)
    PPCODE:
	EXTEND(SP,3);
	PUSHs(sv_2mortal(newSViv(gtk_major_version)));
	PUSHs(sv_2mortal(newSViv(gtk_minor_version)));
	PUSHs(sv_2mortal(newSViv(gtk_micro_version)));
	PERL_UNUSED_VAR (ax);

=for apidoc
Returns undef if the version of gtk+ currently in use is compatible with the
given version, otherwise returns a string describing the mismatch.  Note that
this is not the same logic as C<Gtk2::CHECK_VERSION>.  This check is not
terribly reliable, and should not be used to test for availability of widgets
or functions in the Gtk2 module --- use C<Gtk2::CHECK_VERSION> for that.
See L<Glib::version> for a more detailed description of when you'd want to
do a runtime-version test.
=cut
gchar * 
gtk_check_version (class, required_major, required_minor, required_micro)
	guint   required_major
	guint   required_minor
	guint   required_micro
    CODE:
	RETVAL = (gchar *) gtk_check_version (required_major, required_minor, required_micro);
    OUTPUT:
	RETVAL

=for apidoc Gtk2::MAJOR_VERSION __function__
The major version of the gtk+ library against which Gtk2 was compiled.
Equivalent to gtk+'s GTK_MAJOR_VERSION.
=cut

=for apidoc Gtk2::MINOR_VERSION __function__
The minor version of the gtk+ library against which Gtk2 was compiled.
Equivalent to gtk+'s GTK_MINOR_VERSION.
=cut

=for apidoc Gtk2::MICRO_VERSION __function__
The micro version of the gtk+ library against which Gtk2 was compiled.
Equivalent to gtk+'s GTK_MICRO_VERSION.
=cut

=for apidoc Gtk2::major_version __function__
The major version of the gtk+ library current in use at runtime.
Equivalent to gtk+'s global variable gtk_major_version.
=cut

=for apidoc Gtk2::minor_version __function__
The minor version of the gtk+ library current in use at runtime.
Equivalent to gtk+'s global variable gtk_minor_version.
=cut

=for apidoc Gtk2::micro_version __function__
The micro version of the gtk+ library current in use at runtime.
Equivalent to gtk+'s global variable gtk_micro_version.
=cut

guint
MAJOR_VERSION ()
    ALIAS:
	Gtk2::MINOR_VERSION = 1
	Gtk2::MICRO_VERSION = 2
	Gtk2::major_version = 3
	Gtk2::minor_version = 4
	Gtk2::micro_version = 5
    CODE:
	switch (ix)
	{
	case 0: RETVAL = GTK_MAJOR_VERSION; break;
	case 1: RETVAL = GTK_MINOR_VERSION; break;
	case 2: RETVAL = GTK_MICRO_VERSION; break;
	case 3: RETVAL = gtk_major_version; break;
	case 4: RETVAL = gtk_minor_version; break;
	case 5: RETVAL = gtk_micro_version; break;
	default:
		RETVAL = -1;
		g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

=for apidoc
=for signature (MAJOR, MINOR, MICRO) = Gtk2->GET_VERSION_INFO
Shorthand to fetch as a list the gtk+ version for which Gtk2 was compiled.
See C<Gtk2::MAJOR_VERSION>, etc.
=cut
void
GET_VERSION_INFO (class)
    PPCODE:
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSViv (GTK_MAJOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (GTK_MINOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (GTK_MICRO_VERSION)));
	PERL_UNUSED_VAR (ax);

=for apidoc
Provides a mechanism for checking the version information that Gtk2 was
compiled against. Essentially equvilent to the macro GTK_CHECK_VERSION. In most
cases this function should be used rather than 
L<check_version ()|/"string = Gtk2-E<gt>B<check_version> ($required_major, $required_minor, $required_micro)">.
=cut
gboolean
CHECK_VERSION (class, guint required_major, guint required_minor, guint required_micro)
    CODE:
	RETVAL = GTK_CHECK_VERSION (required_major, required_minor,
				    required_micro);
    OUTPUT:
	RETVAL


#############################################################################
#############################################################################

=for object Gtk2::main
=cut

=for apidoc Gtk2::init_check
This is the non-fatal version of C<< Gtk2->init >>; instead of calling C<exit>
if Gtk+ initialization fails, C<< Gtk2->init_check >> returns false.  This
allows your application to fall back on some other means of communication with
the user - for example a curses or command-line interface.
=cut

=for apidoc
Initialize Gtk+.  This must be called before any other Gtk2 functions in a 
GUI application; the Gtk2 module's import method allows you to pass C<-init>
in the C<use> statement to do this automatically.  This function also scans
I<@ARGV> for any options it knows, and will remove them automagically.

Note: this function will terminate your program if it is unable to initialize
the gui for any reason.  If you want your program to fall back to some other
interface, you want to use C<< Gtk2->init_check >> instead.
=cut
gboolean
gtk_init (class=NULL)
    ALIAS:
	Gtk2::init_check = 2
    PREINIT:
	GPerlArgv *pargv;
    CODE:
	pargv = gperl_argv_new ();

	if (ix == 2) {
		RETVAL = gtk_init_check (&pargv->argc, &pargv->argv);
	} else if (PL_minus_c) {
		/* When in syntax check mode, we need to avoid calling gtk_init
		 * even if asked to because it might abort the program (e.g. if
		 * DISPLAY is not set). */
		RETVAL = gtk_init_check (&pargv->argc, &pargv->argv);
        } else {
		gtk_init (&pargv->argc, &pargv->argv);
		/* gtk_init() either succeeds or does not return. */
		RETVAL = TRUE;
	}

	gperl_argv_update (pargv);
	gperl_argv_free (pargv);
    OUTPUT:
	RETVAL

#if GTK_CHECK_VERSION(2, 4, 5)

##  gboolean gtk_parse_args (int *argc, char ***argv) 
gboolean
gtk_parse_args (class=NULL)
    PREINIT:
	GPerlArgv *pargv;
    CODE:
	pargv = gperl_argv_new ();

	RETVAL = gtk_parse_args (&pargv->argc, &pargv->argv);

	gperl_argv_update (pargv);
	gperl_argv_free (pargv);
    OUTPUT:
	RETVAL

#endif

#if GTK_CHECK_VERSION(2, 6, 0)

# I see no way to wrap this.  Bare GOptionEntries don't carry enough context to
# let us setup the SV synchronization.  We would need to be able to pass in a
# whole GOptionGroup.
##  gboolean gtk_init_with_args (int *argc, char ***argv, char *parameter_string, GOptionEntry *entries, char *translation_domain, GError **error);

##  GOptionGroup *gtk_get_option_group (gboolean open_default_display);
GOptionGroup_own *
gtk_get_option_group (class, open_default_display)
	gboolean open_default_display
    C_ARGS:
	open_default_display

#endif

 ##void           gtk_disable_setlocale    (void);
void gtk_disable_setlocale (class)
    C_ARGS:
	/*void*/

 ##gchar *        gtk_set_locale           (void);
const gchar * gtk_set_locale (class)
    C_ARGS:
	/*void*/

 ##PangoLanguage *gtk_get_default_language (void);
PangoLanguage *
gtk_get_default_language (class)
    C_ARGS:
	/*void*/

gint
gtk_events_pending (class)
    C_ARGS:
	/*void*/

## void gtk_main_do_event (GdkEvent *event);
=for apidoc
This is the event handler that GTK+ registers with GDK.  GTK+ exposes it to
allow filtering of events between GDK and GTK+; it is rare that you would
need this, except if you are using C<Gtk2::Gdk::Event::handler_set>.
=cut
void gtk_main_do_event (class, GdkEvent *event);
    C_ARGS:
	event

void
gtk_main (class)
    C_ARGS:
	/*void*/

guint
gtk_main_level (class)
    C_ARGS:
	/*void*/

void
gtk_main_quit (class=NULL)
    C_ARGS:
	/*void*/

gboolean
gtk_main_iteration (class)
    C_ARGS:
	/*void*/

gboolean
gtk_main_iteration_do (class, blocking)
	gboolean blocking
    C_ARGS:
	blocking

 ### gtk-perl implemented these as widget methods, but they are not widget
 ### methods.  they deal with the global grab setting.  this is bound to 
 ### be a FAQ.

 ## Gtk2->grab_add (widget)
void
gtk_grab_add (class, widget)
	GtkWidget * widget
    C_ARGS:
	widget

GtkWidget_ornull *
gtk_grab_get_current (class)
    C_ARGS:
	/*void*/

 ## Gtk2->grab_remove (widget)
void
gtk_grab_remove	(class, widget)
	GtkWidget * widget
    C_ARGS:
	widget

void 
gtk_init_add (class, function, data=NULL)
	SV          * function
	SV          * data
    PREINIT:
	GPerlCallback * real_callback;
    CODE:
	real_callback = gperl_callback_new(function, data, 
				0, NULL, G_TYPE_BOOLEAN);
	gtk_init_add((GtkFunction)gtk2perl_init_add_callback_invoke,
		     real_callback);

## guint gtk_quit_add
## guint gtk_quit_add_full
guint
gtk_quit_add (class, main_level, function, data=NULL)
	guint   main_level
	SV    * function
	SV    * data
    PREINIT:
    	GPerlCallback * real_callback;
    CODE:
	real_callback = gperl_callback_new(function, data, 
				0, NULL, G_TYPE_UINT);
	RETVAL = gtk_quit_add_full(main_level, 
			  (GtkFunction)gtk2perl_quit_add_callback_invoke, 
			  NULL, real_callback, 
			  (GtkDestroyNotify)gperl_callback_destroy);
    OUTPUT:
	RETVAL

void	   
gtk_quit_remove (class, quit_handler_id)
	guint   quit_handler_id
    C_ARGS:
    	quit_handler_id

## void gtk_quit_add_destroy (guint main_level, GtkObject *object);
void gtk_quit_add_destroy (class, guint main_level, GtkObject *object)
    C_ARGS:
	main_level, object

 ##void	   gtk_quit_remove_by_data (gpointer	       data);

# these (timeout, idle, and input) are all deprecated in favor of the 
# corresponding glib functions.
 ##guint   gtk_timeout_add	   (guint32	       interval,
 ##				    GtkFunction	       function,
 ##				    gpointer	       data);
 ##guint   gtk_timeout_add_full	   (guint32	       interval,
 ##				    GtkFunction	       function,
 ##				    GtkCallbackMarshal marshal,
 ##				    gpointer	       data,
 ##				    GtkDestroyNotify   destroy);
 ##void	   gtk_timeout_remove	   (guint	       timeout_handler_id);
 ##
 ##guint   gtk_idle_add		   (GtkFunction	       function,
 ##				    gpointer	       data);
 ##guint   gtk_idle_add_priority   (gint	       priority,
 ##     			    GtkFunction	       function,
 ##				    gpointer	       data);
 ##guint   gtk_idle_add_full	   (gint	       priority,
 ##				    GtkFunction	       function,
 ##				    GtkCallbackMarshal marshal,
 ##				    gpointer	       data,
 ##				    GtkDestroyNotify   destroy);
 ##void	   gtk_idle_remove	   (guint	       idle_handler_id);
 ##void	   gtk_idle_remove_by_data (gpointer	       data);
 ##guint   gtk_input_add_full	   (gint	       source,
 ##				    GdkInputCondition  condition,
 ##				    GdkInputFunction   function,
 ##				    GtkCallbackMarshal marshal,
 ##				    gpointer	       data,
 ##				    GtkDestroyNotify   destroy);
 ##void	   gtk_input_remove	   (guint	       input_handler_id);

 ##guint gtk_key_snooper_install (GtkKeySnoopFunc snooper, gpointer func_data);
=for apidoc
=for arg snooper (subroutine) function to call on every event
Install a key "snooper" function which will get called on all key
events before those events are delivered normally.  These snoopers can
be used to implement custom key event handling.

C<key_snooper_install> returns an id that may be used with
C<key_snooper_remove> (below).  I<snooper> is called as

    stopbool = &snooper ($widget, $event, $func_data);

It should return true to stop event propagation, the same as
C<Gtk2::Widget> event signal handlers.  The C<Gtk2::EVENT_STOP> and
C<Gtk2::EVENT_PROPAGATE> constants can be used for the return (see
L<Gtk2::Widget>).
=cut
guint gtk_key_snooper_install (class, SV * snooper, SV * func_data=NULL)
    CODE:
	RETVAL = install_key_snooper (snooper, func_data);
    OUTPUT:
	RETVAL

 ##void	gtk_key_snooper_remove (guint snooper_handler_id);
void gtk_key_snooper_remove (class, guint snooper_handler_id)
    CODE:
	remove_key_snooper (snooper_handler_id);

 ##GdkEvent*       gtk_get_current_event       (void);
GdkEvent_own_ornull*
gtk_get_current_event (class)
    C_ARGS:
	/*void*/

 ##guint32         gtk_get_current_event_time  (void);
guint32 gtk_get_current_event_time (class);
    C_ARGS:
	/*void*/

 ##gboolean        gtk_get_current_event_state (GdkModifierType *state);
GdkModifierType gtk_get_current_event_state (class)
    CODE:
	if (!gtk_get_current_event_state (&RETVAL))
		XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

 ##GtkWidget* gtk_get_event_widget	   (GdkEvent	   *event);
GtkWidget_ornull *
gtk_get_event_widget (class, GdkEvent_ornull * event)
    C_ARGS:
	event

# this stuff is only here to generate pod pages for abstract and functionless
# object, that is the objects exist only as parents and have no functions of
# their own

=for object Gtk2::Separator
=cut

=for object Gtk2::Scrollbar
=cut

MODULE = Gtk2		PACKAGE = Gtk2::Widget		PREFIX = gtk_

=for apidoc

From gtk+'s API documentation:

You most likely don't want to use any of these functions; synthesizing events
is rarely needed. Consider asking on the mailing list for better ways to
achieve your goals. For example, use Gtk2::Gdk::invalidate_rect or
Gtk2::Widget::queue_draw instead of making up expose events.

=cut
 ##void gtk_propagate_event (GtkWidget * widget, GdkEvent * event);
void
gtk_propagate_event (widget, event)
	GtkWidget * widget
	GdkEvent * event

# --------------------------------------------------------------------------- #

MODULE = Gtk2	PACKAGE = Gtk2::Pango

# All the stuff below is to create POD stubs for Gtk2::Pango::* that link to
# the new Pango::* POD pages.

=for object Gtk2::Pango::AttrBackground - backwards compatibility wrapper for Pango::AttrBackground
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrBackground
=cut


=for object Gtk2::Pango::AttrColor - backwards compatibility wrapper for Pango::AttrColor
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrColor
=cut


=for object Gtk2::Pango::AttrFallback - backwards compatibility wrapper for Pango::AttrFallback
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrFallback
=cut


=for object Gtk2::Pango::AttrFamily - backwards compatibility wrapper for Pango::AttrFamily
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrFamily
=cut


=for object Gtk2::Pango::AttrFontDesc - backwards compatibility wrapper for Pango::AttrFontDesc
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrFontDesc
=cut


=for object Gtk2::Pango::AttrForeground - backwards compatibility wrapper for Pango::AttrForeground
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrForeground
=cut


=for object Gtk2::Pango::AttrGravity - backwards compatibility wrapper for Pango::AttrGravity
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrGravity
=cut


=for object Gtk2::Pango::AttrGravityHint - backwards compatibility wrapper for Pango::AttrGravityHint
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrGravityHint
=cut


=for object Gtk2::Pango::Attribute - backwards compatibility wrapper for Pango::Attribute
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::Attribute
=cut


=for object Gtk2::Pango::AttrInt - backwards compatibility wrapper for Pango::AttrInt
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrInt
=cut


=for object Gtk2::Pango::AttrIterator - backwards compatibility wrapper for Pango::AttrIterator
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrIterator
=cut


=for object Gtk2::Pango::AttrLanguage - backwards compatibility wrapper for Pango::AttrLanguage
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrLanguage
=cut


=for object Gtk2::Pango::AttrLetterSpacing - backwards compatibility wrapper for Pango::AttrLetterSpacing
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrLetterSpacing
=cut


=for object Gtk2::Pango::AttrList - backwards compatibility wrapper for Pango::AttrList
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrList
=cut


=for object Gtk2::Pango::AttrRise - backwards compatibility wrapper for Pango::AttrRise
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrRise
=cut


=for object Gtk2::Pango::AttrScale - backwards compatibility wrapper for Pango::AttrScale
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrScale
=cut


=for object Gtk2::Pango::AttrShape - backwards compatibility wrapper for Pango::AttrShape
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrShape
=cut


=for object Gtk2::Pango::AttrSize - backwards compatibility wrapper for Pango::AttrSize
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrSize
=cut


=for object Gtk2::Pango::AttrStretch - backwards compatibility wrapper for Pango::AttrStretch
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrStretch
=cut


=for object Gtk2::Pango::AttrStrikethrough - backwards compatibility wrapper for Pango::AttrStrikethrough
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrStrikethrough
=cut


=for object Gtk2::Pango::AttrStrikethroughColor - backwards compatibility wrapper for Pango::AttrStrikethroughColor
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrStrikethroughColor
=cut


=for object Gtk2::Pango::AttrString - backwards compatibility wrapper for Pango::AttrString
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrString
=cut


=for object Gtk2::Pango::AttrStyle - backwards compatibility wrapper for Pango::AttrStyle
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrStyle
=cut


=for object Gtk2::Pango::AttrUnderline - backwards compatibility wrapper for Pango::AttrUnderline
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrUnderline
=cut


=for object Gtk2::Pango::AttrUnderlineColor - backwards compatibility wrapper for Pango::AttrUnderlineColor
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrUnderlineColor
=cut


=for object Gtk2::Pango::AttrVariant - backwards compatibility wrapper for Pango::AttrVariant
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrVariant
=cut


=for object Gtk2::Pango::AttrWeight - backwards compatibility wrapper for Pango::AttrWeight
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::AttrWeight
=cut


=for object Gtk2::Pango::Cairo - backwards compatibility wrapper for Pango::Cairo
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::Cairo
=cut


=for object Gtk2::Pango::Cairo::Context - backwards compatibility wrapper for Pango::Cairo::Context
=cut

=for object Gtk2::Pango::Cairo::Font - backwards compatibility wrapper for Pango::Cairo::Font
=cut

=for object Gtk2::Pango::Cairo::FontMap - backwards compatibility wrapper for Pango::Cairo::FontMap
=cut

=for object Gtk2::Pango::Color - backwards compatibility wrapper for Pango::Color
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::Color
=cut


=for object Gtk2::Pango::Context - backwards compatibility wrapper for Pango::Context
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::Context
=cut


=for object Gtk2::Pango::Font - backwards compatibility wrapper for Pango::Font
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::Font
=cut


=for object Gtk2::Pango::FontDescription - backwards compatibility wrapper for Pango::FontDescription
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::FontDescription
=cut


=for object Gtk2::Pango::FontFace - backwards compatibility wrapper for Pango::FontFace
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::FontFace
=cut


=for object Gtk2::Pango::FontFamily - backwards compatibility wrapper for Pango::FontFamily
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::FontFamily
=cut


=for object Gtk2::Pango::FontMap - backwards compatibility wrapper for Pango::FontMap
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::FontMap
=cut


=for object Gtk2::Pango::FontMetrics - backwards compatibility wrapper for Pango::FontMetrics
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::FontMetrics
=cut


=for object Gtk2::Pango::Fontset - backwards compatibility wrapper for Pango::Fontset
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::Fontset
=cut


=for object Gtk2::Pango::Gravity - backwards compatibility wrapper for Pango::Gravity
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::Gravity
=cut


=for object Gtk2::Pango::Language - backwards compatibility wrapper for Pango::Language
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::Language
=cut


=for object Gtk2::Pango::Layout - backwards compatibility wrapper for Pango::Layout
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::Layout
=cut


=for object Gtk2::Pango::LayoutIter - backwards compatibility wrapper for Pango::LayoutIter
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::LayoutIter
=cut


=for object Gtk2::Pango::LayoutLine - backwards compatibility wrapper for Pango::LayoutLine
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::LayoutLine
=cut


=for object Gtk2::Pango::Matrix - backwards compatibility wrapper for Pango::Matrix
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::Matrix
=cut


=for object Gtk2::Pango::Renderer - backwards compatibility wrapper for Pango::Renderer
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::Renderer
=cut


=for object Gtk2::Pango::Script - backwards compatibility wrapper for Pango::Script
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::Script
=cut


=for object Gtk2::Pango::ScriptIter - backwards compatibility wrapper for Pango::ScriptIter
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::ScriptIter
=cut


=for object Gtk2::Pango::TabArray - backwards compatibility wrapper for Pango::TabArray
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::TabArray
=cut


=for object Gtk2::Pango::version - backwards compatibility wrapper for Pango::version
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

As of Gtk2 1.220, pango bindings are provided by the standalone Pango module.
This namespace is provided for backwards compatibility.  The relevant
documentation moved to Pango and is linked to below.

=cut

=for see_also Pango::version
=cut
