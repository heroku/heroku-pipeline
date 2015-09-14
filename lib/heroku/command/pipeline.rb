require 'heroku/cisaurus/cisaurus'
require 'heroku/command/base'
require 'heroku/api/config_vars'
require 'rest_client'
require 'net/http'

# manage continuous delivery pipelines
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
  # -d, --depth DEPTH  # limit the pipeline to a given number of downstreams
  #
  def index
    deprecation_notice!
    downstreams = @cisauraus.downstreams(app, options[:depth])
    verify_downstream! downstreams.first
    display "Pipeline: #{downstreams.unshift(app).join ' ---> '}"
  end

  # pipeline:add DOWNSTREAM_APP
  #
  # add a downstream app to this app
  #
  def add
    deprecation_notice!
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
    deprecation_notice!
    downstream = shift_argument
    verify_downstream! downstream
    @cisauraus.removeDownstream(app, downstream)
    display "Removed downstream app: #{downstream}"
  end

  # pipeline:diff
  #
  # compare the commits of this app to its downstream app
  #
  def diff
    deprecation_notice!
    downstream = @cisauraus.downstreams(app, 1).first
    verify_downstream! downstream

    print_and_flush "Comparing #{app} to #{downstream}..."

    diff = @cisauraus.diff(app)
    print_and_flush "done, "

    if diff.size > 0
      display "#{app} ahead by #{diff.size} #{plural('commit', diff.size)}:"
      diff.each do |commit|
        commit_detail = `git log -n 1 --pretty=format:"  %h  %ad  %s  (%an)" --date=short  #{commit} 2>/dev/null`
        if $?.exitstatus == 0
          display commit_detail
        else
          display "  #{commit}"
        end
      end
    else
      display "everything is up to date"
    end
  end

  # pipeline:promote
  #
  # promote the latest release of this app to its downstream app
  #
  def promote
    deprecation_notice!
    downstream = @cisauraus.downstreams(app, 1).first
    verify_downstream! downstream
    print_and_flush("Promoting #{app} to #{downstream}...")
    promotion = @cisauraus.promote(app) { print_and_flush "." }
    print_and_flush("done, #{promotion['release']}\n")
  end

  protected

  def deprecation_notice!
    display("WARNING: This older 'pipelines' feature has been superseded by a new Heroku Pipelines.\n" +
            "         Please upgrade as soon as possible. This older feature will be disabled soon.\n" +
            "         See: https://devcenter.heroku.com/articles/pipelines\n\n")
  end

  def plural(word, qty)
    if (qty == 1)
      word
    else
      word + "s"
    end
  end

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
