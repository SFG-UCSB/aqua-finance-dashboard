
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
library(knitr)


####Global Variables####
#Finfish, shellfish, seaweed
#User can categorize costs as they choose, allows felxibility to meet a variety of costframes and contexts

#number of lines/cages/etc. per unit of space
prod_unit_dens_defaults <- c(1,1,5)
#number of individuals per production unit
stocking_dens_defaults <- c(4821,1299536,100)
#intial size, height/weight but reflects the price point
start_size_defaults <- c(0.015,.0008,1)
#minimum harvest size, can be exceeded in a timestep
harvest_size_defaults <- c(4.2,.023,7)
#discrete growth in percentage per timestep
growth_defaults <- list("0.6", ".323", "0.384,0,0,0.384")
#continuous mortality rate (percent of total individuals who die in a timestep)
death_defaults <- c(0.0357,0.0186, 0)
#Gate price per relevant growth statistics that the farmer recieves
sales_price_defaults <- c(9.57,3.92,1.31)
#timestep of model. Expressed as number of timesteps in a year
#timestep_defaults <- c(12,12,52)
#Initial farm investment that is independent of farm size
init_fixed_cap_defaults <- c(762676,572000,155326)
#Inital farm investment that depends on size of farm
var_cap_defaults <- c(35715,728,15817)
#Cost of harvesting product
harv_cost_defaults <- c(0,2312,593)
#Cost of seed to stock product
stock_cost_defaults <- c(13839,1182,308)

#RECOMMENT

#Cost to opperate farm relative to timestep. May Include things like feed for fed aquaculture
fixed_monthly_costs_defaults <- c(4037,15340,1034)
var_monthly_costs_defaults <- c(4572,383,1034)

#Cost to operate farm on a yearly scale. May include maitenenace, insurance, admin overhead etc.
annual_costs_defaults <- c(553624,151840,114630)

model_timestep = 12






###Helper Functions

#The harvest_schedule() function allows the larger model funciton to calculate the number of harvests in the time horizon for a certain growth/production regime. This is done so that the profitability of a farm is not artificially lowered when a production cycle is caught mid-way by the end of the time horizon.

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


#Allows an absolute index counter for time to be translated to one relative to a year. Allows for n-term array for growth rates where n is the timestep.
timestep_helper <- function(index,timestep) {
  if (index %% timestep == 0)
    return(timestep)
  else
    return(index %% timestep)
}

# Takes a string of growth values sepearated by the `,` character and extrapolates them equally to create an n-term growth rate array where n is the number of timesteps in a year. The number of timesteps in a year must be evenly divisible by the numer of entries in the rateString argument, else the function throws an error.
annualRates <- function(rateString, timestep){
  rates <- as.numeric(strsplit(rateString,",")[[1]])
  
  if(timestep%%length(rates) != 0){
    stop("Number of growth rates must be evenly divisible into number of annual timesteps")
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

####Implementation of ShinyDashboardThemes (Optional Aesthetic)#######

# logo_sfg <- shinyDashboardLogoDIY(
#   boldText = "Aquaculture Planning",
#   mainText = "Financial Tool",
#   textSize = 16,
#   badgeText = "SFG",
#   badgeTextColor = "white",
#   badgeTextSize = 2,
#   badgeBackColor = "black",
#   badgeBorderRadius = 3
# )

##

# rmdfiles <- c("dash-intro.RMd","ref-guide.Rmd")
# sapply(rmdfiles, knit, quiet = T)

#Larger production model function that reports all required outputs to dashboard.

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
  var_cap,
  harv_cost,
  restock_cost,
  fixed_monthly_costs,
  var_monthly_costs,
  annual_maintenance_cost
){
  
  #Set a simulation bounding length based on number of years and timestep interval. Will be ammended with a "0th" timestep to hold conditions and costs.
  num_timesteps <- time_horz * timestep
  
  #Create a placeholder data frame to host model results.  
  results <- data.frame(
    Year = as.integer(c(0,rep(1:time_horz, each = timestep))),
    Timesteps = seq(0,num_timesteps),
    Cycle = vector(length = num_timesteps+1, mode = "numeric"),
    Counter = vector(length = num_timesteps+1, mode = "numeric"),
    Size = vector(length = num_timesteps+1, mode = "numeric"),
    Individuals = vector(length = num_timesteps+1, mode = "numeric"),
    Harv_Size = vector(length = num_timesteps+1, mode = "numeric"),
    Harv_Biomass = vector(length = num_timesteps+1, mode = "numeric"),
    Revenue = vector(length = num_timesteps+1, mode = "numeric"),
    Costs = vector(length = num_timesteps+1, mode = "numeric")
  )
  
  #Converts the annual discount rate to an effective discount rate that is relative to the timestep chosen.
  effective_discount <- (1+discount)^(1/timestep)-1
  
  
  #number of time steps since stocking, resets intermittenly
  stock_counter <-1
  
 #index for number of harvests that have occured, checked against the output of the harvest schedule function
  cycle_counter <- 1
  
 #number of individuals to be stocked at beginning of each production cycle based upon the size of the farm, num of production units per spatial unit, and the stocking density
   stock_indiv <- farm_size * unit_area * ind_unit
  stock_size <- init_size
  
  #Sets the size of all indiviudals to the initial size for the 0th timestep. Also sets the original population size to the stocking number claculated above.
  results$Size[1] <- stock_size
  results$Individuals[1] <- stock_indiv
  
  init_invest <- fixed_init_cost + var_cap * farm_size + restock_cost*farm_size
  
  results$Costs[1] <- init_invest
  results$Counter[1] <- 0
  
  
  
  #calcualte appropriate number of harvest cycles based upon helper function
  num_cycles <-
    harvest_schedule(time_horz,timestep,init_size, harvest_size, growth)
  
#Production Model Cycle#

#Iterates through number of timesteps
#Checks each timestep to see if max number of possible harvest cycles has been performed as reported by harvest_schedule() helper function. This limits expenditures that will have unrealized profits over time horizon.
#Growth and mortality occur
#There is a check to see if harvest size has been reached:
  #If yes: 1) cycle counter advances 2)Harvst size and harvested biomass is recorded 3)Revenue is calculated based on sales price 4) cost of harvesting is added to that timestep's costs 5) if there are more harvests to occur -> restock, reset size and indiviudals, and add associated stocking costs 6)reset the stock-counter to track timesteps since last stocking
  #If no: advance stock counter
  #Finish by adding monthly op costs, and if at the end of the year, add annual costs
  
  
  for (i in 1:num_timesteps)
  {
    if (cycle_counter > num_cycles)
    {
      break
    }
    
    ref_time <- timestep_helper(i,timestep)
    
    results$Cycle[i+1]<-cycle_counter
    results$Counter[i+1]<-stock_counter
    
    #Growth
    results$Size[i+1] <-
      results$Size[i] * (1 + growth[ref_time])
    
    #Mortality
    results$Individuals[i+1] <-
      stock_indiv * exp(-stock_counter* death)
    
    
    
    # If individual weight has reached harvest weight (~5 kg), harvest and restock
    if (results$Size[i+1] > harvest_size) {
      # Update harvest cycle counter
      cycle_counter <- cycle_counter + 1
      
      results$Harv_Size[i+1]<-results$Size[i+1]
      
      results$Harv_Biomass[i+1]<- results$Size[i+1] * results$Individuals[i+1]
      
      # label harvest cycle and calculate harvest
      results$Revenue[i+1] <- price * results$Harv_Biomass[i+1]
      
      results$Costs[i+1] <- results$Costs[i+1] + harv_cost*farm_size
      
      # If harvest cycle counter is still less than or equal to the number of harvest cycles, restock.
      if (cycle_counter <= num_cycles) {
        # Restock
        results$Size[i+1] <- stock_size
        results$Individuals[i+1] <- stock_indiv
        
        results$Costs[i+1] <- results$Costs[i+1] + restock_cost * farm_size
        
        # Update stock counter
        stock_counter <- 1
      }
    }
    else{
      stock_counter <- stock_counter + 1
    }
    
    results$Costs[i+1] <- results$Costs[i+1] + fixed_monthly_costs + var_monthly_costs*farm_size
    
    if(ref_time == timestep)
    {
      results$Costs[i+1] <- results$Costs[i+1] + annual_maintenance_cost
    }
  }
  
  #After production model looping, calculated: profit, the profit discounted by the effective discount rate, and the NPV
  
  results <- results %>% 
    mutate(Profit = Revenue - Costs, Disc_Prof = Profit/(1+effective_discount)^Timesteps, NPV = cumsum(Disc_Prof)) %>% gather(Costs, Revenue, key = "Type", value = "Value")
  
  #Series of auxillairy values to be calculated to inform value boxes on the display of tool 1)inital investment 2)is the NPV >0 at the time horizon, and if so, when does it break even? 3)average annual production 
  
#1) initial investment is calculated as the sum of the oringial fixed and variable costs, as well as the first stocking cost  

#2) The code first checks to see if the NPV is at least zeron at the time horizon and sets a boolen `profitable` as appropriate. If it is profitable, the first timestep in which the NPV is above zero is reported as the "breakeven" point, with a single index adjustment to account for the inclusion of a 0th timestep. If not profitable, the breakeven timestep is set to NULL.   
  if(last(results$NPV) >= 0){
    profitable <- TRUE
    breakeven <- min(which(results$NPV >= 0))-1
  }else{
    profitable <- FALSE
    breakeven <- NULL
  }

#The appropriate timestep (e.g. weeks, months, etc) is saved as a string so that the dashboard can be display it alongside the breakeven index  
  if(timestep == 52){
    phrase <- "weeks"
  }else if(timestep == 12){
    phrase <- "months"
  }else phrase <- "timesteps"
  
#3) creates a subset of data that is grouped by year including the total summative yield, revenue, and profit. The NPV at the end of each year is also reported. 
  annual_data <- results %>%
    spread(Type, Value) %>% 
    group_by(Year) %>% 
    summarise(Yield = sum(Harv_Biomass), Revenue = sum(Revenue), Profit = sum(Profit), NPV = last(NPV)) %>% 
    ungroup()

#Mean annual yield is calculated,Year 0, used for the initial investment timestep, is removed for mean calculation purposes 

  yield = mean(annual_data$Yield[-1])
  
#Cashflow implementation
  
  cycle_data <- results %>%
    spread(Type, Value) %>% 
    select(Counter, Size, Individuals,Costs,Revenue,Profit)%>% 
    group_by(Counter) %>% 
    summarize_all(mean) %>% 
    filter(Counter != 0) %>% 
    gather(Costs, Revenue, key = "Type", value = "Value")
    
  
#returns a list of params used to populate graphs and value boxes in UI
  
  
  return(list(results = results, annual_data = annual_data, init_invest = init_invest, isProfitable = profitable, breakeven = breakeven, phrase = phrase, yield = yield, cycle_data = cycle_data))
} 
