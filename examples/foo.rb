require 'betfair'
  
bf = Betfair::API.new  
helpers = Betfair::Helpers.new

session_token = bf.login('username', 'password', 82, 0, 0, nil).to_s
puts session_token
puts ""

# This call just returns back a huge string, markets ar edeliminated by ':', run the split method to convert string to a array
markets = bf.get_all_markets(session_token, 1, [1,3], nil, nil, nil, nil).split(':')

# puts helpers.all_markets(markets)

# Loop though the markets array
markets.each do |market| 
  
  # Once we have a market then the fields with in this are delimnated by '~', run the split method to convert string to a array
  market = market.split('~')
  
  market_id = market[0]
  market_name = market[1].to_s
  menu_path = market[5]
  
  # Now lets just look for Match Odds for Tottenham for the English Premier League
  if market_name == 'Match Odds' and menu_path.include? 'Barclays Premier League' and menu_path.include? 'Tottenham'
    # Run the API call to get the Market Info
    details =  bf.get_market(session_token, 1, market_id)
    # Run the API call to get the prices
    prices = bf.get_market_prices_compressed(session_token, 1, market_id)
    
    # Pump the data into the helpers
    
    puts helpers.market_info(details)
    puts ""
    puts helpers.combine(details, prices)
    puts ""
    puts helpers.prices_complete(prices)
    
  end
  
end