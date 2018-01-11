require 'logger'

LEVEL = Logger::INFO  # change here the level of log you want to have

# WFLogger is used in the project to log errors, progress, infos
# Wrapping the Logger class and encapsulating it into a Singleton
# Reroute log output to a log file at the project's root directory
class WFLogger < Logger
  @@wflog = nil;

  # singleton
  def self.instance
    if(@@wflog.nil?)
      open('wf.log','w') # clear log file
      @@wflog = WFLogger.new 'wf.log' # redirect logging output to wf.log
      @@wflog.level = LEVEL
    end
    return @@wflog
  end

  protected_methods :new
end