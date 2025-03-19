# frozen_string_literal: true

module Services
  class UrlProcessor

    def extract_url(text)

      patterns = [
        %r{(https?://)?open\.spotify\.com/track/[a-zA-Z0-9]+},
        %r{(https?://)?spotify\.com/track/[a-zA-Z0-9]+},
        %r{(https?://)?deezer\.com/\w+/track/\d+},
        %r{(https?://)?deezer\.com/track/\d+},
        %r{(https?://)?dzr\.page\.link/[a-zA-Z0-9]+}
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
