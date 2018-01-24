require 'json'
require 'net/http'
require 'uri'
require 'openssl'

require_relative 'src/wf_controller'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
# shitty solution for Ocra SSL CHECK keep failing

ctr = WFController.new
ctr.load_files ARGV
all_orders=[]
updated = nil
lock = Mutex.new

system 'cls' or system 'clear'
print "\nPlease wait...\n"

# update the orders when querying is done
query_thread = Thread.new do
  loop do
    all_orders = OrderFilter.sort_orders_by_price((OrderFilter.filter_ingame_buyers(ctr.query_items)))
    lock.lock
    updated = true
    lock.unlock
    sleep 5
  end
end

# display changes only if the query thread updated the orders
display_thread = Thread.new do
  loop do
    if updated
      system 'cls' or system 'clear'
      all_orders.each do |ord|
        print "#{ord}#{ord.price>=10 ? "#{ord.create_custom_private_message}" : "\n"}"
      end
      lock.lock
      updated=false
      lock.unlock
    end
    sleep 1
  end
end

exit if defined?(Ocra) # Ocra uses dynamic dependence resolution
# => if we are bundling the app we have to exit after 1st loop

#main program loop, threads do all the work
loop do
  sleep 50
end