# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require 'webmock/minitest'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require_relative '../lib/models/conversion_result'
require_relative '../lib/models/track'
require_relative '../lib/models/links'
require_relative '../lib/services/api_client'
require_relative '../lib/services/url_processor'
require_relative '../lib/services/message_handler'