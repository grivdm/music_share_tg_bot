# frozen_string_literal: true

require_relative '../test_helper'

class MessageHandlerTest < Minitest::Test
  def setup
    @logger = Logger.new(File::NULL)
    @handler = Services::MessageHandler.new(@logger)

    @mock_bot = mock('bot')
    @mock_api = mock('api')
    @mock_bot.stubs(:api).returns(@mock_api)

    @chat_id = 123_456_789
  end

  def test_send_welcome_message
    @mock_api.expects(:send_message).with(
      chat_id: @chat_id,
      text: '👋'
    ).once

    @handler.send_welcome_message(@mock_bot, @chat_id)
  end

  def test_send_help_message
    @mock_api.expects(:send_message).with(
      chat_id: @chat_id,
      text: "Send me a Spotify, Youtube Music, or Deezer link, and I'll convert it to other music platforms."
    ).once

    @handler.send_help_message(@mock_bot, @chat_id)
  end

  def test_send_unsupported_message
    @mock_api.expects(:send_message).with(
      chat_id: @chat_id,
      text: 'Understand music links from Spotify, Youtube Music, and Deezer only.'
    ).once

    @handler.send_unsupported_message(@mock_bot, @chat_id)
  end
end
