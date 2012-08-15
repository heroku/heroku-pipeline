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
  # display info about the app pipeline
  #
  def index
    upstream_app = app
    pipeline = [ upstream_app ]
    until upstream_app.nil?
      downstream_app = get_downstream_app upstream_app
      verify_config! downstream_app if pipeline.length == 1
      pipeline.push downstream_app unless downstream_app.nil?
      raise Heroku::Command::CommandFailed, "Recursive pipeline: #{pipeline.join ' ---> '}" if upstream_app == downstream_app
      upstream_app = downstream_app
    end

    display "Pipeline: #{pipeline.join ' ---> '}"
  end

  # pipeline:add DOWNSTREAM_APP
  #
  # add a downstream app to this app
  #
  def add
    curr_downstream_app = get_downstream_app
    raise Heroku::Command::CommandFailed, "Downstream app already configured: #{curr_downstream_app}" if curr_downstream_app

    downstream_app = shift_argument
    verify_config! downstream_app

    raise Heroku::Command::CommandFailed, "Downstream app cannot be recursive" if downstream_app == app

    verify_app_access! downstream_app

    Heroku::Auth.api.put_config_vars(app, DOWNSTREAM_APP => downstream_app)
    display "Added downstream app: #{downstream_app}"
  end

  # pipeline:remove
  #
  # remove the downstream app of this app
  #
  def remove
    downstream_app = get_downstream_app
    verify_config! downstream_app

    Heroku::Auth.api.delete_config_var(app, DOWNSTREAM_APP)
    display "Removed downstream app: #{downstream_app}"
  end

  # pipeline:promote
  #
  # promote the latest release of this app to the downstream app
  #
  def promote
    upstream_app = app

    downstream_app = get_downstream_app
    verify_config! downstream_app

    [upstream_app, downstream_app].each do |a|
      verify_app_access! a
    end

    print_and_flush("Promoting #{upstream_app} to #{downstream_app}...")
    url = "https://:#{Heroku::Auth.api_key}@release-pipelines.herokuapp.com/apps/#{upstream_app}/copy/#{downstream_app}"
    body = {
        "cloud" => "heroku.com",
        "command" => "pipeline:promote"
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

  def get_downstream_app(a = app)
    config_vars = Heroku::Auth.api.get_config_vars(a).body
    if config_vars.has_key? DOWNSTREAM_APP
      config_vars[DOWNSTREAM_APP]
    end
  end

  def verify_config!(downstream_app)
    if downstream_app.nil?
      raise Heroku::Command::CommandFailed, "Downstream app not specified. Use `heroku pipeline:add DOWNSTREAM_APP` to add one."
    end
  end

  def verify_app_access!(app)
    begin
      heroku.get("/apps/#{app}")
    rescue RestClient::ResourceNotFound => e
      raise Heroku::Command::CommandFailed, "No access to #{app}"
    end
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