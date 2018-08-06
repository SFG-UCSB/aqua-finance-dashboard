dashboardPage(
  dashboardHeader(title = logo_sfg, titleWidth = 300),
  #Sidebar tabs
  dashboardSidebar(sidebarMenu(
    menuItem(
      "Introduction",
      tabName = "intro",
      icon = icon("sticky-note")
    ),
    menuItem("Model", tabName = "model", icon = icon("desktop")),
    menuItem("Map", tabName = "map", icon = icon("globe")),
    menuItem("Parameters", tabName = "param", icon = icon("wrench"))
  )),
  #Body
  dashboardBody(
    shinyDashboardThemes(theme = "poor_mans_flatly"),
    #Sets up structure for individual tabs
    tabItems(
      #IntroTab
      tabItem(tabName = "intro",
              fluidRow(
                box(
                  title = 'Overview',
                  solidHeader = FALSE,
                  status = 'primary',
                  width = 12,
                  includeMarkdown(path = 'dash-intro.Rmd')
                )
              )),
      #ModelTab
      tabItem(tabName = "model",
              fluidRow(
                box(plotOutput(
                  "financePlot", height = 400, width = 475
                ), width = 8, title = "Projected Cash Flow"),
                
                box(
                  sliderInput(
                    "num_acres",
                    "How large is the farm (acres)?",
                    value = 50,
                    min = 10,
                    max = 100,
                    step = 5
                  ),
                  sliderInput(
                    "years",
                    "Time Horizon (years):",
                    min = 3,
                    max = 10,
                    value = 5,
                    step = 1
                  ),
                  width = 4,
                  offset = 2,
                  title = "User Inputs"
                )
              )),
      #MapTab
      tabItem(tabName = "map",
              fluidRow(leafletOutput("aquamap"))),
      #ParamTab
      tabItem(tabName = "param",
              fluidRow(
              #revenue adjusters  
                box(title = "Revenue Adjusters",
                  numericInput(
                    inputId =
                      "productivity",
                    label = "Production (lbs per acre)",
                    value = 10000,
                    step = 500
                  ),
                    numericInput(
                      inputId = "sales_price",
                      label = "Sale Value ($ per lb)",
                      value = 2.5,
                      step = 0.05
                    )
              ),
              #cost adjusters
              box(title = "Expense Adjusters",
                  numericInput(inputId = "cap_costs",
                               label = "Initial Fixed Capital Costs ($)",
                  value = 200000,
                  step = 25000),
                  numericInput(inputId = "annual_costs",
                               label = "Annual Operating Costs($)",
                               value = 500000,
                               step = 25000),
                  numericInput(inputId = "processing_costs",
                               label = "Post Harvest Production Costs ($)",
                               value = 100000,
                               step = 25000)
                              )
              ),
              fluidRow(box(
                tableOutput("ledger"), collapsible = T, collapsed = T, title = "Financial Summary Table"
              ))
              )
    )
  )
)
  