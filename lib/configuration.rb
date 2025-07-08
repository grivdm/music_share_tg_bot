# frozen_string_literal: true

require 'logger'

class Configuration
  DEFAULT_API_URL = 'http://localhost:3000'

  def self.telegram_bot_token
    ENV['TELEGRAM_BOT_TOKEN'] || raise('TELEGRAM_BOT_TOKEN environment variable is required')
  end

  def self.api_url
    ENV['MUSIC_SHARE_API_URL'] || DEFAULT_API_URL
  end

  def self.logger
    @logger ||= begin
      logger = Logger.new($stdout)
      logger.level = Logger::INFO
      $stdout.sync = true
      logger
    end
  end
end
