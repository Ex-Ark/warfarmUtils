## Synopsis

This ruby script *aim to simplify* the browsing of the *unofficial* Warframe Market website http://warframe.market

Requests the API for multiple items/mods at once, can be given customizable filters, can be used to determine profitable trades and/or best deal.

## Bot usage example
![usage_example_search_syndicate](https://www.dropbox.com/s/7ipya2ldo751ikv/bot_discord_warfarm_syndicate.PNG?raw=1)
## Code Example

Get all online buyers for a given pool of items (ex: syndicates items)
```
files << 'perrin.wf'
files << 'loka.wf'
ctr = WFController.new
ctr.load_files files
all_orders = ctr.query_items
buy_orders = OrderFilter.filter_ingame_buyers(all_orders)
buy_orders.each do |ord|
    # your thing goes here
end
```

Determine profitable trades ( usage will be changed Soon™)
``` 
items =  WFReader.readWFFile 'buy_sell.wf'
s = Smart.new 
profitables = s.threaded_get_all_interesting_items items
## request these items from the API, compare prices, online status
## returns profitable and available trades
profitables.each do |profitable|
  print "#{profitable}\n"       ## display each profitable trade (Object typeof Order)
end
```
## Motivation

Because at the time, warframe.market doesn't support multiple requests, and you have to keep multiples tabs opened to watch an entire pool of items.

Because I'm that lazy.

Because I can.

## Installation

##Windows

To quickly run this project simply pick from the build/ directory the app.exe and the db/ directory.

The executable expects params, that are files containing item list.

If you don't want to create your own pool of items just pick any existing .bat launcher you want.

` .\start_app_with_perrin.bat`

If you don't trust my .exe you will have to setup Ruby environment on your machine. ( => git clone )

 `ruby app.rb`

If you want to modify and then bundle my lib into and .exe install Ocra gem and run

` .\export_project_to_bundle_exe.bat`
`.\export_buy_sell_to_bundle_exe.bat`

This will remove the build directory and generate a new one accordingly to your current db/ directory and ruby source code.

##Linux

Soon™

## Warframe Market API
12 / 2017 https://api.warframe.market/v1/items/HERE_YOUR_ITEM/orders

## License

GNU public license v3.0
