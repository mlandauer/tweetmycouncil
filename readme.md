Tweet My Council
================

When's the next bin pick up in your street? How do you submit a development application? Where's my closest library?

You shouldn't have to know who your local council is to have these questions answered. Tweet My Council is a simple service that works this out for you. Just use the hashtag `#tmyc`, geotag your tweet and Tweet My Council will work out your local council and RT your question to them.

Configuration
-------------

For local development, copy `configuration.yaml.example` to `configuration.yaml` and set up your Twitter credentials. When deploying to Heroku, environment variables are used and are set with `heroku config:add CONSUMER_KEY=8N029N81`, etc.
