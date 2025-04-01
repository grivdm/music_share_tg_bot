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
    @logger = @bot.instance_variable_get(:@logger)
  end
  
  def test_initialization
    assert_instance_of Services::UrlProcessor, @url_processor
    assert_instance_of Services::ApiClient, @api_client
    assert_instance_of Services::MessageHandler, @message_handler
    assert_instance_of Logger, @logger
    
    assert_equal ENV['MUSIC_SHARE_API_URL'], @bot.instance_variable_get(:@api_url)
    assert_equal ENV['TELEGRAM_BOT_TOKEN'], @bot.instance_variable_get(:@token)
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
    mock_message.stubs(:chat).returns(stub(id: 123456, type: 'private', title: nil))
    mock_message.stubs(:from).returns(stub(first_name: 'Test User', id: 789))
    
    @message_handler.expects(:send_welcome_message).with(mock_bot, 123456).once
    
    @bot.send(:process_message, mock_bot, mock_message)
  end
  
  def test_process_message_help_command
    mock_bot = mock('bot')
    mock_message = mock('message')
    
    mock_message.stubs(:text).returns('/help')
    mock_message.stubs(:chat).returns(stub(id: 123456, type: 'private', title: nil))
    mock_message.stubs(:from).returns(stub(first_name: 'Test User', id: 789))
    
    @message_handler.expects(:send_help_message).with(mock_bot, 123456).once
    
    @bot.send(:process_message, mock_bot, mock_message)
  end
  
  def test_process_message_music_link
    mock_bot = mock('bot')
    mock_message = mock('message')
    mock_api = mock('api')
    
    mock_message.stubs(:text).returns('Check out this song: https://open.spotify.com/track/123456')
    mock_message.stubs(:chat).returns(stub(id: 123456, type: 'private', title: nil))
    mock_message.stubs(:from).returns(stub(first_name: 'Test User', id: 789))
    mock_bot.stubs(:api).returns(mock_api)
    
    # Stub the critical methods to avoid real calls and WebMock errors
    @url_processor.stubs(:extract_url).returns('https://open.spotify.com/track/123456')
    @api_client.stubs(:convert_link).returns(nil)
    
    # Mock the message sending
    mock_api.stubs(:send_message).returns({'result' => {'message_id' => 789}})
    mock_api.stubs(:edit_message_text).returns(true)
    
    # Suppress logging
    @logger.stubs(:info)
    @logger.stubs(:warn)
    
    # This test just verifies there are no errors when a music link is processed
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
    mock_message.stubs(:chat).returns(stub(id: 123456, type: 'private', title: nil))
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
    mock_message.stubs(:chat).returns(stub(type: 'private', title: nil, id: 123456))
    
    @logger.expects(:info).with(regexp_matches(/Received message from Test User/))
    
    @bot.send(:log_incoming_message, mock_message)
  end
  
  def test_process_music_link
    mock_bot = mock('bot')
    mock_api = mock('api')
    mock_message = mock('message')
    
    # Setup message
    mock_message.stubs(:text).returns('https://open.spotify.com/track/123456')
    mock_message.stubs(:chat).returns(stub(id: 123456))
    
    # Setup URL processing
    @url_processor.expects(:extract_url).with('https://open.spotify.com/track/123456').returns('https://open.spotify.com/track/123456')
    
    # Setup processing message
    mock_bot.stubs(:api).returns(mock_api)
    mock_api.expects(:send_message).with(
      chat_id: 123456,
      text: '🔄 Processing your link...'
    ).returns({'result' => {'message_id' => 789}})
    
    # Setup API client response
    mock_conversion_result = mock('conversion_result')
    mock_conversion_result.stubs(:valid?).returns(true)
    mock_conversion_result.stubs(:to_markdown).returns('Converted markdown')
    
    @api_client.expects(:convert_link).with('https://open.spotify.com/track/123456').returns(mock_conversion_result)
    
    # Expect edit message
    mock_api.expects(:edit_message_text).with(
      chat_id: 123456,
      message_id: 789,
      text: 'Converted markdown',
      parse_mode: 'Markdown',
      disable_web_page_preview: false
    )
    
    # Suppress logger output for testing
    @logger.stubs(:info)
    
    @bot.send(:process_music_link, mock_bot, mock_message)
  end
  
  def test_process_music_link_invalid_result
    mock_bot = mock('bot')
    mock_api = mock('api')
    mock_message = mock('message')
    
    # Setup message
    mock_message.stubs(:text).returns('https://open.spotify.com/track/123456')
    mock_message.stubs(:chat).returns(stub(id: 123456))
    
    # Setup URL processing
    @url_processor.expects(:extract_url).with('https://open.spotify.com/track/123456').returns('https://open.spotify.com/track/123456')
    
    # Setup processing message
    mock_bot.stubs(:api).returns(mock_api)
    mock_api.expects(:send_message).with(
      chat_id: 123456,
      text: '🔄 Processing your link...'
    ).returns({'result' => {'message_id' => 789}})
    
    # Setup API client response
    @api_client.expects(:convert_link).with('https://open.spotify.com/track/123456').returns(nil)
    
    # Expect edit message
    mock_api.expects(:edit_message_text).with(
      chat_id: 123456,
      message_id: 789,
      text: "❌ Sorry, I couldn't convert that link. Make sure it's from a supported platform."
    )
    
    # Suppress logger output for testing
    @logger.stubs(:info)
    @logger.stubs(:warn)
    
    @bot.send(:process_music_link, mock_bot, mock_message)
  end
  
  def test_process_music_link_api_error
    mock_bot = mock('bot')
    mock_api = mock('api')
    mock_message = mock('message')
    
    # Setup message
    mock_message.stubs(:text).returns('https://open.spotify.com/track/123456')
    mock_message.stubs(:chat).returns(stub(id: 123456))
    
    # Setup URL processing
    @url_processor.expects(:extract_url).with('https://open.spotify.com/track/123456').returns('https://open.spotify.com/track/123456')
    
    # Setup processing message
    mock_bot.stubs(:api).returns(mock_api)
    mock_api.expects(:send_message).with(
      chat_id: 123456,
      text: '🔄 Processing your link...'
    ).returns({'result' => {'message_id' => 789}})
    
    # Setup API client to raise error
    @api_client.expects(:convert_link).with('https://open.spotify.com/track/123456').raises(StandardError.new('API error'))
    
    # Expect edit message
    mock_api.expects(:edit_message_text).with(
      chat_id: 123456,
      message_id: 789,
      text: '❌ Sorry, an error occurred while processing your request.'
    )
    
    # Suppress logger output for testing
    @logger.stubs(:info)
    @logger.stubs(:error)
    
    @bot.send(:process_music_link, mock_bot, mock_message)
  end
end