class Cisaurus

  HOST = ENV['CISAURUS_HOST'] || "cisaurus.herokuapp.com"
  DOWNSTREAMS = "/pipeline/downstreams"
  VERSION = "v1"

  def initialize(app)
    @base_url = "http://:#{Heroku::Auth.api_key}@#{HOST}"
    @ver_url  = "#{@base_url}/#{VERSION}"
    @app_url  = "#{@ver_url}/apps/#{app}"
  end

  def downstreams
    RestClient.get @app_url + DOWNSTREAMS, headers
  end

  def addDownstream(downstream)
    RestClient.post @app_url + DOWNSTREAMS + downstream, "", headers
  end

  def removeDownstream(downstream)
    RestClient.delete @app_url + DOWNSTREAMS + downstream, headers
  end

  def promote
    RestClient.post @app_url + "/pipeline/promote", "", headers
  end

  def check_status(id)
    RestClient.get @ver_url + "/jobs/" + id, headers
  end

  private
  def headers
    {
        'User-Agent'       => "cli-plugin/#{VERSION}",
        'X-Ruby-Version'   => RUBY_VERSION,
        'X-Ruby-Platform'  => RUBY_PLATFORM
    }
  end
end