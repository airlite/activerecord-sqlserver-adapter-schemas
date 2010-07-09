#!/usr/bin/env ruby
require 'test/unit'
require File.join(File.dirname(__FILE__), 'connection')

module Schemas
  
class Definitions < Test::Unit::TestCase
  def setup
    con.default_schema = 'dbo'
  end
  
  def test_column_definitions
    assert con.column_definitions('schema_checks').length.nonzero?
    assert con.column_definitions('dbo.schema_checks').length.nonzero?
    assert con.column_definitions('activerecord_unittest..schema_checks').length.nonzero?
    assert con.column_definitions('activerecord_unittest.dbo.schema_checks').length.nonzero?
    assert con.column_definitions('foo.schema_checks').length.zero?
    
    con.default_schema = 'foo'
    assert con.column_definitions('schema_checks').length.zero?
    assert con.column_definitions('dbo.schema_checks').length.nonzero?
    assert con.column_definitions('activerecord_unittest..schema_checks').length.zero?
    assert con.column_definitions('activerecord_unittest.dbo.schema_checks').length.nonzero?
    assert con.column_definitions('activerecord_unittest.foo.schema_checks').length.zero?
  end
  
  def test_view_information
    assert_nil con.view_information 'foo.schema_checks_view'
    assert_not_nil con.view_information 'dbo.schema_checks_view'
    assert_not_nil con.view_information 'schema_checks_view'
    assert_not_nil con.view_information 'activerecord_unittest.dbo.schema_checks_view'
    assert_not_nil con.view_information 'activerecord_unittest..schema_checks_view'
  end
  
  def test_columns
    assert con.columns('schema_checks').length.nonzero?
    assert con.columns('dbo.schema_checks').length.nonzero?
    assert con.columns('foo.schema_checks').length.zero?
    assert con.columns('activerecord_unittest..schema_checks').length.nonzero?
    assert con.columns('activerecord_unittest.dbo.schema_checks').length.nonzero?
    assert con.columns('activerecord_unittest.foo.schema_checks').length.zero?
  end
  
  def con
    con = ActiveRecord::Base.connection
  end
end

end
