
# object representation of a Warframe market order
class Order
  attr_accessor :player_name, :price, :type, :platform, :region,:item, :online

  def initialize(player_name,price,type,item_name,platform,online,region='en')
    @player_name = player_name
    @price = price
    @type = type
    @item = item_name
    @platform = platform
    @region = region
    @online = online
  end

  def pc?
    @platform == 'pc'
  end

  def online?
    @online == 'online'
  end

  def offline?
    !online?
  end

  def ingame?
    @online == 'ingame'
  end

  def selling?
    @type == 'sell'
  end

  def buying?
    !selling?
  end

  # returns a string that can be used in warframe chat to message the player
  # contains  player name, type of order {BUY/SELL} , price , item name
  def create_custom_private_message
    "/w #{@player_name} Hi! I want to #{selling? ? 'buy' : 'sell'} [#{@item.gsub('_',' ').split.map(&:capitalize).join(' ')}] for #{@price} platinum. Still interested?\n\n"
  end

  def to_s
    "#{@price} #{@player_name}(#{@online}) #{@item}\n"
  end
end