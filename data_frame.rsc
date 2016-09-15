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

  // test check (which is called by mutate)
  /*df.mutate("bad1", 5)      // raises a type error
  df.mutate("bad2", {1, 2}) // raises a length error*/

  // test nrow/ncol
  if df.nrow() <> 3 then Throw("test: nrow failed")
  if df.ncol() <> 2 then Throw("test: ncol failed")

  // test mutate
  df.mutate("addition", df.new_col1 + df.new_col2)
  answer = {4, 6, 8}
  for a = 1 to answer.length do
    if df.addition[a] <> answer[a] then Throw("test: mutate failed")
  end

  // test write_csv
  df.write_csv("C:\\Users/warddk/Desktop/Scratch/test.csv")

  // test read_view
  df = null
  df = CreateObject("df")
  csv_file = "C:\\projects/data_frame/unit_test_data/example.csv"
  view = OpenTable("view", "CSV", {csv_file})
  df.read_view(view)
  CloseView(view)
  answer = {1, 2, 3}
  for a = 1 to answer.length do
    if df.ID[a] <> answer[a] then Throw("test: read_view failed")
  end

  // test read_csv and read_bin
  df = null
  df = CreateObject("df")
  df.read_csv(csv_file)
  answer = {1, 2, 3}
  for a = 1 to answer.length do
    if df.ID[a] <> answer[a] then Throw("test: read_csv failed")
  end
  df = null
  df = CreateObject("df")
  bin_file = Substitute(csv_file, ".csv", ".bin", )
  df.read_bin(bin_file)
  for a = 1 to answer.length do
    if df.ID[a] <> answer[a] then Throw("test: read_bin failed")
  end

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

  Macro "colnames" do
    return(GetObjectVariableNames(self))
  endItem

  Macro "ncol" do
    array = self.colnames()
    return(array.length)
  endItem

  Macro "nrow" (col_name) do
    array = self.colnames()
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

  /*
    Checks that the data frame is valid
  */
  Macro "check" do

    // Convert all columns to vectors and check length
    colnames = self.colnames()
    for i = 1 to colnames.length do
      colname = colnames[i]

      // Type check
      type = TypeOf(self.(colname))
      if type <> "vector" then do
        if type = "array" then self.(colname) = A2V(self.(colname))
        else Throw("check: '" + colname + "' is neither an array nor vector")
      end

      // Length check
      if i = 1 then do
        length = self.(colname).length
      end else do
        if length <> self.(colname).length then do
          Throw("check: '" + colname + "' has different length than first column")
        end
      end
    end
  endItem


  Macro "mutate" (name, vector) do
    self.(name) = vector
    self.check()
  endItem

  /*
  file
    String
    full path of file

  append
    True/False
    Whether to append to an existing csv (defaults to false)
  */
  Macro "write_csv" (file, append) do

    // Check for required arguments
    if file = null then do
      Throw("write_csv: no file provided")
    end
    else if Right(file, 3) <> "csv" then do
      Throw("write_csv: file must be a csv")
    end

    // Check validity of table
    self.check()

    // Open a csv file for writing
    if append then file = OpenFile(file, "a")
    else file = OpenFile(file, "w")

    // Write the row of column names
    colnames = self.colnames()
    for i = 1 to colnames.length do
      if i = 1 then firstLine = colnames[i]
      else firstLine = firstLine + "," + colnames[i]
    end
    WriteLine(file, firstLine)

    // Write each remaining row
    for r = 1 to self.nrow() do
      line = null
      for c = 1 to colnames.length do
        vec = self.(colnames[c])
        type = vec.type

        strVal = if type = "string" then vec[r]
        else String(vec[r])

        line = if c = 1 then strVal
        else line + "," + strVal
      end
      WriteLine(file, line)
    end

    CloseFile(file)
  endItem

  /*
  Converts a view into a table object.
  view (string): TC view name
  set (string): optional set name
  */

  Macro "read_view" (view, set) do

    // Check for required arguments and
    // that data frame is currently empty
    if view = null then do
      Throw("read_view: Required argument 'view' missing.")
    end
    if self.colnames() <> NULL
      then Throw("read_view: data frame must be empty")

    a_fields = GetFields(view, )
    a_fields = a_fields[1]

    for f = 1 to a_fields.length do
      field = a_fields[f]

      // When a view has too many rows, a "???" will appear in the editor
      // meaning that TC did not load the entire view into memory.
      // Creating a selection set will force TC to load the entire view.
      if f = 1 then do
        SetView(view)
        qry = "Select * where nz(" + field + ") >= 0"
        SelectByQuery("temp", "Several", qry)
      end

      self.(field) = GetDataVector(view + "|" + set, field, )
    end
    self.check()
  endItem

  /*
  Simple wrappers to read_view that read bin and csv directly
  */

  Macro "read_bin" (file) do
    // Check extension
    ext = ParseString(file, ".")
    ext = ext[2]
    if ext <> "bin" then Throw("read_bin: file not a .bin")

    view = OpenTable("view", "FFB", {file})
    self.read_view(view)
    CloseView(view)
  endItem
  Macro "read_csv" (file) do
    // Check extension
    a_parts = ParseString(file, ".")
    ext = a_parts[2]
    if ext <> "csv" then Throw("read_csv: file not a .csv")

    view = OpenTable("view", "CSV", {file})
    self.read_view(view)
    CloseView(view)

    // Remove the .DCC
    DeleteFile(Substitute(file, ".csv", ".DCC", ))
  endItem


endClass
