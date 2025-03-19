# frozen_string_literal: true

module Services
  class MessageHandler
    def initialize(logger)
      @logger = logger
    end

    def send_welcome_message(bot, chat_id)
      bot.api.send_message(
        chat_id: chat_id,
        text: '👋'
      )
    end

    def send_unsupported_message(bot, chat_id)
      bot.api.send_message(
        chat_id: chat_id,
        text: "Understand music links from Spotify or Deezer only."
      )
    end
  end
end
