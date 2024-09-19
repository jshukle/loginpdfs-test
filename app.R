# Project uses renv v.1.0.7
# renv::init()
# renv::status()
# renv::snapshot()

# create manifest.json file for posit cloud hosting
# rsconnect::writeManifest()

# remotes::install_version("rmarkdown", version = "2.20", repos = "http://cran.us.r-project.org")
# https://stackoverflow.com/questions/17082341/installing-older-version-of-r-package

# remotes::install_github("JohnCoene/waiter")

# load shiny
library(shiny)
library(waiter)

# load packages from Maria's former code here for now (look to remove later)
library(data.table)
library(lubridate)
library(purrr)

# these libraries loaded here for webshot2
library(webshot2)
library(pagedown)
library(curl)

# source modules for app
source("scripts/modules/csvInputModule.R")
source("scripts/modules/processDataModule.R")
source("scripts/modules/renderPDFsModule.R")

ui <- fluidPage(
  waiter::useWaitress(),
  sidebarLayout(
    sidebarPanel(
      csvInputUI("dataInput", "User data (.csv format)"),
      renderPDFsUI("renderPDFs")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Input", dataTableOutput("inputTable")),
        tabPanel("xWalk", dataTableOutput("xWalkTable"))
      )
    )
  )
)

server <- function(input, output, session) {
  
  inputData <- csvInputServer("dataInput", stringsAsFactors = FALSE)
  
  processedData <- reactive({
    processInputData("dataProcess", inputData = inputData)
  })
  
  output$inputTable <- renderDataTable({
    inputData()
  })
  
  output$xWalkTable <- renderDataTable({
    processedData()$school_teacher_xwalk
  })
  
  renderPDFsServer("renderPDFs", processedData = processedData)

}

shinyApp(ui, server)