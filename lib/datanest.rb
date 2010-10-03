# encoding: UTF-8

class HighLine
  class Menu
    def update_responses(  )
      append_default unless default.nil?
      @responses = @responses.merge(
                     :ambiguous_completion =>
                       "Nejednoznačný výber.  " +
                       "Prosím vyberte jednu z možností #{options.inspect}.",
                     :ask_on_error         =>
                       "?  ",
                     :invalid_type         =>
                       "Musíte zadať platnú možnosť #{options}.",
                     :no_completion        =>
                       "Musíte vybrat jednu z možností " +
                       "#{options.inspect}.",
                     :not_in_range         =>
                       "Vaša odpoveď sa nenachádza v očakávanom rozmedzí " +
                       "(#{expected_range}).",
                     :not_valid            =>
                       "Vaša odpoveď nie je platná (musí nastať zhoda s " +
                       "#{@validate.inspect})."
                   )
    end
  end
end

module Datanest
  # ak ma vasa databaza stlpec s pk iny ako prednastaveny, zmente prosim hodnotu v nasledovnom riadku
  PRIMARY_KEY_NAME = '_record_id'
  
  def define_activerecord_model(name)
    eval("class #{name.classify} < ActiveRecord::Base; set_table_name('#{name}'); set_primary_key ('#{PRIMARY_KEY_NAME}'); end")
  end
  
  
  def get_column(name = nil)
    ask("Zadajte prosim `#{name}` stlpec: ") { |q| q.validate = /\w+/; q.responses[:not_valid] = 'Nazov stlpca musi obsahovat aspon jeden znak. Zadanie opakujte!';}
  end
  
  def test_column(model, column)
    model.first.send column.to_sym
    yield
    rescue
      puts 'Zadany stlpec neexistuje, skontrolujte prosim spravnost zadanych udajov a skuste znova.'
  end
  
  def init
    while true do
      begin
        host = get_server
        username = get_username
        password = get_password
        database = get_database
        establish_connection(host, database, username, password)
        puts 'Udaje na pripojenie k databaze boli zadane spravne.'
    
        break
      rescue
        puts 'Pri pripajani na databazu nastala chyba, skontrolujte prosim spravnost udajov a dostupnost databazy a skuste znova.'
      end
    end
  end
  
  def establish_connection(host, database, username, password)
    ActiveRecord::Base.establish_connection(
      :adapter  => "mysql2",
      :host     => host,
      :database => database,
      :username => username,
      :password => password,
      :encoding => "utf8"
    )
    ActiveRecord::Base.connection.transaction
  end
  
  def get_and_test_table(name = 'master')
    while true do
      begin
        table = get_table(name)
        define_activerecord_model(table)
        model = table.capitalize.classify.constantize
        break if model.columns
      rescue
        puts 'Zadana tabulka sa v databaze nenachadza.'
        quit_or_retry
      end
    end
    return table, model
  end
  
  def get_and_test_column(model, column_id)
    column_name = get_column(column_id)
    unless model.columns_hash.keys.include?(column_name)
      puts "Zadany stlpec `#{column_name}` sa nenachadza v tabulke `#{model.table_name}`.\nSkontrolujte prosim zadane udaje a skuste znova.\nProgram sa teraz ukonci."
      exit
    end
    return column_name
  end
  
  def update_decision
    choose do |menu|
      menu.choice('prepisat') { return true }
      menu.choices('preskocit') { return false }
      menu.choices('ukoncit program'){ exit }
    end
  end
  
  def get_server
    url = ask('Zadajte prosim adresu MySQL servera: ') { |q| q.default = '127.0.0.1'}
    URI.parse(url)
    url
    rescue URI::InvalidURIError
      puts 'Zadana adresa nie je spravna, skontrolujte prosim jej spravnost.'
  end
  
  def get_username
    ask('Zadajte prosim MySQL pouzivatelske meno: ') { |q| q.validate = /\w+/; q.responses[:not_valid] = 'Pouzivatelske meno musi obsahovat aspon jeden znak. Zadanie opakujte!'; }
  end
  
  def get_password
    ask('Zadajte prosim MySQL pouzivatelske heslo: ') do |q| 
      q.echo = "x"
      q.validate = /\w+/
      q.responses[:not_valid] = 'Heslo musi obsahovat aspon jeden znak. Zadanie opakujte!'
    end
  end
  
  def get_database
    ask('Zadajte prosim MySQL databazu: ') { |q| q.validate = /\w+/; q.responses[:not_valid] = 'Nazov databazy musi obsahovat aspon jeden znak. Zadanie opakujte!'; }
  end
  
  def get_table(name = nil)
    ask("Zadajte prosim MySQL #{name} tabulku: ") { |q| q.validate = /\w+/; q.responses[:not_valid] = 'Nazov tabulky musi obsahovat aspon jeden znak. Zadanie opakujte!';}
  end
  
  def ask_for_ico
    ask("Zadajte ico: ") { |q| q.validate = /\w+/; q.responses[:not_valid] = 'Ico musi obsahovat aspon jeden znak. Zadanie opakujte!';}
  end
  
  def put_intro(row_count)
    puts "Začína sa spracovanie dát. Počet riadkov na spracovanie: #{row_count}."
    puts "Program bude informovať o počte spracovaných riadkov po spracovaní každých 20-tich riadkov."
  end
  
  def put_stats(overwritten, skipped)
    puts "\n\nSpracovanie dát ukončené.\nPočet prepísaných riadkov: #{overwritten}.\nPočet preskočených riadkov: #{skipped}."
  end
end