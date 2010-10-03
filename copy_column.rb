#!/usr/bin/env ruby 
# encoding: UTF-8

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
    init
    master_table_name, master_model = get_and_test_table('master')
    target_table_name, target_model = get_and_test_table('target')
    if master_model.count != target_model.count
      puts "Počty riadkov v `master` a `target` tabuľke nie su rovnaké.\nMaster: #{master_model.count}.\nTarget: #{target_model.count}.\nSpracovanie dat nemôže pokračovať."
      exit
    end
    master_column_name, master_id_column_name = get_and_test_column(master_model, 'master_master'),  get_and_test_column(master_model, 'master_id')
    target_column_name = get_and_test_column(target_model, 'target_target')
    
    elements_saved, elements_processed = 0, 0
    
    put_intro(master_model.count)
    master_model.all.each do |master_element|
      elements_processed += 1
      puts "Spracovávam záznam číslo #{elements_processed}." if elements_processed % 20 == 0 || elements_processed == 1
      target_element = target_model.find(master_element.send(master_id_column_name))
      if target_element.send(target_column_name) != nil
        puts "Spracovávam riadok #{elements_processed}.\nV stĺpci `master_master` je hodnota: '#{master_element.send(master_column_name) == nil ? "null" : master_element.send(master_column_name)}'.\nHodnota v stĺpci `target_target` je '#{target_element.send(target_column_name)}'.\nČo si želáte spraviť?"
        if update_decision
          target_element.update_attribute(target_column_name, master_element.send(master_column_name))
          elements_saved += 1
        else
          next
        end
      else
        target_element.update_attribute(target_column_name, master_element.send(master_column_name))
        elements_saved += 1
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
