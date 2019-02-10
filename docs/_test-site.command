#!/bin/bash

# this requires Jekyll, which you can get by running $ sudo gem install jekyll
# This particular site also requires the paginate gem: $ sudo gem install jekyll-paginate
# create a new site using $ jekyll new my-awesome-site

cd "`dirname $0`"
jekyll serve --watch --open-url
