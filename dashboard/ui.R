dashboardPage(
  dashboardHeader(title = logo_sfg, titleWidth = 300),
  #Sidebar tabs
  dashboardSidebar(
    sidebarMenu(
    menuItem("Introduction", tabName = "intro", icon = icon("sticky-note")),
    menuItem("Model", tabName = "model", icon = icon("desktop")),
    menuItem("Map", tabName = "map", icon = icon("globe")),
    menuItem("Parameters", tabName = "param", icon = icon("wrench"))
    )
  ),
    #Body
  dashboardBody(
    shinyDashboardThemes(theme = "poor_mans_flatly"),
  #Sets up structure for individual tabs  
    tabItems(
      #IntroTab
      tabItem(tabName = "intro",
              fluidRow(
                box(title = 'Overview', solidHeader = FALSE, status = 'primary',
                    width = 12,
                    includeMarkdown(path = 'dash-intro.Rmd'))
              )
              ),
      #ModelTab
    tabItem(tabName = "model",
              fluidRow(
                box(plotOutput("financePlot", height = 400, width = 475), width = 9),
                
                box(sliderInput(
                  "num_acres",
                  "How large is the farm?",
                  value = 50,
                  min = 10,
                  max = 100,
                  step =10
                ),radioButtons(
                  "init_costs",
                  "Level of initial capitalization:",
                  choiceNames = list("Low", "Medium", "High"),
                  choiceValues = list(200000,500000,800000),
                  selected = 500000
                ),
                width = 3, offset = 2
                    )
              ),
            fluidRow(
              box(tableOutput("ledger"))
            )
      ),
      #MapTab
      tabItem(tabName = "map",
              fluidRow(
                leafletOutput("aquamap")
              )
              ),
      #ParamTab
      tabItem(tabName = "param",
              fluidRow(
                box(
                  numericInput(
                    "op_costs",
                    "Annual Operational Costs:",
                    value = 500000,
                    step = 50000
                  ),
                  numericInput(
                    "mussPrice",
                    "Price of Mussels ($/lb)",
                    value = round(2.50,2),
                    step = 0.1
                  ),
                  sliderInput(
                    "years",
                    "Time Horizon:",
                    min = 3,
                    max = 10,
                    value = 5,
                    step = 1
                  )
                )
              )
              )
   )
  )
)
