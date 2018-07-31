library(tidyverse)
library(shinydashboard)
library(shiny)
library(leaflet)
library(sp)
library(dashboardthemes)

discount = 0.05


state_water <- matrix(
  c(-119.4487876,34.354345,
    -119.509735,34.336419,
    -119.428569,34.286472,
    -119.3475,34.236466,
    -119.320165, 34.258837,
    -119.395774,34.313343),
  ncol = 2, byrow = T)

sps <- SpatialPolygons(list(
  Polygons(list(Polygon(state_water)), 1)))


logo_sfg <- shinyDashboardLogoDIY(
  
  boldText = "Aquaculture"
  ,mainText = "Financial Model"
  ,textSize = 16
  ,badgeText = "SFG"
  ,badgeTextColor = "white"
  ,badgeTextSize = 2
  ,badgeBackColor = "darkslategrey"
  ,badgeBorderRadius = 3
  
)


revenue <- function(numAcres, lb_per_acres = 10000, price_per_lb = NULL){
  production <- numAcres * lb_per_acres
  if(!is.null(price_per_lb)){
    price <- price_per_lb
  }else{
    price <- (-1.25/1000000 * production)+2.625
  }
  return(production * price)
}

cost_projection <- function(numAcres, numYears, fixedCap = NULL) {
  #fixedCap Costs
  if (is.null(fixedCap)) {
    #quasi-scaling of costs here lol
  } else{
    capital <- fixedCosts
  }
}
