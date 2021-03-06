library(rvest)
library(polite)
library(tidyverse)
library(here)

session <- bow("https://iditarod.com/race/2019/logs/", force = TRUE)

# Get links to all logs
log_pages <- scrape(session)  %>% #, params="t=semi-soft&per_page=100") %>%
  html_nodes(".post-content") %>%
  map(~html_nodes(., "a"))  %>%
  pluck(1)  %>%
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


# Check what logs have loaded
log_existing <- readRDS(here("/data/log_all.RDS"))

log_missing <- log_text_clean %>%
  anti_join(log_existing %>% select(log_number))


# Get locations and distance

loc_dist <- tibble::tribble(
                      ~Checkpoint, ~Distance,
                      "Anchorage",         0,
              "Campbell Airstrip",        11,
                         "Willow",        11,
                         "Yentna",        53,
                       "Skwentna",        83,
                    "Finger Lake",       123,
                     "Rainy Pass",       153,
                           "Rohn",       188,
                        "Nikolai",       263,
                        "McGrath",       311,
                        "Takotna",       329,
                          "Ophir",       352,
                       "Iditarod",       432,
                       "Shageluk",       487,
                          "Anvik",       512,
                       "Grayling",       530,
                   "Eagle Island",       592,
                         "Kaltag",       652,
                     "Unalakleet",       737,
                     "Shaktoolik",       777,
                          "Koyuk",       827,
                           "Elim",       875,
                 "White Mountain",       921,
                         "Safety",       976,
                           "Nome",       998
              ) %>%
  mutate(Distance_from_prior = Distance - lag(Distance))




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

missing_log_table <- log_pages %>%
  enframe() %>%
  mutate(log_number = str_sub(value, 37, 39)) %>%
  right_join(log_missing)


# Takes about 10 minutes to run if all...
log_new <- map_df(missing_log_pages$value,
                  scrape_func, .id = "src")

log_all_clean <- log_new %>%
  mutate(src = parse_integer(src)) %>%
  left_join(log_text_clean, by = c("src" = "row"))

log_all_clean2 <- log_all_clean %>%
  separate(InTime, into = c("InTimeDt", "InTimeTime"), sep = " ", remove = FALSE) %>%
  mutate(InTime2 = lubridate::mdy_hms(paste0(InTimeDt, "/19 ", InTimeTime))) %>%
  separate(OutTime, into = c("OutTimeDt", "OutTimeTime"), sep = " ", remove = FALSE) %>%
  mutate(OutTime2 = lubridate::mdy_hms(paste0(OutTimeDt, "/19 ", OutTimeTime)))



### TO DO - INTEGRATE
# log_all_clean %>%
#   mutate(InTime = convert_time(InTime),
#          OutTime = convert_time(OutTime),
#          PreviousTimeOut = convert_time(PreviousTimeOut))


saveRDS(log_all_clean, here("/data/log_new.RDS"))

