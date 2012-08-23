require 'heroku/command/base'
require 'heroku/api/config_vars'
require 'rest_client'
require 'net/http'

# advanced slug operations
#
class Heroku::Command::Slug < Heroku::Command::Base
  VERSION = "0.3-PRE-ALPHA"

  # slug:cp SOURCE_APP TARGET_APP
  #
  # copies the latest release of one app to another app
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
        "cloud"   =>  ENV['HEROKU_HOST'] || "heroku.com",
        "command" => "slugs:cp"
    }
    begin
      response = RestClient.post url, body, headers
      print_and_flush("done, #{json_decode(response)['release']}\n")
    rescue RestClient::Forbidden => e
      display
      raise Heroku::Command::CommandFailed, e.response
    end
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