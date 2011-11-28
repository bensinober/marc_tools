#!/usr/bin/env ruby
require 'rubygems'
require 'marc'

# quit unless our script gets two command line arguments
unless ARGV.length == 2
  puts "Missing input or output file!"
  puts "Usage: ruby fixnormarc.rb InputFile.mrc OutputFile.mrc\n"
  exit
end

# our input file should be the first command line arg
input_file = ARGV[0]

# our output file should be the second command line arg
output_file = ARGV[1]

writer = MARC::Writer.new(output_file)

# reading records from a batch file
reader = MARC::ForgivingReader.new(input_file)

  reader.each do | record | 

    record.each do | field |
	  if field.tag == '000' 
	    record.fields.delete(field)
	  end
    end
    #puts output_file

  writer.write(record)

end

writer.close()
