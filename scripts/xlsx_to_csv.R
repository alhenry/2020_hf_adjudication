# convert code_list to csv for USAGI

pacman::p_load(readxl, fs, tidyverse)

latest_file <- dir_ls("results/", glob = "*phenotype_adjudication.xlsx") %>% 
  sort(decreasing = T) %>% 
  .[[1]]

data <- excel_sheets(latest_file) %>% 
  map(~read_xlsx(latest_file, sheet = .x)) %>% 
  discard(~nrow(.x) == 0) %>% 
  bind_rows

outfile <- latest_file %>% str_replace("\\.xlsx", ".csv")
write_csv(data, outfile)
