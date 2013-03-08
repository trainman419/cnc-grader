#! /usr/bin/env rackup

require 'rubygems' unless defined?(Gem)
require 'bundler'

Bundler.require(:default)

require "./datamap"
require "./config"

require './grader'

run Sinatra::Application
