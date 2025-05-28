# frozen_string_literal: true

require 'telegram/bot'
require 'dotenv/load'

require_relative 'lib/configuration'
require_relative 'lib/services/url_processor'
require_relative 'lib/services/api_client'
require_relative 'lib/services/message_handler'
require_relative 'lib/services/music_link_processor'

class Bot
  def initialize
    @token = Configuration.telegram_bot_token
    @api_url = Configuration.api_url
    @logger = Configuration.logger
    @url_processor = Services::UrlProcessor.new
    @api_client = Services::ApiClient.new(@api_url, @logger)
    @message_handler = Services::MessageHandler.new(@logger)
    @music_link_processor = Services::MusicLinkProcessor.new(@url_processor, @api_client, @logger)
  end

  def start
    Telegram::Bot::Client.run(@token) do |bot|
      @logger.info 'Bot started!'

      bot.listen do |message|
        case message
        when Telegram::Bot::Types::Message
          process_message(bot, message)
        end
      end
    end
  rescue StandardError => e
    @logger.error "Error: #{e.message}"
    @logger.error e.backtrace.join("\n")
    sleep 5
    retry
  end

  private

  def process_message(bot, message)
    return unless message.text

    log_incoming_message(message)

    chat_id = message.chat.id
    case message.text
    when %r{^/start$}
      @message_handler.send_welcome_message(bot, chat_id)
    when %r{^/help$}
      @message_handler.send_help_message(bot, chat_id)
    when %r{(https?://)?(open\.spotify\.com|spotify\.com|deezer\.com|dzr\.page\.link|music\.youtube\.com)/}
      @music_link_processor.process(bot, message)
    end
  end

  def log_incoming_message(message)
    chat_type = message.chat.type
    user_info = message.from ? "#{message.from.first_name} (ID: #{message.from.id})" : 'Unknown user'
    chat_info = "#{chat_type} - #{message.chat.title || 'Private'} (ID: #{message.chat.id})"
    @logger.info "Received message from #{user_info} in #{chat_info}: #{message.text}"
  end
end

Bot.new.start if __FILE__ == $PROGRAM_NAME
