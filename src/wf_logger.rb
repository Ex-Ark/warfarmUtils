require 'logger'

#Logger class of this project
class WFLogger < Logger
  @@wflog = nil;

  # singleton
  def self.instance
    if(@wflog.nil?)
      @@wflog = WFLogger.new open('wf.log','a') # redirect logging output to wf.log
    end
    return @@wflog
  end

  def self.set_level level
    @@wflog.level level
  end

  protected_methods :new
end