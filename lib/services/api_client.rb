# frozen_string_literal: true

require 'httparty'
require 'json'
require_relative '../models/conversion_result'

module Services
  class ApiClient
    def initialize(api_url, logger)
      @api_url = api_url
      @logger = logger
    end

    def convert_link(url)
      @logger.info "Sending request to API with URL: #{url}"

      begin
        response = HTTParty.post(
          "#{@api_url}/api/v1/convert",
          body: { url: url }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        if response.success?
          @logger.info "API Response status: #{response.code}, body: #{response.body}"

          begin
            result = JSON.parse(response.body)
            @logger.info "Parsed JSON result: #{result.inspect}"

            if result && result['track'] && result['links']
              conversion_result = Models::ConversionResult.from_json(result)

              if conversion_result&.valid?
                @logger.info "API response successful, track: #{conversion_result.track.title} by #{conversion_result.track.artist}"
                conversion_result
              else
                @logger.error 'Conversion result object invalid'
                nil
              end
            else
              @logger.error "API response missing required fields 'track' or 'links': #{result.inspect}"
              nil
            end
          rescue JSON::ParserError => e
            @logger.error "Failed to parse JSON response: #{e.message}"
            @logger.error "Raw response: #{response.body}"
            nil
          end
        else
          @logger.error "API Error: #{response.code} - #{response.body}"
          nil
        end
      rescue StandardError => e
        @logger.error "Request Error: #{e.class} - #{e.message}"
        @logger.error e.backtrace.join("\n")
        nil
      end
    end
  end
end
