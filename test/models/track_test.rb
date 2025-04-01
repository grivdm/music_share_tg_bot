# frozen_string_literal: true

require_relative '../test_helper'

class TrackTest < Minitest::Test
  def test_valid_track
    track_data = {
      'title' => 'Test Song',
      'artist' => 'Test Artist',
      'album' => 'Test Album',
      'isrc' => 'USABC1234567'
    }
    
    track = Models::Track.new(track_data)
    
    assert track.valid?
    assert_equal 'Test Song', track.title
    assert_equal 'Test Artist', track.artist
    assert_equal 'Test Album', track.album
    assert_equal 'USABC1234567', track.isrc
  end
  
  def test_invalid_track_missing_title
    track_data = {
      'artist' => 'Test Artist',
      'album' => 'Test Album'
    }
    
    track = Models::Track.new(track_data)
    
    refute track.valid?
  end
  
  def test_invalid_track_missing_artist
    track_data = {
      'title' => 'Test Song',
      'album' => 'Test Album'
    }
    
    track = Models::Track.new(track_data)
    
    refute track.valid?
  end
  
  def test_from_json_valid_data
    json_data = {
      'title' => 'Test Song',
      'artist' => 'Test Artist',
      'album' => 'Test Album'
    }
    
    track = Models::Track.from_json(json_data)
    
    assert_instance_of Models::Track, track
    assert track.valid?
  end
  
  def test_from_json_invalid_data
    assert_nil Models::Track.from_json(nil)
    assert_nil Models::Track.from_json('not a hash')
    assert_nil Models::Track.from_json({})
  end
  
  def test_to_markdown
    track_data = {
      'title' => 'Test Song',
      'artist' => 'Test Artist',
      'album' => 'Test Album'
    }
    
    track = Models::Track.new(track_data)
    markdown = track.to_markdown
    
    assert_includes markdown, '*Test Song*'
    assert_includes markdown, 'Test Artist'
    assert_includes markdown, 'Test Album'
  end
  
  def test_to_markdown_without_album
    track_data = {
      'title' => 'Test Song',
      'artist' => 'Test Artist'
    }
    
    track = Models::Track.new(track_data)
    markdown = track.to_markdown
    
    assert_includes markdown, '*Test Song*'
    assert_includes markdown, 'Test Artist'
    refute_includes markdown, 'Test Album'
  end
end