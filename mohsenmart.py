import requests
import json
import yaml
import re

my_list = yaml.load(open('list.yml'))
name_to_id = dict(map(lambda (name, item): (name, item['id']), my_list.iteritems()))
id_to_name = {v: k for k, v in name_to_id.items()}
check_availability_path = "/Home/CheckAvailability"
place_order_path = "/Home/Order"

def names_to_ids(names):
  return map(lambda s: name_to_id[s], names)

def ids_to_names(ids):
  return map(lambda s: id_to_name[s], ids)

def post_request(path, data):
  host = 'http://knockmart.com'
  url = ''.join([host, path])
  data = json.dumps(data)
  headers = json.loads(open('headers.json').read())
  r = requests.post(url, data = data, headers = headers)
  print r.status_code, r.text
  try:
    return json.loads(r.text)
  except Exception, e:
    return {}
  return {}

def which_out_of_stock(ids_counts):
  global name_to_id, id_to_name, check_availability_path
  ids = list(ids_counts.keys())
  payload = {"WarehouseId": 1, "Items": map(lambda id: {"ID": id}, ids)}
  avail = post_request(check_availability_path, payload)
  out_of_stock = [str(i["ID"]) for i in avail['Items'] if i['IsOutOfStock']]
  return out_of_stock

def add_names(names):
  ids_counts = dict(map(lambda s: (name_to_id[s], my_list[s]['count']), names))
  return add_to_cart(ids_counts)

def add_to_cart(ids_counts):
  f = open('cart.json')
  cart = json.loads(f.read())
  f.close()
  ids_out_of_stock = which_out_of_stock(ids_counts)
  for (k, v) in ids_counts.iteritems():
    if k not in ids_out_of_stock:
      if k in cart['Items']:
        cart['Items'][k] += v
      else:
        cart['Items'][k] = v
  with open('cart.json', 'w') as outfile:
    json.dump(cart, outfile)
  return cart['Items']

def remove_from_cart(ids_counts):
  cart = json.loads(open('cart.json').read())['Items']
  for (k, v) in ids_counts.iteritems():
    if k in cart and cart[k] >= v:
      cart[k] -= v
    else:
      cart.pop(k, None)
  with open('cart.json', 'w') as outfile:
    json.dump(cart, outfile)
  return cart

def clear_cart():
  with open('cart.json', 'w') as outfile:
    json.dump({'Items': {}}, outfile)
  return True

def show_cart(cart = None):
  if cart == None: cart = json.loads(open('cart.json').read())['Items']
  return "\n".join(map(lambda (k, v): "  %s x %s" % (v, id_to_name[k]), cart.iteritems()))

def place_order(cart = None):
  global name_to_id, place_order_path
  if cart == None: cart = json.loads(open('cart.json').read())['Items']
  data = { "Address": None,
              "SelectedAddress": 4343,
              "SelectedPhone": 5447,
              "TimeSlotID": 45,
              "PaymentMethod": "CashOnDelivery",
              "UserId": "7fd8caf0-5cad-4fca-849d-c97243a8231c",
              "WarehouseId": 1,
              "EnterpriseDiscount": None,
              "Items": map(lambda (id, qty): {"Id": id, "Qty": qty, "Coupon": None}, cart.iteritems())
         }
  post_request(place_order_path, data)
  return True

def handle_command(command):
  order = re.match('\s*please\s+order', command)
  add = re.match('\s*we\s+are\s+out\s+of', command)
  show = re.match('\s*show\s+cart', command)
  place = re.match('place order!', command)
  items = []
  if order:
    command = command.replace(order.group(), '').strip()
    items = re.compile("\s*,\s*").split(command)
    add_names(items)
    print show_cart()
  elif add:
    command = command.replace(add.group(), '').strip()
    items = re.compile("\s*,\s*").split(command)
    add_names(items)
    print show_cart()
  elif show:
    print show_cart()
  elif place:
    place_order()
  return items

clear_cart()
handle_command("please order brown toast, normal toast, digestive, olives")
# handle_command("place order!")
