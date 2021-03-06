require 'json'
require 'uri'
require 'http'
require 'time'
require 'discordrb'
require 'active_support'
require 'active_support/core_ext'

require_relative 'scrap_item_logo'

DISCORD_MAX_CHAR_PER_MESSAGE = 2000

WFCONTENT = 'http://content.warframe.com/dynamic/worldState.php'

# requires you to have an api key for you project
# https://discordapp.com/developers/applications/me/
token = File.open('discord_api_key.sd').readline

# this is my secret api
REMOTE_API = File.open('remote_api.sd').readline.strip
# this is my secret token
wf_token = File.open('remote_api_key.sd').readline.strip

puts "token found: #{token}"
puts "linked to remote api : #{REMOTE_API}"
puts "using X-WF-TOKEN=#{wf_token}"
AUTH_HEADERS = { 'X-WF-TOKEN' => wf_token }

response = Http.get "#{REMOTE_API}/syndicates", headers: AUTH_HEADERS
SYNDICATES = response.parse(:json)

SHORT_SYNDICATE_NAME = {
    veil: 'Red Veil',
    perrin: 'Perrin Sequence',
    loka: 'New Loka',
    meridian: 'Steel Meridian',
    hexis: 'Arbiter of Hexis',
    suda: 'Cephalon Suda'
}.freeze

# returns remaining time before cetus_missions reset
def cetus_time
  resp = Http.get WFCONTENT
  world_state = resp.parse(:json)
  cetus_missions = world_state['SyndicateMissions'].select { |syndicate| syndicate['Tag']=='CetusSyndicate' }.first
  expires_at = cetus_missions['Expiry']['$date']['$numberLong'].to_i
  (expires_at / 1000) - Time.now.to_i
end

cetus_icons = {
    day: 'https://raw.githubusercontent.com/PopThosePringles/Warframe-Cetus-Time-Left/master/sun.png',
    night: 'https://raw.githubusercontent.com/PopThosePringles/Warframe-Cetus-Time-Left/master/moon.png'
}

# convert remaining time to day/nigh cycle
def cetus_day_night_cycle
  night_duration = 3000 # 50 minutes * 60 seconds
  day_duration = 6000 # 100 minutes * 60 seconds
  remaining = cetus_time
  if remaining.between?(0, night_duration)
    state = 'night'
  else
    state = 'day'
  end
  remaining += night_duration + day_duration if remaining < 0
  if remaining > night_duration
    state = 'day'
    remaining -= night_duration
  end
  hours = remaining / 3600
  minutes = (remaining % 3600) / 60
  seconds = remaining % 60
  will_be_time = DateTime.now + hours.hours + minutes.minutes + seconds.seconds
  {
    state: state,
    h: hours,
    m: minutes,
    s: seconds,
    will_be_time: will_be_time
  }
  # TODO make forecast of future time cetus clock each day / hour
end

def find_syndicate_id syndicate
  full_name = SHORT_SYNDICATE_NAME[syndicate.to_sym]
  s = SYNDICATES.select { |s| s['name'] == full_name }
  return s.first['id'], s.first['logo']
end

def get_all_id
  SYNDICATES.map { |s| s['id'] }
end

def refresh_syndicate_orders id
  Http.put "#{REMOTE_API}/update_orders/#{id}", headers: AUTH_HEADERS
end

def delete_syndicate_orders id
  Http.delete "#{REMOTE_API}/update_orders/#{id}", headers: AUTH_HEADERS
end

def get_syndicate_orders id
  Http.get "#{REMOTE_API}/syndicates/#{id}/orders", headers: AUTH_HEADERS
end

bot = Discordrb::Commands::CommandBot.new token: token, prefix: '!', client_id: '400033254830374913'
known_commands = {
    help:
        "You are currently reading this silly!",
    ping:
        "Test me, if i'm up i'll answer pong!",
    syndicate:
        "Get all orders from warframe.market for given syndicates\n\
   Minimum price can be specified, with a default value of 10\n\
   Aliases: s | search\n\
   Usage: !s <syndicate> [<min_price>]\n\
   Get all available syndicates by calling !syndicate without params",
    refresh:
        "Refresh to the most recent orders for a syndicate\n\
    Usage: !refresh <syndicate>",
    clear:
        "Clear all orders for a syndicate\n\
    Usage: !clear <syndicate>",
    item:
        "Check the online prices on warframe.market for an item\n\
         It returns the minimum price you can buy it for, and the maximum price at which you can sell\n\
        Aliases: i | price\n\
        Example: !item banshee_prime_chassis",
  cetus:
   "Get the current time cycle in Cetus\n\
    Usage: !cetus"
}
bot.command :help do |_event, *args|
  _event.channel.send_embed do |embed|
    embed.title = "All available commands:"
    embed.color = 3447003
    embed.description = "Prefix is '!' "
    known_commands.each do |command, explanation|
      embed.add_field(name: "!#{command}", value: "#{explanation}")
    end
  end
end

def refresh_syndicate name
  id, logo = find_syndicate_id name
  delete_syndicate_orders id
  refresh_syndicate_orders id
end

def clear_syndicate name
  id, logo = find_syndicate_id name
  delete_syndicate_orders id
end

bot.command :refresh do |_event, *args|
  return if args.empty?

  if args[0] == 'all'
    get_all_id.each do |id|
      refresh_syndicate_orders id
    end
    _event.channel.send_embed do |embed|
      embed.color = 3447003
      embed.description = "Refresh for all syndicates started"
    end
  else
    refresh_syndicate args[0]
    _event.channel.send_embed do |embed|
      embed.color = 3447003
      embed.description = "Refresh for #{SHORT_SYNDICATE_NAME[args[0].to_sym]} started"
    end
  end
end

bot.command :clear do |_event, *args|
  return if args.empty?

  if args[0] == 'all'
    get_all_id.each do |id|
      delete_syndicate_orders id
    end
    _event.channel.send_embed do |embed|
      embed.color = 3447003
      embed.description = "Cleared all syndicates orders"
    end
  else
    clear_syndicate args[0]
    _event.channel.send_embed do |embed|
      embed.color = 3447003
      embed.description = "Cleared #{SHORT_SYNDICATE_NAME[args[0].to_sym]} orders"
    end
  end
end

bot.command %i[time cetus] do |_event, *args|
  infos = cetus_day_night_cycle
  _event.channel.send_embed do |embed|
    embed.color = 3447003
    embed.title = 'Cetus Day/Night Cycle'
    embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: cetus_icons[infos[:state].to_sym])
    embed.description = 'Plains of Eidolon'
    embed.add_field(name: 'Current time:', value: infos[:state])
    embed.add_field(name: 'Remaining:', value: "#{infos[:h]}h:#{infos[:m]}m:#{infos[:s]}s")
    embed.add_field(name: 'Next cycle start at:', value: infos[:will_be_time].strftime('%H:%M:%S'))
  end
end

bot.command %i[item price i] do |_event, *args|
  return if args.empty?

  name = args[0]
  resp = Http.get "https://api.warframe.market/v1/items/#{name}/orders"
  if resp.status.success?
    buy_price = 0
    sell_price = Float::INFINITY
    s_player_name = b_player_name = '#ND#'
    resp.parse(:json)['payload']['orders'].each do |order|
      next if order['user']['status'] == 'offline'
      if order['order_type'] == 'sell' && order['platinum'] < sell_price
        sell_price = order['platinum']
        s_player_name = order['user']['ingame_name']
      else
        if order['order_type'] == 'buy' && order['platinum'] > buy_price
          buy_price = order['platinum']
          b_player_name = order['user']['ingame_name']
        end
      end
    end
    thumb = get_item_thumbnail name
    _event.channel.send_embed do |embed|
      embed.color = 3447003
      embed.title = 'Price check'
      embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: thumb)
      embed.description = "Online prices on warframe.market for #{name}"
      if sell_price != Float::INFINITY
        embed.add_field(name: "#{s_player_name} is currently selling it for a minimum of:", value: sell_price.to_s)
      else
        embed.add_field(name: "Nobody is currently selling it")
      end
      if buy_price != 0
        embed.add_field(name: "#{b_player_name} is currently buying it for a maximum of:", value: buy_price.to_s)
      else
        embed.add_field(name: "Nobody is currently buying it")
      end
    end
  end
end


bot.command %i[syndicate search s] do |_event, *args|
  return if args.empty?

  id, logo = find_syndicate_id args[0]
  price = args[1] ? args[1].to_i : 10
  response = get_syndicate_orders id
  orders = response.parse(:json)
  # discord limit is 25 field object
  _event.channel.send_embed do |embed|
    embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: logo)
    embed.color = 3447003
    embed.title = "#{SHORT_SYNDICATE_NAME[args[0].to_sym]} orders"
    embed.description = '25 first orders sorted by price'
    orders.select { |o| o['price'] >= price }.sort_by { |o| o['price'] }[0..24].each do |order|
      time_elapsed = ((Time.now - Time.parse(order['updated_at'])) / 60).round
      embed.add_field(name: "#{order['price']} platinum    #{time_elapsed} minutes ago", value: order['private_message'], inline: true)
    end
  end
end

bot.command [:ping, :pang] do |_event, *args|
  'pong'
end

puts "This bot's invite URL is #{bot.invite_url}."
puts 'Click on it to invite it to your server.'
bot.run
