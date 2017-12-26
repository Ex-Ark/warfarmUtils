require 'json'
require 'net/http'
require 'uri'
require 'openssl'

require_relative 'src/wf_controller'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
# shit solution for Ocra SSL CHECK keep failing
ctr = WFController.new
ctr.load_files ARGV

loop do
  all_orders = ctr.query_items
  buy_orders = OrderFilter.sort_orders_by_price(OrderFilter.filter_ingame_buyers all_orders)
  system 'clear' or system 'cls'
  buy_orders.each do |ord|
    print "#{ord}#{ord.price>=10 ? "#{ord.create_custom_private_message}" : "\n"}"
  end

  exit if defined?(Ocra) # Ocra uses dynamic dependence resolution
  # => if we are bundling the app we have to exit after 1st loop
  0.step(300, 5) do |i|
    printf("\rNext update: [%-60s]", "=" * (i/5))
    sleep(0.5)
  end
  print "\n"
end