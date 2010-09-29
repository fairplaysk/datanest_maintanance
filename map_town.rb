#!/usr/bin/env ruby 

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
  
    while true do
      table = init
      break if table
    end
    
    create_activerecord_model(table.singularize.camelize)
    master_model = table.capitalize.classify.constantize
    
    target_table = get_table('target')
    create_activerecord_model(target_table.singularize.camelize)
    target_model = target_table.capitalize.classify.constantize
    
    target_mesto = get_column('target_mesto')
    test_column(target_model, target_mesto) do
      target_geolocation = get_column('target_geolokacia')
      test_column(target_model, target_geolocation) do
        master_mesto = get_column('master_mesto')
        test_column(master_model, master_mesto) do          
          master_id = get_column('master_id')
          test_column(master_model, master_id) do
            puts 'Spracovavanie dat zacalo.'
            target_model.all.each_with_index do |element, index|
              puts "Spracovanych #{index} zaznamov." if index % 20 == 0
              next unless target_geolocation
              next unless element.send(target_mesto)
              master_search = master_model.send("find_by_#{master_mesto}", element.send(target_mesto))
              next unless master_search
              element.send("#{target_geolocation}=", master_search.send(master_id))
              element.save!
            end
            puts 'Spracovanie zaznamov ukoncene.'
          end
        end
      end
    end

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
