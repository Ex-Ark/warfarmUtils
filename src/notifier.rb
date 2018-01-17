require 'notify-send'


PLAT_ICON = File.expand_path('../db/images/plat.png')

class Notifier

  # send desktop notification
  def self.notify(body,icon,timeout=4000)
    NotifySend.send({summary: 'WFUtils', body: body, icon: icon, timeout: timeout})
  end

  # notify that an offer is worth $plat
  def self.notify_plat(plat)
    notify "Profit of <b>#{plat}</b> plats!\nCheck app for more info.",PLAT_ICON
  end

  # notify that $count people are interested in $name syndicate
  def self.notify_syndicate(name,count)
    ico = File.expand_path("../db/images/#{name}.png")
    notify "#{count==0?'No':count} people interested in #{name.capitalize}",ico
  end
end

