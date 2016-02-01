require 'sentry_breakpad/version'
require 'sentry_breakpad/breakpad_parser'

require 'raven'

module SentryBreakpad
  class << self
    def send_from_file(file_path, extra_info = {}, include_whole_report = true)
      send_event(BreakpadParser.from_file(file_path), extra_info, include_whole_report)
    end

    def send_from_string(string, extra_info = {}, include_whole_report = true)
      send_event(BreakpadParser.new(string), extra_info, include_whole_report)
    end

  private

    def send_event(parser, extra_info, include_whole_report)
      Raven.client.send_event(parser.raven_event(extra_info, include_whole_report))
    end
  end
end
