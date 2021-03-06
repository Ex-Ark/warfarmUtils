require_relative 'api_getter'
require_relative 'filter'
require_relative 'db_reader'
require_relative 'dal'
require_relative 'wf_logger'

class WFController
  attr_reader :items

  def initialize(files=nil)
    @api_getter = APIGetter.new
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
      orders = @api_getter.get_all_orders_item @items
    else
      WFLogger.instance.warn 'No items to query, perhaps you have not used # load_files(files)'
    end
    orders
  end
end