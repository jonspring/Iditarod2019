library(rvest)
library(polite)
library(tidyverse)
library(here)

session <- bow("https://iditarod.com/race/2019/logs/", force = TRUE)

log_pages <- scrape(session)  %>% #, params="t=semi-soft&per_page=100") %>%
  html_nodes(".post-content") %>%
  map(~html_nodes(., "a")) %>%
  pluck(1) %>%
  xml_attr("href")

# Now that we know the available pages, scrape.



# Test with one page
session2 <- bow(log_pages[1], force = TRUE)

log_raw <- scrape(session2) %>%
  html_nodes(".post-content") %>%
  pluck(1) %>%
  html_node("table") %>%
  html_table(fill = TRUE, header = T)


