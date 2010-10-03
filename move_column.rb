#!/usr/bin/env ruby
# encoding: UTF-8

# == Aplikacia „Prenesenie stlpca v ramci datasetu“ 
# === pripojenie k databaze 
# SW si vypýta MySQL host address, username, password a nazov databazy SW sa pokusi pripojit a oznami vysledok. 
# SW si vypyta meno tabulky, v ktorej bude pracovat. Ak taku nenajde, da na vyber zadat meno tabulky znova alebo skoncit. 
# SW si vypyta meno stlpca (master), ktoreho obsah chce preniest. Skontroluje jeho existenciu. Ak neexistuje, oznami to (a program skonci). 
# SW si vypyta meno stlpca (target), do ktoreho chce prenasany obsah zapisat. Ak neexistuje, oznami to (a program skonci). 
# SW hodnotu poctu spracovanych riadkov nastavi na 0. SW zacne spracovavat prvy riadok.
#   
# === spracovanie riadku 
# SW v riadku zisti hodnotu stlpca target – ak je nenulová, oznámi to a spyta sa, ci hodnotu má prepísať, riadok preskocit alebo program ukoncit. Podla toho program ukonci, prejde na dalsi riadok. Ak ma prepisat hodnotu, pokracuje. 
# SW nacita hodnotu master a zapise ju do target. K hodnote urcujucej pocet spracovanych riadkov pripocita 1. SW zmaze hodnotu v stlpci master. 
# SW zisti, ci je na poslednom riadku v tabulke, ak ano, program sa ukonci – vypise o tom oznam, kde uvedie, kolko riadkov spracoval. 
# SW zisti, ci pocet riadkov je delitelny 20, ak ano, vypise pocet uz spracovanych riadkov. 
# SW prejde na dalsi riadok.
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
require './lib/app'

class App
  def process_command
    init
    master_table_name, master_model = get_and_test_table('master')
    master_column_name, target_column_name = get_and_test_column(master_model, 'master'), get_and_test_column(master_model, 'target')
    
    elements_saved, elements_processed = 0, 0
    
    put_intro(master_model.count)
    master_model.all.each_with_index do |element|
      elements_processed += 1
      puts "Spracovávam záznam číslo #{elements_processed}." if elements_processed % 20 == 0 || elements_processed == 1
      if element.send(target_column_name) != nil
        puts "Spracovávam riadok #{elements_processed}.\nV stĺpci `master` je hodnota: '#{element.send(master_column_name) == nil ? "null" : element.send(master_column_name)}'.\nHodnota v stĺpci `target` je '#{element.send(target_column_name)}'.\nČo si želáte spraviť?"
        if update_decision
          element.update_attribute(target_column_name, element.send(master_column_name))
          elements_saved += 1
        else
          next
        end
      else
        element.update_attribute(target_column_name, element.send(master_column_name))
        elements_saved += 1
      end
      element.update_attribute(master_column_name, nil)
    end
    put_stats(elements_saved, elements_processed-elements_saved)
    
    rescue
      puts 'Pri spracovavaní údajov nastala chyba. Skontrolujte údaje a vyskúšajte znova.'
      
    #process_standard_input
  end

  def quit_or_retry
    choose do |menu|
      menu.prompt = "Vyberte prosím akciu."

      menu.choice('Ukonňčiť program.') { exit }
      menu.choices('Zadať posledný vstup znova.')
    end
  end
  
  def output_version
    puts "#{File.basename(__FILE__)} version #{VERSION}"
  end
end

include Datanest

# Create and run the application
app = App.new(ARGV, STDIN)
app.run
