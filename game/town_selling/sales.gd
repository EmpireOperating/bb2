extends RefCounted
## Exact loose-equipment sale review. The shared Market owns the painted intent;
## Campaign still owns every sale eligibility rule, valuation and ledger write.
static func rows(c) -> Array:
 return c.sale_items().filter(func(uid):return not c.item_def(uid).get("assembly",false))

static func capture(c, site: String, uid: String) -> Dictionary:
 return {"uid":uid,"cash":c.market().get("cash",-1),
  "local_cash":c.economy.towns[site].cash if c.economy.enabled else -1,
  "record_ref":c.items[uid],"record":c.items[uid].duplicate(true),
  "quote":c.sale_quote(uid).duplicate(true),"name":c.item_name(uid)}

static func current(c, site: String, token: Dictionary) -> bool:
 var uid: String = token.uid
 if not c.items.has(uid) or not is_same(c.items[uid],token.record_ref) or c.items[uid]!=token.record or uid not in rows(c):return false
 var live := capture(c,site,uid)
 return live == token and live.quote.reason.is_empty()

static func commit(app, view, sale: Dictionary) -> bool:
 if not view.market_available(app) or not current(app.campaign,view.site,sale):return false
 var c = app.campaign
 if not c.sell_item(sale.uid,sale.quote.price):
  app.tell("Sale refused. Review the current item and merchant quote.")
  return false
 app.tell("Sold %s for %d crowns · %d crowns remain in the merchant’s purse." % [sale.name,sale.quote.price,c.market().cash])
 return true
