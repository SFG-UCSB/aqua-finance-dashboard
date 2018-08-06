shinyServer(function(input,output){
  
  
  
  df <- reactive(data.frame(
    year = seq(1:input$years),
    costs = cost_projection(input$num_acres, input$years),
    revenue = sapply(input$num_acres, revenue)) %>%
    mutate(NPV = (revenue - costs)/(1+discount)^(year-1),
                          cum_prof = cumsum(NPV)))
  
  
  
  output$financePlot <- renderPlot({
    ggplot(df(), aes(x = year, y = cum_prof/1000000))+ geom_hline(yintercept = 0, linetype = 5)+geom_line(size = 1.05) +theme_classic(base_size = 14)+labs(x = "Year", y = "NPV (USD Millions)") 
    })
  
  output$ledger <- renderTable({
    df()
  })
  

  output$aquamap <- renderLeaflet({
    leaflet() %>% 
      setView(lng = -119.4, lat = 34.286, zoom = 10) %>% 
      addProviderTiles(providers$Stamen.Terrain) %>% 
      addPolygons(data = sps, color = "#444444", weight = 1, smoothFactor = 0.5,
                  opacity = 1.0, fillOpacity = 0.5)
      
  })
})
