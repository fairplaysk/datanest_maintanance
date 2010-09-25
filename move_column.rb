#!/usr/bin/env ruby 

# == Synopsis 
#   This is a sample description of the application.
#   Blah blah blah.
#
# == Examples
#   This command does blah blah blah.
#     ruby_cl_skeleton foo.txt
#
#   Other examples:
#     ruby_cl_skeleton -q bar.doc
#     ruby_cl_skeleton --verbose foo.html
#
# == Usage 
#   ruby_cl_skeleton [options] source_file
#
#   For help use: ruby_cl_skeleton -h
#
# == Options
#   -h, --help          Displays help message
#   -v, --version       Display the version, then exit
#   -q, --quiet         Output as little as possible, overrides verbose
#   -V, --verbose       Verbose output
#   TO DO - add additional options
#
# == Author
#   YourName
#
# == Copyright
#   Copyright (c) 2007 YourName. Licensed under the MIT License:
#   http://www.opensource.org/licenses/mit-license.php


# TO DO - replace all ruby_cl_skeleton with your app name
# TO DO - replace all YourName with your actual name
# TO DO - update Synopsis, Examples, etc
# TO DO - change license if necessary

# zip = ask("Zip?  ") { |q| q.validate = /\A\d{5}(?:-?\d{4})?\Z/ }

require 'rubygems'
require 'bundler/setup'
Bundler.require

require 'ostruct'
require 'date'
require 'active_support/inflector'

class App
  VERSION = '0.0.1'
  
  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    
    # Set defaults
    @options = OpenStruct.new
    @options.verbose = false
    @options.quiet = false
    # TO DO - add additional defaults
  end

  # Parse options, check arguments, then process the command
  def run
        
    if parsed_options? && arguments_valid? 
      
      puts "Start at #{DateTime.now}\n\n" if @options.verbose
      
      output_options if @options.verbose # [Optional]
            
      process_arguments            
      process_command
      
      puts "\nFinished at #{DateTime.now}" if @options.verbose
      
    else
      output_usage
    end
      
  end
  
  protected
  
    def parsed_options?
      
      # Specify options
      opts = OptionParser.new 
      opts.on('-v', '--version')    { output_version ; exit 0 }
      opts.on('-h', '--help')       { output_help }
      opts.on('-V', '--verbose')    { @options.verbose = true }  
      opts.on('-q', '--quiet')      { @options.quiet = true }
      # TO DO - add additional options
            
      opts.parse!(@arguments) rescue return false
      
      process_options
      true      
    end

    # Performs post-parse processing on options
    def process_options
      @options.verbose = false if @options.quiet
    end
    
    def output_options
      puts "Options:\n"
      
      @options.marshal_dump.each do |name, val|        
        puts "  #{name} = #{val}"
      end
    end

    # True if required arguments were provided
    def arguments_valid?
      # TO DO - implement your real logic here
      true #if @arguments.length == 1 
    end
    
    # Setup the arguments
    def process_arguments
      # TO DO - place in local vars, etc
    end
    
    def output_help
      output_version
      #RDoc::usage() #exits app
    end
    
    def output_usage
      #RDoc::usage('usage') # gets usage from comments above
    end
    
    def output_version
      puts "#{File.basename(__FILE__)} version #{VERSION}"
    end
    
    def process_command
      # TO DO - do whatever this app does
      
      while true do
        table = init
        break if table
      end
      
      create_activerecord_model(table.singularize.capitalize)
      model = table.capitalize.classify.constantize
      
      master_column = get_master_column
      test_column(model, master_column) do
        target_column = get_target_column
        test_column(model, target_column) do
          model.all.each_with_index do |row, index|
            if row != nil
              update_decision(model, master_column, target_column)
            elsif
              model.send("#{target_column}=", model.send(master_column))
            end
            puts "Spracovanych #{index} riadkov." if index % 20 == 0
          end
          puts "Spracovanie dat ukoncene. Celkovo bolo spracovanych #{model.count} riadkov."
        end
      end
      
      #process_standard_input
    end
    
    def update_decision(model, master, target)
      choose do |menu|
        menu.prompt = "Hodnota v stlpci `target` je nenulova. Co si zelate spravit?"

        menu.choice('prepisat') { model.send("#{target_column}=", model.send(master_column)) }
        menu.choices('preskocit')
        menu.choices('ukoncit program'){ exit }
      end
    end
    
    def get_target_column
      ask('Zadajte prosim `target` stlpec: ') { |q| q.validate = /\w+/}
    end
    
    def test_column(model, column)
      model.first.send column.to_sym
      yield
      rescue
        puts 'Zadany stlpec neexistuje, skontrolujte prosim spravnost zadanych udajov a skuste znova.'
    end
    
    def get_master_column
      ask('Zadajte prosim `master` stlpec: ') { |q| q.validate = /\w+/}
    end
    
    def init
      host = get_server
      username = get_username
      password = get_password
      database = get_database
      establish_connection(host, database, username, password)
      table = get_table
      
      ActiveRecord::Base.connection.execute("select * from #{table} limit 1")
      
      return table
      rescue
        puts 'Pri pripajani na databazu nastala chyba, skontrolujte prosim spravnost udajov a dostupnost databazy a skuste znova.'
    end
    
    def establish_connection(host, database, username, password)
      ActiveRecord::Base.establish_connection(
        :adapter  => "mysql2",
        :host     => host,
        :database => database,
        :username => username,
        :password => password
      )
    end
    
    def get_server
      url = ask('Zadajte prosim adresu MySQL servera: ') { |q| q.default = '127.0.0.1'}
      URI.parse(url)
      url
      rescue URI::InvalidURIError
        puts 'Zadana adresa nie je spravna, skontrolujte prosim jej spravnost.'
    end
    
    def get_username
      ask('Zadajte prosim MySQL pouzivatelske meno: ') { |q| q.validate = /\w+/}
    end
    
    def get_password
      ask('Zadajte prosim MySQL pouzivatelske heslo: ') do |q| 
        q.echo = "x"
        q.validate = /\w+/
      end
    end
    
    def get_database
      ask('Zadajte prosim MySQL databazu: ') { |q| q.validate = /\w+/}
    end
    
    def get_table
      ask('Zadajte prosim MySQL tabulku: ') { |q| q.validate = /\w+/}
    end

    def process_standard_input
      input = @stdin.read      
      # TO DO - process input
      
      @stdin.each do |line| 
        puts line
      end
    end
end


# TO DO - Add your Modules, Classes, etc

def create_activerecord_model(name)
  eval("class #{name} < ActiveRecord::Base; end")
end


# Create and run the application
app = App.new(ARGV, STDIN)
app.run
