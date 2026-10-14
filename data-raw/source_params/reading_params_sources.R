## code to read the parameter Excel file (`params_copy`) goes here
## Tabs: "params" (params.yaml, params_distributions.yaml) and
## "defaultvariables" (defaultvariables.yaml).

# Parameter Excel file, with the source of each value (outside this repository)
params_xlsx <- "J:/EEH/EMF/GOLIAT/03_Work_Package_1/04_Task 1.6_Dose_model/SDM/Output_power/params_sources.xlsx"

# Read from a temporary copy, so the file can stay open in Excel
params_copy <- tempfile(fileext = ".xlsx")
if (!file.copy(params_xlsx, params_copy)) {
  stop("Cannot copy parameter file: ", params_xlsx)
}

# Whole numbers as integers, written without decimals in the YAML files
as_param <- function(value) {
  if (value == round(value) && abs(value) < .Machine$integer.max) as.integer(value) else value
}
