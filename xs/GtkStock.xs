/*
 * $Header$
 */

#include "gtk2perl.h"

/*
struct GtkStockItem {

  gchar *stock_id;
  gchar *label;
  GdkModifierType modifier;
  guint keyval;
  gchar *translation_domain;
};
*/

HV * 
stock_item_to_hv (GtkStockItem * item)
{
	HV * hv = newHV();
	hv_store (hv, "stock_id", 8, newSVpv (item->stock_id, 0), 0);
	hv_store (hv, "label", 5, newSVpv (item->label, 0), 0);
	hv_store (hv, "modifier", 8, newSVGdkModifierType (item->modifier), 0);
	hv_store (hv, "keyval", 6, newSVuv (item->keyval), 0);
	hv_store (hv, "translation_domain", 18, newSVpv (item->translation_domain, 0), 0);
	return hv;
}

GtkStockItem * 
hv_to_stock_item (HV * hv)
{
	GtkStockItem * item = g_new0 (GtkStockItem, 1);
	SV ** svp;

	svp = hv_fetch (hv, "stock_id", 8, FALSE);
	if (svp) item->stock_id = g_strdup (SvPV_nolen (*svp));
	
	svp = hv_fetch (hv, "label", 5, FALSE);
	if (svp) item->label = g_strdup (SvPV_nolen (*svp));

	svp = hv_fetch (hv, "modifier", 8, FALSE);
	if (svp) item->modifier = SvGdkModifierType (*svp);

	svp = hv_fetch (hv, "keyval", 6, FALSE);
	if (svp) item->keyval = SvUV (*svp);

	svp = hv_fetch (hv, "translation_domain", 18, FALSE);
	if (svp) item->translation_domain = g_strdup (SvPV_nolen (*svp));

	return item;
}


MODULE = Gtk2::Stock	PACKAGE = Gtk2::Stock	PREFIX = gtk_stock_

###  void gtk_stock_add (const GtkStockItem *items, guint n_items) 
#void
#gtk_stock_add (items, n_items)
#	const GtkStockItem *items
#	guint n_items
#
###  void gtk_stock_add_static (const GtkStockItem *items, guint n_items) 
#void
#gtk_stock_add_static (items, n_items)
#	const GtkStockItem *items
#	guint n_items

##  gboolean gtk_stock_lookup (const gchar *stock_id, GtkStockItem *item) 
SV *
gtk_stock_lookup (class, stock_id)
	SV * class
	const gchar *stock_id
    PREINIT:
	GtkStockItem item;
	HV * hv;
    CODE:
	if (! gtk_stock_lookup (stock_id, &item))
		XSRETURN_UNDEF;
	hv = stock_item_to_hv (&item);
//	RETVAL = newRV_noinc ((SV*)hv);
	RETVAL = newRV ((SV*)hv);
    OUTPUT:
	RETVAL

##  GSList* gtk_stock_list_ids (void) 
void
gtk_stock_list_ids (class)
	SV * class
    PREINIT:
	GSList * ids, * i;
    PPCODE:
	ids = gtk_stock_list_ids ();
	for (i = ids ; i != NULL ; i = i->next) {
		XPUSHs (sv_2mortal (newSVpv ((char*)(i->data), 0)));
		g_free (i->data);
	}
	g_slist_free (ids);

###  GtkStockItem *gtk_stock_item_copy (const GtkStockItem *item) 
#GtkStockItem *
#gtk_stock_item_copy (item)
#	const GtkStockItem *item
#
###  void gtk_stock_item_free (GtkStockItem *item) 
#void
#gtk_stock_item_free (item)
#	GtkStockItem *item

