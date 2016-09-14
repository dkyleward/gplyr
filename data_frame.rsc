/*
Creates a new class of object called a data_frame.
Allows tables and other data to be loaded into memory
and manipulated more easily than a standard TC view.
*/

Class "data_frame"

  init do
    
  endItem

  Macro "mutate" (name, vector) do
    self.(name) = vector
  endItem

endClass

Macro "test"

  // Create data frame
  df = CreateObject("data_frame")

  // Add some columns
  df.mutate("new_col1", A2V({1, 2, 3}))
  df.mutate("new_col2", A2V({3, 4, 5}))

  // This test confirms that the values can be accessed easily by column name
  first_test = df.new_col1

  // This test confirms that functions are evaluated
  // Currently, you would write this like so
  // df.addition = df.new_col1 + df.new_col2
  // In other words, basic math takes a few more key strokes
  df.mutate("addition", df.new_col1 + df.new_col2)

  // Even though this takes a few more, every other function would take less.
  // Currently, to filter, we have to write:
  // filtered_table = RunMacro("Filter", df, filter_query)
  // That would become
  // filtered_table = df.filter(filter_query)
  // More importantly, we no longer have to worry about conflicting
  // macro names with our other macros.  df.filter() is defined only for
  // this object

  // Throw an error to see results
  Throw()
EndMacro
