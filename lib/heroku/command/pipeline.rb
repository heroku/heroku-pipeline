require 'heroku/cisaurus/cisaurus'
require 'heroku/command/base'
require 'heroku/api/config_vars'
require 'rest_client'
require 'net/http'

# Continuous delivery pipeline actions
#
class Heroku::Command::Pipeline < Heroku::Command::BaseWithApp

  VERSION = "0.4-PRE-ALPHA"
  DOWNSTREAM_APP = "DOWNSTREAM_APP"

  # pipeline
  #
  # display info about the app pipeline
  #
  def index
    downstreams = json_decode Cisaurus.new(app).downstreams
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
    Cisaurus.new(app).addDownstream downstream
    display "Added downstream app: #{downstream}"
  end

  # pipeline:remove
  #
  # remove the downstream app of this app
  #
  def remove
    downstream = shift_argument
    verify_downstream! downstream
    Cisaurus.new(app).removeDownstream downstream
    display "Removed downstream app: #{downstream}"
  end

  # pipeline:promote
  #
  # promote the latest release of this app to the downstream app
  #
  def promote
    downstream = (json_decode Cisaurus.new(app).downstreams).first
    verify_downstream! downstream
    print_and_flush("Promoting #{app} to #{downstream}...")

    promotion = json_decode Cisaurus.new(app).promote
    poll_id = promotion['poll-id']

    while promotion['release'].nil?
      promotion = json_decode Cisaurus.new(app).check_status(poll_id)
      print_and_flush "."
      sleep 2
    end

    print_and_flush("done, #{promotion['release']}\n")
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