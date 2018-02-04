#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(rgdal)
library(leaflet)
library(dplyr)
library(plotly)
library(shinythemes)
library(RColorBrewer)
library(DT)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  #theme
  theme = shinytheme("flatly"),
  # Application title
  titlePanel("World Population and GDP"),
  
  #tabs
  navbarPage("An App to Visualize and Analyse Population and GDP Data for the Countries",
  
    tabPanel("Data in a Map",
            mainPanel(
              bootstrapPage(div(class="outer",
                tags$style(type = "text/css", ".outer {position: fixed; top: 200px; left: 0; right: 0; bottom: 0; overflow: hidden; padding: 0}"),
                                
               leafletOutput("mymap", width = "100%", height = "100%"),
               absolutePanel(top = 10, right = 10,
                             selectInput("color_pal", "Select Data format:",
                                        c("Population Percentiles", "Population Numbers", "GDP Percentiles", "GDP Numbers"),
                                        selected = "Population Percentiles"))
                             
              )))
            ),
    tabPanel("Continent Data",
            mainPanel(
              plotlyOutput("continentPlot",width = "800", height = "500"),
              hr(),
              fluidRow(
                column(width = 5,
                       uiOutput("continentSelect")
                ),
                column(width = 5, offset = 1,
                       sliderInput("n_countries",
                                   "Select number of countries to view:",
                                   min = 1,
                                   max = 30,
                                   value = 10)
                  )
                )
              
              )
            ),
    tabPanel("Linear Model",
           sidebarLayout(
             sidebarPanel(h3("Model Fit for Population Vs GDP"),
                          h4("Select brush points to see calculate and view the linear model"),
                          h4("Slope:"),
                          textOutput("slopeOut"),
                          h4("Intercept:"),
                          textOutput("intOut")
                          ),
             mainPanel(
                plotOutput("plot1", brush = brushOpts(id = "brush1"))
                )
             )
       ),
    tabPanel("View Data",
             h2("World Data Set"),
             DT::dataTableOutput("mytable")
    ),
    tabPanel("Documentation", includeMarkdown("documentation.md")

             

             )

    )
  ))

