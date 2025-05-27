# frozen_string_literal: true

module Services
  class TelegramMessageExtractor
    def self.extract_message_id(telegram_response)
      return nil unless telegram_response

      case telegram_response
      when Telegram::Bot::Types::Message
        telegram_response.message_id
      when Hash
        telegram_response['message_id'] || telegram_response.dig('result', 'message_id')
      end
    end
  end
end
