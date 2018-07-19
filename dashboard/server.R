shinyServer(function(input,output){
  df <- reactive(data.frame(
    year = seq(1:input$years),
    costs = c(input$op_costs+input$init_costs,rep(input$op_costs, input$years-1)),
    revenue = rep(as.numeric(input$size) * input$mussPrice * mussels_longline, input$years)) %>%
    mutate(NPV = (revenue - costs)/(1+discount)^(year-1),
                          cum_prof = cumsum(NPV)))
  
  output$financePlot <- renderPlot({
    ggplot(df(), aes(x = year, y = cum_prof))+geom_line()})
})
