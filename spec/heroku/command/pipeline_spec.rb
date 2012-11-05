require "spec_helper"
require "json"

describe Heroku::Command::Pipeline do

  subject { output }

  before do
    stub_request(:post, /api.heroku.com\/login.*/)
  end

  describe "#index" do
    before do
      stub_pipeline_resource(:get, "dev", "downstreams").to_return(:body => JSON.generate(["staging", "prod"]))
      heroku "pipeline -a dev"
    end

    it { should include "dev ---> staging ---> prod" }
  end

  describe "#add" do
    before do
      stub_pipeline_resource(:get,  "staging", "downstreams").to_return(:body => JSON.generate([]))
      stub_pipeline_resource(:post, "staging", "downstreams", "prod")
      heroku "pipeline:add prod -a staging"
    end

    it { should include "Added downstream app: prod" }
  end

  describe "#remove" do
    before do
      stub_pipeline_resource(:get,  "staging", "downstreams").to_return(:body => JSON.generate([]))
      stub_pipeline_resource(:delete, "staging", "downstreams", "prod")
      heroku "pipeline:remove prod -a staging"
    end

    it { should include "Removed downstream app: prod" }
  end

  describe "#promote" do
    before do
      stub_pipeline_resource(:get,  "staging", "downstreams").to_return(:body => JSON.generate(["prod"]))
      stub_pipeline_resource(:post, "staging", "promote").to_return(:body => JSON.generate("release" => "v0"))
      heroku "pipeline:promote prod -a staging"
    end

    it { should include "Promoting staging to prod...done, v0" }
  end

  def stub_pipeline_resource(method, app, *extras)
    stub_request(method, "https://cisaurus.herokuapp.com/v1/" + extras.unshift("apps/#{app}/pipeline").join("/"))
  end
end
