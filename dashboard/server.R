shinyServer(function(input, output) {
  
  species_index <- reactive({
    switch(input$species,
           "ff" = 1,
           "sf" = 2,
           "sw" = 3)
  })
  
   output$prod_unit_densWidget <- renderUI({
    numericInput("prod_unit_dens",
                 "Production units per area",
                 value = prod_unit_dens_defaults[species_index()],
                 min = 1,
                 step = 1)
  })
  
  output$stocking_densWidget <- renderUI({
    numericInput("stocking_dens",
                 "Individuals per unit of production",
                 value = stocking_dens_defaults[species_index()],
                 min = 1,
                 step = 1
    )
  })
  
  output$start_sizeWidget <- renderUI({
    numericInput("start_size",
                 "Initial size",
                 value = start_size_defaults[species_index()])
  })
  
  output$harvest_sizeWidget <- renderUI({
    numericInput("harvest_size",
                 "Target harvest size",
                 value = harvest_size_defaults[species_index()])
  })
  
  output$growthWidget <- renderUI({
    textInput("growth",
              "Growth rate",
              value = growth_defaults[species_index()])
  })
  
  output$deathWidget <- renderUI({
    numericInput("death",
                 "Mortality",
                 value = death_defaults[species_index()],
                 min = 0,
                 max = 1,
                 step = 0.01)
  })
  output$timestepWidget <- renderUI({
    radioButtons(
      inputId = "timestep",
      label = "Timestep:",
      choices = c(
        "Monthly" = 12,
        "Weekly" = 52
      ),
      selected = timestep_defaults[species_index()]
    )
  })
  output$sales_priceWidget <- renderUI({
    numericInput(
      "sales_price",
      "Sales price ($/mass)",
      value = sales_price_defaults[species_index()],
      min = 0,
      step = 0.1
    )
  })
  output$init_fixed_capWidget <- renderUI({
    numericInput(
      "init_fixed_cap",
      "Fixed Initial Capital",
      value = init_fixed_cap_defaults[species_index()],
      step = 5000
    )
  })
  output$init_var_capWidget <- renderUI({
    numericInput(
      "init_var_cap",
      "Size Variable Initial Cost (Per Acre)",
      value = init_var_cap_defaults[species_index()],
      step = 100
    )
  })
  output$harv_costWidget <- renderUI({
    numericInput(
      "harv_cost",
      "Harvesting Cost",
      value = harv_cost_defaults[species_index()],
      step = 100
    )
  })
  output$stock_costWidget <- renderUI({
    numericInput(
      "stock_cost",
      "Stocking cost",
      value = stock_cost_defaults[species_index()],
      step = 500
    )
  })
  output$op_costsWidget <- renderUI({
    numericInput(
      "op_costs",
      "Operational Costs",
      value = op_costs_defaults[species_index()],
      step = 500
    )
  })
  output$annual_costsWidget <- renderUI({
    numericInput(
      "annual_costs",
      "Annual maitenance cost",
      value = annual_costs_defaults[species_index()],
      step = 500
    )
  })
  
  
  run_model <- reactive({
    output <- production_model(
      species = input$species,
      discount = input$discount,
      farm_size = input$farm_size,
      time_horz = input$time_horz,
      unit_area = input$prod_unit_dens,
      ind_unit = input$stocking_dens,
      growth = annualRates(input$growth, as.numeric(input$timestep)),
      death = input$death,
      init_size = input$start_size,
      harvest_size = input$harvest_size,
      timestep = as.numeric(input$timestep),
      price = input$sales_price,
      fixed_init_cost = input$init_fixed_cap,
      size_var_init_cost = input$init_var_cap,
      harv_cost = input$harv_cost,
      restock_cost = input$stock_cost,
      monthly_op_cost = input$op_costs,
      annual_maintenance_cost = input$annual_costs
    )
    return(output)
  })
  
  output$CashflowPlot <- renderPlot({
    cf <- ggplot(run_model(), aes(x = Timesteps, y = Revenue / 1000)) +
      geom_hline(yintercept = 0, linetype = 5) +
      geom_line(size = 1.05, color = "forestgreen") +
      theme_classic(base_size = 14) +
      geom_line(aes(x = Timesteps, y = Cost / 1000),size = 1.05,color = "firebrick3") +
      NULL
    
    # if (input$timestep == "12") {
    #   cf <- cf + labs(x = "Month", y = "USD Thousands")
    # }else if (input$timestep == "52") {
    #   cf <- cf + labs(x = "Week", y = "USD Thousands")
    # }
    cf
  })
  
  
  output$NPVPlot <- renderPlot({
    ggplot(run_model(), aes(x = Timesteps, y = NPV / 1000000)) +
      geom_hline(yintercept = 0, linetype = 5) +
      geom_line(size = 1.05) +
      theme_classic(base_size = 14) +
      labs(x = "BLAH", y = "NPV (USD Millions)") +
      NULL
  })
  
  output$ledger <- renderTable({
    run_model()
  })
  
  output$aquamap <- renderLeaflet({
    leaflet() %>%
      setView(lng = -119.4,
              lat = 34.286,
              zoom = 10) %>%
      addProviderTiles(providers$Stamen.Terrain) %>%
      addPolygons(
        data = sps,
        color = "#444444",
        weight = 1,
        smoothFactor = 0.5,
        opacity = 1.0,
        fillOpacity = 0.5
      )
    
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
