# Map SNOMED domain ID post-Usagi

pacman::p_load(readxl, fs, tidyverse)

latest_file <- dir_ls("results/", glob = "*phenotype_adjudication.xlsx") %>% 
  sort(decreasing = T) %>% 
  .[[1]]
latest_usagi_map <- dir_ls("results/", glob = "*usagi*.csv") %>% 
  sort(decreasing = T) %>% 
  .[[1]]

usagi_map <- read_csv(latest_usagi_map) %>% 
  select(code = sourceCode, SNOMED_domain = targetDomainId)

data <- excel_sheets(latest_file) %>% set_names(.) %>% 
  map(~read_xlsx(latest_file, sheet = .x) %>%
        mutate(code = as.character(code)) %>% 
        left_join(usagi_map, by = "code") %>% 
        select(dict:events, SNOMED_domain, `include?`))

# write_back to excel
outfile <- latest_file %>% str_replace("\\.xlsx$", "_wDomain.xlsx")

writexl::write_xlsx(data, outfile)
