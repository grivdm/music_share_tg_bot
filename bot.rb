# frozen_string_literal: true

require 'telegram/bot'
require 'dotenv/load'
require 'logger'

require_relative 'lib/models/conversion_result'
require_relative 'lib/services/url_processor'
require_relative 'lib/services/api_client'
require_relative 'lib/services/message_handler'

class Bot
  def initialize
    @token = ENV['TELEGRAM_BOT_TOKEN']
    @api_url = ENV['MUSIC_SHARE_API_URL'] || 'http://localhost:3000'
    @logger = Logger.new($stdout)
    @logger.level = Logger::INFO
    @url_processor = Services::UrlProcessor.new
    @api_client = Services::ApiClient.new(@api_url, @logger)
    @message_handler = Services::MessageHandler.new(@logger)
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
    when %r{(https?://)?(open\.spotify\.com|spotify\.com|deezer\.com|dzr\.page\.link)}
      process_music_link(bot, message)
    end
  end

  def log_incoming_message(message)
    chat_type = message.chat.type
    user_info = message.from ? "#{message.from.first_name} (ID: #{message.from.id})" : 'Unknown user'
    chat_info = "#{chat_type} - #{message.chat.title || 'Private'} (ID: #{message.chat.id})"
    @logger.info "Received message from #{user_info} in #{chat_info}: #{message.text}"
  end

  def process_music_link(bot, message)
    chat_id = message.chat.id
    url = @url_processor.extract_url(message.text)

    return unless url

    @logger.info "Extracted URL: #{url} from chat #{chat_id}"

    processing_message = bot.api.send_message(
      chat_id: chat_id,
      text: '🔄 Processing your link...'
    )

    @logger.info "Processing message structure: #{processing_message.class}"

    message_id = nil

    if processing_message.is_a?(Telegram::Bot::Types::Message)
      message_id = processing_message.message_id
      @logger.info "Extracted message_id #{message_id} from Message object"
    elsif processing_message.is_a?(Hash) && processing_message['message_id']
      message_id = processing_message['message_id']
      @logger.info "Extracted message_id #{message_id} from Hash['message_id']"
    elsif processing_message.is_a?(Hash) && processing_message['result'] && processing_message['result']['message_id']
      message_id = processing_message['result']['message_id']
      @logger.info "Extracted message_id #{message_id} from Hash['result']['message_id']"
    end

    unless message_id
      @logger.error "Cannot extract message_id from the processing message: #{processing_message.inspect}"
      return
    end

    begin
      conversion_result = @api_client.convert_link(url)

      if conversion_result&.valid?
        result_message = conversion_result.to_markdown

        bot.api.edit_message_text(
          chat_id: chat_id,
          message_id: message_id,
          text: result_message,
          parse_mode: 'Markdown',
          disable_web_page_preview: false
        )

        @logger.info "Successfully converted link for chat #{chat_id}"
      else
        bot.api.edit_message_text(
          chat_id: chat_id,
          message_id: message_id,
          text: "❌ Sorry, I couldn't convert that link. Make sure it's from a supported platform."
        )

        @logger.warn 'Failed to convert link: API returned invalid data'
      end
    rescue StandardError => e
      @logger.error "Error processing link: #{e.message}"
      @logger.error e.backtrace.join("\n")

      begin
        if message_id
          bot.api.edit_message_text(
            chat_id: chat_id,
            message_id: message_id,
            text: '❌ Sorry, an error occurred while processing your request.'
          )
        else
          bot.api.send_message(
            chat_id: chat_id,
            text: '❌ Sorry, an error occurred while processing your request.'
          )
        end
      rescue StandardError => edit_error
        @logger.error "Failed to edit error message: #{edit_error.message}"
        @logger.error edit_error.backtrace.join("\n")
      end
    end
  end
end

Bot.new.start if __FILE__ == $PROGRAM_NAME
