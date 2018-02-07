require 'net/http'
require 'uri'
require 'json'

require_relative 'wf_logger'

VERSION_FIELD = 'v1'.freeze
ITEMS_FIELD = 'items'.freeze
ORDERS_FIELD = 'orders'.freeze


WARFRAME_MARKET_API_URL ='https://api.warframe.market'.freeze unless defined? WARFRAME_MARKET_API_URL

module WFAPI

class APIError < StandardError
  attr_reader :request
  def initialize(msg='API responded with an error', req=nil)
    @request = req
    super("#{msg}:#{req != nil ? req : ''}")
  end
end

# designed to work with the Warframe.market JSON API
# api.warframe.market/VERSION_FIELD/ITEMS_FIELD/$searchedItem/ORDERS_FIELD
class APIGetter

  #: @base_url json api url
  def initialize(base_url=WARFRAME_MARKET_API_URL)
    @url = base_url
  end

  # request url and returns api answer
  def get_web_content_for_item(item_name)
    begin
      uri = forge_URI_item_orders(item_name)
      WFLogger.instance.info "Querying JSON #{item_name} ..."
      response = get_response(uri);
    rescue SocketError
      WFLogger.instance.error "Error while trying to connect to #{uri.to_s}"
    rescue APIError => e
      raise e
    end
    response # => String
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

  # does the HTTP request from the uri provided by forge functions
  def get_response(uri)
    res = Net::HTTP.get_response(uri)
    if res.code == '200'
      ret = res.body
    else raise WFAPI::APIError.new('net::http get response error',uri.to_s)
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

end # api getter end

end # module end