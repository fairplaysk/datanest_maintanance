#!/usr/bin/env ruby
# encoding: UTF-8

# == Aplikacia „Prepisanie textu v stlpci v ramci datasetu“ 
#
# == Usage
#   For help use: replace_text.rb -h
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
require './lib/app'

class App
  def process_command
    init
    master_table_name, master_model = get_and_test_table('master')
    master_column_name = get_and_test_column(master_model, 'master')
    
    replace_pattern = ask("Zadajte retazec, ktory chcete nahradit: ")
    replace_with = ask("Zadajte retazec, ktorym chcete nahradit povodny retazec: ")
    
    elements_saved, elements_processed = 0, 0
    
    put_intro(master_model.count)
    master_model.all.each do |element|
      elements_processed += 1
      puts "Spracovávam záznam číslo #{elements_processed}." if elements_processed % 20 == 0 || elements_processed == 1
      if element.send(master_column_name) != nil
        replacement_text = element.send(master_column_name).gsub(replace_pattern, replace_with)
        unless replacement_text == element.send(master_column_name)
          element.update_attribute(master_column_name, replacement_text)
          elements_saved += 1
        end
      end
    end
    put_stats(elements_saved, elements_processed-elements_saved)
    
    rescue
      puts 'Pri spracovavaní údajov nastala chyba. Skontrolujte údaje a vyskúšajte znova.'
      
    #process_standard_input
  end

  def output_version
    puts "#{File.basename(__FILE__)} version #{VERSION}"
  end
end

include Datanest

# Create and run the application
app = App.new(ARGV, STDIN)
app.run
