module ActiveRecord
module Schemas
module ConnectionAdapters
  
module SqlserverAdapter
  def default_schema
    unless sqlserver_2000?
      @default_schema ||= select_values("SELECT default_schema_name FROM sys.database_principals WHERE type = 'S' and name = '#{self.quote_string(@connection_options[:username])}'").first
    end
    @default_schema ||= 'dbo'
  end
  attr_writer :default_schema
  
  def unqualify_schema_name(table_name)
    parts = table_name.to_s.split('.')
    parts.length == 1 || parts[parts.length - 2].blank? ? default_schema : parts[parts.length - 2].gsub(/[\[\]]/,'')
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
