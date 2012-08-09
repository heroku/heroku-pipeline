require 'heroku/command/base'
require 'heroku/api/config_vars'
require 'rest_client'
require 'net/http'

# advanced slug operations
#
class Heroku::Command::Slugs < Heroku::Command::Base
  VERSION = "0.1"
  DEFAULT_HOST = "release-promotion.herokuapp.com"

  # slugs:cp source_app target_app
  #
  # copy an app slug to app to another app
  #
  def cp
    raise Heroku::Command::CommandFailed, "Invalid arguments. Syntax: heroku slugs:cp source_app target_app" if args.length != 2

    source_app = shift_argument
    target_app = shift_argument

    [source_app, target_app].each do |a|
      begin
        heroku.get("/apps/#{a}")
      rescue RestClient::ResourceNotFound => e
        raise Heroku::Command::CommandFailed, "No access to #{a}"
      end
    end

    print_and_flush("Copying slug from #{source_app} to #{target_app}...")
    response = RestClient.post "http://:#{Heroku::Auth.api_key}@#{DEFAULT_HOST}/apps/#{source_app}/promote/#{target_app}", "cloud=heroku.com", headers
    print_and_flush("done, #{json_decode(response)['release']}\n")
  end

  protected

  def headers
    {
        'User-Agent'       => "cli-plugin/#{VERSION}",
        'X-Ruby-Version'   => RUBY_VERSION,
        'X-Ruby-Platform'  => RUBY_PLATFORM
    }
  end

  def print_and_flush(str)
    print str
    $stdout.flush
  end

end