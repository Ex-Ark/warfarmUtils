require 'json'
require_relative 'model/order'
require_relative '../src/wf_logger'

module WFDAL

  def self.valid_json?(json)
    !!JSON.parse(json)
  rescue JSON::ParserError => _e
    false
  end

  def self.json_to_order_array(raw_json,item='')
    orders = []
    begin
    parsed_json=JSON.parse(raw_json)

    parsed_json['payload']['orders'].each do |json_order|
      orders << json_to_order(json_order,item)
    end
    rescue JSON::ParserError => e
      WFLogger.instance.warn("Malformed JSON :#{e}")
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