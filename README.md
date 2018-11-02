# Github Project Charts

Provides several charts to give you varying views of your github project. 

This is a handy tool for checking out team velocity, throughput, wip, cycle time etc. 

# Getting started

1. Install latest version of RVM (must be > 1.11.0)
2. Clone repo
3. CD into repo
4. install correct version of ruby when / if prompted
5. install bundler - gem install bundle
6. download all gems - bundle install
7. define project settings in config.yml (see section below)
8. run app - rackup config.ru

# Project settings

1. REQUIRED: OAUTH - the oauth token of your github repo
2. REQUIRED: GITHUB_PROJECT - the path to your project 
3. REQUIRED: REPO - the path to your github repo
4. REQUIRED: THROUGHPUT_MAP - the names of the columns you want displayed on this chart. NOTE: throughput is calculated based on combined average of these columns.
5. REQUIRED: CUMULATIVE_MAP  - the names of the columns you want displayed on this chart. 
6. OPTIONAL: COLORS - the colours you want to use to represent each column in the cumulative flow chart
7. OPTIONAL: LOG_LEVEL - debug, info, warn, error, fatal
8. OPTIONAL: TITLE - the title of the website


