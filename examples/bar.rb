require 'betfair'
  
bf = Betfair::API.new  
helpers = Betfair::Helpers.new

# Test your API limits out

1.times do |i|
  session_token = bf.login('username', 'password', 264, 0, 0, nil).to_s
  puts session_token
  puts i
end

20.times do |i|
  puts bf.get_all_markets(session_token, 2, [1,3], nil, nil, '2012-01-23', '2012-01-24').split(':')
  puts i
end

40.times do |i|
  details =  bf.get_market(session_token, 1, 104678293)   
  prices = bf.get_market_prices_compressed(session_token, 1, 104678293)
  puts helpers.combine(details, prices)
end
