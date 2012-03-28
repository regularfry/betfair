require 'daemons'

simplebot = { :app_name   => 'simplebot',
              :dir_mode   => :script,
              :dir        => '../'
             }
             
Daemons.run('./simplebot.rb', simplebot)