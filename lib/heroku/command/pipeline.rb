require 'heroku/command/base'
require 'heroku/api/config_vars'
require 'rest_client'
require 'net/http'

# Continuous delivery pipeline actions
#
class Heroku::Command::Pipeline < Heroku::Command::BaseWithApp
  VERSION = "0.2-PRE-ALPHA"
  DOWNSTREAM_APP = "DOWNSTREAM_APP"

  # pipeline
  #
  # get info about downstream
  #
  def index
    downstream_app = get_downstream_app
    verify_config! downstream_app
    display "Downstream app: #{downstream_app}"
  end

  # pipeline:add downstream_app
  #
  # add a downstream_app to this app
  #
  def add
    curr_downstream_app = get_downstream_app
    raise Heroku::Command::CommandFailed, "Downstream app already configured: #{curr_downstream_app}" if curr_downstream_app

    downstream_app = shift_argument
    verify_config! downstream_app

    heroku.add_config_vars(app, {DOWNSTREAM_APP => downstream_app})
    display "Added downstream app: #{downstream_app}"
  end

  # pipeline:remove downstream_app
  #
  # remove the downstream_app of this app
  #
  def remove
    downstream_app = get_downstream_app
    verify_config! downstream_app

    heroku.remove_config_var(app, DOWNSTREAM_APP)
    display "Removed downstream app: #{downstream_app}"
  end

  # pipeline:promote
  #
  # promote this app slug to its downstream app
  #
  def promote
    upstream_app = app

    downstream_app = get_downstream_app
    verify_config! downstream_app

    [upstream_app, downstream_app].each do |a|
      begin
        heroku.get("/apps/#{a}")
      rescue RestClient::ResourceNotFound => e
        raise Heroku::Command::CommandFailed, "No access to #{a}"
      end
    end

    print_and_flush("Promoting #{upstream_app} to #{downstream_app}...")
    RestClient.post "http://:#{api_key}@release-promotion.herokuapp.com/apps/#{upstream_app}/copy/#{downstream_app}", "cloud=heroku.com", headers
    print_and_flush("done\n")
  end

  protected
  def api_key
    Heroku::Auth.api_key
  end

  def get_downstream_app
    config_vars = heroku.config_vars(app)
    if config_vars.has_key? DOWNSTREAM_APP
      config_vars[DOWNSTREAM_APP]
    end
  end

  def verify_config!(downstream_app)
    raise Heroku::Command::CommandFailed, "Downstream app not specified. Use `heroku pipeline:add DOWNSTREAM_APP` to add one." if downstream_app.nil?
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