heroku-pipeline
===============
An experimental Heroku CLI plugin for continuous delivery primatives. 

Installation
------------
    $ heroku plugins:install https://github.com/heroku/heorku-pipeline

Setup
-----
This plugin requires the following user passes:

 - `new-releases`
 - `releases_slug`

Usage
-----
There are currently two commands and they ultimately do the same thing -- that is copy a slug from one app to another -- but with different semantics:

  - `heroku slugs:cp`: modeled after UNIX `cp` cmd to copy slugs between any two apps the user has access. does not have any app context. 
  - `heroku pipeline:promote`: copies slug from context app to downstream app defined in `DOWNSTREAM_APP` config var or takes `--downstream` arg

Under the Hood
--------------
Both commands are communicating with `http://release-promotion.herokuapp.com`, which is a fork of `https://github.com/ddollar/releases`, 
but adds the ability to get the slug from an existing app. The slug retrival and new release creation all happens server-side, so there 
is no download/upload cost to the client.
