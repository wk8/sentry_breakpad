require 'sentry_breakpad/version'
require 'sentry_breakpad/breakpad_parser'
require 'sentry_breakpad/hash_helper'

require 'raven'

module SentryBreakpad
  class << self
    def send_from_file(file_path, extra_info = {})
      send_event(BreakpadParser.from_file(file_path), extra_info)
    end

    def send_from_string(string, extra_info = {})
      send_event(BreakpadParser.new(string), extra_info)
    end

  private

    def send_event(parser, extra_info)
      Raven.client.send_event(parser.raven_event(extra_info))
    end
  end
end
