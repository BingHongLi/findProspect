library(shiny)

finalResultDF <- read.csv(".//data//finalResultDF.csv")

# Define a server for the Shiny app
shinyServer(function(input, output) {
  
  # Filter data based on selections
  output$table <- renderDataTable({
    data <- finalResultDF
    if (input$companyName != "All"){
      data <- data[data$NAME == input$companyName,]
    }
    if (input$companyJob != "All"){
      data <- data[data$JOB == input$companyJob,]
    }
    if (input$companyLink != "All"){
      data <- data[data$LINK == input$companyLink,]
    }

    data
  })
  
})