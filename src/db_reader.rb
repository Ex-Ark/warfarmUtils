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
      WFLogger.instance.error "unknown filename #{filename}\n"
    end
    r # => ARRAY < STRING >
  end
end