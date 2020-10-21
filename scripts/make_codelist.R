# Scripts to extract Gsheet, make code list and make table for adjudication

if (!require("CALIBERcodelists")){
  install.packages("CALIBERcodelists", repos="http://R-Forge.R-project.org")  
}

# install CALIBERlookups from local (to update library)
# install.packages("~/Downloads/CALIBERlookups_0.1-7.tar.gz", repos = NULL,
#                  type="source")

pacman::p_load(CALIBERcodelists, CALIBERlookups, glue,
               tidyverse, googlesheets4, googledrive)

# read in google sheets
URL <- "https://docs.google.com/spreadsheets/d/1FFMXcmpk8tdhl3wKusHGjqK_pEh6RYoLrZMszHqTOEU/edit#gid=1504572823"
df <- read_sheet(URL, skip = 1, na = c("", "na", "NA"))


df_search <- df %>% 
  mutate(across(c(regexp,regexp_negation),
                ~map(.x, function(.y) str_match_all(.y, '(?s)"(.*?)"') %>% .[[1]] %>% .[,2])))

term_lookup <- function(regexp, regexp_negation, dict_select = list('read', 'icd10', 'opcs')){
  
  regexp <- glue_collapse(regexp, "|") %>% glue("(?i)", .)
  
  dict_lookup <- CALIBER_DICT[dict %in% dict_select]
  dict_lookup[,dict := factor(dict, levels = as.character(dict_select))]
  
  DT <- dict_lookup[str_detect(term, regexp)]
  if (!is.na(regexp_negation)){
    regexp_negation <- glue_collapse(regexp_negation, "|") %>% glue("(?i)", .)
    DT <- DT[str_detect(term, regexp_negation, negate = T)]  
  }
  
  DT[,`include?` := TRUE]
  # DT_all <- map(dict, function(d){
  #   setdictionary(d)
  #   DT <- as.codelist(termhas(regexp))
  #   DT[,source := d]
  #   DT
  # }) %>% rbindlist(fill = T)
  # 
  # DT[,`include?` := TRUE]
  # if (!is.na(regexp_negation)){
  #   DT_all <- DT_all[str_detect(term, regexp_negation, negate = T)]  
  # }
  
  DT[order(dict),.(dict, code, term, medcode, events, `include?`)]
}

df_target <- df_search %>% filter(!is.na(regexp))

list_lookup <- map2(df_target$regexp, df_target$regexp_negation, term_lookup) %>% 
  set_names(df_target$`Data elements` %>% str_replace_all("\n", " "))


# create and write to gsheets
filename <- glue("{Sys.Date()}_phenotype_adjudication")
gs4_create(filename, sheets = list_lookup)
drive_mv(filename, path = "~/MCLprojects/ehr_phenotype/")
ss <- drive_get(glue("~/MCLprojects/ehr_phenotype/{filename}")) %>% 
  .$id

# sheet_names <- sheet_properties(ss)$name
# 
# # delete if not in target
# walk(setdiff(sheet_names, df_target$`Data elements`),
#      ~sheet_delete(ss, .x))

# update sheet
for (x in names(list_lookup[-1])){
  sheet_write(data = list_lookup[[x]], ss = ss, sheet = x)
}
iwalk(list_lookup[-1], ~sheet_write(data = .x, ss = ss, sheet = .y))

# to excel
names(list_lookup) %<>%
  str_replace_all("\n", " ") %>% 
  str_remove_all("[[:punct:]]")
  
writexl::write_xlsx(list_lookup, fs::path("results", glue(filename, ".xlsx")))



