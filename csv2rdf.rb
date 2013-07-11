#!/usr/bin/env ruby
# encoding:utf-8

require 'rubygems'
if RUBY_VERSION < "1.9" 
  require "faster_csv" 
  CSV = FCSV 
else 
  require "csv" 
end 
require 'uri'
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
    $stderr.puts("  -s 'separator' column separator")
    $stderr.puts("  -b base_uri must be uri\n")
    $stderr.puts("  -t rdf_type must be uri\n")    
    $stderr.puts("  -r [number] stops processing after given number of records\n")
    exit(2)
end

loop { case ARGV[0]
    when '-i' then  ARGV.shift; $input_file  = ARGV.shift
    when '-o' then  ARGV.shift; $output_file = ARGV.shift
    when '-s' then  ARGV.shift; $separator   = ARGV.shift ||= ","
    when '-b' then  ARGV.shift; $base_uri    = ARGV.shift 
    when '-t' then  ARGV.shift; $rdf_type    = ARGV.shift
    when '-r' then  ARGV.shift; $recordlimit = ARGV.shift.to_i # force integer
    when /^-/ then  usage("Unknown option: #{ARGV[0].inspect}")
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
    subs = {"Æ"=>"Ae", "Ø"=>"Oe", "Å"=>"Aa", "æ"=>"ae", "ø"=>"oe", "å"=>"aa", "Ä"=>"Ae", "Ö"=>"Oe", "ä"=>"ae", "ö"=>"oe", " "=>"_", "é"=>"e", "è"=>"e", "ê"=>"e", "á"=>"a", "à"=>"a", "â"=>"a", "ã"=>"a", "í"=>"i", "ì"=>"i", "î"=>"i", "ĩ"=>"i", "ó"=>"o", "ò"=>"o", "ô"=>"o", "õ"=>"o", "ú"=>"u", "ù"=>"u", "û"=>"u", "ũ"=>"u"}
    id = "#{@record}"
    id.gsub!(/Å|Ø|Æ|å|ø|æ|Ä|Ö|ä|ö|\ |[éèêẽ]|[áàâã]|[íìîĩ]|[óòôõ]|[úùûũ]/) { |match| subs[match] }
    id.gsub!(/[\W]+/,"")
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

csv = CSV.read($input_file, {:headers => true, :encoding => 'UTF-8', :col_sep => $separator})
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
      # k - headers, v - content
        unless v.nil?
          v.strip_leading_and_trailing_punct
          # content starts with http - make URI
          if v =~ /^http/
            rdfrecord.assert(RDF::URI(k), RDF::URI("#{v}"))
          # content contains only digits, make integer
          elsif v =~ /^[\d]+$/
            rdfrecord.assert(RDF::URI(k), RDF::Literal("#{v}", :datatype => RDF::XSD.integer))
          ### special cases can be entered below ###
          elsif k == "http://purl.org/stuff/rev#text"
            rdfrecord.assert(RDF::URI(k), RDF::Literal("#{v}", :language => :nb))
          elsif k == "CommentAltLanguage"
            rdfrecord.assert(RDF::URI("http://purl.org/stuff/rev#text"), RDF::Literal("#{v}", :language => :nn))
          ### end special cases ###
          else
            rdfrecord.assert(RDF::URI(k), v)
          end
        end
      end 
    
    rdfrecord.write_record
  end
end # end writer loop
puts "converted records: #{count}"
