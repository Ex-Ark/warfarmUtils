require 'json'
require 'http'

def get_full_url logo_path
	"https://warframe.market/static/assets/#{logo_path}"
end

def get_item_info item_name
	r = Http.get "https://api.warframe.market/v1/items/#{item_name}"
	if r.status.success?
		parsed = r.parse(:json)['payload']['item']
		the_item = parsed['id']
		item = parsed['items_in_set'].find { |item| item['id'] == the_item}
		item
	end
end

def get_item_logo item_name
	item = get_item_info item_name
	get_full_url item['icon']
end

def get_item_thumbnail item_name
	item = get_item_info item_name
	get_full_url item['thumb']
end