# Module server function
processInputData <- function(id, inputData) {
  moduleServer(
    id,
    ## Below is the module function
    function(input, output, session) {
      
      inputData <- inputData()
      
      data_datatable <- data.table(inputData)
      school_teacher_xwalk <- data_datatable[ , .(number_of_students = .N), by = c("school", "class","district","abv", "project")]
      
      
      all_districts <- unique(school_teacher_xwalk$district)
      
      
      # Return list with data tables
      return(
        list(
          roster_full = inputData,
          school_teacher_xwalk = school_teacher_xwalk,
          all_districts = all_districts
        )
      )
    }
  )    
}