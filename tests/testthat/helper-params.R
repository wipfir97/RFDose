# The reference values of the dose tests were computed with the ETAIN SAR values
# (and the ETAIN placement proportions of params.yaml), so these tests use
# the ETAIN parameters instead of the default (GOLIAT) ones.
etain_params <- load_params(
  sar_path = system.file("extdata", "sar_etain.yaml", package = "RFDose"))
