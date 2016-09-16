/*
Test macro
Runs through all the methods and writes out results
*/
Macro "test"

  // Input files used in some tests
  dir = "C:\\projects/data_frame/unit_test_data"
  csv_file = dir + "/example.csv"
  bin_file = dir + "/example.bin"
  mtx_file = dir + "/example.mtx"
  array = null
  array.ID = {1, 2, 3}
  array.HH = {4, 5, 6}

  // Create data frame
  df = CreateObject("df", array)

  // test check (which is called by mutate)
  /*df.mutate("bad1", 5)      // raises a type error*/
  /*df.mutate("bad2", {1, 2}) // raises a length error*/

  // test nrow/ncol
  if df.nrow() <> 3 then Throw("test: nrow failed")
  if df.ncol() <> 2 then Throw("test: ncol failed")

  // test copy
  new_df = df.copy()
  new_df.tbl.ID = null
  colnames = df.colnames()
  if colnames.length <> 2 then Throw("test: copy failed")

  // test addition
  df.mutate("addition", df.tbl.ID + df.tbl.HH)
  /*
  Addition can also be done like so, but mutate() builds in an auto check()
  df.tbl.addition = df.tbl.ID + df.tbl.HH
  */
  answer = {5, 7, 9}
  for a = 1 to answer.length do
    if df.tbl.addition[a] <> answer[a] then Throw("test: mutate failed")
  end

  // test write_csv
  df.write_csv(dir + "/write_csv output.csv")

  // test read_csv and read_bin (which test read_view)
  df = null
  df = CreateObject("df")
  df.read_csv(csv_file)
  answer = {1, 2, 3}
  for a = 1 to answer.length do
    if df.tbl.ID[a] <> answer[a] then Throw("test: read_csv failed")
  end
  df = null
  df = CreateObject("df")
  df.read_bin(bin_file)
  for a = 1 to answer.length do
    if df.tbl.ID[a] <> answer[a] then Throw("test: read_bin failed")
  end

  // test read_mtx (and read_cur)
  df = null
  df = CreateObject("df")
  df.read_mtx(mtx_file)
  answer = {1, 2, 3, 4}
  for a = 1 to answer.length do
    if df.tbl.Value[a] <> answer[a] then Throw("test: read_view failed")
  end

  // test select
  df = null
  df = CreateObject("df")
  df.read_csv(csv_file)
  df.select("Data")
  answer_length = 1
  answer_name = "Data"
  colnames = df.colnames()
  if colnames.length <> answer_length or colnames[1] <> answer_name
    then Throw("test: select failed")

  // test in
  df = null
  df = CreateObject("df")
  df.read_csv(csv_file)
  tf = df.in({5, 6}, df.tbl.Data)
  if tf <> "True" then Throw("test: in() failed")
  tf = df.in(5, df.tbl.Data)
  if tf <> "True" then Throw("test: in() failed")
  tf = df.in("a", df.tbl.Data)
  if tf <> "False" then Throw("test: in() failed")

  // test group_by and summarize
  df = null
  df = CreateObject("df")
  df.read_mtx(mtx_file)
  df.group_by("TO")
  opts = null
  opts.Value = {"sum"}
  new_df = df.summarize(opts)
  answer = {4, 6}
  for a = 1 to answer.length do
    if new_df.tbl.sum_Value[a] <> answer[a] then Throw("test: summarize() failed")
  end

  ShowMessage("Passed Tests")
EndMacro

/*
Creates a new class of object called a data_frame.
Allows tables and other data to be loaded into memory
and manipulated more easily than a standard TC view.

tbl
  Options Array
  Optional argument to load table data upon creation
  If null, the data frame is created empty

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

Class "df" (tbl)

  init do
    self.tbl = CopyArray(tbl)
    self.check()
    self.groups = null
  EndItem

  /*
  Tests to see if there is any data.  Usually called to stop other methods
  */

  Macro "is_empty" do
    if self.tbl = null then return("true") else return("false")
  EndItem

  /*
  This creates a complete copy of the data frame.  If you try

  new_df = old_df

  you simply get two variable names that point to the same object.
  Instead, use

  new_df = old_df.copy()
  */

  Macro "copy" do

    new_df = CreateObject("df")
    a_properties = GetObjectVariableNames(self)
    for p = 1 to a_properties.length do
      prop = a_properties[p]

      type = TypeOf(self.(prop))
      new_df.(prop) =
        if type = "array" then CopyArray(self.(prop))
        else if type = "vector" then CopyVector(self.(prop))
        else self.(prop)
    end

    return(new_df)
  EndItem

  /*
  Returns array of column names
  */
  Macro "colnames" do
    if self.is_empty() then return()
    for c = 1 to self.tbl.length do
      a_colnames = a_colnames + {self.tbl[c][1]}
    end
    return(a_colnames)
  EndItem

  /*
  Returns number of columns
  */

  Macro "ncol" do
    if self.is_empty() then return()
    return(self.tbl.length)
  EndItem

  /*
  Returns number of rows
  */

  Macro "nrow" do
    if self.is_empty() then return()
    return(self.tbl[1][2].length)
  EndItem

  /*
  Checks that the data frame is valid
  */
  Macro "check" do
    if self.is_empty() then return()

    // Convert all columns to vectors and check length
    for i = 1 to self.tbl.length do
      colname = self.tbl[i][1]

      // Type check
      type = TypeOf(self.tbl.(colname))
      if type <> "vector" then do
        if type = "array" then self.tbl.(colname) = A2V(self.tbl.(colname))
        else Throw("check: '" + colname + "' is neither an array nor vector")
      end

      // Length check
      if self.tbl.(colname).length <> self.nrow() then
        Throw("check: '" + colname + "' has different length than first column")
    end
  EndItem

  /*
  Adds a field to the data frame

  vector
    Array or Vector
  */

  Macro "mutate" (name, vector) do
    self.tbl.(name) = vector
    self.check()
  EndItem

  /*
  Changes the name of a column in a table object

  current_name
    String or array of strings
    current name of the field in the table
  new_name
    String or array of strings
    desired new name of the field
    if array, must be the same length as current_name
  */

  Macro "rename" (current_name, new_name) do

    // Argument checking
    if TypeOf(current_name) <> TypeOf(new_name)
      then Throw("rename: Current and new name must be same type")
    if TypeOf(current_name) <> "string" then do
      if TypeOf(current_name[1]) <> "string"
        then Throw("rename: Field name arrays must contain strings")
      if current_name.lenth <> new_name.length
        then Throw("rename: Field name arrays must be same length")
    end

    // If a single field string, convert string to array
    if TypeOf(current_name) = "string" then do
      current_name = {current_name}
      new_name = {new_name}
    end

    for n = 1 to current_name.length do
      cName = current_name[n]
      nName = new_name[n]

      for c = 1 to self.tbl.length do
        if self.tbl[c][1] = cName then self.tbl[c][1] = nName
      end
    end
  EndItem

  /*
  file
    String
    full path of csv file

  append
    True/False
    Whether to append to an existing csv (defaults to false)
  */
  Macro "write_csv" (file, append) do

    // Check for required arguments
    if file = null then Throw("write_csv: no file provided")
    if Right(file, 3) <> "csv"
      then Throw("write_csv: file name must end with '.csv'")
    if append <> null and !self.in(append, {"a", "w"})
      then Throw("write_csv: 'append' must be either 'a', 'w', or null")

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
        vec = self.tbl.(colnames[c])
        type = vec.type

        strVal = if type = "string" then vec[r]
        else String(vec[r])

        line = if c = 1 then strVal
        else line + "," + strVal
      end
      WriteLine(file, line)
    end

    CloseFile(file)
  EndItem

  /*
  Creates a bin file by first creating a csv (write_csv) and then
  exporting that to a bin file.

  file
    String
    full path of bin file
  */

  Macro "write_bin" (file) do

    // Argument check
    if file = null then Throw("write_bin: no file provided")
    if Right(file, 3) <> "bin"
      then Throw("write_bin: file name must end with '.bin'")

    // First write to csv
    csv_file = Substitute(file, ".bin", ".csv", )
    self.write_csv(csv_file)

    // Open and export that csv to a bin
    view = OpenTable("csv", "CSV", {csv_file})
    ExportView(view + "|", "FFB", file, , )

    // Clean up workspace
    CloseView(view)
    DeleteFile(csv_file)
    DeleteFile(Substitute(csv_file, ".csv", ".DCC", ))
  EndItem

  /*
  Converts a view into a table object.
  Useful if you want to specify a selection set.

  view
    String
    TC view name
  set
    String
    optional set name
  */

  Macro "read_view" (view, set) do

    // Check for required arguments and
    // that data frame is currently empty
    if view = null
      then Throw("read_view: Required argument 'view' missing.")
    if !self.is_empty() then Throw("read_view: data frame must be empty")

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

      self.tbl.(field) = GetDataVector(view + "|" + set, field, )
    end
    self.check()
  EndItem

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
  EndItem
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
  EndItem

  /*
  Most of the time, you will want to use read_mtx(). Check both
  and decide.

  Creates a table object from a matrix currency in long form.
  Uses read_view().
  */

  Macro "read_cur" (mtxcur) do

    // Validate arguments
    if mtxcur = null then Throw("read_mtx: no currency supplied")
    if mtxcur.matrix.Name = null then do
      Throw("read_mtx: mtxcur is not a valid matrix currency")
    end

    // Create a temporary bin file
    file_name = GetTempFileName(".bin")

    // Set the matrix index and export to a table
    SetMatrixIndex(mtxcur.matrix, mtxcur.rowindex, mtxcur.colindex)
    opts = null
    opts.Tables = {mtxcur.corename}
    CreateTableFromMatrix(mtxcur.matrix, file_name, "FFB", opts)

    // Read exported table into view
    self.read_bin(file_name)

    // Clean up workspace
    DeleteFile(file_name)
    DeleteFile(Substitute(file_name, ".bin", ".DCB", ))
  EndItem

  /*
  Reads a matrix file.

  file
    String
    Full file path of matrix

  core
    String
    Core name to read - defaults to first core

  ri and ci
    String
    Row and column indicies to use.  Defaults to the default
    indices.
  */

  Macro "read_mtx" (file, core, ri, ci) do

    // Check arguments and set defaults if needed
    a_parts = ParseString(file, ".")
    ext = a_parts[2]
    if ext <> "mtx" then Throw("read_mtx: file not a .mtx")
    mtx = OpenMatrix(file, )
    if core = null then do
      a_corenames = GetMatrixCoreNames(mtx)
      core = a_corenames[1]
    end
    a_def_inds = GetMatrixIndex(mtx)
    if ri = null then ri = a_def_inds[1]
    if ci = null then ci = a_def_inds[2]

    // Create matrix currency and read it in
    mtxcur = CreateMatrixCurrency(mtx, core, ri, ci, )
    self.read_cur(mtxcur)

  EndItem

  /*
  Creates a view based on a temporary binary file.  The primary purpose of
  this macro is to make GISDK functions/operations available for a table object.
  The view is often read back into a table object afterwards.

  Returns:
  view_name:  Name of the view as opened in TrandCAD
  file_name:  Name of the temporary bin file
  */

  Macro "create_view" do

    // Convert the data frame object into a CSV and open the view
    tempFile = GetTempFileName(".bin")
    self.write_bin(tempFile)
    view_name = OpenTable("bin", "FFB", {tempFile}, )

    return({view_name, tempFile})
  EndItem

  /*
  Only used in development/debugging, an editor is a visible
  window in TC that displays the contents of a view.  Use this to
  see the contents of your data frame in a tabular format.

  Calling create_editor automatically generates an error message
  to stop the code and allow you to view the table.  This also
  prevents from ever being used in production code, and it never
  should be.
  */

  Macro "create_editor" do
    {view_name, file_name} = self.create_view()
    CreateEditor("data frame", view_name + "|", , )
    Throw("Editor created to view\ndata frame contents")
  EndItem

  /*
  Removes field(s) from a table

  fields:
    String or array of strings
    fields to drop from the data frame
  */

  Macro "drop" (fields) do

    // Argument checking and type handling
    if fields = null then Throw("drop: no fields provided")
    if TypeOf(fields) = "string" then fields = {fields}

    for f = 1 to fields.length do
      self.tbl.(fields[f]) = null
    end
  EndItem

  /*
  Like dply or SQL "select", returns a table with only
  the columns listed in "fields".

  fields:
    String or array of strings
    fields to keep in the data frame
  */

  Macro "select" (fields) do

    // Argument checking and type handling
    if fields = null then Throw("select: no fields provided")
    if TypeOf(fields) = "string" then fields = {fields}

    colnames = self.colnames()
    for f = 1 to colnames.length do
      colname = colnames[f]

      if ArrayPosition(fields, {colname}, ) = 0 then self.drop(colname)
    end
  EndItem

  /*
  Checks if a value is listed anywhere in the vector.

  value
    String, numeric, array, or vector
    The value to search for

  array
    Array or vector
    The array to search in

  Returns True/False
  */

  Macro "in" (value, array) do

    // Argument check
    if value = null then Throw("in: value not provided")
    if TypeOf(array) = "vector" then array = V2A(array)
    if array = null then Throw("in: array not provided")
    if TypeOf(value) = "vector" then value = V2A(value)
    else if TypeOf(value) <> "array" then value = {value}

    tf = if ArrayPosition(array, value, ) <> 0 then "True" else "False"
    return(tf)
  EndItem

  /*
  Establishes grouping fields for the data frame.  This modifies the
  behavior of summary functions.
  */

  Macro "group_by" (fields) do

    // Argument checking and type handling
    if fields = null then Throw("group_by: no fields provided")
    if TypeOf(fields) = "string" then fields = {fields}

    self.groups = fields
  EndItem

  /*
  This macro works with group_by() similar to dlpyr in R.
  Summary stats are calculated for the columns specified, grouped by
  the columns listed as grouping columns in the df.groups property.
  (Set grouping fields using group_by().)

  Because a new data frame is returned, the function must be implimented
  like this:

  new_df = df.summarize(...)

  agg
    Options array listing field and aggregation info
    e.g. agg.weight = {"sum", "avg"}
    This will sum and average the weight field
    The possible aggregations are:
      first, sum, high, low, avg, stddev

  Returns
  A new data frame object of the summarized input table object.
  In the example above, the aggregated fields would be
    sum_weight and avg_weight
  */

  Macro "summarize" (agg) do

    // copy this data frame to a new one to prevent modification
    new_df = self.copy()

    // Remove fields that aren't listed for summary or grouping
    for i = 1 to new_df.groups.length do
      a_selected = a_selected + {new_df.groups[i]}
    end
    for i = 1 to agg.length do
      a_selected = a_selected + {agg[i][1]}
    end
    new_df.select(a_selected)

    // Convert the TABLE object into a view in order
    // to leverage GISDKs SelfAggregate() function
    {view, file_name} = new_df.create_view()

    // Create a field spec for SelfAggregate()
    agg_field_spec = view + "." + new_df.groups[1]

    // Create the "Additional Groups" option for SelfAggregate()
    opts = null
    if new_df.groups.length > 1 then do
      for g = 2 to new_df.groups.length do
        opts.[Additional Groups] = opts.[Additional Groups] + {new_df.groups[g]}
      end
    end

    // Create the fields option for SelfAggregate()
    for i = 1 to agg.length do
      name = agg[i][1]
      stats = agg[i][2]

      proper_stats = null
      for j = 1 to stats.length do
        proper_stats = proper_stats + {{Proper(stats[j])}}
      end
      fields.(name) = proper_stats
    end
    opts.Fields = fields

    // Create the new view using SelfAggregate()
    agg_view = SelfAggregate("aggview", agg_field_spec, opts)

    // Read the view into a new table object
    agg_df = self.copy()
    agg_df.tbl = null
    agg_df.read_view(agg_view)

    // The field names from SelfAggregate() are messy.  Clean up.
    // The first fields will be of the format "GroupedBy(ID)".
    // Next is a "Count(bin)" field.
    // Then there is a first field for each group variable ("First(ID)")
    // Then the stat fields in the form of "Sum(trips)"

    // Set group columns back to original name
    for c = 1 to agg_df.groups.length do
      agg_df.tbl[c][1] = agg_df.groups[c]
    end
    // Set the count field name
    agg_df.tbl[agg_df.groups.length + 1][1] = "Count"
    // Remove the First() fields
    agg_df.tbl = ExcludeArrayElements(
      agg_df.tbl,
      agg_df.groups.length + 2,
      agg_df.groups.length
    )
    // Change fields like Sum(x) to sum_x
    for i = 1 to agg.length do
      field = agg[i][1]
      stats = agg[i][2]

      for j = 1 to stats.length do
        stat = stats[j]

        current_field = Proper(stat) + "(" + field + ")"
        new_field = lower(stat) + "_" + field
        agg_df.rename(current_field, new_field)
      end
    end

    CloseView(agg_view)
    return(agg_df)
  EndItem

endClass
