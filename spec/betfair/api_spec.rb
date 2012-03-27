require 'tempfile'
require 'spec_helper'

module Betfair

  describe "Helper methods for mashing the data from the API" do 

    before(:all) do 
      @bf = Betfair::API.new
      @session_token = @bf.login('username', 'password', 82, 0, 0, nil) 
      @helpers = Betfair::Helpers.new
    end
    
    describe "Create a hash from the get_all_markets API call"  do
      it "pulls the relevant stuff out of get_all_markets and puts it in a hash" do
        savon.expects(:get_all_markets).returns(:success)
        markets = @bf.get_all_markets(@session_token, 2)
        markets = @helpers.split_markets_string(markets)
        markets.should_not be_nil        
      end
    end
    
    describe "Create a hash for the market details"  do
      it "pulls the relevant stuff out of market details and puts it in a hash" do
        savon.expects(:get_market).returns(:success)
        market = @bf.get_market(@session_token, 2, 10038633)
        market_info = @helpers.market_info(market)
        market_info.should_not be_nil        
      end
    end
    
    describe "Cleans up the get market details"  do
      it "sort the runners for each market out " do
        savon.expects(:get_market).returns(:success)
        market = @bf.get_market(@session_token, 2, 10038633)
        details = @helpers.details(market)
        details.should_not be_nil        
      end
    end

    describe "Get the price string for a runner"  do
      it "so that we can combine it together with market info" do
        savon.expects(:get_market_prices_compressed).returns(:success)
        prices = @bf.get_market_prices_compressed(@session_token, 2, 10038633)
        prices = @helpers.prices(prices)
        prices.should_not be_nil        
      end
    end
   
    describe "Combine market details and runner prices api call"  do
      it "Combines the two api calls of get_market and get_market_prices_compressed " do
        
        savon.expects(:get_market).returns(:success)
        market = @bf.get_market(@session_token, 2, 10038633)
        
        savon.expects(:get_market_prices_compressed).returns(:success)
        prices = @bf.get_market_prices_compressed(@session_token, 2, 10038633)
                       
        combined = @helpers.combine(market, prices)
        combined.should_not be_nil        
      end
    end  

  end

  describe "Placing and cancelling bets" do
    
    before(:all) do 
      @bf = Betfair::API.new
      @session_token = @bf.login('username', 'password', 82, 0, 0, nil) 
    end
    
    describe "place bet success"  do
      it "should place a bet on the exchange via the api" do
        savon.expects(:place_bets).returns(:success)
        bet = @bf.place_bet(@session_token, 1, 104184109, 58805, 'B', 10.0, 5.0)       
        bet.should_not be_nil
      end
    end
    
    describe "place bet fail"  do
      it "should return an error message" do
        savon.expects(:place_bets).returns(:fail)
        error_code = @bf.place_bet(@session_token, 1, 104184109, 58805, 'B', 2.0, 2.0)       
        error_code[:result_code].should eq('INVALID_SIZE')
      end
    end
    
    describe "place multiple bets success"do
      it "should place mutliple bets on the exchange via the api" do
        savon.expects(:place_bets).returns(:success)
        bets = []
        bets <<  { market_id: 104184109, runner_id: 58805, bet_type: 'B', price: 2.0, size: 2.0, asian_line_id: 0, 
                  bet_category_type: 'E', bet_peristence_type: 'NONE', bsp_liability: 0 }
        bets = @bf.place_multiple_bets(@session_token, 1, bets)       
        bets.should_not be_nil
      end
    end
    
    describe "place multiple bets fail"  do
      it "should return an error message" do
        savon.expects(:place_bets).returns(:fail)
        bets = []
        bets <<  { market_id: 104184109, runner_id: 58805, bet_type: 'B', price: 2.0, size: 2.0, asian_line_id: 0, 
                  bet_category_type: 'E', bet_peristence_type: 'NONE', bsp_liability: 0 }                  
        error_code = @bf.place_multiple_bets(@session_token, 1, bets)      
        error_code[:result_code].should eq('INVALID_SIZE')
      end
    end
      
    describe "cancel bet success" do
      it "should cancel a bet on the exchange via the api" do
        savon.expects(:cancel_bets).returns(:success)
        bet = @bf.cancel_bet(@session_token, 3, 16939689578)       
        bet.should_not be_nil
      end
    end
    
    describe "cancel bet fail"  do
      it "should fail to cancel a bet on the exchange via the api" do
        savon.expects(:cancel_bets).returns(:fail)
        error_code = @bf.cancel_bet(@session_token, 3, 16939689578)        
        error_code.should eq('API_ERROR - NO_SESSION')
      end
    end
    
    describe "cancel multiple bets success" do
      it "should cancel a bet on the exchange via the api" do
        savon.expects(:cancel_bets).returns(:success)
        bets = @bf.cancel_multiple_bets(@session_token, 3, [16939689578, 16939689579, 169396895710])       
        bets.should_not be_nil
      end
    end
    
    describe "cancel bet fail"  do
      it "should fail to cancel mulitple bets on the exchange via the api" do
        savon.expects(:cancel_bets).returns(:fail)
        error_code = @bf.cancel_multiple_bets(@session_token, 3, [16939689578, 16939689579, 169396895710])        
        error_code.should eq('API_ERROR - NO_SESSION')
      end
    end
    
  end

  
  describe "Reading account details" do
    before(:all) do 
      @bf = Betfair::API.new
      @session_token = @bf.login('username', 'password', 82, 0, 0, nil) 
    end    

    describe "reading wallet contents" do
      it "reads the contents of the user's wallet" do
        savon.expects( :get_account_funds ).returns( :success )
        funds = @bf.get_account_funds( @session_token, 1 )
        funds.should_not be_nil
      end
    end
  end

  
  describe "Basic read methods from the API" do 

    before(:all) do 
      @bf = Betfair::API.new
      @session_token = @bf.login('username', 'password', 82, 0, 0, nil) 
    end    

    describe "get all markets success"  do
      it "should return a hash of all markets given the exchange id and and array of market type ids" do
        savon.expects(:get_all_markets).returns(:success)
        markets = @bf.get_all_markets(@session_token, 1, [1,3], nil, nil, nil, nil)        
        markets.should_not be_nil        
      end
    end

    describe "get all markets fail"  do
      it "should return an error message given the exchange id and and array of market type ids and no session id" do
        savon.expects(:get_all_markets).returns(:fail)
        error_code = @bf.get_all_markets(@session_token, 1, [1,3], nil, nil, nil, nil)        
        error_code.should eq('API_ERROR - NO_SESSION')        
      end
    end

    describe "get market success"  do
      it "should return the details for a market given the exchange id and market id" do
        savon.expects(:get_market).returns(:success)
        market = @bf.get_market(@session_token, 2, 10038633)        
        market.should_not be_nil        
      end
    end

    describe "get markets fail"  do
      it "should return an error message given the wrong exchange id or market id" do
        savon.expects(:get_market).returns(:fail)
        error_code = @bf.get_market(@session_token, 2, 10038633)        
        error_code.should eq('INVALID_MARKET - OK')        
      end
    end

    describe "get market prices compressed success"  do
      it "should return comrpessed market prices given the exchange id and market id" do
        savon.expects(:get_market_prices_compressed).returns(:success)
        market = @bf.get_market_prices_compressed(@session_token, 2, 10038633)        
        market.should_not be_nil      
      end
    end

    describe "get market prices compressed fail"  do
      it "should return an error message given the wrong exchange id or market id" do
        savon.expects(:get_market_prices_compressed).returns(:fail)
        error_code = @bf.get_market_prices_compressed(@session_token, 2, 10038633)        
        error_code.should eq('INVALID_MARKET - OK')        
      end
    end

    describe "get active event types success" do
      it "should return active event types given the locale" do
        savon.expects(:get_active_event_types).returns(:success)
        events = @bf.get_active_event_types(@session_token, 'en')
        events.should_not be_nil
      end    
    end
    
    describe "get matched/unmatched bets success" do
      it "should return all of our unmatched and matched bets on an exchange, can take a market_id as the third arguement, plus many more" do 
        savon.expects(:getMUBets).returns(:success)
        bets = @bf.get_mu_bets(@session_token, 1)        
        #bets.length.should eq(2)
        bets[0][:selection_id].should eq("5986909")
        bets[1][:selection_id].should eq("6230544")
      end
    end
    
    describe "get matched/unmatched bets"  do
      it "should return an error message given the exchange id and and array of market type ids and no session id" do
        savon.expects(:getMUBets).returns(:fail)
        error_code = @bf.get_mu_bets(@session_token, 1)        
        error_code.should eq('API_ERROR - NO_SESSION')        
      end
    end

  end
     
  describe "General logins, logouts methods and proxys and Savon logging etc" do 

    before(:all) do 
      @bf = Betfair::API.new
    end


    describe "login" do
      let( :response ) { @bf.login('username', 'password', 82, 0, 0, nil) }
      subject { response }

      before do savon.expects( api_call ).returns( api_response ) end
      
      let( :api_call ) { :login }

      describe "success"  do
        let( :api_response ) { :success }

        it { should be_a_kind_of(String) }
        it { should be_success }
      end

      describe "failure"  do
        describe "with a bad product code" do
          let( :api_response ) { :fail }

          it { should match('PRODUCT_REQUIRES_FUNDED_ACCOUNT') }
          it { should_not be_success }
        end

        describe "with a bad password" do
          let( :api_response ) { :bad_password }
          
          it { should match("INVALID_USERNAME_OR_PASSWORD") }
          it { should_not be_success }
        end

      end
    end


    describe "proxy success"  do
      it "should return a session token" do
        savon.expects(:login).returns(:success)        
        proxy = 'http://localhost:8888'
        session_token = Betfair::API.new(proxy).login('username', 'password', 82, 0, 0, nil).to_s
        session_token.should be_an_instance_of(String)    
      end
    end

    describe "proxy fail"  do
      it "should return an error" do
        savon.expects(:login).returns(:fail)
        proxy = 'http://localhost:8888'
        error_code = Betfair::API.new(proxy).login('username', 'password', 82, 0, 0, nil)
        error_code.should match('PRODUCT_REQUIRES_FUNDED_ACCOUNT')         
      end
    end

    describe "savon logging on"  do
      it "should return a session token" do
        savon.expects(:login).returns(:success)
        proxy = nil
        logging = true
        output = capturing_stdout do
          session_token =  Betfair::API.new(proxy, logging).login('username', 'password', 82, 0, 0, nil).to_s
          session_token.should be_an_instance_of(String)
        end
        output.should_not be_empty
      end
    end


    def capturing_stdout
      result = nil
      Tempfile.open("betfair_api") do |tempout|
        replacement_stdout = File.open("/dev/stdout", "w")
        $stdout.reopen( tempout )

        begin
          yield
        ensure
          $stdout.reopen( replacement_stdout )
        end

        tempout.close
        result = File.read( tempout.path )
      end
      result
    end


  end
  
end
