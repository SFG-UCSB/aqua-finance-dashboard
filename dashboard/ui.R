#The UI is made dynamic using the uiOUtput() suite of functions. This leads to a very bare UI where essentially booksmarks are placed to insert certain widgets based upon user input. The structure uses a three part Shiny Dashboard - a header, sidebar, and body. The sidebar panel has a tab for each of the Introduction, Model Outputs, and Additional User Inputs main panels.



dashboardPage(title = "Aquaculture Financial Tool", skin = "purple",
              dashboardHeader(title = "Aquaculture Planning Financial Tool", titleWidth = 400),
              #dashboardHeader(),
              #Sidebar tabs
              dashboardSidebar(sidebarMenu(
                menuItem("Introduction",tabName = "intro",icon = icon("sticky-note")),
                menuItem("Model & Outputs", tabName = "model", icon = icon("desktop")),
                menuItem("Additional User Inputs",tabName = "param",icon = icon("wrench")),
                menuItem("User Reference Guide", tabName = "ref", icon = icon("question"))
              )
              ),
              
              #Body
              dashboardBody(
                #shinyDashboardThemes(theme = "poor_mans_flatly"),
                #useShinyjs(),
                #Sets up structure for individual tabs
                tabItems(
                  #IntroTab
                  #The Introduction tab includes a markdown document written to introduce the document and the four key user-defined parameters at the core of the simulator: time horizon in years, the size of the farm, the archetypal species (finfish, shellfish, and seaweed) and the discount rate for the analysis
                  tabItem(
                    tabName = "intro",
                    fluidRow(
                      box(
                        title = 'Overview:',
                        solidHeader = TRUE,
                        width = 12,
                        includeMarkdown(path = 'Markdown/dash-intro.Rmd')
                      )
                    )
                  ),
                  #ModelTab
                  #The model tab includes two main parts: a `tab box` used to visual key graphical trends and a series of `value boxes` designed to synthesize the main model outputs. The two main graphical tabs are the Cash Flow Graph and the NPV graph. The Cash Flow Graph depicts the cost and revenue streams shown at the individual timestep level. NPV is calculated at the annual level. Currently a tabpanel is also included for both the output of the raw model results and one in which the results are aggregated by year as well.  
                  tabItem(tabName = "model",
                          fluidRow(
                            box(width = 12, title = "User Defined Farm Inputs: ", solidHeader = TRUE,
                                column(width = 6,
                                       selectInput(
                                         "species",
                                         "Species Type",
                                         choices = c(
                                           "Finfish" = "ff",
                                           "Shellfish" = "sf",
                                           "Seaweed" = "sw"
                                         )
                                       ),
                                       uiOutput("sales_priceWidget")
                                                                       ),
                                column(width = 6,
                                       uiOutput("farm_sizeWidget"),
                                       uiOutput("time_horzWidget")
                                )
                            )
                          ),
                          fluidRow(
                            tabBox(
                              width = 9,
                              tabPanel("Payback Period", plotOutput("NPVPlot")),
                              tabPanel("Annual Cash Flows", 
                                       fluidRow(
                                         box(width = 12,
                                             plotOutput("CFPlot"),
                                             column(width = 4, offset = 4,
                                                    uiOutput("time_sliderWidget")
                                             ),
                                             footer = "*Use the slider to vary the number of months displayed")
                                       )
                              ),
                              #tabPanel("Output Table", tableOutput("ledger")),
                              tabPanel("Annual Data Table", tableOutput("annum"))
                            ),
                            #Additionally, there are three `value boxes` that display three critical model results for stakeholders: 1) The initial capital required to start the farm 2) If the farm is profitable at the end of the time horizon, the timestep during which the farm first breaks even is listed and 3) the average annual yield of product produced
                            fluidRow(
                              valueBoxOutput("init_invest_box", width = 3),
                              valueBoxOutput("profit_box", width = 3),
                              valueBoxOutput("breakeven_box", width = 3),
                              valueBoxOutput("production_box", width = 3)
                            )
                          )),
                  
                  #ParamTab
                  #The additional user inputs tab houses widgets that are "under the hood" of the model and allow for a further degree of customization. They are currently grouped into two boxes, one for financial values and the other for other parameters ditacting the model (mostly biological and structural).
                  
                  tabItem(
                    tabName = "param",
                    fluidRow(
                      box(width = 12,
                          "Please see the 'User Reference Guide' tab on the left for further information about these model inputs.", background = "purple")
                    ),
                    fluidRow(
                      box(title = "Farm Structure ", width = 12, solidHeader = TRUE,
                          column(width = 6,
                                 uiOutput("prod_unit_densWidget")
                          ),
                          column(width = 6, uiOutput("stocking_densWidget")
                          ),
                          footer = "*e.g. \"lines\", \"cages\", \"rafts\", etc.",
                          collapsible = T
                      )
                    ),
                    fluidRow(
                      box(title = "Biological Parameters", width = 12, solidHeader = TRUE,
                          column(width = 6,
                                 uiOutput("start_sizeWidget"),
                                 uiOutput("harvest_sizeWidget")
                          )
                          ,
                          column(width = 6,
                                 uiOutput("growthWidget"),
                                 uiOutput("deathWidget")
                          ),
                          footer = "*Rates are input in the form of a decimal between 0.0 and 1.0",
                          collapsible = T
                      )
                    ),
                    fluidRow(
                      box(width = 12, title = "Financial",
                          solidHeader = TRUE,
                          uiOutput("discountWidget"),
                          collapsible = T,
                          footer = "*e.g. 5% = 0.05"
                      )
                    ),
                    fluidRow(         
                      box(width = 12,title = "Initial Investments", 
                          solidHeader = TRUE,
                          column(width = 6,
                                 uiOutput("init_fixed_capWidget")
                          ),
                          column(width = 6,
                                 uiOutput("var_capWidget")
                          ),
                          footer = "* 'Fixed' costs do not scale with the size of the farm.",
                          collapsible = T
                      )
                    ),
                    fluidRow(
                      box(width = 12, title = "Operational Costs", solidHeader = TRUE,
                          column(width = 4,
                                 uiOutput("fixed_monthly_costsWidget")),
                          column(width = 4,
                                 uiOutput("var_monthly_costsWidget")),
                          column(width = 4,
                                 uiOutput("annual_costsWidget")),
                          collapsible = T
                      )
                    ),
                    fluidRow(
                      box(width = 12, title = "Miscellaneous Costs*", solidHeader = TRUE,
                          column(width = 6,
                                 uiOutput("stock_costWidget")),
                          column(width = 6,
                                 uiOutput("harv_costWidget")),
                          footer = "*These two costs are incurred each time the farm is stocked and harvested respectively and are calculated on a size-variable basis. ",
                          collapsible = T
                      )
                    )
                  ),
                  tabItem(
                    tabName = "ref",
                    fluidRow(
                      tabBox(
                        title = "User Reference Guide",
                        width = 12,
                        tabPanel("Intro & Core Inputs", includeMarkdown("Markdown/ref-intro.Rmd")),
                        tabPanel("Model & Outputs", includeMarkdown("Markdown/ref-model.Rmd")),
                        tabPanel("Additional User Inputs", includeMarkdown("Markdown/ref-addInputs.Rmd")),
                        tabPanel("Data Sources", 
                                 includeMarkdown("Markdown/ref-dataSources.Rmd"),
                                 hr(),
                                 downloadButton("parameters", "Download .csv File with Default Parameter Values"))
                        # ,
                        # tabPanel("renderTest",
                        #          fluidRow(
                        #            #box(
                        #              uiOutput("render")
                        #            #)
                        #          ))
                        
                      )
                    )
                  )
                )))
