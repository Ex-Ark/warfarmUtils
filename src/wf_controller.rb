require_relative 'api_getter'
require_relative 'filter'
require_relative 'db_reader'
require_relative 'dal'
require_relative 'wf_logger'

class WFController
  attr_reader :items

  def initialize(files=nil)
    @api_getter = WFAPI::APIGetter.new
    @items = []
    if(!files.nil?) then load_files(files) end
  end

  # append data from files
  def load_files files
    files.each do|file|
      @items.concat WFReader.readWFFile file
    end
    @items.uniq!
  end
  def query_items
    orders = []
    if(!@items.empty?)
      @items.shuffle! #ninja
      orders = try_threaded_get_all_orders_for_multiple_item @items
    else
      WFLogger.instance.warn 'No items to query, perhaps you have not used # load_files(files)'
    end
    orders
  end

  private
  # returns array containing all orders for this item
  # does not filter results
  def get_all_orders_for_item(item_name)
    json =@api_getter.get_web_content_for_item item_name
    orders = WFDAL::json_to_order_array json
    orders.each do | order|
      order.item = item_name
    end
    orders
  end

  def get_all_orders_for_multiple_item(items)
    start = Time.now
    orders = []
    json_arr =[]
    items.compact.each do |item|
      item.strip!
      json_arr << @api_getter.get_web_content_for_item(item)
    end # get all web content
    # then parse everything
    json_arr.each do |raw_json|
      orders.concat WFDAL::json_to_order_array(raw_json)
    end
    finish = Time.now
    WFLogger.instance.info "loaded in #{finish-start} seconds"
    orders
  end

  def try_threaded_get_all_orders_for_multiple_item(items)
    start = Time.now
    threads = []
    orders = []

    mutex = Mutex.new
    Thread::abort_on_exception=false # TODO  : does not stop a single thread but the whole program

    items.compact.each do |item|
      begin
        threads << Thread.new(item,orders) do | item, orders|
          begin
            content = @api_getter.get_web_content_for_item item
            item_orders = WFDAL::json_to_order_array content
            mutex.synchronize{
              orders.concat item_orders
            }
          rescue NoMethodError => e
            WFLogger.instance.warn("#{item} UNKNOWN : #{e}")
            mutex.synchronize{
              @items.delete(item) # the item does not exist, no point in querying it in the future
            }
          rescue WFAPI::APIError => e
            raise e
          end
        end
      rescue WFAPI::APIError => e
        WFLogger.instance.info("flooding api, sleeping 1 second")
        items << item # we still have to query this item again
        sleep(1)
      end
    end
    threads.each(&:join)
    finish = Time.now
    WFLogger.instance.info "loaded in #{finish-start} seconds"
    orders
  end
end