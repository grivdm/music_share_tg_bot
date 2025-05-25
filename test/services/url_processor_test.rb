# frozen_string_literal: true

require_relative '../test_helper'

class UrlProcessorTest < Minitest::Test
  def setup
    @processor = Services::UrlProcessor.new
  end

  def test_extract_url_spotify_with_http
    text = 'Check out this song: http://open.spotify.com/track/1234567890abcdef'

    url = @processor.extract_url(text)

    assert_equal 'http://open.spotify.com/track/1234567890abcdef', url
  end

  def test_extract_url_spotify_without_http
    text = 'Check out this song: open.spotify.com/track/1234567890abcdef'

    url = @processor.extract_url(text)

    assert_equal 'https://open.spotify.com/track/1234567890abcdef', url
  end

  def test_extract_url_spotify_com
    text = 'Check out this song: spotify.com/track/1234567890abcdef'

    url = @processor.extract_url(text)

    assert_equal 'https://spotify.com/track/1234567890abcdef', url
  end

  def test_extract_url_deezer_track
    text = 'Check out this song: https://deezer.com/track/123456789'

    url = @processor.extract_url(text)

    assert_equal 'https://deezer.com/track/123456789', url
  end

  def test_extract_url_deezer_with_locale
    text = 'Check out this song: https://deezer.com/fr/track/123456789'

    url = @processor.extract_url(text)

    assert_equal 'https://deezer.com/fr/track/123456789', url
  end

  def test_extract_url_deezer_short_link
    text = 'Check out this song: https://dzr.page.link/abcd1234'

    url = @processor.extract_url(text)

    assert_equal 'https://dzr.page.link/abcd1234', url
  end

  def test_extract_url_unsupported_service
    text = 'Check out this song: https://youtube.com/watch?v=dQw4w9WgXcQ'

    url = @processor.extract_url(text)

    assert_nil url
  end

  def test_extract_url_no_url
    text = 'This message has no URLs in it.'

    url = @processor.extract_url(text)

    assert_nil url
  end
end
