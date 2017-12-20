DEBUG_LEVEL = false # 0 means no debug
# you have to defined DEBUG var before including finder, because of multiple definition

require 'json'
require 'net/http'
require 'uri'
require 'openssl'

require_relative 'src/api_getter.rb'
require_relative 'src/filter.rb'
require_relative 'src/db_reader.rb'
require_relative 'src/dal.rb'

WARFRAME_MARKET_API_URL ='https://api.warframe.market'.freeze unless defined? WARFRAME_MARKET_API_URL
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
# shit solution for Ocra SSL CHECK keep failing

warframeFinder = APIGetter.new WARFRAME_MARKET_API_URL

items = []
ARGV.each do|arg|
  items.concat WFReader.readWFFile arg
end
items.uniq!
##WFDAL::json_to_order_array warframeFinder.get_json_content_for_item(items[0])
loop do
  items.shuffle!
  # has to use items list because API doesn't support global GET ( all items at once )
  all_orders = warframeFinder.threaded_get_all_orders_item items
  buy_orders = OrderFilter.filter_ingame_buyers( all_orders)
  print "Loading datas...\n" if DEBUG_LEVEL
  OrderFilter.sort_orders_by_price buy_orders
  system 'clear' or system 'cls' if !DEBUG_LEVEL
  buy_orders.each do |ord|
    print "#{ord}#{ord.price>=10 ? "#{ord.create_custom_private_message}" : "\n"}"
  end
  if DEBUG_LEVEL
    print "\n---- Price Check ----\n"
    items.compact.each do |item|
      price = OrderFilter.filter_lowest_price_seller_for_item(all_orders,item)
      print "#{item} "
      if price == nil
        print ("not in sold !\n")
      else print("#{price}p\n")
      end
    end
  end

  exit if defined?(Ocra) # Ocra uses dynamic dependence resolution
  # => if we are bundling the app we have to exit after 1st loop
  0.step(300, 5) do |i|
    printf("\rNext update: [%-60s]", "=" * (i/5))
    sleep(0.5)
  end
  print "\n"
end