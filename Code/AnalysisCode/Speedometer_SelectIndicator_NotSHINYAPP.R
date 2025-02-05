library(ggplot2)
library(readxl)
library(tidyverse)
library(readr)
library(ggmap)


##Insert csv of Data
Data <- read_csv("Data\\CleanData\\Ready_HUD_HCV.csv", col_names  = TRUE)


##INPUT country you want to select
County_Name <-"19013"

##INPUT Graph Title
GraphTitle = "Housing Choice Voucher Per Houshold Percent"





##rename to standard names, if DATA is not in this column format won't work
colnames(Data)<- c("NAME","value")


##Get quartile range
quartiles <- quantile(Data$value, na.rm =TRUE, probs = seq(0, 1, 1/3))
TotalData <- Data %>%
  mutate(quartile = ifelse(value>quartiles[3],3,
                                  ifelse(value>quartiles[2],2,
                                         1)))%>%
  ##removes ', Iowa' from name
  mutate(StateAverage = mean(value, na.rm =TRUE),CountyMedian = median(value, na.rm =TRUE))


SelectedCounty <- filter(TotalData, TotalData$NAME == County_Name)


##Graphh Creation
library(plotly)
#https://plotly.com/r/gauge-charts/

plot_ly(
  domain = list(x = c(0, 1), y = c(0, 1)),
  value = SelectedCounty$value ,  #value were looking at
  title = list(text = GraphTitle),
  type = "indicator",
  mode = "gauge+number+delta",
  delta = list(reference =  SelectedCounty$StateAverage, decreasing = list(color = "green"),increasing = list(color ='red')),
  gauge = list(
    axis = list(range = list(min(TotalData$value, na.rm=TRUE), max(TotalData$value, na.rm=TRUE))), #min and max values of graph
    steps = list(
      list(range = c(quartiles[1],quartiles[2]), color = "blue"), #adding value ranges by quartile
      list(range = c(quartiles[2],quartiles[3]), color = "yellow"), #adding value ranges by quartile
      list(range = c(quartiles[3],quartiles[4]), color = "red")),
    threshold = list(
      line = list(color = "brown", width = 3),
      thickness = 0.75,
      value = SelectedCounty$StateAverage),
    labels="State Average",
    bar = list(
      color ="black"))
) %>%
  layout(margin = list(l=30,r=30)) %>%
  add_annotations(
    x= 0.5,
    y=0.18,
    text = "Brown Bar is the State Average",
    showarrow = F
  ) %>%
  add_annotations(
    x= 0.5,
    y=0.52,
    text = SelectedCounty$NAME,
    size= 16,
    showarrow = F
)


