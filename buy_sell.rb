require_relative 'src/smart'
require_relative 'src/db_reader'
require 'openssl'

DEBUG_LEVEL = true if ARGV[0]=='debug' || ARGV[0]=='-debug'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

items = []
items.concat WFReader.readWFFile 'buy_sell.wf'
items.shuffle!
items.uniq!

if DEBUG_LEVEL
  s = Smart.new Smart::Verbose_level::ALL
else
  s = Smart.new
end

batch = s.threaded_get_all_interesting_items items

exit if defined?(Ocra)

batch.each do |res|
  print "#{res}\n"
end



print "Press any key to close this window.."
gets




