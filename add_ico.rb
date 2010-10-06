#!/usr/bin/env ruby
# encoding: UTF-8 

# == Aplikacia „Doplnenie ICO“ 
# === pripojenie k databaze 
# SW si vypýta MySQL host address, username, password a nazov databazy 
# SW sa pokusi pripojit a oznami vysledok. 
# SW si vypyta meno tabulky, v ktorej bude pracovat. Ak taku nenajde, da na vyber zadat meno tabulky znova alebo skoncit. 
# SW si vypyta meno stlpca (target_ICO), kam ma zapisat ICO. Skontroluje jeho existenciu. Ak neexistuje, oznami to (a program skonci). 
# SW si vypyta meno stlpca (target_orig), kam ma zapisat informaciu o tom, ci ICO je povodne, alebo nie (doplnene). Skontroluje jeho existenciu. Ak neexistuje, oznami to (a program skonci).
# SW si vypyta meno stlpca (firma), kde je hodnota popisujuca nazov firmy. Skontroluje jeho existenciu. Ak neexistuje, oznami to (a program skonci).
# 
# === zaciatok 
# SW zacne spracovavat prvy riadok.
# 
# === spracovanie riadku 
# SW overi, ci uz nepresiel cez vsetky riadky – ak ano, vypise, ze spracoval celu tabulku a skonci. 
# SW skontroluje, obsah stlpca target_ICO – ak je nenulovy, zapise hodnotu „orig“ do stlpca target_orig a prejde na dalsi riadok. 
# SW nacita obsah stlpca firma, ak ne nulovy, preskoci na spracovanie dalsieho riadku, ak je nenulovy, zobrazi ho. 
# SW porovna ho (vymyslite ako) s nazvami firiem v regise. 
# *** Ak nenajde zhodny nazov, ponukne nazvy, ktore sa mu zdaju podobne (navrhnite ako), moznost preskocit riadok alebo zadat ICO individualne 
# ***** Ak uzivatel zada ICO individualne, hodnota sa zapise do target_ICO, zapise hodnotu „manual“ do stlpca target_orig a prejde na dalsi riadok a program prejde na spracovanie dalsieho riadku. 
# ***** Ak uzivatel zada preskocit riadok, program prejde na spracovanie dalsieho riadku. 
# ***** Ak uzivatel vyberie niektory z „podobnych“ nazvov, ktore program ponukol, zapise do stlpca target_ICO hodnotu ICO pre vybranu firmu, ktorú uvadza regis. Zapise hodnotu „manual“ do stlpca target_orig. Program prejde na spracovanie dalsieho riadku. 
# *** Ak najde zhodny nazov, zapise do stlpca target_ICO hodnotu zistenu v regise. Zapise hodnotu „auto“ do stlpca target_orig
# 
# === poznamky 
# Program by mal vyhodnotit ako totozne firmy aj tie, ktorú maju pravnu formu zapisanu roznym sposobom napr. spoločnosť ručením obmedzenym=s .r. o.=sro=spol. s r. o. a pod. 
# Idealne by bolo, keby vyuzival nejaku tobulku (csv?), ktoru by uzivatel mohol doplnovat.
#
# == Usage
#   For help use: add_ico.rb -h
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
    target_table_name, target_model = get_and_test_table('target')
    regis_table_name, regis_model = get_and_test_table('regis')
    
    target_ICO_name = get_and_test_column(target_model, 'target_ICO')
    target_original_name = get_and_test_column(target_model, 'target_original')
    target_firm_name = get_and_test_column(target_model, 'target_firm')
  
    elements_saved, elements_processed = 0, 0
  
    put_intro(target_model.count)
    target_model.all[@options.start_index-1..-1].each do |target_element|
      elements_processed += 1
      if target_element.send(target_ICO_name) != nil
        target_element.update_attribute(target_original_name, 'orig')
        next
      end
      
      target_model_firm = target_element.send(target_firm_name)
      
      if target_model_firm == nil
        next
      else
        puts "Práve sa spracováva ICO firmy: #{target_model_firm}"
        regis_search = regis_model.find_by_name(target_model_firm)
        if regis_search != nil
          puts "Firma nájdená v regis-e"
          target_element.update_attributes(target_original_name => 'orig', target_ICO_name => regis_search.ico)
          elements_saved += 1
        else
          $config['company_shortcuts'].split(';').each { |shortcut| target_model_firm.gsub!(shortcut, '') }
          target_model_firm = target_model_firm.gsub(/,+|;+|-+/, ' ').gsub(/\s+/, ' ')
          puts "Presná zdhoda v regis-e sa nepodarila nájsť. Hľadám podobné firmy pre #{target_model_firm}"
          regis_like_search = regis_model.where("name like ?", "%#{target_model_firm}%")
          selected_ico = select_ico(regis_like_search)
          next if selected_ico == "skip"
          if selected_ico.respond_to?('ico')
            target_element.update_attributes(target_original_name => 'manual', target_ICO_name => selected_ico.ico)
          else
            target_element.update_attributes(target_original_name => 'manual', target_ICO_name => selected_ico)
          end
          elements_saved += 1
        end
      end
    end
    put_stats(elements_saved, elements_processed-elements_saved)
     
    # rescue
    #   puts 'Pri spracovavaní údajov nastala chyba. Skontrolujte údaje a vyskúšajte znova.'
        
    #process_standard_input
  end
  
  def select_ico(regis_like_search)
    choose do |menu|
      menu.prompt = "Vyberte prosím číslo jednej z firiem, alebo jednu z ostatných akcii."
      
      menu.choices('Zadať ICO manuálne') { return ask_for_ico }
      menu.choices('Preskočiť riadok') { return "skip" }
      
      regis_like_search.each do |regis_like_result|
        menu.choice("Vybrať firmu: #{regis_like_result.name}; ICO: #{regis_like_result.ico}") { return regis_like_result }
      end
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
