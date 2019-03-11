library(rvest)
library(polite)
library(tidyverse)
library(here)

session <- bow("https://iditarod.com/race/2019/logs/", force = TRUE)

# Get links to all logs
log_pages <- scrape(session)  %>% #, params="t=semi-soft&per_page=100") %>%
  html_nodes(".post-content") %>%
  map(~html_nodes(., "a")) %>%
  pluck(1) %>%
  xml_attr("href")


# Get timestamps of all logs
log_text <- scrape(session)  %>% #, params="t=semi-soft&per_page=100") %>%
  html_nodes(".post-content") %>%
  html_text() %>%
  str_split("\n", simplify = T)
log_text <- log_text[-1]                # Remove first element
log_text <- log_text[-length(log_text)] # Remove last element

log_text_clean <- log_text %>%
  matrix(ncol = 2,byrow = TRUE) %>%
  as_tibble()
colnames(log_text_clean) <- log_text_clean[1,]
log_text_clean <- log_text_clean[-1,]                # Remove first element
log_text_clean <- log_text_clean %>%
  janitor::clean_names() %>%
  mutate(log_number = gsub("[[:space:]]", "", log_number),
         created = str_trim(created),
         created_dt = lubridate::mdy_hm(created),
         row = row_number())



# Now that we know the available pages, scrape.
scrape_func <- function(dest) {

  session2 <- bow(dest, force = TRUE)

  log_raw <- scrape(session2) %>%
    html_nodes(".post-content") %>%
    pluck(1) %>%
    html_node("table") %>%
    html_table(fill = TRUE, header = T)

  message(dest)

  log_clean <- log_raw %>%
    janitor::clean_names() %>%
    select(-layover_completed, -layover_completed_2, -status)
  colnames(log_clean) = c("Pos", "Musher", "Bib", "Checkpoint", "InTime", "InDogs",
                          "OutTime", "OutDogs", "RestInCheckp", "TimeEnroute",
                          "PreviousCheckpoint", "PreviousTimeOut", "Speed")
  log_clean <- log_clean %>%
    filter(row_number() != 1)
}


# Takes about 10 minutes to run...
log_all <- map_df(log_pages, scrape_func, .id = "src")


saveRDS(log_all, here("/data/log_all.RDS"))

