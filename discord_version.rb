require 'json'
require 'net/http'
require 'uri'

require 'discordrb'

require_relative 'src/wf_controller'

DISCORD_MAX_CHAR_PER_MESSAGE=2000

# requires you to have an api key for you project
# https://discordapp.com/developers/applications/me/
token = File.open('discord_api_key.sd').readline

p "token found: #{token}\n"

bot = Discordrb::Commands::CommandBot.new token: token, prefix: '!', client_id: '400033254830374913'
known_commands = {
 help:
  "You are currently reading this silly!",
 ping:
  "Test me, if i'm up i'll answer pong!", 
 syndicate:
  "Get all orders from warframe.market for given syndicates\n\
   Aliases: s | search\n\
   Usage: <syndicate1> [ <syndicate2> ]\n\
   Get all available syndicates by calling !syndicate without params"
}
bot.command :help do |_event, *args|
 out = [] 
 out << "Here is the list all currently available commands:"
 known_commands.each do |command,explanation|
   out << "!#{command}             ~> *#{explanation}*"
 end
 out.join("\n")
end

bot.command [:syndicate, :search, :s] do |_event, *args|
  if args.any?
    files = []
    bot.send_temporary_message(_event.channel.id, "*Requesting datas! Hold on #{_event.author.name} ..*\n",30)
    p "#{bot.prefix}:syndicate #{args}"
    args.each do |syndic|
      files << "#{syndic}.wf"
    end
    ctr = WFController.new
    ctr.load_files files
    all_orders = ctr.query_items
    buy_orders = OrderFilter.sort_orders_by_price(OrderFilter.filter_ingame_buyers all_orders)
    out = []
    buy_orders.each do |ord|
	  out << "#{ord}#{ord.price>=10 ? "\n#{ord.create_custom_private_message}" : ''}" unless ord.price < 9
    end
	out = out.join("\n")
	if out.length >= DISCORD_MAX_CHAR_PER_MESSAGE
		bot.send_message(_event.channel.id, "*My text exceeds the 2000 characters limit of Discord\nThis message might be cut sorry :/* \n")
		bot.send_message(_event.channel.id, out[0..DISCORD_MAX_CHAR_PER_MESSAGE-1])
		bot.send_message(_event.channel.id, out[DISCORD_MAX_CHAR_PER_MESSAGE..out.length])
	else 
		bot.send_message(_event.channel.id, out)
		bot.send_temporary_message(_event.channel.id, "\n*loaded in #{Time.now - _event.timestamp} seconds.*",5)
	end
    # Again, the return value of the block is sent to the channel
    ''
  else
    "*No syndicates provided\n Retry with the followings : perrin loka veil hexis suda*"
  end
end

bot.command [:ping, :pang] do |_event, *args|
 'pong'
end

puts "This bot's invite URL is #{bot.invite_url}."
puts 'Click on it to invite it to your server.'
bot.run
