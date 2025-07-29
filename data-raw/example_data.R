## code to prepare `example_data` dataset goes here

example_data <- read.csv("inst/extdata/example_data.csv")

usethis::use_data(example_data, overwrite = TRUE)

