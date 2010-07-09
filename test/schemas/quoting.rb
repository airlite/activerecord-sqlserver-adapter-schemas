#!/usr/bin/env ruby
require 'test/unit'
require File.join(File.dirname(__FILE__), 'connection')

module Schemas
  
class Quoting < Test::Unit::TestCase
  def setup
    con.default_schema = 'dbo'
  end
  
  def test_quote_column_name
    assert_equal con.quote_column_name('schema_checks'), '[schema_checks]'
    assert_equal con.quote_column_name('dbo.schema_checks'), '[dbo].[schema_checks]'
    assert_equal con.quote_column_name('activerecord_unittest..schema_checks'), '[activerecord_unittest]..[schema_checks]'
    assert_equal con.quote_column_name('activerecord_unittest.dbo.schema_checks'), '[activerecord_unittest].[dbo].[schema_checks]'
  end
  
  def con
    con = ActiveRecord::Base.connection
  end
end

end
