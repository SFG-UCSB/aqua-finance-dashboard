shinyServer(function(input,output){
  df <- reactive(data.frame(
    year = seq(1:input$years),
    costs = c(input$op_costs+input$init_costs,rep(input$op_costs, input$years-1)),
    revenue = rep(as.numeric(input$size) * input$mussPrice * mussels_longline, input$years)) %>%
    mutate(NPV = (revenue - costs)/(1+discount)^(year-1),
                          cum_prof = cumsum(NPV)))
  
  
  
  output$financePlot <- renderPlot({
    ggplot(df(), aes(x = year, y = cum_prof))+geom_line()})
  

  output$aquamap <- renderLeaflet({
    leaflet() %>% 
      setView(lng = -119.4, lat = 34.286, zoom = 10) %>% 
      addProviderTiles(providers$Stamen.Terrain) %>% 
      addPolygons(data = sps, color = "#444444", weight = 1, smoothFactor = 0.5,
                  opacity = 1.0, fillOpacity = 0.5)
      
  })
})
