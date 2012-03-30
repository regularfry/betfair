class SimpleBot
    
  require 'betfair'
  require 'date'
  require 'active_support/core_ext' # Only really need this one to do the easy datetime stuff such as 30.minutes.from_now.utc
  
  LOG_PATH            = '/Users/lukebyrne/Sites/current/betfair/examples/simplebot/simplebot.log' # Absolute path to where you want put your log file
  
  USERNAME            = 'username'              # BF Usernmae
  PASSWORD            = 'password'              # BF Password
  PRODUCT_ID          = 82                      # BF Product ID, Free is 82
  VENDOR_SOFTWARE_ID  = 0                       
  LOCATION_ID         = 0
  IP_ADDRESS          = nil
  
  THROTTLE            = 3                      # How many seconds to wait between checking each market
  BANDWIDTH_SAVER     = 30                      # How long to sleep for if no markets are found
  
  EXCHANGE_ID         = 2                       # Exchanges you want to hit up 1 for UK, 2 for AUS
  SPORTS_IDS          = [7]                     # Array of the sports ids you want
  LOCALE              = nil                     # What coutry are you in? Dont really use this
  COUNTRIES           = ['GBR']                 # Array of countries you wish to check for
  FROM_DATE           = Time.now.utc            # Time you want to start checking from in UTC (which is basically GMT, which is the Betfair API time)
  TO_DATE             = 30.minutes.from_now.utc # How far out do you want to look for markets
  
  MARKET_NAMES_INGORE = ['To Be Placed']        # Array of markets to ignore
  MARKET_TYPE         = 'O'                     # Not sure what this is
  MARKET_STATUS       = 'ACTIVE'                # Active market types
  NUMBER_OF_WINNERS   = 1                       # Only one winner per market
  BSP_MARKET          = true                     # Starting price market ?
  IN_PLAY             = 0                     # 0 means not in play, anything above this means in play
  
  ODDS                = 2.0                     # Bet on odds below this
  BET_SIDE            = 'L'                     # What type of bet, B for back and L for Lay
  BET_AMOUNT          = 2.0                     # Note this needs to be a minimum of $5 if you have an AUS account
  BET_PIP             = 0.01                    # Place bet one pip above the ODDS I am checking for, ie this will try and lay 2.0 pounds on odds of 2.01
  
  BF                  = Betfair::API.new        # Initialize BF API methods
  HELPERS             = Betfair::Helpers.new    # Initialize Helper API methods
  
  LOGGER              = Logger.new(LOG_PATH,'daily') # New log file daily  
  original_formatter  = Logger::Formatter.new 
  original_formatter.datetime_format = "%Y-%m-%d %H:%M:%S"
  LOGGER.formatter    = proc { |severity, datetime, progname, msg|
                          original_formatter.call(severity, datetime, progname, "#{USERNAME} - #{COUNTRIES} - #{msg}")
                        }
  
  def run
    begin
      token = login # Get our session token                  
      if token.success? # Successful login
        LOGGER.info "Logged in successfully with #{USERNAME}, token returned - #{token}. Fetching Horses from #{COUNTRIES} and looking to lay odds on runners"
        
        loop do   
          token = BF.keep_alive(token)
          LOGGER.info("Keep alive - #{token}")
                         
          LOGGER.info 'Fetching markets'
          markets = BF.get_all_markets(token, EXCHANGE_ID, SPORTS_IDS, LOCALE, COUNTRIES, FROM_DATE, TO_DATE)     
          
          if markets.is_a?(String) and markets != 'API_ERROR - NO_SESSION' # Markets returned correctly           
            check_markets(token, markets)            
            #token = nil # Set token here to nil to test the token reset below
          
          elsif markets.is_a?(String) and markets == 'API_ERROR - NO_SESSION' # Session token has expired, try and get a new one                                    
            token = reset_login
            
          else # No markets
            LOGGER.info "No markets found, going to sleep for #{BANDWIDTH_SAVER} seconds"
            sleep BANDWIDTH_SAVER                     
          end
          
        end # End loop
        
      else # No login token returned
        LOGGER.info "#{token.to_s} - exiting"
      end 
       
    rescue
       LOGGER.info "Error - SimpleBot.run - #{$!.message}\n(#{$!.class})\n#{$!.backtrace}\n"
    end    
  end
  
  def login 
    BF.login(USERNAME, PASSWORD, PRODUCT_ID, VENDOR_SOFTWARE_ID, LOCATION_ID, IP_ADDRESS)
  end
  
  def reset_login
    token = login             
    if token.success? 
      LOGGER.info "Session token has expired, got a new one - #{token}"  
    else  
      LOGGER.info "Session token has expired, trying to get a new one returned #{token.to_s}"
    end
    return token
  end
  
  def check_markets(token, markets)
    markets_hash = []
    HELPERS.split_markets_string(markets).each do |m| 
      m[:time_to_start] = m[:event_date] - FROM_DATE.to_f # Sort the hash by the time - NEED TO DO THIS
      markets_hash << m if !m[:market_id].nil? and !MARKET_NAMES_INGORE.include?(m[:market_name]) and MARKET_TYPE == m[:market_type] and MARKET_STATUS == m[:market_status] and NUMBER_OF_WINNERS == m[:number_of_winners] and IN_PLAY == m[:bet_delay] #and BSP_MARKET == m[:bsp_market]                  
    end
    
    if markets_hash.count > 0
      markets_hash.each { |m| check_runners(token, EXCHANGE_ID, m[:market_id]); sleep THROTTLE; } 
    else
      LOGGER.info "Markets found but none we are interested in, going to sleep for #{BANDWIDTH_SAVER} seconds"
      sleep BANDWIDTH_SAVER
    end
  end
  
  def check_runners(token, exchange_id, market_id)
    LOGGER.info "#{market_id} - Checking prices for market_id"
    prices = HELPERS.prices_complete( BF.get_market_prices_compressed(token, exchange_id, market_id) )            
    # Need to recheck whether the market is ACTIVE and not IN_PLAY, this time from what gets returned from prices compressed
    if MARKET_STATUS == prices[:market_status].to_s and IN_PLAY == prices[:in_play_delay]
      bets_placed = bets_already_placed(token, exchange_id, market_id)  
      LOGGER.info "#{market_id} - #{bets_placed.count} bets already placed for market_id"  
      
      bets = []
      prices.each do |k,v|        
        bets << { selection_id: v[:selection_id], b1: v[:b1] } if k.is_a?(Numeric) and !bets_placed.include?(v[:selection_id]) and v[:b1] <= ODDS.to_f       
      end
      
      if bets.count > 0
        place_bets(token, exchange_id, market_id, bets) 
      else
        LOGGER.info "#{market_id} - Bets have already been placed for runners AND/OR no more runners to lay below odds of #{ODDS}"
      end
      
    else
      LOGGER.info "#{market_id} - Is currently either not Active or is In Play"
    end
  end
  
  def bets_already_placed(token, exchange_id, market_id)
    begin
      LOGGER.info "#{market_id} - Checking existing bets for market_id"
      bets_placed = []
      foo = BF.get_mu_bets(token, exchange_id, market_id)       
      if foo != 'NO_RESULTS - OK'
        foo = [foo] if foo.is_a?(Hash) # If there is only one bet placed on a market then it returns a Hash, not an Array, needs to be an Array so we can loop it       
        foo.each { |bet| bets_placed << bet[:selection_id].to_i }         
      end
      return bets_placed
    rescue
       LOGGER.info "Error - SimpleBot.bets_already_placed - #{$!.message}\n(#{$!.class})\n#{$!.backtrace}\n"
    end
  end
  
  def place_bets(token, exchange_id, market_id, bets)
    begin
      foo = []
      bets.each do |bet|
        foo <<  { market_id: market_id, runner_id: bet[:selection_id], bet_type: BET_SIDE, price: bet[:b1]+BET_PIP.to_f, size: BET_AMOUNT, asian_line_id: 0, 
                  bet_category_type: 'E', bet_peristence_type: 'NONE', bsp_liability: 0 }   
      end   
      bets = BF.place_multiple_bets(token, exchange_id, foo)    
      LOGGER.info "#{market_id} - Placing bets #{bets}"
    rescue
      LOGGER.info "Error - SimpleBot.run - #{$!.message}\n(#{$!.class})\n#{$!.backtrace}\n"
    end
  end
  
end
SimpleBot.new.run

