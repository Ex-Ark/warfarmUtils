require 'json'
require 'net/http'
require 'uri'

require 'discordrb'

require_relative 'src/wf_controller'

# requires you to have an api key for you project
# https://discordapp.com/developers/applications/me/
token = File.open('discord_api_key.sd').readline

p "token found: #{token}\n"

bot = Discordrb::Commands::CommandBot.new token: token, prefix: '!', client_id: '400033254830374913'

bot.command :syndicate do |_event, *args|
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
    out = ''
    buy_orders.each do |ord|
      out << "#{ord}\n#{ord.price>=10 ? "#{ord.create_custom_private_message}" : ''}"
    end
    bot.send_temporary_message(_event.channel.id, "\n*loaded in #{Time.now - _event.timestamp} seconds.*",5)
    # Again, the return value of the block is sent to the channel
    out
  else
    "*No syndicates provided\n Retry with the followings : perrin loka veil hexis suda*"
  end
end

bot.command :ping do |_event, *args|
 'pong'
end
puts "This bot's invite URL is #{bot.invite_url}."
puts 'Click on it to invite it to your server.'
bot.run