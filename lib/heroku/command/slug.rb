require 'heroku/command/base'
require 'heroku/api/config_vars'
require 'rest_client'
require 'net/http'

# advanced slug operations
#
class Heroku::Command::Slug < Heroku::Command::Base
  VERSION = "0.2-PRE-ALPHA"

  # slug:cp SOURCE_APP TARGET_APP
  #
  # copy an app slug to app to another app
  #
  def cp
    raise Heroku::Command::CommandFailed, "Invalid arguments. Usage: heroku slugs:cp SOURCE_APP TARGET_APP" if args.length != 2

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
    url = "https://:#{Heroku::Auth.api_key}@release-pipelines.herokuapp.com/apps/#{source_app}/copy/#{target_app}"
    body = {
        "cloud" => "heroku.com",
        "command" => "slugs:cp"
    }
    response = RestClient.post url, body, headers
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