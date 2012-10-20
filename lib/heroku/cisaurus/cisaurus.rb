class Cisaurus

  HOST = "cisaurus.herokuapp.com"
  DOWNSTREAMS = "/pipeline/downstreams"
  VERSION = "v1"

  def initialize(app)
    @url = "https://:#{Heroku::Auth.api_key}@#{HOST}/#{VERSION}/apps/#{app}"
  end

  def downstreams
    RestClient.get @url + DOWNSTREAMS, headers
  end

  def addDownstream(downstream)
    RestClient.post @url + DOWNSTREAMS + downstream, "", headers
  end

  def removeDownstream(downstream)
    RestClient.delete @url + DOWNSTREAMS + downstream, headers
  end

  def promote
    RestClient.post @url + "/pipeline/promote", "", headers
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