# BETFAIR API #
## Install the gem ##

Install it with [RubyGems](http://rubygems.org/gems/betfair)

      gem install betfair

or add this to your Gemfile if you use [Bundler](http://gembundler.com/):

      gem 'betfair'    

## Introduction ## 
In a irb console

  require 'betfair'

From a Gemfile

  gem 'betfair'

Load the general api class

  bf = Betfair::API.new

If you want to use a proxy or turn on Savon's logging then just pass
in like so:

This is a local squid proxy I tunnel to from my local 
machine to access the host server in UK for dev purposes.

  proxy = 'http://localhost:8888' 
  logging = true
  bf = Betfair::API.new(proxy, logging)

Proxies can be useful if you want to host on a cloud service such as
Heroku, as you will be denied access to the Betfair API from the
USA. Just proxy via a server from a country that Betfair allows, such
as the UK.

# General API METHODS #
## Login ##
At the heart of the Betfair API is the `session_token`. In order to
get one of these simply call:

  username = 'foo'
  password = 'bar'
  product_id = 82
  vendor_software_id = 0
  location_id = 0
  ip_address = nil

  session_token = bf.login(username, password, product_id, vendor_software_id, location_id, ip_address)

The `session_token` value you get back responds to #success? which will tell you whether login
was successful or not.  If `session_token.success?` returns false,
`session_token.to_s` will give you the error message.

The standard `product_id` is 82, you may have a different one depending
on the level of Betfair API access that you have.

## Logout ##
It is considered good API etiquette to logout once you are done. 

  foo = bf.logout(session_token)

## Keep Alive ##
Your session_token will expire after 20 mins of inactivity. 
Supposedly the token gets refreshed with every API call you make, 
but I am not convinced of this.
This call will refresh it for another 20 mins.
  
  session_token = bf.keep_alive(session_token)

# Read-Only Betting API METHODS #
## Get All Markets ##
The API GetAllMarkets service allows you to retrieve information about all of 
the markets that are currently active or suspended on the given exchange.    

  exchange_id     = 1       # 1 == UK, 2 == AUS
  event_type_ids  = [1,3]   # Full list here http://data.betfair.com/sportids.htm
  locale          = nil 
  countries       = nil 
  from_date       = Time.now.utc
  to_date         = 30.minutes.from_now.utc
  
  markets = 
    bf.get_all_markets(session_token, exchange_id, event_type_ids, locale, countries, from_date, to_date)

## Get MU Bets ##    
The API GetMUBets service allows you to retrieve information about all 
your matched and unmatched bets on a particular exchange server.

  exchange_id   = 1
  market_id     = 12345
  bet_status    = 'MU'
  start_record  = 0
  record_count  = 200
  sort_order    = 'ASC'
  order_by      = 'PLACED_DATE'

  mu_bets =
    bf.get_mu_bets(session_token, exchange_id, market_id, bet_status, start_record, record_count, sort_order, order_by)

## Get Market ##
The API GetMarket service allows the customer to input a Market ID and 
retrieve all static market data for the market requested.

  exchange_id   = 1
  market_id     = 12345
  locale        = nil

  market 
    = bf.get_market(session_token, exchange_id, market_id, locale)

## Get Market Prices Compressed ##
The API GetMarketPricesCompressed service allows you to retrieve 
dynamic market data for a given Market ID in a compressed format. 

  exchange_id       = 1
  market_id         = 12345
  currency_code     = nil

  price = 
    bf.get_market_prices_compressed(session_token, exchange_id, market_id, currency_code)

## Get Active Event Types ##
The API GetAllEventTypes service allows the customer to retrieve lists of all categories of sports 
(Games, Event Types) that have at least one market associated with them, 
regardless of whether that market is now closed for betting. 

  locale = nil

  active_event_types = 
    bf.get_active_event_types(session_token, locale)

## Get Account Funds ##
The API GetAccountFunds service allows you to retrieve information 
about your local wallet on a particular exchange server. 

  exchange_id = 1

  funds = 
    bf.get_account_funds(session_token, exchange_id)

# Bet Placement API METHODS #
## Place Bet ##
The API PlaceBets service allows you to place multiple (1 to 60) bets on a single Market. 

  exchange_id     = 1
  market_id       = 122435
  selection_id    = 58805
  bet_type        = 'B' # Or L for Lay
  price           = 2.0
  size            = 2.0

  place_bet = 
    bf.place_bet(session_token, exchange_id, market_id, selection_id, bet_type, price, size) 

## Place Multiple Bets ##
The API PlaceBets service allows you to place multiple (1 to 60) bets on a single Market. 

  exchange_id     = 1
  bets            = []
  bets <<  { market_id: 12345, runner_id: 58805, bet_type: 'B', price: 2.0, size: 2.0, asian_line_id: 0, 
              bet_category_type: 'E', bet_peristence_type: 'NONE', bsp_liability: 0 }

  place_multiple_bets =               
    bf.place_multiple_bets(session_token, exchange_id, bets)

## Update Bet ##
The API UpdateBets service allows you to edit multiple (1 to 15) bets on a single Market.

  exchange_id = 1
  bet_id: 1234, 
  new_bet_persistence_type = 'NONE'
  new_price = 10.0
  new_size = 10.0 
  old_bet_persistence_type = 'NONE'
  old_price= 5.0
  old_size = 5.0

  update_bet = 
    bf.update_bet(session_token, exchange_id, bet_id, new_bet_persistence_type, new_price, new_size, old_bet_persistence_type, old_price, old_size)

## Update Multiple Bets ##
The API UpdateBets service allows you to edit multiple (1 to 15) bets on a single Market.

  exchange_id = 1
  bets = []
  bets << { bet_id: 1234, new_bet_persistence_type: 'NONE', new_price: 10.0, new_size: 10.0, 
            old_bet_persistence_type: 'NONE', old_price: 5.0, old_size: 5.0 }
          
  update_multiple_bets  =
   bf.update_multiple_bets(session_token, exchange_id, bets
  
  
## Cancel Bet ##
The API CancelBets service allows you to cancel multiple unmatched (1 to 40) bets placed on a single Market.

  exchange_id   = 1
  bet_id        = 1235

  cancel_bet = 
    bf.cancel_bet(session_token, exchange_id, bet_id)

## Cancel Multiple Bets ##
The API CancelBets service allows you to cancel multiple unmatched (1 to 40) bets placed on a single Market.

  exchange_id   = 1
  bet_ids       = [16939689578, 16939689579, 169396895710]

  cancel_multiple_bets = 
    bf.cancel_multiple_bets(session_token, exchange_id, bets)

# Helpers #
There are a bunch of helper methods to help you handle the output from the various API calls.

  helpers = Betfair::Helpers.new

## All Markets ##

  helpers.all_markets(markets)

## Market Info ##

  helpers.market_info

## Combine ##

  helpers.combine

## Details ##

  helpers.details

## Prices ##

  helpers.prices

## Prices Complete ##

  helpers.prices_complete

## Prices String ##

  helpers.prices_string

## Split Markets String ##

  helpers.split_markets_string

# Extra # 
## API Limits ##
[Betfair API Limits](http://bdp.betfair.com/index.php?option=com_content&task=view&id=36&Itemid=64)

## Requirements ##
* savon

## Requirements for testing ##
* savon_spec
* rspec
* rake

## To Do ##
* The WOM of money in Helpers#price_string returns 0 if either all b1,b2,b3 or l1,l2,l3 are all 0
* Add some error checking to the Betfair::Helper methods
* Finish of the mash method, to return a nice hash of all market and runner info
* Write a spec for the mashed method

## Contribute ##
I have only added the Betfair API method calls that I need. 

Feel free to fork this repo, add what you need to with the relevant
RSpec tests and send me a pull request.


## License ##
(The MIT License)

Copyright (c) 2011 Luke Byrne

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
