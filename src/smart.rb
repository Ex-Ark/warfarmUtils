require_relative 'dal.rb'
require_relative 'filter.rb'
require_relative 'api_getter.rb'
require_relative 'wf_logger'

class Smart

  # ALL means display of all orders, those not worth buying, and those that cant be bought / sold
  module Verbose_level
    ALL = 1
    INTERESTING = 2
  end

  # built from a verbose level , as defined in ::Verbose_level
  def initialize (verbose_level=Verbose_level::INTERESTING)
    @finder = APIGetter.new
    @verbose = verbose_level
  end

  # TODO : returns orders (struct ?) instead of displaying
  # display orders for a given item with selling price lower than buying price => platinum profit
  def get_interesting_orders(item)
    ords = WFDAL::json_to_order_array @finder.get_json_content_for_item(item),item
    ret = []
    where_to_buy = OrderFilter.filter_lowest_selling_price(ords)
    where_to_sell = OrderFilter.filter_highest_buying_price(ords)
    if where_to_buy
      if where_to_sell
        if where_to_buy.price < where_to_sell.price
          ret << "Item \'#{item}\'worth buying @#{where_to_buy.player_name} and selling @#{where_to_sell.player_name}"
          ret << "Profit : #{where_to_sell.price-where_to_buy.price} plat"
          ret << where_to_sell.create_custom_private_message
          ret << where_to_buy.create_custom_private_message
        else
          ret << "Item \'#{item}\'not worth buying" if @verbose == Verbose_level::ALL
          ret << "Lost : #{where_to_sell.price-where_to_buy.price} plat" if @verbose == Verbose_level::ALL
        end
      else
        ret << "Nobody buying this shit : #{item}" if @verbose == Verbose_level::ALL
      end
    else
      ret << "Nobody selling this shit : #{item}" if @verbose == Verbose_level::ALL
    end
    ret
  end

  # threaded version to get all items
  # TODO : no longer works with nginx api
  def threaded_get_all_interesting_items(items)
    start = Time.now
    threads = []
    batch = []
    mutex = Mutex.new
    items.compact.each do |item|
      threads << Thread.new(item,batch) do | item, orders|
        WFLogger.instance.info "Querying JSON #{item} ..."
        ret = get_interesting_orders item
        mutex.synchronize{
          ret.each do |str|
            batch << "#{str}\n"
          end
        }
      end
    end
    threads.each(&:join)
    finish = Time.now
    WFLogger.instance.info "loaded in #{finish-start} seconds"
    batch
  end
end

# usage :
# s = Smart.new Smart::Verbose_level::ALL
# || s = Smart.new       // equivalent to Smart::Verbose_level::INTERESTING
# s.get_interesting_orders("eternal_war")
# s.get_interesting_orders("tigris_prime_set")
# s.get_interesting_orders("soma_prime_set")