# frozen_string_literal: true

module Models
  class Links
    attr_reader :platforms

    def initialize(data)
      @platforms = data || {}
    end

    def valid?
      !@platforms.empty?
    end

    def self.from_json(json_data)
      return nil unless json_data.is_a?(Hash)

      links = new(json_data)
      links.valid? ? links : nil
    end

    def platform_emoji(platform)
      case platform.downcase
      when 'spotify'
        '🟢'
      when 'deezer'
        '🔵'
      when 'youtube_music'
        '🔴'
      else
        '🎵'
      end
    end

    def to_markdown
      return '' if @platforms.empty?

      result = "\n*Available on:*\n"
      @platforms.each do |platform, url|
        emoji = platform_emoji(platform)
        result += "#{emoji} [#{platform.capitalize}](#{url})\n"
      end
      result
    end
  end
end
