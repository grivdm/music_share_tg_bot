# frozen_string_literal: true

require_relative '../test_helper'

class ConversionResultTest < Minitest::Test
  def setup
    @track_data = {
      'title' => 'Test Song',
      'artist' => 'Test Artist',
      'album' => 'Test Album'
    }
    
    @links_data = {
      'spotify' => 'https://open.spotify.com/track/123456',
      'deezer' => 'https://deezer.com/track/789012'
    }
    
    @track = Models::Track.new(@track_data)
    @links = Models::Links.new(@links_data)
  end
  
  def test_valid_conversion_result
    result = Models::ConversionResult.new(@track, @links)
    
    assert result.valid?
    assert_equal @track, result.track
    assert_equal @links, result.links
  end
  
  def test_invalid_conversion_result_nil_track
    result = Models::ConversionResult.new(nil, @links)
    
    refute result.valid?
  end
  
  def test_invalid_conversion_result_invalid_track
    invalid_track = Models::Track.new({})
    result = Models::ConversionResult.new(invalid_track, @links)
    
    refute result.valid?
  end
  
  def test_invalid_conversion_result_nil_links
    result = Models::ConversionResult.new(@track, nil)
    
    refute result.valid?
  end
  
  def test_invalid_conversion_result_invalid_links
    invalid_links = Models::Links.new({})
    result = Models::ConversionResult.new(@track, invalid_links)
    
    refute result.valid?
  end
  
  def test_from_json_valid_data
    json_data = {
      'track' => @track_data,
      'links' => @links_data
    }
    
    result = Models::ConversionResult.from_json(json_data)
    
    assert_instance_of Models::ConversionResult, result
    assert result.valid?
    assert_equal 'Test Song', result.track.title
    assert_equal 'Test Artist', result.track.artist
  end
  
  def test_from_json_invalid_data
    assert_nil Models::ConversionResult.from_json(nil)
    assert_nil Models::ConversionResult.from_json('not a hash')
    assert_nil Models::ConversionResult.from_json({})
    assert_nil Models::ConversionResult.from_json({'track' => @track_data})
    assert_nil Models::ConversionResult.from_json({'links' => @links_data})
  end
  
  def test_to_markdown
    result = Models::ConversionResult.new(@track, @links)
    markdown = result.to_markdown
    
    # Track portion
    assert_includes markdown, '*Test Song*'
    assert_includes markdown, 'Test Artist'
    assert_includes markdown, 'Test Album'
    
    # Links portion
    assert_includes markdown, '*Available on:*'
    assert_includes markdown, '[Spotify]'
    assert_includes markdown, '[Deezer]'
  end
end