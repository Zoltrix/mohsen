# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md



module.exports = (robot) ->
  robot.respond /(pls|please|plz) order (.*)/i, (res) ->
    robot.brain.set('milk', {id: '26007', count: '4'})
    robot.brain.set('cheddar cheese', {id: '25713', count: '1'})
    robot.brain.set('mix strawberry', {id: '19555', count: '4'})
    robot.brain.set('milk toast', {id: '17120', count: '1'})

    id_to_name = {}
    cart = res.match[2].split(/\s*(?:,|and)\s*/).map (i) -> id_to_name[robot.brain.get(i)["id"]] = i; robot.brain.get(i)
    robot.brain.set('cart', cart)
    data = JSON.stringify({
         "WarehouseId": 1, 
         "Items": cart.map (i) -> {"ID": i["id"]}
    })
    robot.http("http://knockmart.com/Home/CheckAvailability")
      .header('Content-Type', 'application/json;charset=UTF-8')
      .header("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36")
      .post(data) (err, res2, body) ->
        out = JSON.parse(body)["Items"].filter (i) -> i["IsOutOfStock"]
        console.log body
        res.reply if out.length == 0 then "Ready to order? just say the magic words \"Place order!\"" else "Wait, something's missing: #{out.map (i) -> id_to_name[i["ID"]]}. The rest is ready, just say the magic words \"Place order!\""
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
      "Items": cart.map (i) -> {"Id": i["id"], "Qty": i["count"], "Coupon": null}
    })
    robot.http("http://knockmart.com/Home/Order")
      .header('Content-Type', 'application/json;charset=UTF-8')
      .header("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36")
      .post(data) (err, res2, body) ->
        res.reply if res2["statusCode"] == 200 then "Sweet! The order should be on the way now, sit tight!" else "Hmm, this didn't go as planned."
        return
