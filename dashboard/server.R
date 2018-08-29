shinyServer(function(input,output){
  
  
  run_model <- reactive({
    
output <- production_model(
  species = input$species,
  farm_size = input$farm_size,
  time_horz = input$time_horz,
  discount = input$discount,
  unit_area = input$units_area,
  ind_unit = input$ind_unit,
  monthly_growth = annualRates(input$growth),
  monthly_death = input$death,
  init_size = input$init_size,
  harvest_size = input$harvest_size,
  price = input$sales_price,
  fixed_init_cost = input$fixed_init,
  size_var_init_cost = input$var_init,
  harv_cost = input$harv_cost,
  restock_cost = input$restock_cost,
  monthly_op_cost = input$monthly_op,
  annual_maintenance_cost = input$annual_maitenance
)
   return(output)     
  })
 
  output$CashflowPlot <- renderPlot({
    ggplot(run_model(), aes(x = Month, y = Revenue/1000))+ geom_hline(yintercept = 0, linetype = 5)+geom_line(size = 1.05, color = "forestgreen") +theme_classic(base_size = 14)+labs(x = "Month", y = "USD Thousands")+geom_line(aes(x = Month, y = Cost/1000), size = 1.05, color = "firebrick3")
  })
  
  
  output$NPVPlot <- renderPlot({
    ggplot(run_model(), aes(x = Month, y = NPV/1000000))+ geom_hline(yintercept = 0, linetype = 5)+geom_line(size = 1.05) +theme_classic(base_size = 14)+labs(x = "Month", y = "NPV (USD Millions)")
    })
  
  output$ledger <- renderTable({
    run_model()
  })
  

  output$aquamap <- renderLeaflet({
    leaflet() %>% 
      setView(lng = -119.4, lat = 34.286, zoom = 10) %>% 
      addProviderTiles(providers$Stamen.Terrain) %>% 
      addPolygons(data = sps, color = "#444444", weight = 1, smoothFactor = 0.5,
                  opacity = 1.0, fillOpacity = 0.5)
      
  })
  
  # observeEvent(input$revbutton,{
  #   show("revInputs")
  #   hide("revbutton")
  #   use_user_rev = T
  # })
  # 
  # observeEvent(input$costbutton,{
  #   show("costInputs")
  #   hide("costbutton")
  #   use_user_costs = T
  #   
  # })
})
