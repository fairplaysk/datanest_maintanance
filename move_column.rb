#!/usr/bin/env ruby 

# == Aplikacia „Prenesenie stlpca v ramci datasetu“ 
#   pripojenie k databaze SW si vypýta MySQL host address, username, password a nazov databazy SW sa pokusi pripojit a oznami vysledok. 
#   SW si vypyta meno tabulky, v ktorej bude pracovat. Ak taku nenajde, da na vyber zadat meno tabulky znova alebo skoncit. 
#   SW si vypyta meno stlpca (master), ktoreho obsah chce preniest. Skontroluje jeho existenciu. Ak neexistuje, oznami to (a program skonci). 
#   SW si vypyta meno stlpca (target), do ktoreho chce prenasany obsah zapisat. Ak neexistuje, oznami to (a program skonci). 
#   SW hodnotu poctu spracovanych riadkov nastavi na 0. SW zacne spracovavat prvy riadok.
#   
#   spracovanie riadku 
#   SW v riadku zisti hodnotu stlpca target – ak je nenulová, oznámi to a spyta sa, ci hodnotu má prepísať, riadok preskocit alebo program ukoncit. 
#   Podla toho program ukonci, prejde na dalsi riadok. Ak ma prepisat hodnotu, pokracuje. SW nacita hodnotu master a zapise ju do target. 
#   K hodnote urcujucej pocet spracovanych riadkov pripocita 1. SW zmaze hodnotu v stlpci master. 
#   SW zisti, ci je na poslednom riadku v tabulke, ak ano, program sa ukonci – vypise o tom oznam, kde uvedie, kolko riadkov spracoval. 
#   SW zisti, ci pocet riadkov je delitelny 20, ak ano, vypise pocet uz spracovanych riadkov. 
#   SW prejde na dalsi riadok.
#
# == Usage
#   For help use: move_column.rb -h
#
# == Options
#   -h, --help          Displays help message
#   -v, --version       Display the version, then exit
#   -q, --quiet         Output as little as possible, overrides verbose
#   -V, --verbose       Verbose output
#
# == Author
#   Michal Olah
#
# == Copyright
#   Copyright (c) 2010 Michal Olah. Licensed under the ??? License:
#   http://link_to_licence

require 'rubygems'
require 'bundler/setup'
Bundler.require

require 'ostruct'
require 'date'
require 'active_support/inflector'
require './lib/datanest'

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
      true
    end
    
    # Setup the arguments
    def process_arguments
    end
    
    def output_help
      output_version
      RDoc::usage_no_exit #exits app
    end
    
    def output_usage
      #RDoc::usage('usage') # gets usage from comments above
    end
    
    def output_version
      puts "#{File.basename(__FILE__)} version #{VERSION}"
    end
    
    def process_command
      
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
              model.save!
            end
            puts "Spracovanych #{index+1} riadkov." if index % 20 == 0
          end
          puts "Spracovanie dat ukoncene. Celkovo bolo spracovanych #{model.count} riadkov."
        end
      end
      
      #process_standard_input
    end
    
    def update_decision(model, master, target)
      choose do |menu|
        menu.prompt = "Hodnota v stlpci `target` je nenulova. Co si zelate spravit?"

        menu.choice('prepisat') { model.send("#{target_column}=", model.send(master_column)); model.save!; }
        menu.choices('preskocit')
        menu.choices('ukoncit program'){ exit }
      end
    end
    
    def process_standard_input
      input = @stdin.read      
      # TO DO - process input
      
      @stdin.each do |line| 
        puts line
      end
    end
end


include Datanest

# Create and run the application
app = App.new(ARGV, STDIN)
app.run
