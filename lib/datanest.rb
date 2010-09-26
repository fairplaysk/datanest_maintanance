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
    host = get_server
    username = get_username
    password = get_password
    database = get_database
    establish_connection(host, database, username, password)
    table = get_table('master')
    
    ActiveRecord::Base.connection.execute("select * from #{table} limit 1")
    
    return table
    rescue
      puts 'Pri pripajani na databazu nastala chyba, skontrolujte prosim spravnost udajov a dostupnost databazy a skuste znova.'
  end
  
  def establish_connection(host, database, username, password)
    ActiveRecord::Base.establish_connection(
      :adapter  => "mysql2",
      :host     => host,
      :database => database,
      :username => username,
      :password => password
    )
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