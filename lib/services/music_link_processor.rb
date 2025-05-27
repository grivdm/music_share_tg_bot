# frozen_string_literal: true

require_relative 'telegram_message_extractor'

module Services
  class MusicLinkProcessor
    def initialize(url_processor, api_client, logger)
      @url_processor = url_processor
      @api_client = api_client
      @logger = logger
    end

    def process(bot, message)
      chat_id = message.chat.id
      url = @url_processor.extract_url(message.text)

      return unless url

      @logger.info "Extracted URL: #{url} from chat #{chat_id}"

      processing_response = send_processing_message(bot, chat_id)
      message_id = TelegramMessageExtractor.extract_message_id(processing_response)

      unless message_id
        @logger.error "Cannot extract message_id from: #{processing_response.inspect}"
        return
      end

      handle_conversion(bot, chat_id, message_id, url)
    end

    private

    def send_processing_message(bot, chat_id)
      bot.api.send_message(
        chat_id: chat_id,
        text: '🔄 Processing your link...'
      )
    end

    def handle_conversion(bot, chat_id, message_id, url)
      conversion_result = @api_client.convert_link(url)

      if conversion_result&.valid?
        send_success_response(bot, chat_id, message_id, conversion_result)
      else
        send_failure_response(bot, chat_id, message_id)
      end
    rescue StandardError => e
      handle_conversion_error(bot, chat_id, message_id, e)
    end

    def send_success_response(bot, chat_id, message_id, conversion_result)
      bot.api.edit_message_text(
        chat_id: chat_id,
        message_id: message_id,
        text: conversion_result.to_markdown,
        parse_mode: 'Markdown',
        disable_web_page_preview: false
      )
      @logger.info "Successfully converted link for chat #{chat_id}"
    end

    def send_failure_response(bot, chat_id, message_id)
      bot.api.edit_message_text(
        chat_id: chat_id,
        message_id: message_id,
        text: "❌ Sorry, I couldn't convert that link. Make sure it's from a supported platform."
      )
      @logger.warn 'Failed to convert link: API returned invalid data'
    end

    def handle_conversion_error(bot, chat_id, message_id, error)
      @logger.error "Error processing link: #{error.message}"
      @logger.error error.backtrace.join("\n")

      error_message = '❌ Sorry, an error occurred while processing your request.'

      begin
        if message_id
          bot.api.edit_message_text(chat_id: chat_id, message_id: message_id, text: error_message)
        else
          bot.api.send_message(chat_id: chat_id, text: error_message)
        end
      rescue StandardError => e
        @logger.error "Failed to edit error message: #{e.message}"
        @logger.error e.backtrace.join("\n")
      end
    end
  end
end
