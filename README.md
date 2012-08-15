heroku-pipeline
===============
An experimental Heroku CLI plugin for continuous delivery primitives.

Installation
------------
    $ heroku plugins:install https://github.com/heroku/heroku-pipeline

Setup
-----
This plugin requires the following user passes:

 - `new-releases`
 - `releases_slug`

Usage
-----
  - `heroku pipeline`                          display info about the app pipeline
  - `heroku pipeline:add DOWNSTREAM_APP`       add a downstream app to this app
  - `heroku pipeline:remove`                   remove the downstream app of this app
  - `heroku pipeline:promote`                  promote the latest release of this app to the downstream app

The functionality in `heroku pipeline:promote` is also exposed as a simple copy command without the concept of pipelines:

  - `slug:cp source_app target_app`    copies the latest release of one app to another app


Under the Hood
--------------
Both commands are communicating with `http://release-pipelines.herokuapp.com`, which is a fork of `https://github.com/ddollar/releases`,
but adds the ability to get the slug from an existing app. The slug retrieval and new release creation all happens server-side, so there
is no download/upload cost to the client.
