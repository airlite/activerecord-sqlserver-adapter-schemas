# This module is used to make it easier to deal with legacy char fields by trimming them automatically after a find.
module ActiveRecord
module Schemas
module Base
  # returns true if schema names should be used.  Default is false
  def use_schema_names?
    read_inheritable_attribute(:use_schema_names)
  end
  
  # sets if schema names should be used.
  def use_schema_names=(value)
    write_inheritable_attribute(:use_schema_names, value)
  end
  alias_method :set_use_schema_names, :use_schema_names=
  
  # returns the schema name, either based on the module (via reset_schema_name) of an explicitly set value defined by the class
  def schema_name
    reset_schema_name
  end
  
  # calculates the schema name based on the class's module
  def reset_schema_name
    ar_descendant = class_of_active_record_descendant(self)
    if ar_descendant == self
      name = self.name.split('::').first.downcase
      set_schema_name name
      name
    else
      ar_descendant.schema_name
    end
  end
  
  # overrides the default schema based on the module
  def schema_name=(value = nil, &block)
    define_attr_method :schema_name, value, &block
  end
  alias_method :set_schema_name, :schema_name=
  
  # sets the table name with the schema
  def reset_table_name_with_schema
    ar_descendant = class_of_active_record_descendant(self)
    if self == ar_descendant
      name = reset_table_name
      if use_schema_names? && schema_name
        name = "#{"#{schema_name}." if schema_name}#{name}"
        set_table_name name
      end
      name
    else
      name = ar_descendant.table_name
      set_table_name name
      name
    end
  end
end
end
end
