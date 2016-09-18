# gplyr
Creating a structure in GISDK similar to data frames in R, with methods
that mimic dplyr and tidyr packages.

## Unit testing
A basic set of unit tests is maintained in the macro "test". At least one for each method.  If adding functionality, a unit test must be created to validate the code.  These unit tests will be run before accepting any pull requests.

## Creation
Create a data frame object in GISDK code with the following code

`df = CreateObject("df")`

By default, the data frame is created empty, and one of the input methods below adds data.

## Methods
This section provides a simple list of methods to give an idea of what is available.  A wiki will be created to provide proper documentation and examples for each method.

### Reading / Input
read_view  
read_csv  
read_bin  
read_mtx  
copy

### Writing / Output
write_csv  
write_bin  
create_view  
create_editor

### Manipulation
select  
mutate  
rename  
remove  
group_by  
summarize  
filter  
left_join  
unite  
separate  
spread  
bind_rows

### Utility
is_empty  
nrow  
ncol  
colnames  
check  
in
