require 'rubygems'
require 'active_record'
require 'activerecord-sqlserver-adapter'
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'activerecord-sqlserver-adapter-schemas')

ActiveRecord::Base.configurations = {
  'arunit' => {
    :adapter  => 'sqlserver',
    :mode     => 'ODBC',
    :host     => 'localhost',
    :username => 'rails',
    :dsn      => ENV['ACTIVERECORD_UNITTEST_DSN'] || 'activerecord_unittest',
    :database => 'activerecord_unittest'
  }
}
ActiveRecord::Base.establish_connection 'arunit'
ActiveRecord::Base.connection.default_schema = 'dbo'

unless ActiveRecord::Base.connection.table_exists?('schema_checks')
  ActiveRecord::Base.connection.create_table 'schema_checks' do |table|
    table.string :name, :limit => 32
    table.timestamps
  end
end

unless ActiveRecord::Base.connection.table_exists?('schema_checks_view')
  ActiveRecord::Base.connection.execute "create view schema_checks_view as select * from schema_checks"
end
