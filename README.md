## Synopsis

This ruby script *aim to simplify* the browsing of the *unofficial* Warframe Market website http://warframe.market

Requests the API for multiple items/mods at once, can be given customizable filters, can be used to determine profitable trades and/or best deal.

## Code Example

Get all online buyers for a given pool of items (ex: syndicates items)
```
items = WFReader.readWFFile 'perrin.wf' ## all mods and items that are available in the Perrin Sequence Syndicate
all_orders = warframeFinder.threaded_get_all_orders_item items  ## get all orders, no matter the status, availability , price
buy_orders = OrderFilter.filter_ingame_buyers( all_orders)  ## keep only the players that are ingame AND currently buying these items
OrderFilter.sort_orders_by_price buy_orders ## sort by ascending price
buy_orders.each do |ord|
    print "#{ord}#{ord.price>=10 ? "#{ord.create_custom_private_message}" : "\n"}"  ## print the player, the price
		## as well as the private message that you can directly copy/paste into the game to contact the player
end
```

Determine profitable trades
``` 
items =  WFReader.readWFFile 'buy_sell.wf'  ## read the file containing all the mods/items you want to query
s = Smart.new ## the smart thingy that compares price for you
profitables = s.threaded_get_all_interesting_items items ## request these items from the API, compare prices, online status, and returns profitable and available trades
profitables.each do |profitable|
  print "#{profitable}\n"       ## display each profitable trade (Object typeof Order)
end
```
## Motivation

Because at the time, warframe.market doesn't support multiple requests, and you have to keep multiples tabs opened to watch an entire pool of items.

Because I'm that lazy.

Because I can.

## Installation

Windows
To quickly run this project simply pick from the build/ directory the app.exe and the db/ directory.

The executable expects params, that are files containing item list.

If you don't want to create your own pool of items just pick any .bat launcher you want.

` .\start_app_with_perrin.bat`

If you don't trust my .exe you will have to setup Ruby environment on your machine. ( => git clone )

 `ruby app.rb`

If you want modify and then bundle my lib into and .exe install Ocra gem and run

` .\export_project_to_bundle_exe.bat`
`.\export_buy_sell_to_bundle_exe.bat`

This will remove the build directory and generate a new one accordingly to your current db/ directory and ruby source code.

Linux
Soon™

## Warframe Market API
20/12/2017 https://api.warframe.market/v1/items/HERE_YOUR_ITEM/orders

## License

GNU public license v3.0
