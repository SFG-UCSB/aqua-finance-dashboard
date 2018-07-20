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
                box(title = 'Overview', solidHeader = TRUE, status = 'primary',
                    width = 12,
                    includeMarkdown(path = 'dash-intro.Rmd'))
              )
              ),
      #ModelTab
    tabItem(tabName = "model",
              fluidRow(
                box(plotOutput("financePlot", height = 500, width = 600))
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
                    "init_costs",
                    "Start-Up Costs:",
                    value = 50000,
                    step = 10000
                  ),
                  numericInput(
                    "op_costs",
                    "Annual Operational Costs:",
                    value = 50000,
                    step = 10000
                  ),
                  numericInput(
                    "mussPrice",
                    "Price of Mussels ($/lb)",
                    value = 2.50,
                    step = 0.1
                  ),
                  radioButtons(
                    "size",
                    "Number of longlines:",
                    choices = c(
                      "12" = 12,
                      "36" = 36)),
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
