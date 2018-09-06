dashboardPage(#dashboardHeader(title = logo_sfg, titleWidth = 300),
  dashboardHeader(),
  #Sidebar tabs
  dashboardSidebar(sidebarMenu(
    menuItem("Introduction",tabName = "intro",icon = icon("sticky-note")),
    menuItem("Base Model", tabName = "model", icon = icon("desktop")),
    menuItem("Additional User Inputs",tabName = "param",icon = icon("wrench")),
    menuItem("Site Map", tabName = "map", icon = icon("globe"))
  )),
  
  #Body
  dashboardBody(#shinyDashboardThemes(theme = "poor_mans_flatly"),
    #useShinyjs(),
    #Sets up structure for individual tabs
    tabItems(
      #IntroTab
      tabItem(
        tabName = "intro",
        fluidRow(
          box(
            title = 'Overview',
            solidHeader = FALSE,
            status = 'primary',
            width = 12,
            includeMarkdown(path = 'dash-intro.Rmd')
          )
        ),
        fluidRow(
          sliderInput(
            "farm_size",
            "How large is the farm (acres)?",
            value = 50,
            min = 10,
            max = 100,
            step = 5
          ),
          sliderInput(
            "time_horz",
            "Time Horizon (years):",
            min = 1,
            max = 10,
            value = 10,
            step = 1
          ),
          selectInput(
            "species",
            "Species select:",
            choices = c(
              "Finfish" = "ff",
              "Shellfish" = "sf",
              "Seaweed" = "sw"
            )
          ),
          numericInput("discount",
                       "Discount rate (%):",
                       0.05,
                       0,
                       1,
                       0.01)
        )
      ),
      #ModelTab
      tabItem(tabName = "model",
              fluidRow(
                tabBox(
                  title = "Tabbed Results",
                  width = 12,
                  tabPanel("Cash Flows", plotOutput("CashflowPlot")),
                  tabPanel("NPV", plotOutput("NPVPlot")),
                  tabPanel("Output Table", tableOutput("ledger"))
                )
              )),
      
      #newParamTab
      
      tabItem(
        tabName = "param",
        box(
          uiOutput("prod_unit_densWidget"),
          uiOutput("stocking_densWidget"),
          uiOutput("start_sizeWidget"),
          uiOutput("harvest_sizeWidget"),
          uiOutput("growthWidget"),
          uiOutput("deathWidget"),
          uiOutput("timestepWidget")
        ),
        box(
          uiOutput("sales_priceWidget"),
          uiOutput("init_fixed_capWidget"),
          uiOutput("init_var_capWidget"),
          uiOutput("harv_costWidget"),
          uiOutput("stock_costWidget"),
          uiOutput("op_costsWidget"),
          uiOutput("annual_costsWidget")
         )
      ),
      
      
      #MapTab
      tabItem(tabName = "map",
              fluidRow(
                leafletOutput("aquamap")
              ))
    )))
