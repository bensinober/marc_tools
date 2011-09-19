#!/usr/bin/env ruby

require 'rubygems'
if RUBY_VERSION < "1.9" 
  require "rubygems" 
  require "faster_csv" 
  CSV = FCSV 
else 
  require "csv" 
end 
require 'rdf'
require 'rdf/rdfxml'
require 'rdf/n3'
require 'rdf/ntriples'

def usage(s)
    $stderr.puts(s)
    $stderr.puts("Usage: \n")
    $stderr.puts("#{File.basename($0)} -i input_file.csv -o output_file -b base_uri -t rdf_type [-r recordlimit]\n")
    $stderr.puts("  -i input_file must be comma-separated file\n")
    $stderr.puts("  -o output_file extension can be either .rdf (slooow) .n3 (sloow) or .nt (very fast)\n")
    $stderr.puts("  -b base_uri must be uri\n")
    $stderr.puts("  -t rdf_type must be uri\n")    
    $stderr.puts("  -r [number] stops processing after given number of records\n")
    exit(2)
end

loop { case ARGV[0]
    when '-i':  ARGV.shift; $input_file  = ARGV.shift
    when '-o':  ARGV.shift; $output_file = ARGV.shift
    when '-b':  ARGV.shift; $base_uri    = ARGV.shift
    when '-t':  ARGV.shift; $rdf_type    = ARGV.shift
    when '-r':  ARGV.shift; $recordlimit = ARGV.shift.to_i # force integer
    when /^-/:  usage("Unknown option: #{ARGV[0].inspect}")
    else 
      if !$input_file || !$output_file || !$base_uri || !$rdf_type then usage("Missing argument!\n") end
    break
end; }

class String
  def strip_leading_and_trailing_punct
    str = self.sub(/[\.:,;\/\s\)\]]\s*$/,'').strip
    return str.strip.sub(/^\s*[\.:,;\/\s\(\[]/,'')
  end  
end

class RDFModeler
  attr_reader :record, :statements, :uri
  def initialize(record)
    @record = record
    construct_uri
    @statements = []
  end
  
  def construct_uri
    @uri = RDF::URI.intern($base_uri)
    id = "#{@record}"
    id.gsub!(/[^\w\s\-ÆØÅæøå]/,"")
    id.gsub!(/\s/,"_")
    @uri += id
  end
  
  def set_type(t)
    @statements << RDF::Statement.new(@uri, RDF.type, t)
  end
  
  def assert(p, o)
    @statements << RDF::Statement.new(@uri, RDF::URI(p), o)
  end
  
  def write_record
      @statements.each do | statement |
      #p statement
        @@writer << statement
      end
  end
end
  
count = 0

csv = CSV.read($input_file, {:headers => true, :encoding => 'UTF-8'})
# start writer handle
RDF::Writer.open($output_file) do | writer |
@@writer = writer

  csv.each do | record |
    count += 1
    if $recordlimit then break if count > $recordlimit end
      # take the content of the first column to make record id
      rdfrecord = RDFModeler.new(record[0])
      rdfrecord.set_type(RDF::URI($rdf_type))
      record.each do |k,v| 
        unless v.nil?
          v.strip_leading_and_trailing_punct
          if v =~ /^http/
            rdfrecord.assert(RDF::URI(k), RDF::URI("#{v}"))
          elsif v =~ /^[\d]+$/
            rdfrecord.assert(RDF::URI(k), RDF::Literal("#{v}", :datatype => RDF::XSD.integer))
          else
            rdfrecord.assert(RDF::URI(k), v)
          end
        end
      end 
    
    rdfrecord.write_record
  end
end # end writer loop
puts "converted records: #{count}"
