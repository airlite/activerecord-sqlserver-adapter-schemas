#!/usr/bin/env ruby
require 'test/unit'
require File.join(File.dirname(__FILE__), 'connection')

module Schemas
  
class TableChecks < Test::Unit::TestCase
  def setup
    con.default_schema = 'dbo'
  end
  
  def test_tables
    # test that tables() prefixes the table name with the schema if the schema is not the default schema
    assert_nil con.tables.find { |table| table.start_with?('dbo.') }
    con.default_schema = 'foo'
    assert_not_nil con.tables.find { |table| table.start_with?('dbo.') }
  end
  
  def test_views
    # test that views() prefixes the table name with the schema if the schema is not the default schema
    assert_nil con.views.find { |table| table.start_with?('dbo.') }
    con.default_schema = 'foo'
    assert_not_nil con.views.find { |table| table.start_with?('dbo.') }
  end
  
  def test_table_exists
    assert con.table_exists?('dbo.schema_checks')
    assert con.table_exists?('schema_checks')
    assert !con.table_exists?('foo.schema_checks')
    
    con.default_schema = 'foo'
    assert con.table_exists?('dbo.schema_checks')
    assert !con.table_exists?('schema_checks')
    assert !con.table_exists?('foo.schema_checks')
  end
  
  def test_table_name_or_views_table_name
    assert_equal con.table_name_or_views_table_name('schema_checks'), 'schema_checks'
    assert_equal con.table_name_or_views_table_name('dbo.schema_checks'), 'schema_checks'
    assert_equal con.table_name_or_views_table_name('activerecord_unittest.dbo.schema_checks'), 'schema_checks'
    assert_equal con.table_name_or_views_table_name('activerecord_unittest..schema_checks'), 'schema_checks'
    assert_equal con.table_name_or_views_table_name('activerecord_unittest.foo.schema_checks'), 'activerecord_unittest.foo.schema_checks'
    assert_equal con.table_name_or_views_table_name('foo.schema_checks'), 'foo.schema_checks'
    
    con.default_schema = 'foo'
    assert_equal con.table_name_or_views_table_name('schema_checks'), 'schema_checks'
    assert_equal con.table_name_or_views_table_name('dbo.schema_checks'), 'dbo.schema_checks'
    assert_equal con.table_name_or_views_table_name('activerecord_unittest.dbo.schema_checks'), 'activerecord_unittest.dbo.schema_checks'
    assert_equal con.table_name_or_views_table_name('activerecord_unittest..schema_checks'), 'schema_checks'
    assert_equal con.table_name_or_views_table_name('activerecord_unittest.foo.schema_checks'), 'schema_checks'
    assert_equal con.table_name_or_views_table_name('foo.schema_checks'), 'schema_checks'
  end
  
  def con
    con = ActiveRecord::Base.connection
  end
end

end
