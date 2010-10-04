#!/usr/bin/env ruby
# encoding: UTF-8

# == Aplikacia „Doplnenie mesta“ – mapovanie
# === pripojenie k databaze 
# SW si vypýta MySQL host address, username, password a nazov databazy 
# SW sa pokusi pripojit a oznami vysledok. 
# SW si vypyta meno tabulky (master), v ktorej je zadane geograficke clenenie. Ak taku nenajde, da na vyber zadat meno tabulky znova alebo skoncit. 
# SW si vypyta meno stlpca (mesto) v tabulke target, odkial bude brat hodnotu – vlastne nazov mesta, ku ktoremu sa bude snazit priradit okres a kraj. Skontroluje jeho existenciu. Ak neexistuje, oznami to (a program skonci).
# SW si vypyta meno stlpca (target_geolokacia), kam ma zapisat prepojenie mesta na patricny zaznam v geolokacnej tabulke master (kde je mesto zaradene do okresu a kraja). Skontroluje jeho existenciu. Ak neexistuje, oznami to (a program skonci).
# SW si vypyta meno stlpca (master_mesto) v tabulke master, kde je nazov mesta. Skontroluje jeho existenciu. Ak neexistuje, oznami to (a program skonci).
# 
# === zaciatok 
# SW prejde na prvy riadok v tabulke target
# 
# === spracovanie riadku tabulky target 
# SW skontroluje, ci uz nespracoval celu tabulku (vsetky riadky v tabulke), ak ano, vypise to a program sa ukonci. 
# SW v tabulke target pozrie hodnotu v stlpci target_geolokacia. Ak je nenulova, preskoci na spracovanie dalsieho riadka. 
# SW sa v tabulke target pozrie, aka hodnota je v stlpci mesto. Ak je nulova, preskoci na spracovanie dalsieho riadku, ak nenulova, vypise ju. 
# SW sa snazi najst rovnaku hodnotu v tabulke master v stlpci master_mesto. 
# *** Ak ju najde, zapise v tabulke target v stlpci target_geolokacia prepojenie na patricny zaznam a prejde na spracovanie dalsieho riadku 
# *** Ak zhodu nenajde, prejde na spracovanie dalsieho riadku.
# 
# === poznamky 
# Problem robia mesta Kosice a Bratislava – v geolokacnej tabulke je clenenie na mestske casti a u bratislavy clenenie na obvody – bude teda potrebne zaviest aj lokaciu Bratislava a Kosice (bez presnejsieho clenenia) – v tabulkach totiz taka lokacia je najbeznejsia. 
# SW by nemal byt citlivy na diakritiku. 
# SW by pocas pracovania mal nieco jednoduche vypisovat – nieco, co sa meni, nech je zrejme, ze program bezi a pracuje.
#
# == Usage
#   For help use: map_town.rb -h
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
    
    target_mesto_column_name = get_and_test_column(target_model, 'target_mesto')
    target_geolokacia_column_name = get_and_test_column(target_model, 'target_geolokacia')
    master_mesto_column_name = get_and_test_column(master_model, 'master_mesto')
    master_id_column_name = get_and_test_column(master_model, 'master_id')

    put_intro(target_model.count)
    elements_saved, elements_processed = 0, 0
    target_model.all.each_with_index do |target_element, index|
      elements_processed += 1
      puts "Spracovávam záznam číslo #{elements_processed}." if index % 20 == 0
      next if target_element.send("#{target_geolokacia_column_name}")
      next unless target_element.send(target_mesto_column_name)
      master_search = master_model.send("find_by_#{master_mesto_column_name}", target_element.send(target_mesto_column_name))
      next unless master_search
      target_element.send("#{target_geolokacia_column_name}=", master_search.send(master_id_column_name))
      target_element.save!
      elements_saved += 1
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
