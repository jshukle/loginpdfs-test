#This script generates login cards that customers can use to access SELweb. Please update the file name of the roster file (roster_file_name). 
#Ensure that the input file matches the format to the provided sample file. 
# Login cards (both pdf and html format) will be placed in the "output" folder in the "login_cards" project

# library(tidyverse)
library(pagedown)
library(data.table)
library(lubridate)
# library(here)

roster_file_name <- "pickford_time2.csv"


logo <- here("scripts", "xSEL\ Favicon\ Final.png")

today <- today()

roster_full <- read_csv(here("rosters", roster_file_name), col_types = cols(abv = col_character())) 



data_datatable <- data.table(roster_full)
school_teacher_xwalk <- data_datatable[ , .(number_of_students = .N), by = c("school", "class", 
                                                                             "district", 
                                                                             "abv", "project")]


all_districts <- unique(school_teacher_xwalk$district)
#a <- all_districts[1]                     

for (a in all_districts) {
  district_name_nice <- tolower(gsub(" ", "_", a))
  district_name_nice_date <- paste0(district_name_nice, "_", today)
  dir.create(here("output", district_name_nice_date), showWarnings = F, recursive = T)
  
  all_schools <- unique(school_teacher_xwalk[school_teacher_xwalk$district == a,]$school)
  #i <- all_schools[1]
  
  for (i in all_schools) {
    school_name_nice <- tolower(gsub(" ", "_", i))
    school_dir <- here("output", district_name_nice_date, school_name_nice)
    
    dir.create(here("output", district_name_nice_date, school_name_nice), showWarnings = F, recursive = T)
    
    file.copy(logo, (here("output", district_name_nice_date, school_name_nice)))
    
    
    all_classes <- unique(school_teacher_xwalk[school_teacher_xwalk$district == a & 
                                                 school_teacher_xwalk$school == i,]$class)
    
    #j <- all_classes[6]
    
    for (j in all_classes){
      control_row <- school_teacher_xwalk[school_teacher_xwalk$district == a & 
                                            school_teacher_xwalk$school == i & class == j, ]
      
      teacher_name_nice <- tolower(gsub(" ", "_", control_row$class))[1]
      
      
      
      pagedown::chrome_print(rmarkdown::render(here("scripts", "login_cards_class.Rmd"),
                                               output_file = paste0(school_dir, "/", teacher_name_nice,".html"), 
                                               params = list(prefix = control_row[control_row$class==j,]$abv, 
                                                             school = i, class = j)), format = "pdf")
      
    }
    
  }
  
}
