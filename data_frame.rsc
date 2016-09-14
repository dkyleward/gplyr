/*
Test macro
Runs through all the methods and writes out results
*/
Macro "test"

  // Create data frame
  df = CreateObject("df")

  // Add some columns
  df.mutate("new_col1", A2V({1, 2, 3}))
  df.mutate("new_col2", A2V({3, 4, 5}))

  // test nrow/ncol
  rows = df.nrow()
  cols = df.ncol()

  // test mutate
  df.mutate("addition", df.new_col1 + df.new_col2)

  // test write_csv
  df.write_csv("C:\\test.csv")

  // Throw error to check results
  Throw()
EndMacro

/*
Creates a new class of object called a data_frame.
Allows tables and other data to be loaded into memory
and manipulated more easily than a standard TC view.

Create a data_frame by calling CreateObject("data_frame")

Has the following methods
  nrow
    returns number of rows
  ncol
    returns number of columns
  mutate
    create or modify existing column
    e.g. df.mutate("density", df.households / df.area)
  write_csv
    write table out to csv
    e.g. df.write_csv("C:\\test.csv")
*/

Class "df"

  init do

  endItem

  Macro "mutate" (name, vector) do
    self.(name) = vector
  endItem

  Macro "ncol" do
    array = GetObjectVariableNames(self)
    return(array.length)
  endItem

  Macro "nrow" (col_name) do
    array = GetObjectVariableNames(self)
    if col_name <> null then do
      if TypeOf(col_name) <> "string" then Throw("nrow: col_name must be string")
      pos = ArrayPosition(array, {col_name}, )
      if pos = 0 then Throw("nrow: column '" + col_name + "' not found")
      vector = self.(array[pos])
    end else do
      vector = self.(array[1])
    end
    return(vector.length)
  endItem

  Macro "write_csv" (file) do

    // Check for required arguments
    if file = null then do
      Throw("write_csv: no file provided")
    end

    // Check self to make sure all vectors are the same length
    for i = 1 to self.length do
      if i = 1 then length = self[i][2].length
      else do
        if length <> self[i][2].length then do
          Throw("Write Table: Not all columns have equal length.")
        end
      end
    end

    // Check that the file name ends in CSV
    if Right(file, 3) <> "csv" then do
      Throw("Write Table: File must be a CSV")
    end

    // Open a csv file for writing
    if append then file = OpenFile(file, "a")
    else file = OpenFile(file, "w")

    // Write the row of column names
    for i = 1 to self.length do
      if i = 1 then firstLine = self[i][1]
      else firstLine = firstLine + "," + self[i][1]
    end
    WriteLine(file, firstLine)

    // Write each remaining row
    for r = 1 to self[1][2].length do
      line = null
      for c = 1 to self.length do
        type = self[c][2].type

        if type = "string" then strVal = self[c][2][r]
        else strVal = String(self[c][2][r])
        if c = 1 then line = strVal
        else line = line + "," + strVal
      end
      WriteLine(file, line)
    end

    CloseFile(file)
  endItem

endClass
