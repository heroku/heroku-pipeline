require 'heroku/command/base'
require 'heroku/api/config_vars'
require 'rest_client'
require 'net/http'

# deploy to an app
#
class Heroku::Command::Pipeline < Heroku::Command::BaseWithApp
  VERSION = "0.1"
  DEFAULT_HOST = "release-promotion.herokuapp.com"

  # pipeline
  #
  # deploy to an app
  #
  def index
    display "TODO"
  end

  # pipeline:promote
  #
  # promote an app slug to downstream app
  #
  # -d, --downstream DOWNSTREAM_APP  # target app
  #
  def promote
    host = DEFAULT_HOST

    upstream_app = app

    downstream_app = options[:downstream]
    if downstream_app.nil?
      config_vars = heroku.config_vars(app)
      if config_vars.has_key? "DOWNSTREAM_APP"
        downstream_app = config_vars["DOWNSTREAM_APP"]
      end
    end
    if downstream_app.nil?
      raise Heroku::Command::CommandFailed, "downstream app could not be determined"
    end

    [upstream_app, downstream_app].each do |a|
      begin
        heroku.get("/apps/#{a}")
      rescue RestClient::ResourceNotFound => e
        raise Heroku::Command::CommandFailed, "No access to #{a}"
      end
    end

    print_and_flush("Promoting #{upstream_app} to #{downstream_app}...")
    RestClient.post "http://:#{api_key}@#{host}/apps/#{upstream_app}/promote/#{downstream_app}", "cloud=heroku.com", headers
    print_and_flush("done\n")
  end

  protected
  def api_key
    Heroku::Auth.api_key
  end

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