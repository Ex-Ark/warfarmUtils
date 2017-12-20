
# takes orders and filter them with each function
class OrderFilter
  def self.sort_orders_by_price(orders)
    orders.sort_by! {|ord| ord.price}
  end

  def self.filter_ingame_buyers(orders)
    filter_only_buyers(filter_only_ingame orders)
  end
  # delete all selling players from orders
  def self.filter_only_buyers(orders)
    orders.select { |order | order.buying?}
  end

  # returns selling order with lowest price for a given item
  def self.filter_lowest_price_seller_for_item(orders,item_name)
    ord = orders.select { |order| order.selling? && order.ingame? && order.item == item_name}
    min = ord.min_by{ |order| order.price}
    min
  end
  # returns lowest order in a batch of orders
  def self.filter_lowest_selling_price(orders)
    ord = orders.select { |order| order.selling? && order.ingame?}
    min = ord.min_by{ |order| order.price}
    min
  end

  # returns highest order in a batch of orders
  def self.filter_highest_buying_price(orders)
    ord = orders.select { |order| order.buying? && order.ingame?}
    max = ord.max_by{ |order| order.price}
    max
  end

  def self.filter_only_sellers(orders)
    orders.select { |order| order.selling?}
  end

  # by default will only returns in-game players buying passed item
  # :@in_game can be turned to false to returns all players
  def self.filter_only_ingame(orders)
    orders.select { |order | order.ingame?}
  end

  def self.filter_ingame_sellers(orders)
    filter_only_sellers(filter_only_ingame orders)
  end

  # returns buying order with highest price for a given item
  def self.filter_highest_price_buyer_for_item(orders,item_name)
    ord = orders.select { |order| order.buying? && order.ingame? && order.item == item_name}
    max = ord.max_by{ |order| order.price}
    max
  end
end