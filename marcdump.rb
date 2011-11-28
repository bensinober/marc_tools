#!/usr/bin/env ruby

require 'rubygems'
require 'marc'

# quit unless our script gets two command line arguments
unless ARGV.length == 1
  puts "Missing input file!"
  puts "Usage: ruby marcdump.rb InputFile.mrc\n"
  exit
end

# our input file should be the first command line arg
input_file = ARGV[0]

  # reading records from a batch file
  reader = MARC::Reader.new(input_file)
  
reader.each do | record |
  puts record
end
