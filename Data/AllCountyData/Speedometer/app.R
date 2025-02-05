#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
library(plotly)
library(shiny)
library(ggplot2)
library(readxl)
library(tidyverse)
library(readr)
##IMPORTANT NEED TO FIGURE OUT DIRECTORY
##Should be able to move it to ALL Countries Data folder and be fine

##Overall Dataset
##IMPORTANT assumes this dataset has a column named "county_name" with county names
data <- read_csv("OverallDatabase.csv")

IndicatorGroup<- read_excel("indicator_definitions.xlsx")

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
    
    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(
        tabPanel("", plotlyOutput("Plot")), 
        tabPanel("", 
                 selectInput("county", "Select A County", choices = unique(data$county_name)),
                 selectInput("indicator", "Select an Indicator", choices = colnames(data)[3:ncol(data)]))
      )
    )
    
    )
  


# Define server logic
server <- function(input, output, session) {
  
  ##This observe feature is used to make it possible to take inputs from tableau
  ##When User selected a specific indicator and filters on Tableau, Tableau opens a web page as an object
  ##With The selected county and indicator as parameters in URL
  ##as long as the names in tableau match with names in R, should work
  ##Users do not type the name, it is a given list to minimize errors.
  observe({
    ##obtains Query Data from URL
    query <- parseQueryString(session$clientData$url_search)
    
    county1 <-query[['county']]
    indicator <- query[['indicator']]
    
    ##Because URL querys replaces Spaces with %20, we need to change them back
    county1<- gsub("%20", " ",county1)
    indicator<- gsub("%20", " ",indicator)
    
    ##If the user does make a selection update the inputs for our Shiny App
    if (!is.null(query[['county']])) {
      updateSelectInput(session, "county", selected = county1)
    }
    if (!is.null(query[['indicator']])) {
      updateSelectInput(session, "indicator", selected = indicator)
    }
  })
  
  output$Plot <- plotly::renderPlotly({
    
    ##From our Overall Dataset, Selects the county name and indicator from either Shiny input or Tableau input
    Data <- data%>%
      select(county_name,value =input$indicator)
    IndexForColor <- which(IndicatorGroup$Name == input$indicator)
    Reverse <- IndicatorGroup$`Higher is better`[IndexForColor]
    ##finds the Quartile (But For 3 instead) value breaks
    quartiles <- quantile(Data$value, na.rm =TRUE, probs = seq(0, 1, 1/3))
    
    ##Determines for each County what quartile it is in for selected indicator
    ##Calculates The state average and the county median
    TotalData<- Data %>%
      mutate(quartile = ifelse(value>quartiles[3],3,
                               ifelse(value>quartiles[2],2,
                                      1)))%>%
      mutate(StateAverage = mean(value, na.rm =TRUE),CountyMedian = median(value, na.rm =TRUE))
    
    ##Stores the County that is selected by user
    SelectedCounty <- filter(TotalData, TotalData$county_name == input$county)
    
    ##Creating a Speedometer
    plot_ly(
      domain = list(x = c(0, 1), y = c(0, 1)),
      value = SelectedCounty$value ,  #Indicator we are looking at
      type = "indicator",
      mode = "gauge+number",
      gauge = list(
        axis = list(range = list(min(TotalData$value, na.rm=TRUE), max(TotalData$value, na.rm=TRUE))), #min and max values of graph
        steps = list(
          list(range = c(quartiles[1],quartiles[2]), color = ifelse(Reverse == "F","#4e79a7","#f28e2b")), #adding value ranges by quartile
          list(range = c(quartiles[2],quartiles[3]), color = "grey"), #adding value ranges by quartile
          list(range = c(quartiles[3],quartiles[4]), color = ifelse(Reverse == "F","#f28e2b","#4e79a7"))),
        threshold = list(
          line = list(color = "black", width = 4),
          thickness = 1,
          value = SelectedCounty$CountyMedian),
        labels="State Average",
        bar = list(
          color ="red"))
    )%>%
      ##Used To label
      ## Not connected to Speedometer
      ##Have to Change Values depending on speedometer placement
      layout(margin = list(l=30,r=30)) %>%
      add_annotations(
        x= 0.5,
        y=0.05,
        text = "Black Bar is the County Median",
        showarrow = F
      ) %>%
      add_annotations(
        x= 0.5,
        y=0.5,
        text = SelectedCounty$county_name,
        size= 20,
        showarrow = F
      )
  })
}


# Run the application 
shinyApp(ui = ui, server = server)
