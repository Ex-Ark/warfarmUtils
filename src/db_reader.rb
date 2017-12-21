# read .wf file and returns array of items
class WFReader
  def self.readWFFile(filename)
    r = []
    begin
      contents = File.read "db/#{filename}"
      contents.each_line do |item|
        r << item.strip!
      end
      WFLogger.instance.info "#{self.to_s} read #{r.size} items"
    rescue
      WFLogger.instance.error "unknown filename #{filename}"
    end
    r # => ARRAY < STRING >
  end
end