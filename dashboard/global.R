#Possible reference if we take this in the direction of mapedit
#https://www.r-spatial.org/r/2017/06/09/mapedit_0-2-0.html

#Ian Ladner
#SFG
#Aquaculture Financial Dashboard Tool
#Summer 2018

#load/install req. packages
library(tidyverse)
library(shinydashboard)
library(shiny)
library(leaflet)
library(sp)
library(dashboardthemes)
library(shinyjs)

####Global Variables####
prod_unit_dens_defaults <- c(5,10,10)
stocking_dens_defaults <- c(100,250,250)
start_size_defaults <- c(1,2,1)
harvest_size_defaults <- c(4,5,7)
growth_defaults <- c(0.3,0.2,0.04)
death_defaults <- c(0.03,0.1, 0.01)
sales_price_defaults <- c(4,2.5,1)
timestep_defaults <- c(12,12,52)
init_fixed_cap_defaults <- c(75000,75000,75000)
init_var_cap_defaults <- c(10000,5000,5000)
harv_cost_defaults <- c(500,1500,1500)
stock_cost_defaults <- c(1000,5000,500)
op_costs_defaults <- c(2500,4000,400)
annual_costs_defaults <- c(7500,7500,7500)



###Helper Functions

harvest_schedule <- function(
  num_years,
  timestep,
  init_size,
  target_size,
  growth
){
  
  time_horz <- num_years * timestep
  harvest_counter <- 0 
  size <- init_size
  
  for(counter in 1:time_horz){
    i <- timestep_helper(counter, timestep)
    #discrete growth
    size <- size * (1+growth[i])
    #check for harvest
    if(size >= target_size){
      harvest_counter <- harvest_counter + 1
      size <- init_size 
    }
  }
  return(harvest_counter)
}

timestep_helper <- function(index,timestep) {
  if (index %% timestep == 0)
    return(timestep)
  else
    return(index %% timestep)
}

annualRates <- function(rateString, timestep){
  rates <- as.numeric(strsplit(rateString,",")[[1]])
  
  if(timestep%%length(rates) != 0){
    break
  }
  
  rates <- rep(rates, each = (timestep/length(rates)))
  return(rates)
}






#scales an input variable on a range of two values to fit on a range of two other values. Allows for quick interpolation and extrapolation of two given cost points with the assumption of linearity between costs and individual number of acres. For example, if anchor costs for 10 and 50 acres were $1400 and $6500 respectively, scale_helper could help derive the associated linearly scaled cost for anchors on a 34 or 89 acre farm.
scale_helper <-
  function(unscaledNumber,
           unscaledMin,
           unscaledMax,
           targetMin,
           targetMax) {
    u <- unscaledNumber
    uMin <- unscaledMin
    uMax <- unscaledMax
    tMin <- targetMin
    tMax <- targetMax
    
    return((tMax - tMin) * (u - uMin) / (uMax - uMin) + tMin)
  }



####Spatial Prep#############
state_water <- matrix(
  c(
    -119.4487876,
    34.354345,
    -119.509735,
    34.336419,
    -119.428569,
    34.286472,
    -119.3475,
    34.236466,
    -119.320165,
    34.258837,
    -119.395774,
    34.313343
  ),
  ncol = 2,
  byrow = T
)

sps <- SpatialPolygons(list(Polygons(list(
  Polygon(state_water)
), 1)))


####Implementation of ShinyDashboardThemes (Optional Aesthetic)#######

logo_sfg <- shinyDashboardLogoDIY(
  boldText = "Aquaculture",
  mainText = "Financial Model",
  textSize = 16,
  badgeText = "SFG",
  badgeTextColor = "white",
  badgeTextSize = 2,
  badgeBackColor = "darkslategrey",
  badgeBorderRadius = 3
)

production_model <- function(
  species,
  farm_size,
  time_horz,
  timestep,
  discount,
  unit_area,
  ind_unit,
  growth,
  death,
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
  
  num_timesteps <- time_horz * timestep
  results <- data.frame(
    Timesteps = seq(0,num_timesteps),
    Cycle = vector(length = num_timesteps+1, mode = "numeric"),
    Size = vector(length = num_timesteps+1, mode = "numeric"),
    Individuals = vector(length = num_timesteps+1, mode = "numeric"),
    Harv_Size = vector(length = num_timesteps+1, mode = "numeric"),
    Harv_Biomass = vector(length = num_timesteps+1, mode = "numeric"),
    Revenue = vector(length = num_timesteps+1, mode = "numeric"),
    Cost = vector(length = num_timesteps+1, mode = "numeric")
  )
  
  effective_discount <- (1+discount)^(1/timestep)-1
  
  
  
  stock_counter <-
    1 #number of time steps since stocking, resets intermittenly
  cycle_counter <- 1
  
  stock_indiv <- farm_size * unit_area * ind_unit
  stock_size <- init_size
  
  results$Size[1] <- stock_size
  results$Individuals[1] <- stock_indiv
  
  results$Cost[1] <- fixed_init_cost + size_var_init_cost * unit_area + restock_cost
  
  
  
  
  num_cycles <-
    harvest_schedule(time_horz,timestep,init_size, harvest_size, growth)
  
  #begin iteration process through the number of harvest cycles determined by helper function 'harvest_schedule'
  #for this first version, I will be using discrete growth calcs and instantaneous mortality calcs for comparison
  
  
  for (i in 1:num_timesteps)
  {
    if (cycle_counter > num_cycles)
    {
      break
    }
    
    ref_time <- timestep_helper(i,timestep)
    
    results$Cycle[i+1]<-cycle_counter
    
    #Growth
    results$Size[i+1] <-
      results$Size[i] * (1 + growth[ref_time])
    
    #Mortality
    results$Individuals[i+1] <-
      stock_indiv - stock_indiv * (1 - exp(-death * stock_counter))
    
    
    
    # If individual weight has reached harvest weight (~5 kg), harvest and restock
    if (results$Size[i+1] > harvest_size) {
      # Update harvest cycle counter
      cycle_counter <- cycle_counter + 1
      
      results$Harv_Size[i+1]<-results$Size[i+1]
      
      results$Harv_Biomass[i+1]<- results$Size[i+1] * results$Individuals[i+1]
      
      # label harvest cycle and calculate harvest
      results$Revenue[i+1] <- price * results$Harv_Biomass[i+1]
      
      results$Cost[i+1] <- results$Cost[i+1] + harv_cost
      
      # If harvest cycle counter is still less than or equal to the number of harvest cycles, restock.
      if (cycle_counter <= num_cycles) {
        # Restock
        results$Size[i+1] <- stock_size
        results$Individuals[i+1] <- stock_indiv
        
        results$Cost[i+1] <- results$Cost[i+1] + restock_cost
        
        # Update stock counter
        stock_counter <- 1
      }
    }
    else{
      stock_counter <- stock_counter + 1
    }
    
    results$Cost[i+1] <- results$Cost[i+1] + monthly_op_cost
    if(ref_time == timestep)
    {
      results$Cost[i+1] <- results$Cost[i+1] + annual_maintenance_cost
    }
  }
  results <- results %>% 
    mutate(Profit = Revenue - Cost, Disc_Prof = Profit/(1+effective_discount)^Timesteps, NPV = cumsum(Disc_Prof))
  return(results)
} 
