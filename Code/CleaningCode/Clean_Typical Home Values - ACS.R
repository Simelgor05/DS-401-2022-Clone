library(tidyverse)
library(tidycensus)

# Use Table B25077 Median Value (Dollars) from ACS 2016-20
unit_value <- get_acs(
  geography = "county",
  state = "Iowa",
  variables = c(MedianValue = "B25077_001"),
  year = 2020, 
  cache_table = T, 
  output = "wide"
) %>%
  rename(MedianValue= MedianValueE,
         MedianValueMOE=MedianValueM,
         FIPS = GEOID) %>%
  mutate(MOEPct = MedianValueMOE / MedianValue * 100) %>%
  arrange(FIPS) %>%
  select(FIPS, MedianValue)
View(unit_value)

write.csv(unit_value, "Data/CleanData/Indicator_TypicalHomeValues.csv",
          row.names = F)
