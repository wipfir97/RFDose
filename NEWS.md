# Version 2.0.0

* GOLIAT SAR values replace the ETAIN SAR values
  * One file per phantom (Duke, Ella, Eartha, Thelonious), with their average as the default
  * Smartwatch, headphones and Bluetooth headset keep their ETAIN values
  * New argument `sar_file` to choose the SAR values, e.g. `sar_file = "goliat_average"`; the ETAIN values of version 1.0.0 remain available
* Output power parameters updated with data from GOLIAT Task 1.2
  * New 4G and 5G output powers and duty cycles of the mobile phone
  * Parameters taken from one Excel file with their sources; previous parameters in `params_v1.0.yaml`
  * `use_5g` is TRUE by default
* First version of the stochastic dose model
  * New function `calculate_emf_doses_stochastic()`: doses with parameters, SAR values and inputs drawn from their distributions
  * Argument `seed` for reproducible draws


# Version 1.0.0

* First official (not preliminary) version
* Minor update to specific parameter values
* Re-factoring and testing of top-level and helper functions functions
* Added helper functions for overwriting parameters and default values

# Version 0.3.0

* Major update to dose calculations (introduction of mSAR calculations)
* Re-factoring of most functions
* Detailed function documentation for major functions
* Planned changes: updated calculations plus functionality to supply custom default and parameter values -> will be implemented in version 0.4.0

# Version 0.2.0

* Updated parameters and functions to match newest dose model version (7.3)
* Added additional input variables to adapt calculations
* Added unit tests and reference values for validation
* Renamed package to final name RFDose

# Version 0.1.0

* Initial draft release for internal use
* Basic dose calculation function
* YAML-based parameter loading
* Preliminary validation and testing of calculations

