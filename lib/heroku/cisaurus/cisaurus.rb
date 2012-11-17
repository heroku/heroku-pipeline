class Cisaurus

  CLIENT_VERSION = "0.4-PRE-ALPHA"
  DEFAULT_HOST = ENV['CISAURUS_HOST'] || "cisaurus.heroku.com"

  def initialize(api_key, host = DEFAULT_HOST, api_version = "v1")
    @base_url = "https://:#{api_key}@#{host}"
    @ver_url  = "#{@base_url}/#{api_version}"
  end

  def downstreams(app)
    Heroku::OkJson.decode RestClient.get pipeline_resource(app, "downstreams"), headers
  end

  def addDownstream(app, ds)
    RestClient.post pipeline_resource(app, "downstreams", ds), "", headers
  end

  def removeDownstream(app, ds)
    RestClient.delete pipeline_resource(app, "downstreams", ds), headers
  end

  def diff(app)
    Heroku::OkJson.decode RestClient.get pipeline_resource(app, "diff"), headers
  end

  def promote(app, interval = 2)
    response = RestClient.post pipeline_resource(app, "promote"), "", headers
    while response.code == 202
      response = RestClient.get @base_url + response.headers[:location], headers
      sleep(interval)
      yield
    end
    Heroku::OkJson.decode response
  end

  private

  def pipeline_resource(app, *extras)
    "#{@ver_url}/" + extras.unshift("apps/#{app}/pipeline").join("/")
  end

  def headers
    {
        'User-Agent'       => "cli-plugin/#{CLIENT_VERSION}",
        'X-Ruby-Version'   => RUBY_VERSION,
        'X-Ruby-Platform'  => RUBY_PLATFORM
    }
  end
end