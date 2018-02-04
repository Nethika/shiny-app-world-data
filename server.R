#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(rgdal)
library(leaflet)
library(RColorBrewer)
library(DT)


tmp <- tempdir()
url <- "http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/cultural/ne_50m_admin_0_countries.zip"
file <- basename(url)
#download.file(url, file)
unzip(file, exdir = tmp)
world <- readOGR(dsn = tmp, layer ='ne_50m_admin_0_countries', encoding='UTF-8')
view_cols <- c("ADMIN", "CONTINENT", "SUBREGION","POP_EST","POP_RANK", "POP_YEAR", "GDP_MD_EST","GDP_YEAR","ECONOMY","INCOME_GRP")
view_data <- world@data[view_cols]

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  #############
  output$mytable = DT::renderDataTable({
    view_data
  })
  
    #################
    # Map
    # This reactive expression represents the palette function,
    # which changes as the user makes selections in UI.
    color_pal <- reactive({
      if (input$color_pal == "Population Percentiles") { pal <- colorQuantile("YlOrRd", NULL, n = 5)}
      if (input$color_pal == "Population Numbers") { pal <- colorNumeric(palette = "YlOrRd",domain = world$POP_EST)}
      if (input$color_pal == "GDP Percentiles") { pal <- colorQuantile("YlGn", NULL, n = 5)}
      if (input$color_pal == "GDP Numbers") { pal <- colorNumeric(palette = "YlGn",domain = world$GDP_MD_EST)}

      return(pal)
    })
    
  data_col <- reactive({
    if (input$color_pal == "Population Percentiles") { col <- "POP_EST"}
    if (input$color_pal == "Population Numbers") { col <- "POP_EST"}
    if (input$color_pal == "GDP Percentiles") { col <- "GDP_MD_EST"}
    if (input$color_pal == "GDP Numbers") { col <- "GDP_MD_EST"}
    
    return(col)
  })
  
  legend_title <- reactive({
    if (input$color_pal == "Population Percentiles") { title_n <- "Population"}
    if (input$color_pal == "Population Numbers") { title_n <- "Population"}
    if (input$color_pal == "GDP Percentiles") { title_n <- "GDP"}
    if (input$color_pal == "GDP Numbers") { title_n <- "GDP"}
    
    return(title_n)
  })


    
    info_popup <- paste0("<strong>Country: </strong>", 
                         world$ADMIN, 
                         "<br><strong>Continent: </strong>", 
                         world$CONTINENT,
                         "<br><strong>Sub Region: </strong>", 
                         world$SUBREGION,
                         "<br><strong>Population Estimation: </strong>", 
                         world$POP_EST,
                         "<br><strong>Population Rank: </strong>", 
                         world$POP_RANK, 
                         " (", world$POP_YEAR, ")",
                         "<br><strong>GDP Estimation: </strong>", 
                         world$GDP_MD_EST,
                         " (", world$GDP_YEAR,")",
                         "<br><strong>Economy: </strong>", 
                         world$ECONOMY,
                         "<br><strong>Income Group: </strong>", 
                         world$INCOME_GRP)
    
    output$mymap <- renderLeaflet({
      pal <- colorQuantile("YlOrRd", NULL, n = 5)
    
      leaflet(data = world) %>%
        addProviderTiles(providers$Stamen.TonerLite) %>%
        setView(25.01667, 24.86667, zoom = 1.5) %>%
      addPolygons(fillColor = ~pal(POP_EST), 
                  fillOpacity = 0.6, 
                  color = "black", 
                  weight = 1, 
                  popup = info_popup) %>% 
        addLegend(pal = pal, values = ~POP_EST, opacity = 0.6, labFormat = labelFormat(), title = "Population",
                  position = "bottomleft")
    
    })
    observe({
      pal <- color_pal()
      col <- data_col()
      title_n <- legend_title()
      
      leafletProxy("mymap", data = world) %>%
        clearShapes() %>%
        clearControls() %>% 
        addPolygons(fillColor = ~pal(world[[col]]), 
                    fillOpacity = 0.6, 
                    color = "black", 
                    weight = 1, 
                    popup = info_popup) %>% 
        addLegend(pal = pal, values = ~world[[col]], opacity = 0.6, labFormat = labelFormat(), title = title_n,
                  position = "bottomleft")
        
    })
    ############
    # Continent Data:
    output$continentSelect <- renderUI({
      selectInput("continent_n", "Select a continent to view data:", choices = unique(world$CONTINENT),selected = "North America" )
    })
    
    dataset <- reactive({
      
      datax <- world@data
      #continent_name = input$continentSelect
      continent_name = input$continent_n
      #continent_name = "North America"

      cont_data = datax[datax$CONTINENT == continent_name,]
      
      ## Filter top 10
      n <- input$n_countries
      
      topnData <- cont_data %>% 
        filter(rank(desc(POP_EST))<= n)
      
      return(topnData)
      
    })
    
    output$continentPlot <- renderPlotly({
      
      
      
      p1 <- plot_ly(dataset(),x = ~POP_EST, y = ~reorder(ADMIN, POP_EST), name = 'Population',
                    type = 'bar', orientation = 'h',
                    marker = list(color = 'rgba(255, 0, 0, 0.4)',
                                  line = list(color = 'rgba(255, 0, 0,, 0.8)', width = 1))) %>%
        layout(yaxis = list(showgrid = FALSE, showline = FALSE, showticklabels = TRUE, domain= c(0, 0.85)),
               xaxis = list(zeroline = FALSE, showline = FALSE, showticklabels = TRUE, showgrid = TRUE)) 
      
      
      p2 <- plot_ly(dataset(), x = ~GDP_MD_EST , y = ~reorder(ADMIN, POP_EST), name = 'GDP($)',
                    type = 'bar', orientation = 'h',
                    marker = list(color = 'rgba(50, 171, 96, 0.6)',
                                  line = list(color = 'rgba(50, 171, 96, 1.0)', width = 1))) %>%
        layout(yaxis = list(showgrid = FALSE, showline = TRUE, showticklabels = FALSE,
                            domain = c(0, 0.85)),
               xaxis = list(zeroline = FALSE, showline = FALSE, showticklabels = TRUE, showgrid = TRUE,
                            side = 'top', dtick = 2000000)) 
      
      
      p <- subplot(p1, p2) %>%
        layout(title = paste0('Population and GDP for the continent ',input$continent_n ,' \n (for the top ', input$n_countries, ' countries by Population)'),
               legend = list(x = 0.029, y = 1.038,
                             font = list(size = 10)),
               margin = list(l = 100, r = 20, t = 70, b = 70),
               paper_bgcolor = 'rgb(248, 248, 255)',
               plot_bgcolor = 'rgb(248, 248, 255)') 
      p
      
    })
    
    ############
    # Linear Model:
    model <- reactive({
      brushed_data <- brushedPoints(world, input$brush1,
                                    xvar = "POP_EST", yvar = "GDP_MD_EST")
      if(nrow(brushed_data) < 2){
        return(NULL)
      }
      lm(GDP_MD_EST ~ POP_EST, data = brushed_data)
    })
    
    output$slopeOut <- renderText({
      if(is.null(model())){
        "No Model Found"
      } else {
        model()[[1]][2]
      }
    })
    
    output$intOut <- renderText({
      if(is.null(model())){
        "No Model Found"
      } else {
        model()[[1]][1]
      }
    })
    
    output$plot1 <- renderPlot({
      #sp <- ggplot(data=world@data, aes(x=POP_EST, y=GDP_MD_EST)) + geom_point()
      plot(world$POP_EST, world$GDP_MD_EST, xlab = "Population",
           ylab = "GDP", main = "Linear Model",
           cex = 1.5, pch = 16, bty = "n")
      if(!is.null(model())){
        #sp <- sp + geom_abline(intercept = model()[[1]][1], slope = model()[[1]][2], color="red",  size=1.5)
        abline(model(), col = "blue", lwd = 2)
        #ggplotly(sp)
      }
      #else ggplotly(sp)
    })
    ###############
    
  })
  

