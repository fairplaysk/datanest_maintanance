#!/usr/bin/env ruby 

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
    
    puts "Zacina sa spracovanie dat. Pocet riadkov na spracovanie: #{master_model.count}."
    master_model.all.each_with_index do |element|
      elements_processed += 1
      puts "Spracovavam zaznam cislo #{elements_processed}. Dalsia informacia o spracovanych zaznamoch bude vypisana po 20 zaznamoch, alebo po ukonceni spracovavania..." if elements_processed % 20 == 0 || elements_processed == 1
      if element.send(target_column_name) != nil
        puts "Spracovavam riadok #{elements_processed}.\nV stlpci `master` je hodnota: #{element.send(master_column_name) == nil ? "null" : element.send(master_column_name)}.\nHodnota v stlpci `target` je #{element.send(target_column_name)}.\nCo si zelate spravit?"
        if update_decision
          element.send("#{target_column_name}=", element.send(master_column_name) != nil ? element.send(master_column_name) : nil) 
          elements_saved += 1
        else
          next
        end
      else
        element.send("#{target_column_name}=", element.send(master_column_name))
        elements_saved += 1
      end
      element.send("#{master_column_name}=", nil)
      element.save!
    end
    puts "\n\nSpracovanie dat ukoncene.\nPocet prepisanych riadkov: #{elements_saved}.\nPocet preskocenych riadkov: #{elements_processed-elements_saved}."
      
    #process_standard_input
  end

  def quit_or_retry
    choose do |menu|
      menu.prompt = "Vyberte prosim akciu."

      menu.choice('Ukoncit program.') { exit }
      menu.choices('Zadat posledny vstup znova.')
    end
  end

  def update_decision
    choose do |menu|
      menu.choice('prepisat') { return true }
      menu.choices('preskocit') { return false }
      menu.choices('ukoncit program'){ exit }
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
