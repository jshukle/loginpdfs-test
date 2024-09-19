# Module UI function
renderPDFsUI <- function(id) {
  # `NS(id)` returns a namespace function, which was save as `ns` and will
  # invoke later.
  ns <- NS(id)
  
  tagList(
    # actionButton(ns("render"), "Render Login PDFs")
    downloadButton(
      style = "width: 100%;",
      outputId = ns('render'),
      label = "Render Login PDFs",
      icon = icon("file-pdf"),
      class = "btn-primary"
      )
  )
}

# Module server function
renderPDFsServer <- function(id, processedData) {
  moduleServer(
    id,
    ## Below is the module function
    function(input, output, session) {
      
      waitress <- Waitress$new("#renderPDFs-render", theme = "overlay-percent") # call the waitress
      
      #### Report creation and output
      output$render <- downloadHandler(
        filename = function() {
          paste("login_cards_teacher.zip")
        },
        content = function(file) {
          
          waitress$start(
              div(
                style = "position:fixed;
                        top:200px;
                        left:25px;
                        color: white; background: #666666; opacity: .8;
                        z-index: 1000;",
                h3(
                  # style = "margin-top: 100px;",
                  "Generating login PDFs ..."
                )
              )
            ) # call waitress
          
          # create temp dir
          tmpdir <- tempdir()
          
          # cleanup any prior files within directory
          files <- list.files(tmpdir, full.names = TRUE, recursive = TRUE)
          unlink(files)
          dirs <- list.dirs(file.path(tmpdir, "output"), full.names = TRUE, recursive = TRUE)
          unlink(dirs, recursive=TRUE)
          # list.dirs(tmpdir, full.names = TRUE, recursive = TRUE)
          
          processedData <- processedData()
          
          # copy over.rmd template
          rmd_in_path <- "scripts/report_templates/login_cards_teacher.Rmd"
          rmd_tmp_path <-  file.path(tmpdir, basename(rmd_in_path))
          file.copy(rmd_in_path, rmd_tmp_path, overwrite = TRUE)
          
          # copy over card html template
          html_template_in_path <- "scripts/report_templates/customcard.html"
          html_template_tmp_path <-  file.path(tmpdir, basename(html_template_in_path))
          file.copy(html_template_in_path, html_template_tmp_path, overwrite = TRUE)
          
          # logo path
          logo_in_path <- "scripts/images/Insight_favicon.png"
          logo_tmp_path <-  file.path(tmpdir, basename(logo_in_path))
          file.copy(logo_in_path, logo_tmp_path, overwrite = TRUE)
          
          # Set the working directory to the temporary directory
          appwd <- getwd()
          setwd(tmpdir)
          
          for (a in processedData$all_districts) {
            
            wait_percent <- (1/length(processedData$all_districts))*100
            waitress$inc(wait_percent) # increase by wait_percent
            
            district_name_nice <- tolower(gsub(" ", "_", a))
            district_name_nice_date <- paste0(district_name_nice, "_", lubridate::today())
            district_dir <- file.path(tmpdir, "output", district_name_nice_date)
            dir.create(district_dir, showWarnings = F, recursive = T)

            all_schools <- unique(processedData$school_teacher_xwalk[processedData$school_teacher_xwalk$district == a,]$school)

            for (i in all_schools) {
              
              school_name_nice <- tolower(gsub(" ", "_", i))
              school_dir <- file.path(tmpdir, "output", district_name_nice_date, school_name_nice)

              dir.create(school_dir, showWarnings = F, recursive = T)

              file.copy(logo_tmp_path, school_dir, overwrite = TRUE)

              all_classes <- unique(processedData$school_teacher_xwalk[processedData$school_teacher_xwalk$district == a & 
                                                                         processedData$school_teacher_xwalk$school == i,]$class)
              
              for (j in all_classes){
                
                control_row <- processedData$school_teacher_xwalk[processedData$school_teacher_xwalk$district == a & 
                                                                    processedData$school_teacher_xwalk$school == i & class == j, ]
                
                teacher_name_nice <- tolower(gsub(" ", "_", control_row$class))[1]
                
                card_html_path <- paste0(school_dir, "/", teacher_name_nice,".html")
                card_pdf_path <- paste0(school_dir, "/", teacher_name_nice,".pdf")
                
                rmarkdown::render(
                  input = rmd_tmp_path,
                  output_file = card_html_path,
                  params = list(
                    roster = processedData$roster_full,
                    prefix = control_row[control_row$class==j,]$abv,
                    school = i,
                    teacher = j
                  )
                )
                
                webshot2::webshot(
                  url = paste0("file://", school_dir, "/", teacher_name_nice,".html"), 
                  file = paste0(school_dir, "/", teacher_name_nice,".pdf"), 
                  delay = 2
                  )
                
              }
              
            }
            
          }
          
          # browser()
          # list.files(getwd(), full.names = TRUE)
          
          zip::zipr(
            root = tmpdir,
            zipfile = "login_cards_teacher.zip",
            files = file.path(tmpdir, "output")
          )
          
          card_out_path <- file.path(tmpdir, "login_cards_teacher.zip")
          
          file.copy(card_out_path, file)

          waitress$close() # hide when done
          
          on.exit(setwd(appwd))

        }
      )
      
      # Return the reactive that yields the data frame
      # return(dataframe)
    }
  )    
}