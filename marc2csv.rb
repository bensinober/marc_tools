#!/usr/bin/env ruby
# coding:utf-8

require 'rubygems'
require 'marc'
if RUBY_VERSION < "1.9" 
  require "faster_csv" 
  CSV = FCSV 
else 
  require "csv" 
end 

def usage(s)
    $stderr.puts(s)
    $stderr.puts("Usage: \n")
    $stderr.puts("#{File.basename($0)} -i input_file.mrc -o output_file.csv [-r recordlimit]\n")
    $stderr.puts("  -i input_file must be MARC binary\n")
    $stderr.puts("  -o output_file file must be comma-separated file\n")
    $stderr.puts("  -r [number] stops processing after given number of records\n")
    exit(2)
end

loop { case ARGV[0]
    when '-i' then ARGV.shift; $input_file  = ARGV.shift
    when '-o' then ARGV.shift; $output_file = ARGV.shift
    when '-r' then ARGV.shift; $recordlimit = ARGV.shift.to_i # force integer
    when /^-/ then usage("Unknown option: #{ARGV[0].inspect}")
    else 
      if !$input_file || !$output_file then usage("Missing argument!\n") end
    break
end; }

count = 0

# reading records from a batch file
reader = MARC::Reader.new($input_file)

#csv = CSV.open($output_file, "wb:ASCII-8BIT:UTF-8", {:headers => true, :write_headers => true, :quote_char => '"', :col_sep =>',', :force_quotes => true})
csv = CSV.open($output_file, "wb:UTF-8", {:headers => true, :write_headers => true, :quote_char => '"', :col_sep =>',', :force_quotes => true})

marc_tags = []
marc_tagandsubfields = []
headers = []
csv_rows = []

reader.each do | record |
csv_records = {}
  count += 1
  if $recordlimit then break if count > $recordlimit end

  record.tags.each do | marctag | 
    # put all marc tag fields into array object 'marcfields' for later use
    marcfields = record.find_all { |field| field.tag == marctag }

    # iterate each marc tag array object to catch multiple marc fields
    # use index to identify repeated fields 
    marcfields.each_with_index do | field,index | 
     # record.each do | field |
        unless field.is_a?(MARC::ControlField)
          field.each do |subfield|
            unless marc_tagandsubfields.include?(marctag + subfield.code + "_#{index}") then marc_tagandsubfields << marctag + subfield.code  + "_#{index}" end
			
            csv_records[marctag + subfield.code + "_#{index}"] = subfield.value
            #puts marctag + subfield.code
          end
        else
        # controlfields
          unless marc_tagandsubfields.include?(marctag) then marc_tagandsubfields << marctag end
          csv_records[marctag] = field.value
        end
      end
    #end
  end
csv_rows << csv_records   
end
#p csv_rows
marc_tagandsubfields.sort!
headers << marc_tagandsubfields
csv << marc_tagandsubfields.each { | marc_tagandsubfield| }
csv_rows.each do |row|
  csv << marc_tagandsubfields.map { | header | row[header] }
end

