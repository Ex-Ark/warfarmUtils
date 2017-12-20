
require 'json'
require 'net/http'
require 'uri'
require 'thread'

require_relative 'model/order.rb'
require_relative 'filter.rb'
require_relative 'dal.rb'

VERSION_FIELD = 'v1'.freeze
ITEMS_FIELD = 'items'.freeze
ORDERS_FIELD = 'orders'.freeze

DEBUG_LEVEL = false unless defined? DEBUG_LEVEL # 0 means no debug

WARFRAME_MARKET_API_URL ='https://api.warframe.market'.freeze unless defined? WARFRAME_MARKET_API_URL

# designed to work with the Warframe.market JSON API
# api.warframe.market/VERSION_FIELD/ITEMS_FIELD/$searchedItem/ORDERS_FIELD
class APIGetter
  #: @base_url json api url
  def initialize(base_url=WARFRAME_MARKET_API_URL)
    @url = base_url
  end

  # returns array containing all orders for this item
  # does not filter results
  def get_all_orders_for_item(item_name)
    json = get_json_content_for_item item_name
    orders = WFDAL.json_to_order_array json
    orders.each do | order|
      order.item = item_name
    end
    orders
  end

  # request url and returns Json Data
  def get_json_content_for_item(item_name)
    begin
      uri = forge_URI_item_orders(item_name)
      response = get_response(uri)
      parsed = JSON.parse(response)
    rescue SocketError
      print "Error while trying to connect to #{uri.to_s}\n" if DEBUG_LEVEL
    rescue JSON::ParserError => e
      print "Error in malformed JSON.\n #{e}" if DEBUG_LEVEL
    end
    parsed
  end



  def get_all_orders_for_item_list(items)
    start = Time.now
    orders = []
    items.compact.each do |item|
      item.strip!
      print "Querying JSON #{item} ...\n" if DEBUG_LEVEL
      arr = JSON.parse(get_response(forge_URI_item_orders(item)))
      arr['payload']['orders'].each do |order|
        orders << Order.new(
            order['user']['ingame_name'],
            order['platinum'],
            order['order_type'],
            item,
            order['platform'],
            order['user']['status']
        )
      end
    end
    finish = Time.now
    print "loaded in #{finish-start} seconds\n" if DEBUG_LEVEL
    orders
  end

  # threaded version of above function
  def threaded_get_all_orders_item(items)
    start = Time.now
    threads = []
    orders = []
    mutex = Mutex.new
    items.compact.each do |item|
      threads << Thread.new(item,orders) do | item, orders|
        item.strip!
        print "Querying JSON #{item} ...\n" if DEBUG_LEVEL
        arr = JSON.parse(get_response(forge_URI_item_orders(item)))
        begin
        arr['payload']['orders'].each do |order|
          mutex.synchronize{ orders << Order.new(
              order['user']['ingame_name'],
              order['platinum'],
              order['order_type'],
              item,
              order['platform'],
              order['user']['status']
          )
          }
        end
        rescue NoMethodError => e
          print("#{item} UNKNOW : #{e}\n") if DEBUG_LEVEL
        end
      end
    end
    threads.each(&:join)
    finish = Time.now
    print "loaded in #{finish-start} seconds\n" if DEBUG_LEVEL
    orders
  end

  private

  # does the HTTP request from uri, provided by forge functions
  def get_response(uri)
    Net::HTTP.get(uri) # => String
  end

  # returns the URI for this item's json
  # as described in this class top-documentation
  def forge_URI_item(item_name)
    URI("#{@url}/#{VERSION_FIELD}/#{ITEMS_FIELD}/#{item_name}")
  end

  # concatenate uri from designed item with ORDERS_FIELD using forge_URI_item
  def forge_URI_item_orders(item_name)
    URI("#{forge_URI_item(item_name)}/#{ORDERS_FIELD}")
  end

  def forge_URI_all
    URI("#{@url}/#{VERSION_FIELD}/#{ITEMS_FIELD}")
  end
end