#! /usr/bin/env rackup

require 'rubygems' unless defined?(Gem)
require 'bundler'

Bundler.require(:default)

require 'bcrypt'

require './grader'
require "./datamap"
require "./config"

run Sinatra::Application
