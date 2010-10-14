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
    target_table_name, target_model = get_and_test_table('target')
    regis_table_name, regis_model = get_and_test_table('regis')
    
    customer_column_ico = 'customer_ico'#get_and_test_column(target_model, 'customer_ico')
    customer_column_name = 'procurement_subject'
    supplier_column_ico = 'supplier_ico'#get_and_test_column(target_model, 'supplier_ico')
    supplier_column_name = 'supplier_name'
    
    
    elements_saved, elements_processed = 0, 0
    
    elements = target_model.select("#{target_table_name}.#{$config['primary_key_name']}, #{target_table_name}.#{customer_column_ico}, #{target_table_name}.#{supplier_column_ico}, 
                                    #{target_table_name}.#{customer_column_name}, #{target_table_name}.#{supplier_column_name}, rcust.ico AS cico, rsupp.ico AS sico").
                                    joins("LEFT JOIN #{regis_table_name} rcust on rcust.ico = #{target_table_name}.#{customer_column_ico}
                                    LEFT JOIN #{regis_table_name} rsupp on rsupp.ico = #{target_table_name}.#{supplier_column_ico}").where(:etl_loaded_date => nil).readonly(false)
    
    put_intro(elements.size)
    elements[@options.start_index-1..-1].each do |element|
      elements_processed += 1
      already_saved = false
      puts "Spracovávam záznam číslo #{elements_processed+@options.start_index-1}." if elements_processed % 20 == 0 || elements_processed == 1
      
      if element.cico.nil?
        target_model_firm = element.send(customer_column_name)
        puts "Objednavatatela #{target_model_firm} sa nepodarilo najst v databaze regis."
        $config['company_shortcuts'].split(';').each { |shortcut| target_model_firm.gsub!(shortcut, '') }
        target_model_firm = target_model_firm.gsub(/,+|;+|-+/, ' ').gsub(/\s+/, ' ').gsub(/\s+$/, '')
        regis_like_search = regis_model.where("name like ?", "%#{target_model_firm}%")
        selected_ico = select_ico(regis_like_search)
        if selected_ico != "skip"
          if selected_ico.respond_to?('ico')
            element.update_attributes!(customer_column_ico => selected_ico.ico)
            elements_saved += 1
          else
            element.update_attributes!(customer_column_ico => selected_ico)
            elements_saved += 1
          end
        end
      end
      
      if element.sico.nil?
        target_model_firm = element.send(supplier_column_name)
        puts "Dodavatela #{target_model_firm} sa nepodarilo najst v databaze regis."
        $config['company_shortcuts'].split(';').each { |shortcut| target_model_firm.gsub!(shortcut, '') }
        target_model_firm = target_model_firm.gsub(/,+|;+|-+/, ' ').gsub(/\s+/, ' ').gsub(/\s+$/, '')
        puts "Hladam podobne firmy pre #{target_model_firm}"
        regis_like_search = regis_model.where("name like ?", "%#{target_model_firm}%")
        selected_ico = select_ico(regis_like_search)
        if selected_ico != "skip"
          if selected_ico.respond_to?('ico')
            element.update_attributes!(supplier_column_ico => selected_ico.ico)
            elements_saved += 1 unless already_saved
          else
            element.update_attributes!(supplier_column_ico => selected_ico)
            elements_saved += 1 unless already_saved
          end
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
