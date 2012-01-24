module Betfair
  
  class API
    
    def place_bet(session_token, exchange_id, market_id, runner_id, bet_type, price, size)		
      bf_bet = { :marketId => market_id, :selectionId => runner_id, :betType => bet_type, :price => price, :size => size, :asianLineId => 0, :betCategoryType => 'E', :betPersistenceType => 'NONE', :bspLiability => 0 }      
      response = exchange(exchange_id).request :bf, :placeBets do
        soap.body = { 'bf:request' => { :header => api_request_header(session_token), :bets => { 'PlaceBets' => [bf_bet] } } }
      end      
      error_code = response.to_hash[:place_bets_response][:result][:error_code]
      error_code2 = response.to_hash[:place_bets_response][:result][:header][:error_code]
  	  return error_code == 'OK' ? response.to_hash[:place_bets_response][:result][:bet_results][:place_bets_result] : "#{error_code} - #{error_code2}"  		
    end

    def cancel_bet(session_token, exchange_id, bet_id)
      response = exchange(exchange_id).request :bf, :cancelBets do
        soap.body = { 'bf:request' => { :header => api_request_header(session_token), :bets => { 'CancelBets' => [ { :betId => bet_id } ] } } } # "CancelBets" has to be a string, not a symbol!
      end		
      error_code = response.to_hash[:cancel_bets_response][:result][:error_code]
      error_code2 = response.to_hash[:cancel_bets_response][:result][:header][:error_code]
  		return error_code == 'OK' ? response.to_hash[:cancel_bets_response][:result][:bet_results][:cancel_bets_result] : "#{error_code} - #{error_code2}"
    end
        
  	def get_market(session_token, exchange_id, market_id, locale = nil) 
  		response = exchange(exchange_id).request :bf, :getMarket do
  			soap.body = { 'bf:request' => { :header => api_request_header(session_token), :marketId => market_id, :locale => locale } }
  		end
  		error_code = response.to_hash[:get_market_response][:result][:error_code]
  		error_code2 = response.to_hash[:get_market_response][:result][:header][:error_code]
      return error_code == 'OK' ? response.to_hash[:get_market_response][:result][:market] : "#{error_code} - #{error_code2}"
  	end
    
    def get_market_prices_compressed(session_token, exchange_id, market_id, currency_code = nil)
      response = exchange(exchange_id).request :bf, :getMarketPricesCompressed do
       soap.body = { 'bf:request' => { :header => api_request_header(session_token),  :marketId => market_id, :currencyCode => currency_code } }
      end
      error_code = response.to_hash[:get_market_prices_compressed_response][:result][:error_code]      
      error_code2 = response.to_hash[:get_market_prices_compressed_response][:result][:header][:error_code]
      return error_code == 'OK' ? response.to_hash[:get_market_prices_compressed_response][:result][:market_prices] : "#{error_code} - #{error_code2}"
    end

    def get_active_event_types(session_token, locale = nil)
      response = @global_service.request :bf, :getActiveEventTypes do
        soap.body = { 'bf:request' => { :header => api_request_header(session_token), 
                                        :locale => locale
                                      } 
                    }
      end            
      error_code = response.to_hash[:get_active_event_types_response][:result][:error_code] 
      error_code2 = response.to_hash[:get_active_event_types_response][:result][:header][:error_code]      
      return error_code == 'OK' ? response.to_hash[:get_active_event_types_response][:result][:event_type_items][:event_type] : "#{error_code} - #{error_code2}"      
    end
    
    def get_all_markets(session_token, exchange_id, event_type_ids = nil, locale = nil, countries = nil, from_date = nil, to_date = nil)
      response = exchange(exchange_id).request :bf, :getAllMarkets do
        soap.body = { 'bf:request' => { :header => api_request_header(session_token), 
                                        :eventTypeIds => { 'int' => event_type_ids }, 
                                        :locale => locale, :countries => { 'country' => countries }, 
                                        :fromDate => from_date, 
                                        :toDate => to_date 
                                      } 
                    }
      end            
      error_code = response.to_hash[:get_all_markets_response][:result][:error_code] 
      error_code2 = response.to_hash[:get_all_markets_response][:result][:header][:error_code]      
      return error_code == 'OK' ? response.to_hash[:get_all_markets_response][:result][:market_data] : "#{error_code} - #{error_code2}"      
    end
                  
    def login(username, password, product_id, vendor_software_id, location_id, ip_address)
      response = @global_service.request :bf, :login do 
        soap.body = { 'bf:request' => { :username => username, 
                                        :password => password, 
                                        :productId => product_id, 
                                        :vendorSoftwareId => vendor_software_id, 
                                        :locationId => location_id, 
                                        :ipAddress => ip_address 
                                       } 
                    }
      end      
      session_token(response.to_hash[:login_response][:result][:header])       
    end
      
    def exchange(exchange_id)   
      exchange_id == 2  ? @aus_service : @uk_service
    end

    def api_request_header(session_token)      
      { :client_stamp => 0, :session_token => session_token }
    end
        
    def session_token(response_header)      
      response_header[:error_code] == 'OK' ? response_header[:session_token] : response_header[:error_code]
  	end

  	def initialize(proxy = nil, logging = nil)
      
      logging == true ? Savon.log = true : Savon.log = false
  		
  		@global_service = Savon::Client.new do |wsdl, http|
  		  wsdl.endpoint = 'https://api.betfair.com/global/v3/BFGlobalService'
  		  wsdl.namespace = 'https://www.betfair.com/global/v3/BFGlobalService'		     
  		  http.proxy = proxy if !proxy.nil?
  		end

  		@uk_service = Savon::Client.new do |wsdl, http|
  		  wsdl.endpoint = 'https://api.betfair.com/exchange/v5/BFExchangeService'
        wsdl.namespace = 'http://www.betfair.com/exchange/v3/BFExchangeService/UK'
        http.proxy = proxy if !proxy.nil?
  		end

  		@aus_service = Savon::Client.new do |wsdl, http|
  		  wsdl.endpoint = 'https://api-au.betfair.com/exchange/v5/BFExchangeService'
  		  wsdl.namespace = 'http://www.betfair.com/exchange/v3/BFExchangeService/AUS'
  		  http.proxy = proxy if !proxy.nil?
  		end

  	end
      
  end
  
  class Helpers  	  	

	  def all_markets(markets)
  	  market_hash = {}
  	  markets.gsub! '\:', "\0"
  	  markets = markets.split ":"
  	  markets.each do |piece|
  	    piece.gsub! "\0", '\:'
  		  market_hash[piece.split('~')[0].to_i] = { :market_id            => piece.split('~')[0].to_i,
                  	                              :market_name          => piece.split('~')[1].to_s,
                          	                      :market_type          => piece.split('~')[2].to_s,
                                  	              :market_status        => piece.split('~')[3].to_s,
                                                  # bf returns in this case time in Epoch, but in milliseconds
                                                  :event_date           => Time.at(piece.split('~')[4].to_i/1000),
                                                  :menu_path            => piece.split('~')[5].to_s,
  	                                              :event_hierarchy      => piece.split('~')[6].to_s,
          	                                      :bet_delay            => piece.split('~')[7].to_s,
                  	                              :exchange_id          => piece.split('~')[8].to_i,
                          	                      :iso3_country_code    => piece.split('~')[9].to_s,
                                                  # bf returns in this case time in Epoch, but in milliseconds
                                                  :last_refresh         => Time.at(piece.split('~')[10].to_i/1000),
                                          	      :number_of_runners    => piece.split('~')[11].to_i,
                                                  :number_of_winners    => piece.split('~')[12].to_i,
  	                                              :total_amount_matched => piece.split('~')[13].to_f,
          	                                      :bsp_market           => piece.split('~')[14] == 'Y' ? true : false,
                  	                              :turning_in_play      => piece.split('~')[15] == 'Y' ? true : false
                          	                    } 
  	  end
  	  return market_hash
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
  	
  	def combine(market, prices)
  	  market = details(market)            
  	  prices = prices(prices)
			market[:runners].each do |runner|
				runner.merge!( { :market_id => market[:market_id] } )
				runner.merge!( { :market_type_id => market[:market_type_id] } )
				runner.merge!(price_string(prices[runner[:runner_id]]))
			end
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
  		aux_hash =   {  :market_id            => aux.split('~')[0].to_i,
  			            :currency             => aux.split('~')[1].to_s,
  			            :market_status        => aux.split('~')[2].to_s,
  			            :in_play_delay        => aux.split('~')[3].to_i,
  			            :number_of_winners    => aux.split('~')[4].to_i,
  			            :market_information   => aux.split('~')[5].to_s,
  			            :discount_allowed     => aux.split('~')[6] == 'true' ? true : false,
  			            :market_base_rate     => aux.split('~')[7].to_s,
  			            :refresh_time_in_milliseconds => aux.split('~')[8].to_i,
  			            :removed_runners      => aux.split('~')[9].to_s,
  			            :bsp_market           => aux.split('~')[10] == 'Y' ? true : false
  			          }
	
  		# now iterating over the prices excluding the first piece that we already parsed above 
  		pieces[1..-1].each do |piece|
  		  piece.gsub! "\0", '\:'
		  
  		  # using the selection_id as hash key
  		  price_hash_key = piece.split('~')[0].to_i
		  
  		  price_hash[price_hash_key] = {  :selection_id         => piece.split('~')[0].to_i,
  			                              :order_index          => piece.split('~')[1].to_i,
  			                              :total_amount_matched => piece.split('~')[2].to_f,
  			                              :last_price_matched   => piece.split('~')[3].to_f,
  			                              :handicap             => piece.split('~')[4].to_f,
  			                              :reduction_factor     => piece.split('~')[5].to_f,
  			                              :vacant               => piece.split('~')[6] == 'true' ? true : false,
  			                              :far_sp_price         => piece.split('~')[7].to_f,
  			                              :near_sp_price        => piece.split('~')[8].to_f,
  			                              :actual_sp_price      => piece.split('~')[9].to_f                           
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