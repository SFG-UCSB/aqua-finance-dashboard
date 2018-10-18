shinyServer(function(input, output) {
  
#The species_index() is a reactive function that forms the backbone of the server. It allows for the dynamic switching between species-type defaults based on which species the user has selected on the original app ladning page. It passes an index to the functions that render the widgets which then pick their starting values from lists that are indexed according to the pattern dictated in species_index. Note: ff = finfish, sf = shellfish, sw = seaweed (algae)  
  
  species_index <- reactive({
    
     switch(input$species,
           "ff" = 1,
           "sf" = 2,
           "sw" = 3
          )
  })
  
  #The following code chunks call to renderUI() to dynamically create widgets that populate the app. 
  
     output$prod_unit_densWidget <- renderUI({
       numericInput("prod_unit_dens",
                 "Production Units* (per hectare)",
                 value = prod_unit_dens_defaults[species_index()],
                 min = 1,
                 step = 1)
  })
  
  output$stocking_densWidget <- renderUI({
    numericInput("stocking_dens",
                 "Stocking Density (individuals per production unit)",
                 value = stocking_dens_defaults[species_index()],
                 min = 1,
                 step = 1
    )
  })
  
  output$start_sizeWidget <- renderUI({
    numericInput("start_size",
                 "Initial Stocking Size (kg)",
                 value = start_size_defaults[species_index()],
                 min = 0,
                 step = 0.1)
  })
  
  output$harvest_sizeWidget <- renderUI({
    numericInput("harvest_size",
                 "Minimum Harvest Size (kg)",
                 value = harvest_size_defaults[species_index()],
                 min = 0,
                 step = 1)
  })
  
  output$growthWidget <- renderUI({
    textInput("growth",
              "Monthly Growth Rate*",
              value = growth_defaults[[species_index()]])
  })
  
  output$deathWidget <- renderUI({
    numericInput("death",
                 "Instantaneous Mortality Rate*",
                 value = death_defaults[species_index()],
                 min = 0,
                 max = 1,
                 step = 0.01)
  })
  # output$timestepWidget <- renderUI({
  #   radioButtons(
  #     inputId = "timestep",
  #     label = "Timestep:",
  #     choices = c(
  #       "Monthly" = 12,
  #       "Weekly" = 52
  #     ),
  #     selected = timestep_defaults[species_index()]
  #   )
  # })
  output$sales_priceWidget <- renderUI({
    numericInput(
      "sales_price",
      "Wholesale Price ($/kg)",
      value = sales_price_defaults[species_index()],
      min = 0,
      step = 0.1
    )
  })
  output$init_fixed_capWidget <- renderUI({
    numericInput(
      "init_fixed_cap",
      "Fixed* Capital Costs",
      value = init_fixed_cap_defaults[species_index()],
      step = 5000
    )
  })
  output$var_capWidget <- renderUI({
    numericInput(
      "var_cap",
      "Size Variable Capital Costs",
      value = var_cap_defaults[species_index()],
      step = 100
    )
  })
  output$fixed_monthly_costsWidget <- renderUI({
    numericInput(
      "fixed_monthly_costs",
      "Fixed Monthly Costs",
      value = fixed_monthly_costs_defaults[species_index()],
      step = 500
    )
  })
  output$var_monthly_costsWidget <- renderUI({
    numericInput(
      "var_monthly_costs",
      "Size Variable Monthly Costs (per hectare)",
      value = var_monthly_costs_defaults[species_index()],
      step = 500
    )
  })
  output$annual_costsWidget <- renderUI({
    numericInput(
      "annual_costs",
      "Additional Fixed Annual Costs",
      value = annual_costs_defaults[species_index()],
      step = 500
    )
  })
  output$harv_costWidget <- renderUI({
    numericInput(
      "harv_cost",
      "Harvesting Cost (per hectare)",
      value = harv_cost_defaults[species_index()],
      step = 100
    )
  })
  output$stock_costWidget <- renderUI({
    numericInput(
      "stock_cost",
      "Cost of Seed and Stocking (per hectare)",
      value = stock_cost_defaults[species_index()],
      step = 500
    )
  })

  

 #The run_model() function is essentially a reactive wrapper for the production_model() function defined in the global.R script.  
  
  
  run_model <- reactive({
    
    results <- production_model(
      species = input$species,
      discount = input$discount,
      farm_size = input$farm_size,
      time_horz = input$time_horz,
      unit_area = input$prod_unit_dens,
      ind_unit = input$stocking_dens,
      growth = annualRates(input$growth, as.numeric(model_timestep)),
      death = input$death,
      init_size = input$start_size,
      harvest_size = input$harvest_size,
      timestep = model_timestep,
      price = input$sales_price,
      fixed_init_cost = input$init_fixed_cap,
      var_cap = input$var_cap,
      harv_cost = input$harv_cost,
      restock_cost = input$stock_cost,
      fixed_monthly_costs = input$fixed_monthly_costs,
      var_monthly_costs = input$var_monthly_costs,
      annual_maintenance_cost = input$annual_costs
    )
    
    return(results)
  })
  
#Use lapply to pass a list of the widgets to the outputOptions()  function which allows the suspendWhenHidden argument (default = T) to be set to false. This was added to circumvent the native dashboard reactive behavior during which the widgets (and graphical outputs that depending on their values) only would update in response to the species choice selection when that tab was navigated to. Now, widgets will update any time the app notices that the species selectiion has been changed.
  
  lapply(c(
    "prod_unit_densWidget",
    "stocking_densWidget",
    "start_sizeWidget",
    "harvest_sizeWidget",
    "growthWidget",
    "deathWidget",
    #"timestepWidget",
    "sales_priceWidget",
    "init_fixed_capWidget",
    "var_capWidget",
    "harv_costWidget",
    "stock_costWidget",
    "fixed_monthly_costsWidget",
    "var_monthly_costsWidget",
    "prod_unit_densWidget",
    "annual_costsWidget"
  ),
  function(x)outputOptions(output, x, suspendWhenHidden = FALSE))

  output$CFPlot <- renderPlot({
    ggplot(run_model()$cycle_data, aes(x = as.factor(Counter), y = Value/1000, fill = Type)) +
      geom_bar(stat= "identity", position = position_dodge())+
      theme_minimal(base_size = 15)+
      NULL
  }
  )
  
  output$NPVPlot <- renderPlot({
     ggplot(run_model()$annual_data, aes(x = Year, y = NPV / 1000000)) +
      geom_hline(yintercept = 0, linetype = 5) +
      geom_line(size = 1.05) +
      theme_classic(base_size = 15) +
      labs(x = "Year", y = "USD Millions")+
            NULL
  })
  
  output$ledger <- renderTable({
     run_model()$cycle_data
  })
  
  output$annum <- renderTable({
    run_model()$annual_data
  })
  
  output$init_invest_box <- renderValueBox({
    valueBox(
      value = paste0("$",prettyNum(round(run_model()$init_invest,-4),big.mark = ",")), 
      subtitle = "Initial Investment",
      color = "olive",
      icon = icon("money"))
  })
  
  output$breakeven_box <- renderValueBox({
    if(run_model()$isProfitable){
    valueBox(
      value = paste(run_model()$breakeven,run_model()$phrase), 
      subtitle = "Payback Period", 
      color = "olive",
      icon = icon("calendar"))
    }else{
      valueBox(
        value = "NPV < 0", 
        subtitle = "at Time Horizon", 
        color = "red",
        icon = icon("calendar"))
    }
  })
  
  output$production_box <- renderValueBox({
    valueBox(
      value = paste(prettyNum(round(run_model()$yield,-3), big.mark = ","), "kg"), 
      subtitle = "Avgerage Annual Yield", 
      color = "olive",
      icon = icon("spoon"))
  })
  
  output$parameters <- downloadHandler(
    filename = "parameters.csv",
    content = function(file) {
      write_csv(runModel()$annual_data, file, row.names = FALSE)
    }
  )
})
