#!/usr/bin/env ruby

require 'rubygems'
require 'marc'

# quit unless our script gets two command line arguments
unless ARGV.length > 0
  puts "Missing input file!"
  puts "Usage: ruby marc2xml.rb InputFile.mrc [OutputFile.xml]\n"
  exit
end

# our input file should be the first command line arg
input_file = ARGV[0]

# our output file should be the second command line arg
if ARGV[1]
output_file = ARGV[1]
writer = MARC::XMLWriter.new(output_file)
end
  
  # reading records from a batch file
  reader = MARC::Reader.new(input_file)

output = open(output_file, "w+")
output << "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
output << "<collection>\n"

reader.each do | record |
  if ARGV.length == 2
  writer.write(record)
  # insert linefeed between each record
  output << "\n"
  end
  #puts record.to_xml
end

output << "</collection>\n"
 
if ARGV[1]
  writer.close()
end
