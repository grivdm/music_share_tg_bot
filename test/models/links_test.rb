# frozen_string_literal: true

require_relative '../test_helper'

class LinksTest < Minitest::Test
  def test_valid_links
    links_data = {
      'spotify' => 'https://open.spotify.com/track/123456',
      'deezer' => 'https://deezer.com/track/789012'
    }
    
    links = Models::Links.new(links_data)
    
    assert links.valid?
    assert_equal links_data, links.platforms
  end
  
  def test_invalid_links_empty
    links = Models::Links.new({})
    
    refute links.valid?
  end
  
  def test_invalid_links_nil
    links = Models::Links.new(nil)
    
    refute links.valid?
  end
  
  def test_from_json_valid_data
    json_data = {
      'spotify' => 'https://open.spotify.com/track/123456',
      'deezer' => 'https://deezer.com/track/789012'
    }
    
    links = Models::Links.from_json(json_data)
    
    assert_instance_of Models::Links, links
    assert links.valid?
  end
  
  def test_from_json_invalid_data
    assert_nil Models::Links.from_json('not a hash')
    
    links = Models::Links.from_json({})
    assert_nil links
  end
  
  def test_platform_emoji
    links = Models::Links.new({})
    
    assert_equal '🟢', links.platform_emoji('spotify')
    assert_equal '🟢', links.platform_emoji('SPOTIFY')
    assert_equal '🔵', links.platform_emoji('deezer')
    assert_equal '🎵', links.platform_emoji('unknown')
  end
  
  def test_to_markdown
    links_data = {
      'spotify' => 'https://open.spotify.com/track/123456',
      'deezer' => 'https://deezer.com/track/789012'
    }
    
    links = Models::Links.new(links_data)
    markdown = links.to_markdown
    
    assert_includes markdown, '*Available on:*'
    assert_includes markdown, '[Spotify]'
    assert_includes markdown, '[Deezer]'
    assert_includes markdown, 'https://open.spotify.com/track/123456'
    assert_includes markdown, 'https://deezer.com/track/789012'
  end
  
  def test_to_markdown_empty
    links = Models::Links.new({})
    markdown = links.to_markdown
    
    assert_equal '', markdown
  end
end