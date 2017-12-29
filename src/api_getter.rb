
require 'json'
require 'net/http'
require 'uri'
require 'thread'

require_relative 'wf_logger'
require_relative 'model/order'
require_relative 'filter'
require_relative 'dal'

VERSION_FIELD = 'v1'.freeze
ITEMS_FIELD = 'items'.freeze
ORDERS_FIELD = 'orders'.freeze


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
      WFLogger.instance.error "Error while trying to connect to #{uri.to_s}"
    rescue JSON::ParserError => e
      WFLogger.instance.error "Error in malformed JSON.\n#{e}"
    end
    parsed
  end

  # threaded
  def threaded_get_all_orders_item(items)
    start = Time.now
    threads = []
    orders = []
    mutex = Mutex.new
    items.compact.each do |item|
      threads << Thread.new(item,orders) do | item, orders|
        item.strip!
        WFLogger.instance.info "Querying JSON #{item} ..."
        begin
          sleep(rand(10)) #TODO : request in controller as background process to avoid flodding the server
          #TODO complete thread to query and update datas, another thread to display UI
          arr = JSON.parse(get_response(forge_URI_item_orders(item)))
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
        rescue JSON::ParserError => e
          WFLogger.instance.warn("#{item} Invalid Json : #{e}")
        rescue NoMethodError => e
          WFLogger.instance.warn("#{item} UNKNOWN : #{e}")
        end
      end
    end
    threads.each(&:join)
    finish = Time.now
    WFLogger.instance.info "loaded in #{finish-start} seconds"
    orders
  end

  private

  # does the HTTP request from uri, provided by forge functions
  def get_response(uri)
    res = Net::HTTP.get_response(uri)
    if res.code == '200'
      ret = res.body
    else ret = "Html error : #{res.code}"
    end
    ret # => String
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