# Description:
#   For ordering groceries
##
# Configuration:
#   KNOCKMART_USERID
#
# Commands:
#   please (order|add) <groceries> - adds the groceries to cart if they are in stock
#   place order - places an order with the groceries currently in the cart
#   show cart - shows the items currently in the groceries cart
#   show list - shows all items in the full groceries list
#   (clear|empty) cart - clears the groceries cart
#
# Notes:
#   Places an order on knockmart
#
# Author:
#   matefh

yaml = require 'yaml-js'
fs = require 'fs'

print = (x) -> console.log x

refresh_list = (robot) ->
  my_list = yaml.load(fs.readFileSync('../list.yml').toString())
  robot.brain.set('my_list', my_list)
  return my_list

load_list = (robot) ->
  my_list = robot.brain.get("my_list")
  if my_list == null
    my_list = refresh_list(robot)
  return my_list

show_list = (list) ->
  strs = []
  for k, i of list
    strs = strs.concat(["#{k} = #{i["count"]} x #{i["name"]}"])
  return "\n" + strs.sort().join("\n")


module.exports = (robot) ->
  robot.respond /(show|groceries)* list/i, (res) ->
    res.reply show_list(refresh_list(robot))

  robot.respond /(show|groceries)* cart/i, (res) ->
    cart = robot.brain.get('cart') or {}
    res.reply if Object.keys(cart).length > 0 then "\n" + ("  #{i["count"]} x #{i["name"]}" for k, i of cart).join("\n") else "The cart is still empty though."

  robot.respond /(clear|empty)* cart/i, (res) ->
    robot.brain.set('cart', {})
    res.reply "This conversation never happened."

  robot.respond /(?:pls|please|plz)? (?:order|add) (.*)/i, (res) ->
    my_list = load_list(robot)
    id_to_name = {}
    for k, v of my_list
      id_to_name[v["id"]] = k
    items = res.match[1].toLowerCase().split(/\s*(?:,|and)\s*/).map (i) -> my_list[i]
    items = items.filter (i) -> i
    data = JSON.stringify({
         "WarehouseId": 1,
         "Items": items.map (i) -> {"ID": i["id"]}
    })
    if items.length == 0
      res.reply "What was that? Are you sure its in my list?" + "\n" + show_list(load_list(robot))
      return
    robot.http("http://knockmart.com/Home/CheckAvailability")
      .header('Content-Type', 'application/json;charset=UTF-8')
      .header("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36")
      .post(data) (err, res2, body) ->
        body = JSON.parse(body)
        out = body["Items"].filter (i) -> i["IsOutOfStock"]
        avail = body["Items"].filter (i) -> !i["IsOutOfStock"]
        cart = robot.brain.get('cart', cart) or {}
        for i in avail
          name = id_to_name[i["ID"]]
          if cart[name]
            cart[name]["count"] += my_list[name]["count"]
          else
            cart[name] = {
              id: my_list[name]["id"],
              name: my_list[name]["name"],
              count: my_list[name]["count"]
            }
        robot.brain.set('cart', cart)
        cart_str = ("  #{i["count"]} x #{i["name"]}" for k, i of cart).join("\n")
        res.reply if out.length == 0 then "\n#{cart_str}\nReady to order? just say the magic words \"Place order!\"" else "\n#{cart_str}\nWait, something's missing: #{out.map (i) -> id_to_name[i["ID"]]}. The rest is ready, just say the magic words \"Place order!\""
        return

  robot.respond /place order/i, (res) ->
    cart = robot.brain.get('cart')
    data = JSON.stringify({
      "Address": null,
      "SelectedAddress": 4343,
      "SelectedPhone": 5447,
      "TimeSlotID": 45,
      "PaymentMethod": "CashOnDelivery",
      "WarehouseId": 1,
      "EnterpriseDiscount": null,
      "UserId": process.env.KNOCKMART_USERID or "",
      "Items": ({"Id": i["id"], "Qty": i["count"], "Coupon": null} for k, i of cart)
    })
    robot.http("http://knockmart.com/Home/Order")
      .header('Content-Type', 'application/json;charset=UTF-8')
      .header("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36")
      .post(data) (err, res2, body) ->
        res.reply if res2["statusCode"] == 200 then "Done! The order should be on the way now, sit tight!" else "Hmm, this didn't go as planned."
        return
