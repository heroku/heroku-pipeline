require 'heroku/cisaurus/cisaurus'
require 'heroku/command/base'
require 'heroku/api/config_vars'
require 'rest_client'
require 'net/http'

# Continuous delivery pipeline actions
#
class Heroku::Command::Pipeline < Heroku::Command::BaseWithApp

  DOWNSTREAM_APP = "DOWNSTREAM_APP"

  def initialize(args, heroku=nil)
    super(args, heroku)
    @cisauraus = Cisaurus.new(Heroku::Auth.api_key)
  end

  # pipeline
  #
  # display info about the app pipeline
  #
  def index
    downstreams = json_decode @cisauraus.downstreams(app)
    verify_downstream! downstreams.first
    display "Pipeline: #{downstreams.unshift(app).join ' ---> '}"
  end

  # pipeline:add DOWNSTREAM_APP
  #
  # add a downstream app to this app
  #
  def add
    downstream = shift_argument
    verify_downstream! downstream
    @cisauraus.addDownstream(app, downstream)
    display "Added downstream app: #{downstream}"
  end

  # pipeline:remove
  #
  # remove the downstream app of this app
  #
  def remove
    downstream = shift_argument
    verify_downstream! downstream
    @cisauraus.removeDownstream(app, downstream)
    display "Removed downstream app: #{downstream}"
  end

  # pipeline:promote
  #
  # promote the latest release of this app to the downstream app
  #
  def promote
    downstream = (json_decode @cisauraus.downstreams(app)).first
    verify_downstream! downstream
    print_and_flush("Promoting #{app} to #{downstream}...")

    promotion = @cisauraus.promote(app) do
      print_and_flush "."
    end

    body = json_decode promotion
    print_and_flush("done, #{body['release']}\n")
  end

  protected

  def verify_downstream!(downstream_app)
    if downstream_app.nil?
      raise Heroku::Command::CommandFailed, "Downstream app not specified. Use `heroku pipeline:add DOWNSTREAM_APP` to add one."
    end
  end

  def print_and_flush(str)
    print str
    $stdout.flush
  end
end