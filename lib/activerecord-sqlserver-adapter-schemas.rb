require File.join(File.dirname(__FILE__), 'active_record', 'schemas', 'base')
require File.join(File.dirname(__FILE__), 'active_record', 'schemas', 'connection_adapters', 'sqlserver_adapter')

class ActiveRecord::Base
  extend ActiveRecord::Schemas::Base
  
  def self.table_name
    reset_table_name_with_schema
  end
end

class ActiveRecord::ConnectionAdapters::SQLServerAdapter
  include ActiveRecord::Schemas::ConnectionAdapters::SqlserverAdapter
  
  # This method is overridden to support linked servers
  def unqualify_db_name(table_name)
    table_names = table_name.to_s.split('.')
    table_names.length >= 3 ? table_names[0...table_names.length - 2].join('.').tr('[]','') : nil
  end
  
  # This method is overridden to support schema names
  def tables(name = nil)
    # return schema.table unless the schema is the default schema, in which case just return table
    info_schema_query do
      select_values("SELECT TABLE_SCHEMA + '.' + TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME <> 'dtproperties'").collect do |table|
        default_schema && table.index("#{default_schema}.") == 0 ? table[default_schema.length + 1..table.length] : table
      end
    end
  end
  
  # This method is overridden to support schema names
  def views(name = nil)
    # return schema.view unless the schema is the default schema, in which case just return view
    @sqlserver_views_cache ||= 
      info_schema_query do
         select_values("SELECT TABLE_SCHEMA + '.' + TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME NOT IN ('sysconstraints','syssegments')").collect do |view|
           default_schema && view.index("#{default_schema}.") == 0 ? view[default_schema.length + 1..view.length] : view
         end
      end
  end
  
  # This method is overridden to support references such as database..table
  def quote_column_name(column_name)
    column_name.to_s.split('..').collect do |part|
      part.split('.').map{ |name| name =~ /^\[.*\]$/ ? name : "[#{name}]" }.join('.')
    end.join('..')
  end
  
  # overridden to support schemas.  sp_helpindex does not support linked servers
  def indexes(table_name, name = nil)
    db_name = unqualify_db_name(table_name)
    db_name << '.' if db_name
    schema_name = unqualify_schema_name(table_name) << '.'
    table_name = unqualify_table_name(table_name)

    select("EXEC sp_helpindex '#{quote_table_name("#{db_name}#{schema_name}#{table_name}")}'",name).inject([]) do |indexes,index|
      if index['index_description'] =~ /primary key/
        indexes
      else
        name    = index['index_name']
        unique  = index['index_description'] =~ /unique/
        columns = index['index_keys'].split(',').map do |column|
          column.strip!
          column.gsub! '(-)', '' if column.ends_with?('(-)')
          column
        end
        indexes << ::ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, name, unique, columns)
      end
    end
  end
  
  def view_information(table_name)
    db_name = unqualify_db_name(table_name)
    schema_name = unqualify_schema_name(table_name)
    table_name = unqualify_table_name(table_name)
    
    @@sqlserver_view_information_cache ||= {}
    @@sqlserver_view_information_cache[table_name.downcase] ||= begin
      sql = "SELECT * FROM #{"#{db_name}." if db_name}INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = '#{table_name}'"
      sql << " and TABLE_SCHEMA = '#{schema_name}'" if schema_name
      view_info = info_schema_query { select_one(sql) }
      if view_info
        if view_info['VIEW_DEFINITION'].blank? || view_info['VIEW_DEFINITION'].length == 4000
          view_info['VIEW_DEFINITION'] = info_schema_query { select_values("EXEC sp_helptext #{table_name}").join }
        end
      end
      view_info
    end
  end
  
  def column_definitions(table_name)
    db_name = unqualify_db_name(table_name)
    db_name << '.' if db_name
    schema_name = unqualify_schema_name(table_name)
    table_name = unqualify_table_name(table_name)
    sql = %{
      SELECT
      columns.TABLE_NAME as table_name,
      columns.COLUMN_NAME as name,
      columns.DATA_TYPE as type,
      columns.COLUMN_DEFAULT as default_value,
      columns.NUMERIC_SCALE as numeric_scale,
      columns.NUMERIC_PRECISION as numeric_precision,
      CASE
        WHEN columns.DATA_TYPE IN ('nchar','nvarchar') THEN columns.CHARACTER_MAXIMUM_LENGTH
        ELSE COL_LENGTH(columns.TABLE_SCHEMA+'.'+columns.TABLE_NAME, columns.COLUMN_NAME)
      END as length,
      CASE
        WHEN columns.IS_NULLABLE = 'YES' THEN 1
        ELSE NULL
      end as is_nullable,
      CASE
        WHEN COLUMNPROPERTY(OBJECT_ID(columns.TABLE_SCHEMA+'.'+columns.TABLE_NAME), columns.COLUMN_NAME, 'IsIdentity') = 0 THEN NULL
        ELSE 1
      END as is_identity
      FROM #{db_name}INFORMATION_SCHEMA.COLUMNS columns
      WHERE columns.TABLE_NAME = '#{table_name}'
      #{"AND columns.TABLE_SCHEMA = '#{schema_name}'" if schema_name}
      ORDER BY columns.ordinal_position
    }.gsub(/[ \t\r\n]+/,' ')
    results = info_schema_query { select(sql,nil,true) }
    results.collect do |ci|
      ci.symbolize_keys!
      ci[:type] = case ci[:type]
                  when /^bit|image|text|ntext|datetime$/
                    ci[:type]
                  when /^numeric|decimal$/i
                    "#{ci[:type]}(#{ci[:numeric_precision]},#{ci[:numeric_scale]})"
                  when /^char|nchar|varchar|nvarchar|varbinary|bigint|int|smallint$/
                    ci[:length].to_i == -1 ? "#{ci[:type]}(max)" : "#{ci[:type]}(#{ci[:length]})"
                  else
                    ci[:type]
                  end
      if ci[:default_value].nil? && views.include?(table_name)
        real_table_name = table_name_or_views_table_name(table_name)
        real_column_name = views_real_column_name(table_name,ci[:name])
        col_default_sql = "SELECT c.COLUMN_DEFAULT FROM #{db_name}INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = '#{real_table_name}' AND c.COLUMN_NAME = '#{real_column_name}'"
        ci[:default_value] = info_schema_query { select_value(col_default_sql) }
      end
      ci[:default_value] = case ci[:default_value]
                           when nil, '(null)', '(NULL)'
                             nil
                           else
                             match_data = ci[:default_value].match(/\A\(+N?'?(.*?)'?\)+\Z/m)
                             match_data ? match_data[1] : nil
                           end
      ci[:null] = ci[:is_nullable].to_i == 1 ; ci.delete(:is_nullable)
      ci
    end
  end
end
