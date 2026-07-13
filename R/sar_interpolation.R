library(readxl)
library(dplyr)
library(tidyr)

file = "Duke_male_adult.xlsx"
sheet = "Duke_ear_normalized"
prefix = "Duke_ear"

df <- read_excel(file, sheet = sheet)
df <- dplyr::select(df, -`Average_brain (W/kg)`, -`Average_WB (W/kg)`)


ziel_freq <- c(700, 800, 900, 1450, 1800, 2100, 2400, 2600, 3500, 5000)

num_cols <- df %>%
  select(where(is.numeric), -frequency_mhz) %>%
  names()

df_interp <- df %>%
  group_by(placement) %>%
  complete(frequency_mhz = ziel_freq) %>%
  arrange(frequency_mhz, .by_group = TRUE) %>%
  mutate(
    across(
      all_of(num_cols),
      ~ approx(
        x = frequency_mhz[!is.na(.x)],
        y = .x[!is.na(.x)],
        xout = frequency_mhz,
        rule = 1
      )$y
    )
  ) %>%
  filter(frequency_mhz %in% ziel_freq) %>%
  ungroup()

df_interp <- df_interp %>% mutate(
  yaml_name_whole_body = paste0(prefix, "_",frequency_mhz,"_",placement,": ",`SAR_wholebody (mW/kg)`),
  yaml_name_whole_brain = paste0(prefix, "_",frequency_mhz,"_",placement,": ",`SAR_brain (mW/kg)`)
)

write.csv(df_interp, file = paste0("data/",sheet,"_interpol.csv"))

