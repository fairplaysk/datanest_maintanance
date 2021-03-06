#!/usr/bin/env ruby 
# encoding: UTF-8

# == Aplikacia „Mazanie celého obsahu tabuľky“ 
# === pripojenie k databaze 
# SW si vypýta MySQL host address, username, password a nazov databazy 
# SW sa pokusi pripojit a oznami vysledok. 
# SW si vypyta meno tabulky, ktorej obsah chce zmazat. Ak taku nenajde, da na vyber zadat meno tabulky znova alebo skoncit. 
# SW zisti pocet riadkov v tabulke a zapamata si ho. Vypise ho a opyta sa, ci uzivatel chce obsah tabulky zmazat. Ak nie, program sa ukonci. 
# SW upozorni, ze zmazanim obsahu tabulky dojde aj k strate priradenych komentárov a inych udajov, ktore sa viazu na zaznamy v tabulke a opyta sa, ci uzivatel chce pokracovat. Ak nie, program sa ukonci. 
# SW polozi otazku „Peter o tom vie?“ Ak je odpoved nie, program sa ukonci.
# SW hodnotu poctu zmazanych riadkov nastavi na 0. SW zacne spracovavat prvy riadok.
# 
# === spracovanie riadku 
# SW zmaze riadok. K hodnote poctu zmazanych riadkov pricita 1. 
# SW zisti, ci je na poslednom riadku v tabulke, ak ano, – vypise oznam, ze ukoncil program, uvedie, kolko riadkov zmazal a program ukonci. 
# SW zisti, ci pocet riadkov je delitelny 20, ak ano, vypise pocet uz zmazanych riadkov. 
# SW prejde na dalsi riadok.
#
# == Usage
#   For help use: delete_table.rb -h
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
    
    rows_affected = 0
    puts "V zadanej tabuľke sa nachádza #{master_model.count} riadkov. Naozaj si želáte všetky zmazať?"
    if confirm_delete
      puts "Zmazaním obsahu tabuľky dôjde aj k strate priradených komentárov a iných údajov, ktoré sa viažu na záznamy v tabuľke! Želáte si napriek tomu pokračovaľ?"
      if ask_again
        puts "Peter o tom vie?"
        if peter_knows?
          puts "Začína sa s mazaním..."
          rows_affected = master_model.delete_all
          puts "Mazanie sa úspešne ukončilo. Vymazalo sa #{rows_affected} riadkov."
        end
      end
    end
    
    rescue
      puts 'Pri mazaní nastala chyba. Skontrolujte údaje a vyskúšajte znova.'
      
    #process_standard_input
  end
  
  def confirm_delete
    choose do |menu|
      menu.choice('ano') { return true }
      menu.choices('nie') { return false }
    end
  end
  
  def ask_again
    choose do |menu|
      menu.choice('ano') { return true }
      menu.choices('nie') { return false }
    end
  end
  
  def peter_knows?
    choose do |menu|
      menu.choice('nie') { return false }
      menu.choices('ano') { return true }
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
