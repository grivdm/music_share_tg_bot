# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../bot'

class BotTest < Minitest::Test
  def setup
    # Set environment variables for testing
    ENV['TELEGRAM_BOT_TOKEN'] = 'test_token'
    ENV['MUSIC_SHARE_API_URL'] = 'https://test-api.example.com'

    @bot = Bot.new

    # Access instance variables for testing
    @url_processor = @bot.instance_variable_get(:@url_processor)
    @api_client = @bot.instance_variable_get(:@api_client)
    @message_handler = @bot.instance_variable_get(:@message_handler)
    @music_link_processor = @bot.instance_variable_get(:@music_link_processor)
    @logger = @bot.instance_variable_get(:@logger)
  end

  def test_initialization
    assert_instance_of Services::UrlProcessor, @url_processor
    assert_instance_of Services::ApiClient, @api_client
    assert_instance_of Services::MessageHandler, @message_handler
    assert_instance_of Services::MusicLinkProcessor, @music_link_processor
    assert_instance_of Logger, @logger

    assert_equal ENV.fetch('MUSIC_SHARE_API_URL', nil), @bot.instance_variable_get(:@api_url)
    assert_equal ENV.fetch('TELEGRAM_BOT_TOKEN', nil), @bot.instance_variable_get(:@token)
  end

  def test_fallback_api_url
    # Test with no API URL set
    ENV.delete('MUSIC_SHARE_API_URL')
    fallback_bot = Bot.new

    assert_equal 'http://localhost:3000', fallback_bot.instance_variable_get(:@api_url)
  end

  def test_process_message_start_command
    mock_bot = mock('bot')
    mock_message = mock('message')

    mock_message.stubs(:text).returns('/start')
    mock_message.stubs(:chat).returns(stub(id: 123_456, type: 'private', title: nil))
    mock_message.stubs(:from).returns(stub(first_name: 'Test User', id: 789))

    @message_handler.expects(:send_welcome_message).with(mock_bot, 123_456).once

    @bot.send(:process_message, mock_bot, mock_message)
  end

  def test_process_message_help_command
    mock_bot = mock('bot')
    mock_message = mock('message')

    mock_message.stubs(:text).returns('/help')
    mock_message.stubs(:chat).returns(stub(id: 123_456, type: 'private', title: nil))
    mock_message.stubs(:from).returns(stub(first_name: 'Test User', id: 789))

    @message_handler.expects(:send_help_message).with(mock_bot, 123_456).once

    @bot.send(:process_message, mock_bot, mock_message)
  end

  def test_process_message_music_link
    mock_bot = mock('bot')
    mock_message = mock('message')

    mock_message.stubs(:text).returns('Check out this song: https://open.spotify.com/track/123456')
    mock_message.stubs(:chat).returns(stub(id: 123_456, type: 'private', title: nil))
    mock_message.stubs(:from).returns(stub(first_name: 'Test User', id: 789))

    # Expect MusicLinkProcessor to be called
    @music_link_processor.expects(:process).with(mock_bot, mock_message).once

    # Suppress logging
    @logger.stubs(:info)

    @bot.send(:process_message, mock_bot, mock_message)
  end

  def test_process_message_no_text
    mock_bot = mock('bot')
    mock_message = mock('message')

    mock_message.stubs(:text).returns(nil)

    # No methods should be called
    @message_handler.expects(:send_welcome_message).never
    @message_handler.expects(:send_help_message).never
    @url_processor.expects(:extract_url).never

    @bot.send(:process_message, mock_bot, mock_message)
  end

  def test_process_message_other_text
    mock_bot = mock('bot')
    mock_message = mock('message')

    mock_message.stubs(:text).returns('Just a regular message')
    mock_message.stubs(:chat).returns(stub(id: 123_456, type: 'private', title: nil))
    mock_message.stubs(:from).returns(stub(first_name: 'Test User', id: 789))

    # Regular text message should check for URLs
    @url_processor.stubs(:extract_url).returns(nil)

    # No other methods should be called
    @message_handler.expects(:send_welcome_message).never
    @message_handler.expects(:send_help_message).never

    @logger.stubs(:info)

    @bot.send(:process_message, mock_bot, mock_message)
  end

  def test_log_incoming_message
    mock_message = mock('message')

    mock_message.stubs(:text).returns('Test message')
    mock_message.stubs(:from).returns(stub(first_name: 'Test User', id: 789))
    mock_message.stubs(:chat).returns(stub(type: 'private', title: nil, id: 123_456))

    @logger.expects(:info).with(regexp_matches(/Received message from Test User/))

    @bot.send(:log_incoming_message, mock_message)
  end
end
