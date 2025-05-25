# frozen_string_literal: true

require_relative '../test_helper'

class ApiClientTest < Minitest::Test
  def setup
    @logger = Logger.new(File::NULL)
    @api_url = 'https://music-share-api.example.com'
    @api_client = Services::ApiClient.new(@api_url, @logger)

    @valid_response = {
      'track' => {
        'title' => 'Test Song',
        'artist' => 'Test Artist',
        'album' => 'Test Album'
      },
      'links' => {
        'spotify' => 'https://open.spotify.com/track/123456',
        'deezer' => 'https://deezer.com/track/789012'
      }
    }
  end

  def test_convert_link_success
    url = 'https://open.spotify.com/track/1234567890abcdef'

    stub_request(:post, "#{@api_url}/api/v1/convert")
      .with(
        body: { url: url }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      .to_return(
        status: 200,
        body: @valid_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @api_client.convert_link(url)

    assert_instance_of Models::ConversionResult, result
    assert result.valid?
    assert_equal 'Test Song', result.track.title
    assert_equal 'Test Artist', result.track.artist
    assert_equal 'Test Album', result.track.album
  end

  def test_convert_link_api_error
    url = 'https://open.spotify.com/track/invalid'

    stub_request(:post, "#{@api_url}/api/v1/convert")
      .with(
        body: { url: url }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      .to_return(
        status: 404,
        body: { error: 'Track not found' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @api_client.convert_link(url)

    assert_nil result
  end

  def test_convert_link_invalid_json
    url = 'https://open.spotify.com/track/bad_json'

    stub_request(:post, "#{@api_url}/api/v1/convert")
      .with(
        body: { url: url }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      .to_return(
        status: 200,
        body: 'not valid json',
        headers: { 'Content-Type': 'application/json' }
      )

    result = @api_client.convert_link(url)

    assert_nil result
  end

  def test_convert_link_missing_fields
    url = 'https://open.spotify.com/track/missing_fields'

    stub_request(:post, "#{@api_url}/api/v1/convert")
      .with(
        body: { url: url }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      .to_return(
        status: 200,
        body: { track: { title: 'Test' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @api_client.convert_link(url)

    assert_nil result
  end

  def test_convert_link_network_error
    url = 'https://open.spotify.com/track/network_error'

    stub_request(:post, "#{@api_url}/api/v1/convert")
      .with(
        body: { url: url }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      .to_raise(StandardError.new('Network error'))

    result = @api_client.convert_link(url)

    assert_nil result
  end

  def test_convert_link_invalid_result
    url = 'https://open.spotify.com/track/invalid_result'

    response = @valid_response.dup
    response['track'].delete('artist') # Makes track invalid

    stub_request(:post, "#{@api_url}/api/v1/convert")
      .with(
        body: { url: url }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      .to_return(
        status: 200,
        body: response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @api_client.convert_link(url)

    assert_nil result
  end
end
