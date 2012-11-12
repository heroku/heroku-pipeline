heroku-pipeline
===============
An experimental Heroku CLI plugin for [continuous delivery](http://en.wikipedia.org/wiki/Continuous_delivery) on Heroku.

This plugin is used to set up a simple pipeline of apps where the latest release of one app can be promoted to the next app downstream. The promotion only copies the upstream build artifact and leaves the downstream app's config vars, add-ons, and Git repo untouched. An app can only have one downstream app, but there is no limit to the length of the pipeline or the number of upstream apps. 

Example Usage
-------------
An example of a simple pipeline where developers push to a staging app and later promote the slug to production:

    $ cd deep-thought-1234-staging

    $ heroku pipeline:add deep-thought-1234
    Added downstream app: deep-thought-1234

    $ heroku pipeline
    Pipeline: deep-thought-1234-staging ---> deep-thought-1234

    $ git commit -m "A super important fix"

    $ git push heroku master

    ...

    $ heroku pipeline:diff
    Comparing deep-thought-1234-staging to deep-thought-1234...done, deep-thought-1234-staging ahead by 1 commit:
      73ab415  2012-01-01  A super important fix  (Joe Developer)

    $ heroku pipeline:promote
    Promoting deep-thought-1234-staging to deep-thought-1234...done, v2
    
    $ heroku releases --app deep-thought-1234
    
    === deep-thought-1234 Releases
    v2  Promote deep-thought-1234-staging v6 0f0a53b  brainard@heroku.com   1m ago
    v1  Initial release                               brainard@heroku.com   2m ago

Installation
------------
    $ heroku plugins:install git@github.com:heroku/heroku-pipeline.git

Commands
--------
  - `heroku pipeline`                          display info about the app pipeline
  - `heroku pipeline:add DOWNSTREAM_APP`       add a downstream app to this app
  - `heroku pipeline:remove`                   remove the downstream app of this app
  - `heroku pipeline:diff`                     compare the commits of this app to its downstream app
  - `heroku pipeline:promote`                  promote the latest release of this app to its downstream app