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
