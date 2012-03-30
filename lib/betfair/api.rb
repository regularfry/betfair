module Betfair

  class API

    ## Some handy constants...

    EXCHANGE_IDS = {
      :aus => 2,
      :uk  => 1
    }
    
    PRODUCT_ID_FREE = 82

    BET_TYPE_LAY  = 'L'
    BET_TYPE_BACK = 'B'


    ## Success and Failure get mixed in to API result values
    # so that you can tell the difference easily - just call
    # #success? on the result to find out if it worked
    module Success
      def success?; true; end
    end # module Success


    module Failure
      def success?; false; end
    end # module Failure


    ## Bet Placement API METHODS
    #

    def place_bet(session_token, exchange_id, market_id, selection_id, bet_type, price, size)		
      bf_bet = { 
        :marketId           => market_id, 
        :selectionId        => selection_id, 
        :betType            => bet_type, 
        :price              => price, 
        :size               => size, 
        :asianLineId        => 0, 
        :betCategoryType    => 'E', 
        :betPersistenceType => 'NONE', 
        :bspLiability       => 0 
      }

      response = exchange(exchange_id).
        session_request( session_token,
                         :placeBets, 
                         :place_bets_response,
                         :bets => { 'PlaceBets' => [bf_bet] } )

      return response.maybe_result( :bet_results, :place_bets_result )
    end

    
   def place_multiple_bets(session_token, exchange_id, bets)		
      bf_bets = []
      bets.each do |bet|
        bf_bets << { 
          :marketId           => bet[:market_id], 
          :selectionId        => bet[:runner_id], 
          :betType            => bet[:bet_type], 
          :price              => bet[:price], 
          :size               => bet[:size], 
          :asianLineId        => bet[:asian_line_id], 
          :betCategoryType    => bet[:bet_category_type], 
          :betPersistenceType => bet[:bet_peristence_type], 
          :bspLiability       => bet[:bsp_liability] 
        }
      end

      response = exchange(exchange_id).
        session_request( session_token,
                         :placeBets, 
                         :place_bets_response,
                         :bets => { 'PlaceBets' => bf_bets } )

      return response.maybe_result( :bet_results, :place_bets_result )
    end      
    
    def update_bet(session_token, exchange_id, bet_id, new_bet_persitence_type, new_price, new_size, old_bet_persitance_type, old_price, old_size)
       bf_bet = { 
          :betId                  => bet_id, 
          :newBetPersistenceType  => new_bet_persitence_type, 
          :newPrice               => new_price, 
          :newSize                => new_size, 
          :oldBetPersistenceType  => old_bet_persitance_type, 
          :oldPrice               => old_price, 
          :oldSize                => old_size
        }

        response = exchange(exchange_id).
          session_request( session_token,
                           :updateBets, 
                           :update_bets_response,
                           :bets => { 'UpdateBets' => [bf_bet] } )

        return response.maybe_result( :bet_results, :update_bets_result )
    end

    def update_multiple_bets(session_token, exchange_id, bets)
      bf_bets = []
      bets.each do |bet|
        bf_bets << { 
          :betId                  => bet[:bet_id], 
          :newBetPersistenceType  => bet[:new_bet_persitence_type], 
          :newPrice               => bet[:new_price], 
          :newSize                => bet[:new_size], 
          :oldBetPersistenceType  => bet[:old_bet_persitance_type], 
          :oldPrice               => bet[:old_price], 
          :oldSize                => bet[:old_size] 
        }
      end

      response = exchange(exchange_id).
        session_request( session_token,
                         :updateBets, 
                         :update_bets_response,
                         :bets => { 'UpdateBets' => bf_bets } )

      return response.maybe_result( :bet_results, :update_bets_result )     
    end
    
    def cancel_bet(session_token, exchange_id, bet_id)
      bf_bet = { :betId => bet_id }

      response = exchange(exchange_id).
        session_request( session_token,
                         :cancelBets, 
                         :cancel_bets_response,
                         :bets => { 'CancelBets' => [bf_bet] } ) # "CancelBets" has to be a string, not a symbol!
      
      return response.maybe_result( :bet_results, :cancel_bets_result )
    end
        
    def cancel_multiple_bets(session_token, exchange_id, bets)
      bf_bets = []
      bets.each { |bet_id| bf_bets << { :betId => bet_id } }

      response = exchange(exchange_id).
        session_request( session_token,
                         :cancelBets, 
                         :cancel_bets_response,
                         :bets => { 'CancelBets' => bf_bets } ) # "CancelBets" has to be a string, not a symbol!
      
      return response.maybe_result( :bet_results, :cancel_bets_result )
    end
    
    def cancel_bet_by_market(session_token, exchange_id, market_id)
      raise 'Service not available in product id of 82'
    end
    
    ## Read-Only Betting API METHODS
    #
    
    def get_mu_bets( session_token, exchange_id, market_id = 0, bet_status = 'MU', start_record = 0, record_count = 200, sort_order = 'ASC', order_by =  'PLACED_DATE') #, bet_ids = nil, , exclude_last_second = nil, matched_since = nil
      response = exchange(exchange_id).
        session_request( session_token, 
                         :getMUBets, 
                         :get_mu_bets_response,
                         #:betIds => bet_ids,
                         :betStatus => bet_status,
                         #:excludeLastSecond => exclude_last_second,
                         :marketId => market_id,
                         #:matchedSince => matched_since,
                         :orderBy => order_by,
                         :recordCount => record_count,
                         :sortOrder => sort_order,
                         :startRecord => start_record
                         )

      return response.maybe_result( :bets, :mu_bet )
    end
    
    
    def get_market(session_token, exchange_id, market_id, locale = nil) 
      response = exchange(exchange_id).
        session_request( session_token, 
                         :getMarket, 
                         :get_market_response,
                         :marketId => market_id, 
                         :locale   => locale )

      return response.maybe_result( :market )
    end


    def get_market_prices_compressed(session_token, exchange_id, market_id, currency_code = nil)
      response = exchange(exchange_id).
        session_request( session_token,
                         :getMarketPricesCompressed, 
                         :get_market_prices_compressed_response,
                         :marketId => market_id,
                         :currencyCode => currency_code )
      
      return response.maybe_result( :market_prices )
    end


    def get_active_event_types(session_token, locale = nil)
      response = @global_service.
        session_request( session_token,
                         :getActiveEventTypes, 
                         :get_active_event_types_response,
                         :locale => locale )

      return response.maybe_result( :event_type_items, :event_type )
    end


    def get_all_markets(session_token, exchange_id, event_type_ids = nil, locale = nil, countries = nil, from_date = nil, to_date = nil)
      response = exchange(exchange_id).
        session_request( session_token, 
                         :getAllMarkets, 
                         :get_all_markets_response,
                         :eventTypeIds => { 'int' => event_type_ids }, 
                         :locale       => locale, 
                         :countries    => { 'country' => countries }, 
                         :fromDate     => from_date, 
                         :toDate       => to_date )
      
      return response.maybe_result( :market_data )
    end


    def get_account_funds( session_token, exchange_id )
      response = exchange(exchange_id).
        session_request( session_token, 
                         :getAccountFunds, 
                         :get_account_funds_response )

      return response.maybe_result
    end

    def login(username, password, product_id, vendor_software_id, location_id, ip_address)
      response = @global_service.request( :login, 
                                          :login_response, 
                                          :username         => username, 
                                          :password         => password, 
                                          :productId        => product_id, 
                                          :vendorSoftwareId => vendor_software_id, 
                                          :locationId       => location_id, 
                                          :ipAddress        => ip_address )

      return response.maybe_result( :header, :session_token )
    end
    
    ## General API METHODS
    #
    
    def keep_alive(session_token)
      response = @global_service.
        session_request( session_token,
                         :keep_alive, 
                         :keep_alive_response )
      
      # Need to do the old school way of checking as the keep_alive response doesn't return a minorErrorCode, so fails
      error_code = response[:header][:error_code]     
      return error_code == 'OK' ? response[:header][:session_token] : error_code
      #return response.maybe_result( :header, :session_token )
    end
    
    def logout(session_token)
      response = @global_service.
        session_request( session_token,
                         :logout, 
                         :logout_response )
      return response.maybe_result( :header, :session_token )
    end

    #
    ## END OF API METHODS


    def exchange(exchange_id)   
      exchange_id == EXCHANGE_IDS[:aus] ? @aus_service : @uk_service
    end

    def session_token(response_header)      
      response_header[:error_code] == 'OK' ? response_header[:session_token] : response_header[:error_code]
    end


    def initialize(proxy = nil, logging = nil)

      SOAPClient.log = logging

      @global_service = SOAPClient.global( proxy )
      @uk_service     = SOAPClient.uk( proxy )
      @aus_service    = SOAPClient.aus( proxy )

    end




    # A wrapper around the raw Savon::Client to hide the details of
    # the Savon API and those parts of the Betfair API which are
    # constant across the different API method calls
    class SOAPClient

      # Handy constants
      NAMESPACES = {
        :aus    => 'http://www.betfair.com/exchange/v3/BFExchangeService/AUS',
        :global => 'https://www.betfair.com/global/v3/BFGlobalService',
        :uk     => 'http://www.betfair.com/exchange/v3/BFExchangeService/UK' }
      ENDPOINTS  = {
        :aus    => 'https://api-au.betfair.com/exchange/v5/BFExchangeService',
        :global => 'https://api.betfair.com/global/v3/BFGlobalService',
        :uk     => 'https://api.betfair.com/exchange/v5/BFExchangeService' }


      # Factory methods for building clients to the different endpoints
      def self.global( proxy ); new( :global, proxy ); end
      def self.uk( proxy );     new( :uk, proxy );     end
      def self.aus( proxy );    new( :aus, proxy );    end


      # Wrapper to avoid leaking Savon's logging API
      def self.log=(logging); Savon.log = !!logging; end


      # Pass the `region` (see ENDPOINTS for valid values) to pick the
      # WSDL endpoint and namespace.  `proxy` should be a string URL
      # for HTTPI to use as a proxy setting.
      def initialize( region, proxy )
        @client = Savon::Client.new do |wsdl, http|
          wsdl.endpoint  = ENDPOINTS[region]
          wsdl.namespace = NAMESPACES[region]
          http.proxy = proxy if proxy
        end
      end


      # Delegate the SOAP call to bf:`method` with `body` as the
      # `bf:request` field.  Getting a Hash back, this method returns
      # response[result_field][:result] as its result.
      def request( method, result_field, body )
        response = @client.request( :bf, method ) {
          soap.body = { 'bf:request' => body }
        }.to_hash[result_field][:result]

        response.extend( ErrorPresenter )
        
        response
      end


      # For those requests which take place in the context of a session,
      # this method constructs the correct header and delegates to #request.
      def session_request( session_token, method, result_field, body = {})
        header_body = { :header => api_request_header(session_token) }
        full_body = header_body.merge( body )

        request method, result_field, full_body
      end


      def api_request_header(session_token)      
        { :client_stamp => 0, :session_token => session_token }
      end
      protected :api_request_header


    end # class SoapClient


    # Mix this into a Hash to give it basic error reporting and a nice
    # path-based data extractor.
    module ErrorPresenter

      def success?
        self[:error_code] == "OK"
      end


      def format_error
        "#{self[:error_code]} - #{self[:header][:error_code]}"
      end


      def maybe_result( *path )
        if success?
          path.inject(self){|m,r| m[r]}.extend( Success )
        else
          format_error().extend( Failure )
        end
      end

      
    end # module ErrorPresenter


  end # class API



  class Helpers  	  	
    
    ## HELPER METHODS
    #
    
    def all_markets(markets)
      market_hash = {}
      markets.gsub! '\:', "\0"
      markets = markets.split ":"
      markets.each do |piece|
        piece.gsub! "\0", '\:'
        foo = piece.split('~')
        market_hash[foo[0].to_i] = { 
          :market_id            => foo[0].to_i,
          :market_name          => foo[1].to_s,
          :market_type          => foo[2].to_s,
          :market_status        => foo[3].to_s,
          # bf returns in this case time in Epoch, but in milliseconds
          :event_date           => Time.at(foo[4].to_i/1000),
          :menu_path            => foo[5].to_s,
          :event_hierarchy      => foo[6].to_s,
          :bet_delay            => foo[7].to_s,
          :exchange_id          => foo[8].to_i,
          :iso3_country_code    => foo[9].to_s,
          # bf returns in this case time in Epoch, but in milliseconds 
          :last_refresh         => Time.at(foo[10].to_i/1000),
          :number_of_runners    => foo[11].to_i,
          :number_of_winners    => foo[12].to_i,
          :total_amount_matched => foo[13].to_f,
          :bsp_market           => foo[14] == 'Y' ? true : false,
          :turning_in_play      => foo[15] == 'Y' ? true : false
        } 
      end
      return market_hash
    end
    
    # Pass in the string returned from the get_all_markets() API call and get back a proper hash
    # This duplicates the helper above, not sure where this came from one of contributors must have added it.
    def split_markets_string(string)
      string_raw = string
      foo = []
      if string_raw.is_a?(String)
        string_raw.split(':').each do |string|
          bar = string.split('~')
          
          bsp_market        = bar[14] == 'Y' ? true : false
          turning_in_play   = bar[15] == 'Y' ? true : false
          event_date        = Time.at(bar[4].to_i/1000).utc
          last_refresh      = Time.at(bar[10].to_i/1000).utc
          
          doh = { market_id: bar[0].to_i, market_name: bar[1], market_type: bar[2], market_status: bar[3], event_date: event_date, menu_path: bar[5], event_heirachy: bar[6], 
                  bet_delay: bar[7].to_i, exchange_id: bar[8].to_i, iso3_country_code: bar[9], last_refresh: last_refresh, number_of_runners: bar[11].to_i, number_of_winners: bar[12].to_i, 
                  total_amount_matched: bar[13].to_f, bsp_market: bsp_market, turning_in_play: turning_in_play }        
          foo << doh if !doh[:market_name].nil?
        end
      end
      return foo
    end

    def market_info(details)
      { :exchange_id => nil,
        :market_type_id => nil,
        :market_matched => nil,
        :menu_path => details[:menu_path], 
        :market_id => details[:market_id], 
        :market_name => details[:name],
        :market_type_name => details[:menu_path].to_s.split('\\')[1]
      }
    end

    def details(market)
      runners = []
      market[:runners][:runner].each { |runner| runners << { :runner_id => runner[:selection_id].to_i, :runner_name => runner[:name] } }
      return { :market_id => market[:market_id].to_i, :market_type_id => market[:event_type_id].to_i, :runners => runners }
    end

    def prices(prices)
      price_hash = {}					
      prices.gsub! '\:', "\0"
      pieces = prices.split ":"
      pieces.each do |piece|
        piece.gsub! "\0", '\:'
        price_hash[piece.split('~')[0].to_i] = piece
      end
      return price_hash
    end
    
    def combine(market, prices)
      market = details(market)            
      prices = prices(prices)
      market[:runners].each do |runner|
        runner.merge!( { :market_id => market[:market_id] } )
        runner.merge!( { :market_type_id => market[:market_type_id] } )
        runner.merge!(price_string(prices[runner[:runner_id]]))
      end
    end

    ##
    #
    # Complete representation of market price data response, 
    # except "removed runners" which is returned as raw string. 
    #
    ##
    def prices_complete(prices)
      aux_hash   = {}
      price_hash = {}         

      prices.gsub! '\:', "\0"
      pieces = prices.split ":"

      # parsing first the auxiliary price info
      aux = pieces.first
      aux.gsub! "\0", '\:'
      foo = aux.split('~')
      aux_hash =   {  
        :market_id                      => foo[0].to_i,
        :currency                       => foo[1].to_s,
        :market_status                  => foo[2].to_s,
        :in_play_delay                  => foo[3].to_i,
        :number_of_winners              => foo[4].to_i,
        :market_information             => foo[5].to_s,
        :discount_allowed               => foo[6] == 'true' ? true : false,
        :market_base_rate               => foo[7].to_s,
        :refresh_time_in_milliseconds   => foo[8].to_i,
        :removed_runners                => foo[9].to_s,
        :bsp_market                     => foo[10] == 'Y' ? true : false
      }

      # now iterating over the prices excluding the first piece that we already parsed above 
      pieces[1..-1].each do |piece|
        piece.gsub! "\0", '\:'
        
        bar = piece.split('~')
        # using the selection_id as hash key
        price_hash_key = bar[0].to_i

        price_hash[price_hash_key] = {  
          :selection_id                 => bar[0].to_i,
          :order_index                  => bar[1].to_i,
          :total_amount_matched         => bar[2].to_f,
          :last_price_matched           => bar[3].to_f,
          :handicap                     => bar[4].to_f,
          :reduction_factor             => bar[5].to_f,
          :vacant                       => bar[6] == 'true' ? true : false,
          :far_sp_price                 => bar[7].to_f,
          :near_sp_price                => bar[8].to_f,
          :actual_sp_price              => bar[9].to_f                           
        }

        # merge lay and back prices into price_hash
        price_hash[price_hash_key].merge!(price_string(piece, true))
      end

      price_hash.merge!(aux_hash)

      return price_hash
    end

    def price_string(string, prices_only = false)
      string_raw = string
      string = string.split('|')

      price = { :prices_string => nil, :runner_matched => 0, :last_back_price => 0, :wom => 0, 
        :b1 => 0, :b1_available => 0, :b2 => 0, :b2_available => 0, :b3 => 0, :b3_available => 0,
        :l1 => 0, :l1_available => 0, :l2 => 0, :l2_available => 0, :l3 => 0, :l3_available => 0 
      }    			

      if !string[0].nil? and !prices_only
        str = string[0].split('~')	
        price[:prices_string] = string_raw
        price[:runner_matched] = str[2].to_f
        price[:last_back_price]   = str[3].to_f
      end

      # Get the b prices (which are actually the l prices)
      if !string[1].nil?
        b = string[1].split('~')	
        price[:b1]             = b[0].to_f if !b[0].nil?
        price[:b1_available]   = b[1].to_f if !b[1].nil?
        price[:b2]             = b[4].to_f if !b[5].nil?
        price[:b2_available]   = b[5].to_f if !b[6].nil?
        price[:b3]             = b[8].to_f if !b[8].nil?
        price[:b3_available]   = b[9].to_f if !b[9].nil?  				 				
        combined_b = price[:b1_available] + price[:b2_available] + price[:b3_available]
      end				

      # Get the l prices (which are actually the l prices)
      if !string[2].nil?
        l = string[2].split('~')
        price[:l1]             = l[0].to_f if !l[0].nil?
        price[:l1_available]   = l[1].to_f if !l[1].nil?
        price[:l2]             = l[4].to_f if !l[4].nil?
        price[:l2_available]   = l[5].to_f if !l[5].nil?
        price[:l3]             = l[8].to_f if !l[8].nil?
        price[:l3_available]   = l[9].to_f if !l[9].nil?  				  				
        combined_l = price[:l1_available] + price[:l2_available] + price[:l3_available]
      end			

      price[:wom] = combined_b / ( combined_b + combined_l ) unless combined_b.nil? or combined_l.nil?

      return price			  		
    end
    
  end
  
end
