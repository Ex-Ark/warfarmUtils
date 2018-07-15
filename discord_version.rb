require 'json'
require 'uri'
require 'http'
require 'time'
require 'discordrb'


DISCORD_MAX_CHAR_PER_MESSAGE=2000


# requires you to have an api key for you project
# https://discordapp.com/developers/applications/me/
token = File.open('discord_api_key.sd').readline

# this is my secret api
REMOTE_API = File.open('remote_api.sd').readline

puts "token found: #{token}"
puts "linked to remote api : #{REMOTE_API}"
response = Http.get "#{REMOTE_API}/syndicates"
SYNDICATES = response.parse(:json)

SHORT_SYNDICATE_NAME = {
  veil: 'Red Veil',
  perrin: 'Perrin Sequence',
  loka: 'New Loka',
  meridian: 'Steel Meridian',
  hexis: 'Arbiter of Hexis',
  suda: 'Cephalon Suda'
}

def find_syndicate_id syndicate
  full_name = SHORT_SYNDICATE_NAME[syndicate.to_sym]
  s = SYNDICATES.select { |s| s['name'] == full_name }
  return s.first['id'], s.first['logo']
end

def get_all_id
  SYNDICATES.map {|s| s['id']}
end

def refresh_syndicate_orders id
  Http.put "#{REMOTE_API}/update_orders/#{id}"
end

def delete_syndicate_orders id
  Http.delete "#{REMOTE_API}/update_orders/#{id}"
end

def get_syndicate_orders id
  Http.get "#{REMOTE_API}/syndicates/#{id}/orders"
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
    Usage: !clear <syndicate>"  
}
bot.command :help do |_event, *args|
 _event.channel.send_embed do |embed|
    embed.title = "All available commands:"
    embed.color = 3447003
    embed.description = "Prefix is '!' "
   known_commands.each do |command,explanation|
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


bot.command [:syndicate, :search, :s] do |_event, *args|
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
    orders.select { |o| o['price'] >= price  }.sort_by { |o| o['price']}[0..24].each do |order|
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
