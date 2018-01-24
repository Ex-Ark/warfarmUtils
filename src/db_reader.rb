# read .wf file and returns array of items
class WFReader
  def self.readWFFile(filename)
    r = []
    begin
      # check exact filename, if doesn't exists search in db/ folder
      if File.exist?(filename)
        contents = File.read filename
      else
        contents = File.read "db/#{filename}"
      end
      contents.each_line do |item|
        r << item.strip!
      end
      WFLogger.instance.info "#{self.to_s} now has #{r.size} items"
    rescue
      WFLogger.instance.error "unknown filename #{filename}"
    end
    r # => ARRAY < STRING >
  end
end