#Define things for model testing

growth_rates <- rnorm(12, mean = 0.3, sd = 0.1)
#survival <- 0.90 #annual survivability



#actual function

production_model <- function(
  species,
  farm_size,
  time_horz,
  discount,
  unit_area,
  ind_unit,
  monthly_growth,
  monthly_death,
  init_size,
  harvest_size,
  price,
  fixed_init_cost,
  size_var_init_cost,
  harv_cost,
  restock_cost,
  monthly_op_cost,
  annual_maintenance_cost
){
  
  num_months <- time_horz * 12
  results <- data.frame(
    Month = seq(0,num_months),
    Cycle = vector(length = num_months+1, mode = "numeric"),
    Size = vector(length = num_months+1, mode = "numeric"),
    Individuals = vector(length = num_months+1, mode = "numeric"),
    Harv_Size = vector(length = num_months+1, mode = "numeric"),
    Harv_Biomass = vector(length = num_months+1, mode = "numeric"),
    Revenue = vector(length = num_months+1, mode = "numeric"),
    Cost = vector(length = num_months+1, mode = "numeric")
  )
  
  effective_monthly_discount <- (1+discount)^(1/12)-1
  
  
  stock_counter <-
    1 #number of time steps since stocking, resets intermittenly
  cycle_counter <- 1
  
  stock_indiv <- farm_size * unit_area * ind_unit
  stock_size <- init_size
  
  results$Size[1] <- stock_size
  results$Individuals[1] <- stock_indiv
  
  results$Cost[1] <- fixed_init_cost + size_var_init_cost * unit_area + restock_cost
  
  
  num_cycles <-
    harvest_schedule(time_horz, init_size, harvest_size, monthly_growth)
  
  #begin iteration process through the number of harvest cycles determined by helper function 'harvest_schedule'
  #for this first version, I will be using discrete growth calcs and instantaneous mortality calcs for comparison
  
  
  for (m in 1:(num_months))
  {
    if (cycle_counter > num_cycles)
    {
      break
    }
    
    ref_month <- month_helper(m)
    
    results$Cycle[m+1]<-cycle_counter
    
    #Growth
    results$Size[m+1] <-
      results$Size[m] * (1 + monthly_growth[ref_month])
   
     #Mortality
    results$Individuals[m+1] <-
      stock_indiv - stock_indiv * (1 - exp(-monthly_death * stock_counter))
    
    
    
    # If individual weight has reached harvest weight (~5 kg), harvest and restock
    if (results$Size[m+1] > harvest_size) {
      # Update harvest cycle counter
      cycle_counter <- cycle_counter + 1
    
      results$Harv_Size[m+1]<-results$Size[m+1]
      
      results$Harv_Biomass[m+1]<- results$Size[m+1] * results$Individuals[m+1]
      
      # label harvest cycle and calculate harvest
      results$Revenue[m+1] <- price * results$Harv_Biomass[m+1]
      
      results$Cost[m+1] <- results$Cost[m+1] + harv_cost
      
      # If harvest cycle counter is still less than or equal to the number of harvest cycles, restock.
      if (cycle_counter <= num_cycles) {
        # Restock
        results$Size[m+1] <- stock_size
        results$Individuals[m+1] <- stock_indiv
        
        results$Cost[m+1] <- results$Cost[m+1] + restock_cost
        
        # Update stock counter
        stock_counter <- 1
      }
    }
    else{
      stock_counter <- stock_counter + 1
    }
    
    results$Cost[m+1] <- results$Cost[m+1] + monthly_op_cost
    if(ref_month == 12)
    {
      results$Cost[m+1] <- results$Cost[m+1] + annual_maintenance_cost
    }
  }
  results <- results %>% 
    mutate(Profit = Revenue - Cost, Disc_Prof = Profit/(1+effective_monthly_discount)^Month, NPV = cumsum(Disc_Prof))
  return(results)
} 
