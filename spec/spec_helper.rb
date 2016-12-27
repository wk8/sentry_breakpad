$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'sentry_breakpad'

def fixtures_dir
  File.expand_path('../fixtures', __FILE__)
end

def fixture_path(fixture_name)
  File.join(fixtures_dir, fixture_name)
end

def read_fixture(fixture_name)
  File.read(fixture_path(fixture_name))
end
