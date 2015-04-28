require 'logger'
require 'elasticsearch'
require 'pry'
require 'hashie'
require 'geocoder'

class Location
    SLEEP_INTERVAL=0.2
    ADDRESS_COMPONENTS_MAPPINGS={
      locality: :locality,
      district: :administrative_area_level_2,
      state: :administrative_area_level_1,
      country: :country
    }
    attr_reader :loc,:locality,:district,:state,:country
    def initialize(loc)
      @loc=loc
      @results=reverse_search
      set_identity
    end
    private
    def reverse_search
      sleep(SLEEP_INTERVAL)
      Geocoder.search(loc)
    end
    def set_identity
      @locality = get_name(:locality)
      @district = get_name(:district)
      @state = get_name(:state)
      @country = get_name(:country)
      raise 'Location not set!' if(@locality&&@district&&@state&&@country).nil?
    end
    def get_name(type)
      begin
        result = @results.find{|r|!r.address_components_of_type(ADDRESS_COMPONENTS_MAPPINGS[type]).empty?}
        result.address_components_of_type(ADDRESS_COMPONENTS_MAPPINGS[type]).first['long_name']
      rescue => e
        ""
      end
    end
  end

module Processors
  class ReverseSearch
    def self.perform
      begin
      file = File.expand_path("./logs/logfile.log", File.dirname(__FILE__))
      logger = Logger.new(file)
      logger.info "STARTING REVERSE SEARCH"
      @client = ::Elasticsearch::Client.new log: false
      response = @client.search({
        index: "_all",
        type: "events_v1",
        size: 1000,
        body: {
          "query"=> {
            "constant_score" => {
              "filter" => {
                "and"=> [
                  {
                    "term"=> {
                      "eid"=>"GE_GENIE_START"
                    }
                  },
                  {
                    "missing" => {
                      "field" => "edata.eks.ldata.country",
                      "existence" => true,
                      "null_value" => true
                    }
                  }
                ]
              }
            }
          }
        }
      })
      response = Hashie::Mash.new response
      logger.info "FOUND #{response.hits.hits.count} hits."
      response.hits.hits.each do |hit|
        result = nil
        if _loc=hit._source.edata.eks.loc
          _id = hit._id
          logger.info "LOC #{_loc}"
          location = Location.new(_loc)
          ldata = {
                ldata: {
                  locality: location.locality,
                  district: location.district,
                  state: location.state,
                  country: location.country
                }
              }
          logger.info "LDATA #{ldata.to_json}"
          edata = {
            edata:{
              eks: ldata
            }
          }
          result = @client.update({
            index: hit._index,
            type: hit._type,
            id: _id,
            body: {
              doc: edata
            }
          })
          logger.info "RESULT #{result.to_json}"
        end
        yield _loc,ldata,hit
      end
      logger.info "ENDING REVERSE SEARCH"
     rescue => e
      logger.error e
     end
    end
  end
end
