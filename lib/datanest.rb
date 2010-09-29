module Datanest
  def create_activerecord_model(name)
    eval("class #{name} < ActiveRecord::Base; end")
  end
  
  
  def get_column(name = nil)
    ask("Zadajte prosim `#{name}` stlpec: ") { |q| q.validate = /\w+/}
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
      :password => password
    )
    ActiveRecord::Base.connection.transaction
  end
  
  def get_and_test_table(name = 'master')
    while true do
      begin
        table = get_table(name)
        create_activerecord_model(table.singularize.camelize)
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
  
  def get_server
    url = ask('Zadajte prosim adresu MySQL servera: ') { |q| q.default = '127.0.0.1'}
    URI.parse(url)
    url
    rescue URI::InvalidURIError
      puts 'Zadana adresa nie je spravna, skontrolujte prosim jej spravnost.'
  end
  
  def get_username
    ask('Zadajte prosim MySQL pouzivatelske meno: ') { |q| q.validate = /\w+/}
  end
  
  def get_password
    ask('Zadajte prosim MySQL pouzivatelske heslo: ') do |q| 
      q.echo = "x"
      q.validate = /\w+/
    end
  end
  
  def get_database
    ask('Zadajte prosim MySQL databazu: ') { |q| q.validate = /\w+/}
  end
  
  def get_table(name = nil)
    ask("Zadajte prosim MySQL #{name} tabulku: ") { |q| q.validate = /\w+/}
  end
end