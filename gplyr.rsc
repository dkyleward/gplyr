/*
Test macro
Runs through all the methods and writes out results
*/
Macro "test"

  // Input files used in some tests
  dir = "C:\\projects/gplyr/unit_test_data"
  csv_file = dir + "/example.csv"
  bin_file = dir + "/example.bin"
  mtx_file = dir + "/example.mtx"
  spread_file = dir + "/spread_example.csv"
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

  // test colnames
  df = CreateObject("df")
  df.read_mtx(mtx_file)
  names = {"a", "b", "c", "d"}
  df.colnames(names)
  check = df.colnames()
  for a = 1 to names.length do
    if check[a] <> names[a] then Throw("test: colnames failed")
  end

  // test read_csv and read_bin (which test read_view)
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

  // test write_csv
  df = CreateObject("df")
  df.read_csv(csv_file)
  test_csv = dir + "/write_csv output.csv"
  df.write_csv(test_csv)
  df = CreateObject("df")
  df.read_csv(test_csv)
  DeleteFile(test_csv)
  if df.ncol() <> 2 then Throw("test: write_csv failed")

  // test read_mtx (and read_cur)
  df = CreateObject("df")
  df.read_mtx(mtx_file)
  answer = {1, 2, 3, 4}
  for a = 1 to answer.length do
    if df.tbl.value[a] <> answer[a] then Throw("test: read_view failed")
  end

  // test select
  df = CreateObject("df")
  df.read_csv(csv_file)
  df.select("Data")
  answer_length = 1
  answer_name = "Data"
  colnames = df.colnames()
  if colnames.length <> answer_length or colnames[1] <> answer_name
    then Throw("test: select failed")

  // test in
  df = CreateObject("df")
  df.read_csv(csv_file)
  tf = df.in({5, 6}, df.tbl.Data)
  if tf <> "True" then Throw("test: in() failed")
  tf = df.in(5, df.tbl.Data)
  if tf <> "True" then Throw("test: in() failed")
  tf = df.in("a", df.tbl.Data)
  if tf <> "False" then Throw("test: in() failed")

  // test group_by and summarize
  df = CreateObject("df")
  df.read_mtx(mtx_file)
  df.group_by("TO")
  opts = null
  opts.value = {"sum"}
  df.summarize(opts)
  answer = {4, 6}
  for a = 1 to answer.length do
    if df.tbl.sum_value[a] <> answer[a] then Throw("test: summarize() failed")
  end

  // test filter
  df = CreateObject("df")
  df.read_csv(csv_file)
  df.filter("ID = 1")
  if df.tbl.ID[1] <> 1 then Throw("test: filter() failed")

  // test left_join
  master = CreateObject("df")
  master.read_csv(csv_file)
  slave = CreateObject("df")
  slave.read_mtx(mtx_file)
  master.left_join(slave, "ID", "FROM")
  answer = {"ID", "Data", "TO", "value", "second_core"}
  for a = 1 to answer.length do
    if master.tbl[a][1] <> answer[a] then Throw("test: left_join() failed")
  end

  // test unite and separate
  df = CreateObject("df")
  df.read_mtx(mtx_file)
  df.unite({"FROM", "TO"}, "comb")
  answer = {"1_1", "1_2", "2_1", "2_2"}
  for a = 1 to answer.length do
    if df.tbl.comb[a] <> answer[a] then Throw("test: unite() failed")
  end
  df.separate("comb", {"a", "b"})
  answer = {1, 1, 2, 2}
  for a = 1 to answer.length do
    if df.tbl.a[a] <> answer[a] then Throw("test: separate() failed")
  end

  // test spread
  df = CreateObject("df")
  df.read_csv(spread_file)
  df.spread("Color", "Count", 0)
  if df.tbl[2][1] <> "Blue" then Throw("test: spread() failed")
  answer = {0, 115, 25}
  for a = 1 to answer.length do
    if df.tbl.Blue[a] <> answer[a] then Throw("test: spread() failed")
  end
  // Add arbitrary numeric column and re-test
  df = CreateObject("df")
  df.read_csv(spread_file)
  df.mutate("arbitrary", {1, 2, 3, 4, 5, 6})
  df.spread("Color", "Count", 0)
  if df.tbl[3][1] <> "Blue" then Throw("test: spread() failed")
  answer = {0, 0, 115, 0, 0, 25}
  for a = 1 to answer.length do
    if df.tbl.Blue[a] <> answer[a] then Throw("test: spread() failed")
  end

  // test bind_rows
  df = CreateObject("df")
  df.read_csv(csv_file)
  df2 = CreateObject("df")
  df2.read_csv(csv_file)
  df.bind_rows(df2)
  if df.tbl[2][1] <> "Data" then Throw("test: bind_rows() failed")
  answer = {4, 5, 6, 4, 5, 6}
  for a = 1 to answer.length do
    if df.tbl.Data[a] <> answer[a] then Throw("test: bind_rows() failed")
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
  Either:
    Returns array of all column names
    Sets all column names

  Use rename() to change individual column names

  names
    Array of strings
    If provided, the method will set the column names instead of
    retrieve them
  */
  Macro "colnames" (names) do

    // Argument checking
    if self.is_empty() then return()
    if names <> null then do
      if TypeOf(names) <> "array" then
        Throw("colnames: if provided, 'names' argument must be an array")
      if names.length <> self.ncol() then
        Throw("colnames: 'names' length does not match number of columns")
    end

    if names = null then do
      for c = 1 to self.ncol() do
        a_colnames = a_colnames + {self.tbl[c][1]}
      end
      return(a_colnames)
    end else do
      for c = 1 to names.length do
        self.tbl[c][1] = names[c]
      end
    end
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
  Reads a matrix file.

  file
    String
    Full file path of matrix

  cores
    String or array of strings
    Core names to read - defaults to all cores

  ri and ci
    String
    Row and column indicies to use.  Defaults to the default
    indices.

  all_cells
    "Yes" or "No"
    Whether to include every ij pair in the data frame.  Defaults to "Yes".
    Set to "No" to drop cells with missing values.
  */

  Macro "read_mtx" (file, cores, ri, ci, all_cells) do

    // Check arguments and set defaults if needed
    if !self.is_empty() then Throw("read_mtx: data frame must be empty")
    a_parts = ParseString(file, ".")
    ext = a_parts[2]
    if ext <> "mtx" then Throw("read_mtx: file name must end in '.mtx'")
    mtx = OpenMatrix(file, )
    a_corenames = GetMatrixCoreNames(mtx)
    if cores = null then cores = a_corenames
    if TypeOf(cores) = "string" then cores = {cores}
    if TypeOf(cores) <> "array" then
      Throw("read_mtx: 'cores' must be either an array, string, or null")
    for c = 1 to cores.length do
      if !self.in(cores[c], a_corenames)
        then Throw("read_mtx: core '" + cores[c] + " not found in matrix")
    end
    {d_ri, d_ci} = GetMatrixIndex(mtx)
    if ri = null then ri = d_ri
    if ci = null then ci = d_ci
    {row_inds, col_inds} = GetMatrixIndexNames(mtx)
    if !self.in(ri, row_inds)
      then Throw("read_mtx: row index '" + ri + "' not found in matrix")
    if !self.in(ci, col_inds)
      then Throw("read_mtx: column index '" + ci + "' not found in matrix")
    if all_cells = null then all_cells = "Yes"

    // Set the matrix index and export to a table
    SetMatrixIndex(mtx, ri, ci)
    file_name = GetTempFileName(".bin")
    opts = null
    opts.Complete = all_cells
    opts.Tables = cores
    CreateTableFromMatrix(mtx, file_name, "FFB", opts)

    // Read exported table into view
    self.read_bin(file_name)

    // Clean up workspace
    DeleteFile(file_name)
    DeleteFile(Substitute(file_name, ".bin", ".DCB", ))
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

  agg
    Options array listing field and aggregation info
    e.g. agg.weight = {"sum", "avg"}
    This will sum and average the weight field
    The possible aggregations are:
      first, sum, high, low, avg, stddev

  Returns
  A new data frame of the summarized input table object.
  In the example above, the aggregated fields would be
    sum_weight and avg_weight
  */

  Macro "summarize" (agg) do

    // Remove fields that aren't listed for summary or grouping
    for i = 1 to self.groups.length do
      a_selected = a_selected + {self.groups[i]}
    end
    for i = 1 to agg.length do
      a_selected = a_selected + {agg[i][1]}
    end
    self.select(a_selected)

    // Convert the TABLE object into a view in order
    // to leverage GISDKs SelfAggregate() function
    {view, file_name} = self.create_view()

    // Create a field spec for SelfAggregate()
    agg_field_spec = view + "." + self.groups[1]

    // Create the "Additional Groups" option for SelfAggregate()
    opts = null
    if self.groups.length > 1 then do
      for g = 2 to self.groups.length do
        opts.[Additional Groups] = opts.[Additional Groups] + {self.groups[g]}
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

    // Read the view back into the data frame
    self.tbl = null
    self.read_view(agg_view)

    // The field names from SelfAggregate() are messy.  Clean up.
    // The first fields will be of the format "GroupedBy(ID)".
    // Next is a "Count(bin)" field.
    // Then there is a first field for each group variable ("First(ID)")
    // Then the stat fields in the form of "Sum(trips)"

    // Set group columns back to original name
    for c = 1 to self.groups.length do
      self.tbl[c][1] = self.groups[c]
    end
    // Set the count field name
    self.tbl[self.groups.length + 1][1] = "Count"
    // Remove the First() fields
    self.tbl = ExcludeArrayElements(
      self.tbl,
      self.groups.length + 2,
      self.groups.length
    )
    // Change fields like Sum(x) to sum_x
    for i = 1 to agg.length do
      field = agg[i][1]
      stats = agg[i][2]

      for j = 1 to stats.length do
        stat = stats[j]

        current_field = Proper(stat) + "(" + field + ")"
        new_field = lower(stat) + "_" + field
        self.rename(current_field, new_field)
      end
    end

    CloseView(agg_view)
  EndItem

  /*
  Applies a query to a table object.

  query
    String
    Valid TransCAD query (e.g. "ID = 5" or "Name = 'Sam'")
    Do not include "Select * where" in the query string
  */

  Macro "filter" (query) do

    // Argument check
    if query = null then Throw("filter: query is missing")
    if TypeOf(query) <> "string" then Throw("filter: query must be a string")
    if Proper(Left(query, 6)) = "Select" then
      Throw("filter: do not include 'Select * where' in your query")

    {view, file} = self.create_view()
    SetView(view)
    query = "Select * where " + query
    SelectByQuery("set", "Several", query)
    self.tbl = null
    self.read_view(view, "set")
  EndItem


  /*
  Joins two data frame objects.

  slave_tbl
    data frame objects

  m_id and s_id
    String or array
    The id fields from master and slave to use for join.  Use an array to
    specify multiple fields to join by.
  */

  Macro "left_join" (slave_tbl, m_id, s_id) do

    // Argument check
    if TypeOf(m_id) = "string" then m_id = {m_id}
    if TypeOf(s_id) = "string" then s_id = {s_id}
    if m_id.length <> s_id.length then
      Throw("left_join: 'm_id' and 's_id' are not the same length")

    {master_view, master_file} = self.create_view()
    {slave_view, slave_file} = slave_tbl.create_view()

    dim m_spec[m_id.length]
    dim s_spec[s_id.length]
    for i = 1 to m_id.length do
      m_spec[i] = master_view + "." + m_id[i]
      s_spec[i] = slave_view + "." + s_id[i]
    end

    jv = JoinViewsMulti("jv", m_spec, s_spec, )
    self.tbl = null
    self.read_view(jv)

    // JoinViewsMulti() will attach the view names to the m_id and s_id fields
    // if they are the same.
    // Remove the s_id fields, and clean the m_id fields (if needed)
    for i = 1 to m_id.length do
      m = m_id[i]
      s = s_id[i]

      if m = s then do
        // Rename master field
        current_name = "[" + master_view + "]." + m
        self.rename(current_name, m)
        // Delete slave field
        self.tbl.("[" + slave_view + "]." + s) = null
      end else do
        // Delete slave field
        self.tbl.(s) = null
      end
    end

    // Clean up the workspace
    CloseView(jv)
    CloseView(master_view)
    DeleteFile(master_file)
    DeleteFile(Substitute(master_file, ".bin", ".DCB", ))
    CloseView(slave_view)
    DeleteFile(slave_file)
    DeleteFile(Substitute(slave_file, ".bin", ".DCB", ))
  EndItem

  /*
  Concatenates multiple column values into a single column

  cols
    Array of strings
    column names to unite

  new_col
    String
    Name of new column to place results

  sep
    String
    Separator to use between values
    Defaults to `_`
  */

  Macro "unite" (cols, new_col, sep) do

    // Argument check
    if sep = null then sep = "_"
    if cols = null then Throw("unite: `cols` not provided")
    if new_col = null then Throw("unite: `new_col` not provided")
    if TypeOf(cols) <> "array" then Throw("unite: `cols` must be an array")

    for c = 1 to cols.length do
      col = cols[c]

      vec = self.tbl.(col)
      vec = if (vec.type = "string")
        then self.tbl.(col)
        else String(self.tbl.(col))
      self.tbl.(new_col) = if (c = 1)
        then vec
        else self.tbl.(new_col) + sep + vec
    end
  EndItem

  /*
  Opposite of unite().  Separates a column based on a delimiter

  col
    String
    Name of column to seaprate

  new_cols
    Array of strings
    Names of new columns

  sep
    String
    Delimter to use to parse
  */

  Macro "separate" (col, new_cols, sep) do

    // Argument check
    if sep = null then sep = "_"
    if col = null then Throw("unite: `col` not provided")
    if new_cols = null then Throw("unite: `new_cols` not provided")
    if TypeOf(new_cols) <> "array" then Throw("unite: `new_cols` must be an array")
    vec = self.tbl.(col)
    if TypeOf(vec[1]) <> "string" then
      Throw("separate: column '" + col + "' doesn't contain strings")

    dim array[new_cols.length, self.nrow()]
    for r = 1 to self.nrow() do
      vec = self.tbl.(col)
      string = vec[r]
      parts = ParseString(string, sep)

      // Error check
      if r = 1 then do
        if parts.length <> new_cols.length then
          Throw("separate: `new_cols` length doesn't match parsed '" + col + "'")
      end

      for p = 1 to parts.length do
        value = parts[p]

        // Convert any string-number into a number
        value = if value = "0"
          then 0
          else if Value(value) = 0
            then value
            else Value(value)

        array[p][r] = value
      end
    end

    // fill data frame
    for c = 1 to new_cols.length do
      self.tbl.(new_cols[c]) = array[c]
    end

    // remove original column
    self.tbl.(col) = null
  EndItem

  /*
  Place holder for notes about spread()
  - create columns for each unique value of key
  - fill each with values where the key is matched
  - create a new field that unites non-key/value columns
  - start a new data frame with just that field
  - use that to perform joins
  - then separate
  */

  Macro "spread" (key, value, fill) do

    // Argument check
    if key = null then Throw("spread: `key` missing")
    if value = null then Throw("spread: `value` missing")
    if !self.in(key, self.colnames()) then Throw("spread: `key` not in table")
    if !self.in(value, self.colnames()) then
      Throw("spread: `value` not in table")

    // Create a single-column data frame that concatenates all fields
    // except for key and value
    first_col = self.copy()
    first_col.tbl.(key) = null
    first_col.tbl.(value) = null
    // If more than one field remains in the table, unite them
    if first_col.ncol() > 1 then do
      unite = "True"
      join_col = "unite"
      a_unite_cols = first_col.colnames()
      first_col.unite(a_unite_cols, join_col)
      first_col.select(join_col)
    end else do
      join_col = first_col.colnames()
      join_col = join_col[1]
    end
    opts = null
    opts.Unique = "True"
    vec = SortVector(first_col.tbl.(join_col), opts)
    first_col.mutate(join_col, vec)

    // Create a second working table.
    split = self.copy()
    // If necessary, combine columns in `split` to match `first_col` table
    if unite then split.unite(a_unite_cols, join_col)
    opts = null
    opts.Unique = "True"
    a_unique_keys = SortVector(split.tbl.(key), opts)
    for k = 1 to a_unique_keys.length do
      key_val = a_unique_keys[k]

      // TransCAD requires field names to look like strings.
      // Add an "s" at start of name if needed.
      col_name = if TypeOf(key_val) <> "string"
        then "s" + String(key_val)
        else key_val

      temp = if split.tbl.(key) = key_val then split.tbl.(value) else null
      split.mutate(col_name, temp)

      // Create a sub table from `split` and join it to `first_col`
      sub = split.copy()
      sub.select({join_col, col_name})
      sub.filter(col_name + " <> null")
      first_col.left_join(sub, join_col, join_col)

      // Fill in any null values with `fill`
      first_col.tbl.(col_name) = if first_col.tbl.(col_name) = null
        then fill
        else first_col.tbl.(col_name)
    end

    // Create final table
    self.tbl = null
    self.tbl.(join_col) = first_col.tbl.(join_col)
    if unite then self.separate(join_col, a_unite_cols)
    first_col.tbl.(join_col) = null
    self.tbl = InsertArrayElements(self.tbl, self.tbl.length + 1, first_col.tbl)
  EndItem

  /*
  Combines the rows of two tables. They must have the
  same columns.

  df
    data frame object
    data frame that gets appended
  */

  Macro "bind_rows" (df) do

    // Check that tables have same columns
    col1 = self.colnames()
    col2 = df.colnames()
    for i = 1 to col1.length do
      if col1[i] <> col2[i] then Throw("bind_rows: Columns are not the same")
    end

    // Make sure both tables are vectorized and pass all checks
    self.check()
    df.check()

    // Combine tables
    final = null
    for i = 1 to col1.length do
      col_name = col1[i]

      a1 = V2A(self.tbl.(col_name))
      a2 = V2A(df.tbl.(col_name))
      self.tbl.(col_name) = a1 + a2
    end

    // Final check
    self.check()
  EndItem

endClass
