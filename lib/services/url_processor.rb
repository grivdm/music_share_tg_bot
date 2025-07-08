# frozen_string_literal: true

module Services
  class UrlProcessor
    def extract_url(text)
      patterns = [
        # Spotify URLs
        %r{(https?://)?open\.spotify\.com/track/[a-zA-Z0-9]+},
        %r{(https?://)?spotify\.com/track/[a-zA-Z0-9]+},

        # Deezer URLs
        %r{(https?://)?deezer\.com/\w+/track/\d+},
        %r{(https?://)?deezer\.com/track/\d+},
        %r{(https?://)?link\.deezer\.com/[a-zA-Z0-9]+},
        %r{(https?://)?dzr\.page\.link/[a-zA-Z0-9]+},

        # YouTube Music URLs
        %r{(https?://)?music\.youtube\.com/watch\?v=[a-zA-Z0-9]+}
      ]

      patterns.each do |pattern|
        next unless (match = text.match(pattern))

        url = match[0]
        url = "https://#{url}" unless url.start_with?('http')
        return url
      end

      nil
    end
  end
end
