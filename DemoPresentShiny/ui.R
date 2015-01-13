library(shiny)

finalResultDF <- read.csv(".//data//finalResultDF.csv")

# Define the overall UI
shinyUI(
  fluidPage(
    titlePanel("Find Big Data Jobs"),
    
    # Create a new Row in the UI for selectInputs
    fluidRow(
      column(4, 
             selectInput("companyName", 
                         "CompanyName:", 
                         c("All", 
                           unique(as.character(finalResultDF$NAME))))
      ),
      column(4, 
             selectInput("companyJob", 
                         "Job:", 
                         c("All", 
                           unique(as.character(finalResultDF$JOB))))
      ),      
      column(4, 
             selectInput("companyLink", 
                         "Link:", 
                          c("All", 
                          unique(as.character(finalResultDF$LINK))))
      )


    ),
    # Create a new row for the table.
    fluidRow(
      dataTableOutput(outputId="table")
    )    
  )  
)