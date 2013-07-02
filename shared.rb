require File.dirname(__FILE__) + '/lib/googlecalendar'
require 'rubygems'
require 'yaml'
require 'jenkins_api_client'
require 'rexml/document'
require 'parse-cron'
include REXML
include Googlecalendar
