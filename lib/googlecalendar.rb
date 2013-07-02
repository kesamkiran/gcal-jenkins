$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Googlecalendar
  # List of lib files to include
  FILES = %w{event.rb gcalendar.rb gdata.rb net.rb}
end

# Add all FILES as require
Googlecalendar::FILES.each { |f| require "googlecalendar/#{f}"}
