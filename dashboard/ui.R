dashboardPage(
  #dashboardHeader(title = logo_sfg, titleWidth = 300),
  dashboardHeader(),
  #Sidebar tabs
  dashboardSidebar(sidebarMenu(
    menuItem("Introduction", tabName = "intro", icon = icon("sticky-note")),
    menuItem("Base Model", tabName = "model", icon = icon("desktop")),
    menuItem("Additional User Inputs", tabName = "param", icon = icon("wrench")),
    menuItem("Site Map", tabName = "map", icon = icon("globe"))
  )),
  
  #Body
  dashboardBody(
    #shinyDashboardThemes(theme = "poor_mans_flatly"),
    #useShinyjs(),
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
                numericInput(
                  "discount",
                  "Discount rate (%):",
                  0.05,
                  0,
                  1,
                  0.01
                )
              )),
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
              )
      ),
    
      #newParamTab
      
      tabItem(
        tabName = "param",
        box(
          numericInput("units_area",
                       "Production units per area",
                       value = 10,
                       min = 1,
                       step = 1),
          numericInput("ind_unit",
                       "Individuals per unit of production",
                       value = 10,
                       min = 1,
                       step = 1
                       ),
          numericInput("init_size",
                       "Initial size",
                       value = 1),
          numericInput("harvest_size",
                       "Target harvest size",
                       value = 5),
          textInput("growth",
                       "Monthly growth rate",
                       value = "0.2,0.25,0.33,0.27"),
          numericInput("death",
                       "Monthly mortality",
                       value = 0.02,
                       min = 0,
                       max = 1,
                       step = 0.01),
          numericInput("sales_price",
                       "Sales price ($/mass)",
                       value = 2,
                       min = 0,
                       step = 0.1)
        ),
        box(
          numericInput("fixed_init",
                       "Fixed Initial Capital",
                       value = 50000,
                       step = 5000),
          numericInput("var_init",
                       "Size Variable Initial Cost (Per Acre)",
                       value = 1000,
                       step = 100),
          ##PER ACRE?
          numericInput("harv_cost",
                       "Harvesting Cost",
                       value = 1000,
                       step = 100),
          ##MAKE THIS PER ACRE AS WELL?
          numericInput("restock_cost",
                       "Stocking cost",
                       value = 2000,
                       step = 500),
          numericInput("monthly_op",
                       "Operational Costs (monthly)",
                       value = 5000,
                       step = 500),
          #Turn into percentage of Cap?
          numericInput("annual_maitenance",
                       "Annual maitenance cost",
                       value = 5000,
                       step = 500)
        )
      ), 
      
      
      #MapTab
      tabItem(tabName = "map",
              fluidRow(leafletOutput("aquamap")))
    )
  )
)
