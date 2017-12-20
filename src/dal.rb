require_relative 'model/order.rb'

class WFDAL
  def self.json_to_order_array(parsed_json,item='')
    orders = []
    parsed_json['payload']['orders'].each do |json_order|
      orders << json_to_order(json_order,item)
    end
    orders
  end

  private
  def self.json_to_order(parsed_json,item)
    Order.new(
        parsed_json['user']['ingame_name'],
        parsed_json['platinum'],
        parsed_json['order_type'],
        item,
        parsed_json['platform'],
        parsed_json['user']['status']
    )
  end
end