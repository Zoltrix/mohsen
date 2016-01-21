
module.exports = (robot) ->
  robot.respond /(?:pls|please|plz)? (?:order|add) (.*)/i, (res) ->
    console.log res.match
    yaml = require 'yaml-js'
    fs = require 'fs'
    my_list = robot.brain.get("my_list")
    if my_list == null
      my_list = yaml.load(fs.readFileSync('../list.yml').toString())
      robot.brain.set("my_list", my_list)
    id_to_name = {}
    for k, v of my_list
      id_to_name[v["id"]] = k
    items = res.match[1].split(/\s*(?:,|and)\s*/).map (i) -> my_list[i]
    data = JSON.stringify({
         "WarehouseId": 1, 
         "Items": items.map (i) -> {"ID": i["id"]}
    })
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
            cart[name] = my_list[name]
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
      "Items": ({"Id": i["id"], "Qty": i["count"], "Coupon": null} for k, i of cart)
    })
    robot.http("http://knockmart.com/Home/Order")
      .header('Content-Type', 'application/json;charset=UTF-8')
      .header("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36")
      .post(data) (err, res2, body) ->
        res.reply if res2["statusCode"] == 200 then "Done! The order should be on the way now, sit tight!" else "Hmm, this didn't go as planned."
        return
