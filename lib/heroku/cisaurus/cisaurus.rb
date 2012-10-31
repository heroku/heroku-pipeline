class Cisaurus

  CLIENT_VERSION = "0.4-PRE-ALPHA"
  DOWNSTREAMS = "/pipeline/downstreams"

  def initialize(api_key, host = "cisaurus.herokuapp.com", api_version = "v1")
    @base_url = "http://:#{api_key}@#{host}"
    @ver_url  = "#{@base_url}/#{api_version}"
  end

  def downstreams(app)
    RestClient.get app_url(app) + DOWNSTREAMS, headers
  end

  def addDownstream(app, downstream)
    RestClient.post app_url(app) + DOWNSTREAMS + downstream, "", headers
  end

  def removeDownstream(app, downstream)
    RestClient.delete app_url(app) + DOWNSTREAMS + downstream, headers
  end

  def promote(app)
    RestClient.post app_url(app) + "/pipeline/promote", "", headers
  end

  def get(rel_url)
    RestClient.get @base_url + rel_url, headers
  end

  private
  def app_url(app)
    "#{@ver_url}/apps/#{app}"
  end

  def headers
    {
        'User-Agent'       => "cli-plugin/#{CLIENT_VERSION}",
        'X-Ruby-Version'   => RUBY_VERSION,
        'X-Ruby-Platform'  => RUBY_PLATFORM
    }
  end
end