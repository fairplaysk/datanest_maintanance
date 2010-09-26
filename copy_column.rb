#!/usr/bin/env ruby 

# == Aplikacia „Kopírovanie stĺpca do inej tabulky“
# === pripojenie k databaze 
# SW si vypýta MySQL host address, username, password a nazov databazy SW sa pokusi pripojit a oznami vysledok. 
# SW si vypyta meno tabulky (master), v ktorej bude pracovat. Ak taku nenajde, da na vyber zadat meno tabulky znova alebo skoncit. 
# SW si vypyta meno tabulky (target), v ktorej bude pracovat. Ak taku nenajde, da na vyber zadat meno tabulky znova alebo skoncit. 
# SW porovna pocet riadkov v tabulke master a v tabulke target – ak sa nezhoduju oznami to (program skonci)
# 
# === test integrity 
# SW si vypyta meno stlpca (master-master) v tabulke master, ktoreho obsah chce preniest. 
# Skontroluje jeho existenciu. Ak neexistuje, oznami to (a program skonci). 
# SW si vypyta meno stlpca s kontrolnym ID v tabulke master, ktoreho obsah chce preniest. Skontroluje jeho existenciu. Ak neexistuje, oznami to (a program skonci). 
# SW si vypyta meno stlpca (target-target) v tabulke target, do ktoreho chce prenasany obsah zapisat. Ak neexistuje, oznami to (a program skonci).
# 
# === nastavenie zaciatku 
# SW hodnotu poctu spracovanych riadkov nastavi na 0. 
# SW sa presunie na prvy riadok v tabulke master
# 
# === spracovanie riadku 
# SW zisti hodnotu kontrolneho ID v tabulke master 
# SW vyhlada v tabulke target riadok s rovnakym ID ako je hodnota „kontrolneho ID“ v tabulke master. 
# SW zisti hodnotu stlpca target-target v tabulke target (v riadku, ktoreho ID=hodnota kontrolneho ID) – ak je nenulová, oznámi to a spyta sa, ci hodnotu má prepísať, riadok preskocit alebo program ukoncit. Podla toho program ukonci alebo prejde na dalsi riadok (otestuje, ci uz nepresiel vsetky) v tabulke master. Ak ma prepisat hodnotu, pokracuje. 
# SW nacita hodnotu master-master v tabulke master a zapise ju do target-target v tabulke target (v riadku, ktoreho ID=hodnota kontrolneho ID). K hodnote urcujucej pocet spracovanych riadkov pripocita 1. 
# SW zisti, ci je na poslednom riadku v tabulke master, ak ano, program sa ukonci – vypise o tom oznam, kde uvedie, kolko riadkov spracoval. 
# SW zisti, ci pocet riadkov je delitelny 20, ak ano, vypise pocet uz spracovanych riadkov. 
# SW prejde na spracovanie dalsieho riadku v tabulke master.
# treba ratat aj s prazdnym obsahom – ten tiez treba „kopirovat/preniest“...
#
# == Usage
#   For help use: copy_column.rb -h
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
  
    while true do
      master_table = init
      break if master_table
    end
  
    create_activerecord_model(master_table.singularize.capitalize)
    master_model = master_table.capitalize.classify.constantize
    
    target_table = get_table('target')
    create_activerecord_model(target_table.singularize.capitalize)
    target_model = target_table.capitalize.classify.constantize
    
    master_column = get_column('master')
    test_column(master_model, master_column) do
      master_id_column = get_column('master_id')
      test_column(master_model, master_id_column) do
        target_column = get_column('target')
        test_column(target_model, target_column) do
          
          master_model.all.each_with_index do |master_element, index|
            target_element = target_model.find(master_model.send(master_id_column))
            target_column_value = target_element.send(target_column)
            if target_column_value != nil
              update_decision(...)
            else
              target_element.send("#{target_column}=", master_element.send(master_column))
            end
            puts "Spracovanych #{index+1} riadkov." if index % 20 == 0
          end
          puts "Spracovanie dat ukoncene. Celkovo bolo spracovanych #{model.count} riadkov."
          
        end
      end
    end
    
  
    #process_standard_input
  end

  def update_decision(master_element, target_element, master_column, target_column)
    choose do |menu|
      menu.prompt = "Hodnota v stlpci `target` je nenulova. Co si zelate spravit?"

      menu.choice('prepisat') { target_element.send("#{target_column}=", master_element.send(master_column)); target_element.save!; }
      menu.choices('preskocit')
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
