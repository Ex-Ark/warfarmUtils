require 'thread'
require_relative 'src/wf_controller'

files = []
files << 'perrin.wf'
files << 'loka.wf'
ctr = WFController.new
ctr.load_files  files
all_orders=[]
updated = nil
lock = Mutex.new

  print "Please wait...\n"

  g = Thread.new do
    loop do
      all_orders = OrderFilter.sort_orders_by_price((OrderFilter.filter_ingame_buyers(ctr.query_items)))
      lock.lock
        updated = true
      lock.unlock
      sleep 5
    end
  end

  d = Thread.new do
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

loop do
  sleep 50
end