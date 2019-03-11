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
