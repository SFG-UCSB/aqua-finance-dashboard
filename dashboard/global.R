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


####Global Variables####
discount = 0.05
lbs_per_acre = 10000

###Helper Functions


#revene() calculates the expected production given a farm size input and the global variable 'lbs_per_acre'. For expected income, the price_per_lb can be defined by a used or calculated internally if left as default NULL value. The price point is calculated using a pseudo economics equation derived from VSE slides (Scott Lindell). Unlike cost_projection, revenue is design to calculate for a given year and then be iterated upon.
revenue <-
  function(numAcres,
           price_per_lb = NULL) {
    production <- numAcres * lbs_per_acre
    price <- price_per_lb
    if (is.null(price)) {
      price <- (-1.25 / 1000000 * production) + 2.625
    }
    return(production * price)
  }


#Unlike revenue, cost_projection was written to return the expected cost stream over the entire time horizon. This was chosen to make implementation of intital capital costs in year 1 more seamless. As written, this function uses the scale_helper function to extrapolate given cost points in Scott Lindell's VSE presentation [http://venturashellfishenterprise.com/archives/WS6/WS6_Presentation.pdf].
cost_projection <-
  function(numAcres,
           numYears,
           fixedCap = NULL,
           annual_op_costs = NULL,
           processing_costs = NULL) {
    #Set dummy variables for calculation to inputs. NULL in default usage
    cap <- fixedCap
    op <- annual_op_costs
    proc <- processing_costs
    
    #If null, update costs with scaled equations
    #fixedCap Costs
    if (is.null(cap)) {
      #cost of line kept linear due to close linear relationship when reported in slides
      lines <- 5000 * numAcres
      equip_boat <- scale_helper(numAcres, 10, 50, 110000, 550000)
      cap <- lines + equip_boat
    }
    
    if (is.null(op)) {
      #per acre costs for admin, insurance, seed, payroll, and annual operations
      admin <- scale_helper(numAcres, 10, 50, 8000, 15000)
      insurance <- scale_helper(numAcres, 10, 50, 4000, 16000)
      seed <- scale_helper(numAcres, 10, 50, 15000, 46000)
      payroll <- scale_helper(numAcres, 10, 50, 43000, 162000)
      annualops <- scale_helper(numAcres, 10, 50, 46000, 179000)
      
      variable <- admin + insurance + seed + payroll + annualops
      
      #depreciation, set at 10% of capital to start
      deprec <- 0.1 * cap
      
      op <- variable + deprec
    }
    
    #Processing cost funtion
    
    if (is.null(proc)) {
      #processing and packing per lb of production
      pack_cost <- (0.03 + 0.03) * numAcres * lbs_per_acre
      #7.5% of production cost
      selling_cost <- 0.075 * (pack_cost + op)
      #freight to wholesaler, per lb of production
      shipping_cost <- 0.075 * numAcres * lbs_per_acre
      
      #total post harvesting costs
      proc <- pack_cost + selling_cost + shipping_cost
    }
    
    #construct vector of costs
    total_annual <- op + proc
    costs <- rep(total_annual, numYears)
    #add in fixed capital costs to year 1
    costs[1] = costs[1] + cap
    
    return(costs)
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