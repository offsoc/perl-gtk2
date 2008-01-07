/*
 * Copyright (c) 2006 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Header$
 */

#include "gtk2perl.h"

 /* For gtk2perl_sv_to_strv and gtk2perl_sv_from_strv. */
#include "gtk2perl-private.h"

/*
struct _GtkRecentFilterInfo
{
  GtkRecentFilterFlags contains;

  const gchar *uri;
  const gchar *display_name;
  const gchar *mime_type;
  const gchar **applications;
  const gchar **groups;

  gint age;
};
*/

static SV *
newSVGtkRecentFilterInfo (const GtkRecentFilterInfo *info)
{
  HV *hv;

  if (!info)
    return &PL_sv_undef;

  hv = newHV ();

  hv_store (hv, "contains", 8,
            newSVGtkRecentFilterFlags (info->contains), 0);

  if (info->uri)
    hv_store (hv, "uri", 3, newSVpv (info->uri, PL_na), 0);

  if (info->display_name)
    hv_store (hv, "display_name", 12, newSVGChar (info->display_name), 0);

  if (info->mime_type)
    hv_store (hv, "mime_type", 9, newSVGChar (info->mime_type), 0);

  if (info->applications)
    hv_store (hv, "applications", 12, gtk2perl_sv_from_strv (info->applications), 0);

  if (info->groups)
    hv_store (hv, "groups", 6, gtk2perl_sv_from_strv (info->groups), 0);

  hv_store (hv, "age", 3, newSViv (info->age), 0);

  return newRV_noinc ((SV *) hv);
}

static GtkRecentFilterInfo *
SvGtkRecentFilterInfo (SV *sv)
{
  HV *hv;
  SV **svp;
  GtkRecentFilterInfo *info;

  if (!gperl_sv_is_defined (sv) || !SvROK (sv) || SvTYPE (SvRV (sv)) != SVt_PVHV)
    croak ("invalid recent filter info - expecting a hash reference");

  hv = (HV *) SvRV (sv);
  info = gperl_alloc_temp (sizeof (GtkRecentFilterInfo));

  if ((svp = hv_fetch (hv, "contains", 8, 0)))
    info->contains = SvGtkRecentFilterFlags (*svp);

  if ((svp = hv_fetch (hv, "uri", 3, 0)))
    info->uri = SvPV_nolen (*svp);

  if ((svp = hv_fetch (hv, "display_name", 12, 0)))
    info->display_name = SvGChar (*svp);

  if ((svp = hv_fetch (hv, "mime_type", 9, 0)))
    info->mime_type = SvGChar (*svp);

  if ((svp = hv_fetch (hv, "applications", 12, 0)))
    info->applications = gtk2perl_sv_to_strv (*svp);

  if ((svp = hv_fetch (hv, "groups", 6, 0)))
    info->groups = gtk2perl_sv_to_strv (*svp);

  if ((svp = hv_fetch (hv, "age", 3, 0)))
    info->age = SvIV (*svp);

  return info;
}

static gboolean
gtk2perl_recent_filter_func (const GtkRecentFilterInfo *filter_info,
			     gpointer                   user_data)
{
  GPerlCallback *callback = (GPerlCallback *) user_data;
  GValue value = { 0, };
  gboolean retval;
  SV *sv;

  g_value_init (&value, G_TYPE_BOOLEAN);
  sv = newSVGtkRecentFilterInfo (filter_info);

  gperl_callback_invoke (callback, &value, sv);
  retval = g_value_get_boolean (&value);

  SvREFCNT_dec (sv);
  g_value_unset (&value);

  return retval;
}

MODULE = Gtk2::RecentFilter	PACKAGE = Gtk2::RecentFilter	PREFIX = gtk_recent_filter_

GtkRecentFilter *
gtk_recent_filter_new (class)
    C_ARGS:
        /* void */

void gtk_recent_filter_set_name (GtkRecentFilter *filter, const gchar *name)

const gchar *gtk_recent_filter_get_name (GtkRecentFilter *filter)

void
gtk_recent_filter_add_mime_type (GtkRecentFilter *filter, const gchar *mime_type)

void
gtk_recent_filter_add_pattern (GtkRecentFilter *filter, const gchar *pattern)

void
gtk_recent_filter_add_pixbuf_formats (GtkRecentFilter *filter)

void
gtk_recent_filter_add_application (GtkRecentFilter *filter, const gchar *application)

void
gtk_recent_filter_add_group (GtkRecentFilter *filter, const gchar *group)

void
gtk_recent_filter_add_age (GtkRecentFilter *filter, gint days)

void
gtk_recent_filter_add_custom (filter, needed, func, data=NULL)
	GtkRecentFilter *filter
	GtkRecentFilterFlags needed
	SV *func
	SV *data
    PREINIT:
        GType param_types[1];
	GPerlCallback *callback;
    CODE:
        param_types[0] = GPERL_TYPE_SV;
	callback = gperl_callback_new (func, data, 1, param_types, G_TYPE_BOOLEAN);
	gtk_recent_filter_add_custom (filter, needed,
				      gtk2perl_recent_filter_func, callback,
				      (GDestroyNotify) gperl_callback_destroy);

GtkRecentFilterFlags
gtk_recent_filter_get_needed (GtkRecentFilter *filter)

gboolean
gtk_recent_filter_filter (filter, filter_info)
	GtkRecentFilter *filter
	SV *filter_info
    C_ARGS:
    	filter, SvGtkRecentFilterInfo (filter_info)

