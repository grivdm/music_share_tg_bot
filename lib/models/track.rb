# frozen_string_literal: true


module Models
  class Track
    attr_reader :title, :artist, :album, :isrc

    def initialize(data)
      @title = data['title']
      @artist = data['artist']
      @album = data['album']
      @isrc = data['isrc']
    end

    def valid?
      !@title.nil? && !@artist.nil?
    end

    def self.from_json(json_data)
      return nil unless json_data && json_data.is_a?(Hash)

      track = new(json_data)
      track.valid? ? track : nil
    end

    def to_markdown
      result = "🎵 *#{@title}*\n"
      result += "👤 #{@artist}\n"
      result += "💿 #{@album}\n" if @album
      result
    end
  end
end
