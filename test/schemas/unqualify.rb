#!/usr/bin/env ruby
require 'test/unit'
require File.join(File.dirname(__FILE__), 'connection')

module Schemas
  
class Unqualify < Test::Unit::TestCase
  def setup
    con.default_schema = 'dbo'
  end
  
  def test_unqualify_schema_name
    assert_equal con.unqualify_schema_name('MyDatabase.foo.my_table'), 'foo'
    assert_equal con.unqualify_schema_name('MyDatabase..my_table'), 'dbo'
    assert_equal con.unqualify_schema_name('foo.MyTable'), 'foo'
    assert_equal con.unqualify_schema_name('MyTable'), 'dbo'
    assert_equal con.unqualify_schema_name('LinkedServer.MyDatabase.foo.my_table'), 'foo'
  end
  
  def test_unqualify_table_name_if_default_schema
    assert_equal con.unqualify_table_name_if_default_schema('my_table'), 'my_table'
    
    assert_equal con.unqualify_table_name_if_default_schema('dbo.my_table'), 'my_table'
    assert_equal con.unqualify_table_name_if_default_schema('foo.my_table'), 'foo.my_table'
    
    # Are these next 3 tests really the correct behavior?
    assert_equal con.unqualify_table_name_if_default_schema('MyDatabase..my_table'), 'my_table'
    assert_equal con.unqualify_table_name_if_default_schema('LinkedServer.MyDatabase.dbo.my_table'), 'my_table'
    assert_equal con.unqualify_table_name_if_default_schema('LinkedServer.MyDatabase.foo.my_table'), 'LinkedServer.MyDatabase.foo.my_table'
  end
  
  def test_unqualify_db_name
    assert_equal con.unqualify_db_name('LinkedServer.MyDatabase.dbo.my_table'), 'LinkedServer.MyDatabase'
    assert_equal con.unqualify_db_name('MyDatabase.dbo.my_table'), 'MyDatabase'
    assert_equal con.unqualify_db_name('MyDatabase..my_table'), 'MyDatabase'
  end
  
  def con
    con = ActiveRecord::Base.connection
  end
end

end
