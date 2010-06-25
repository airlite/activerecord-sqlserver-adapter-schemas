module ActiveRecord
module Schemas
module ConnectionAdapters
  
module SqlserverAdapter
  
  # When this module is included, the following methods are chained in order
  # to strip off the schema names if the schema is the default schema
  def self.included(base)
    base.alias_method_chain :columns, :default_schema_check
    base.alias_method_chain :table_exists?, :default_schema_check
    base.alias_method_chain :table_name_or_views_table_name, :default_schema_check
  end
  
  def default_schema
    unless sqlserver_2000?
      @default_schema ||= select_values("SELECT default_schema_name FROM sys.database_principals WHERE type = 'S' and name = '#{self.quote_string(@connection_options[:username])}'").first
    end
    @default_schema ||= 'dbo'
  end
  attr_writer :default_schema
  
  def table_name_or_views_table_name_with_default_schema_check(table_name)
    table_name = unqualify_table_name_if_default_schema(table_name)
    table_name_or_views_table_name_without_default_schema_check(table_name)
  end
  
  def table_exists_with_default_schema_check?(table_name)
    table_name = unqualify_table_name_if_default_schema(table_name)
    table_exists_without_default_schema_check?(table_name)
  end
  
  def columns_with_default_schema_check(table_name, column_name = nil)
    table_name = unqualify_table_name_if_default_schema(table_name) if table_name
    columns_without_default_schema_check(table_name, column_name)
  end
  
  def unqualify_schema_name(table_name)
    parts = table_name.to_s.split('.')
    parts.length == 1 ? default_schema : parts[parts.length - 2].gsub(/[\[\]]/,'')
  end
  
  def unqualify_table_name_if_default_schema(table_name)
    schema = unqualify_schema_name(table_name)
    schema == default_schema ? unqualify_table_name(table_name) : table_name
  end
  
  # override index name so that if there is a schema, rename it schema_table instead of schema.table
  def index_name(table_name, options) #:nodoc:
    super table_name.tr('.', '_'), options
  end
end

end
end
end
