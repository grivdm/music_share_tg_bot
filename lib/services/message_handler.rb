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

    def send_help_message(bot, chat_id)
      bot.api.send_message(
        chat_id: chat_id,
        text: "Send me a Spotify, Youtube Music, or Deezer link, and I'll convert it to other music platforms."
      )
    end

    def send_unsupported_message(bot, chat_id)
      bot.api.send_message(
        chat_id: chat_id,
        text: "Understand music links from Spotify, Youtube Music, and Deezer only."
      )
    end
  end
end
