# frozen_string_literal: true

require_relative 'track'
require_relative 'links'

module Models
  class ConversionResult
    attr_reader :track, :links

    def initialize(track, links)
      @track = track
      @links = links
    end

    def valid?
      !@track.nil? && @track.valid? && !@links.nil? && @links.valid?
    end

    def self.from_json(json_data)
      return nil unless json_data.is_a?(Hash)

      track_data = json_data['track']
      links_data = json_data['links']

      track = Track.from_json(track_data)
      links = Links.from_json(links_data)

      return nil unless track && links

      result = new(track, links)
      result.valid? ? result : nil
    end

    def to_markdown
      "#{@track.to_markdown}#{@links.to_markdown}"
    end
  end
end
