Credits
-------
Big thanks to wotsisname from the Betfair forums, as per [this post](http://forum.bdp.betfair.com/showthread.php?p=6117#post6117)
and [from here](http://bespokebots.com/betfair_bots.php).

I pretty much copied this directly from his Python bot.


Notes on what it does
---------------------

Logs in to the Betfair UK exchange and monitors the session, logging in again if the session is closed.

Calls GetAllMarkets and obtains all UK horse racing markets starting in the next 24 hours.

Filters the markets so we end up with a list of win only, single winner, odds markets with BSP disabled. 

This should leave us with only the UK win markets.

The strategy checks each market for existing bets. 
If we have no matched or unmatched bets, the bot will check for any runner available to back at 2.00 or less. 
If runners are found, it places a LAY bet at the current back price +1 tick/pip to a £2 stake. 
This places your bet at the front of the queue or gets matched immediately, depending on the back/lay price spread of the market. 
The bots maximum lay price is 2.01.

The bot does NOT have a GUI and is intended to be run on a dedicated PC/Mac or a remote VPS.
 
Therefore, you should only use this code if you are comfortable with programming in Ruby AND running your scripts from a command line. 
The API library has been thoroughly tested in a Linux production environment and uptimes exceeding 6 months are easily achieved with suitable error handling.


Disclaimer
----------
Please note that the bot strategy has NOT been tested beyond basic functionality, so I have no idea whether or not it is profitable long term. 
The free source code is only intended as an example, so it is up to YOU decide whether or not to use it. 
Please don't blame me if you lose money using the bot.


Daemonize
----------

`ruby daemonize.rb` run will test the script and output to the logfile location specified

or 

`ruby daemonize.rb` start will start the script as a daemon  and output to the logfile location specified in the background with a pidfile in the root folder


Monit
-----
See the monit.conf for an example on how to keep this alive on a server.
