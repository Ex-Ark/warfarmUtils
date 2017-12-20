
DEBUG_LEVEL = false unless defined? DEBUG_LEVEL # 0 means no debug

# read .wf file and returns array of items
class WFReader
  def self.readWFFile(filename)
    r = []
    begin
      contents = File.read "db/#{filename}"
      contents.each_line do |item|
        r << item.strip!
      end
    rescue LoadError
      print "unknown filename #{filename}\n" if DEBUG_LEVEL
    end
    r # => ARRAY < STRING >
  end
end