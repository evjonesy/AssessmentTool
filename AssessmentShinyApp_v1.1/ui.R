library(shiny)
library(shinyBS)
library(shinyFiles)
library(raster)
library(rgdal)
library(maptools)
library(rgeos)
library(reshape2)
library(plyr)
library(dplyr)
library(ggmap)
library(leaflet)
library(DT)



shinyUI(
  navbarPage('Assessment Tool: Station Table Populator',
             tabPanel('Basic Tool',
                      sidebarPanel(
                        h4(strong('Instructions:')),
                        p('Please navigate to the directory with GIS data downloaded with the app and select a .csv file of 
                          stations.'),
                        h5(strong('Select GIS Data Directory')),
                        shinyDirButton('directory', 'Choose Directory', 'Please select a folder containing necessary GIS data.'),
                        fileInput('sites','Upload Sites',accept='.csv',width='100%'),
                        hr(),
                        # choose DEQ Regional Office
                        selectInput("regionalOffice"
                                    ,label = 'Select a VDEQ Regional Office'
                                    ,choices=c('','BRRO-L','BRRO-R','NRO','PRO','SWRO','TRO','VRO')
                                    ,selected=''),
                        hr(),
                        #run analysis button
                        p(strong("Navigate to the 'Results Table'"), "tab and ",strong("click the 'Merge Sites with GIS Information' button")," after you have uploaded a .csv of stations."),
                        p("Calculation progress can be tracked in the upper right hand corner."),
                        actionButton('runButton','Merge Sites with GIS Information'),
                        hr(),
                        p(strong("Check the 'Geometry Issues Table'"), "to verify all sites latched to the only one ID305B. If the table
                          is populated, then you need to proceed to the 'Advanced Mapping' tab to manually select WQ Standards 
                          information. Otherwise, you may proceed directly to the 'Final Results' tab. "),width=3),
                      mainPanel(
                        tabsetPanel(
                          tabPanel("Input Table",tableOutput('inputTable')),
                          tabPanel("Results Table",tableOutput('resultsTable')),
                          tabPanel("Geometry Issues Table",tableOutput('outputTableIssues'))
                        )
                      )),
             tabPanel('Advanced Mapping',
                      column(3,
                             wellPanel( #sidebarPanel(
                               h4(strong('Instructions:')),
                               p("Click the 'Plot Problem Sites on Map' button", strong("after you have identified sites in the previous step that need further review.")),
                               p("Calculation progress can be tracked in the upper right hand corner."),
                               actionButton('runButton2','Plot Problem Sites on Map'),
                               hr(),
                               p("Once the lower table is populated,", strong("select only the ID305B's would you like to keep"), "for each site, then proceed 
                                 to the User Selection Tab to review your results before moving to the Final Results Tab."),
                               downloadButton("downloadProblemSites","Download Problem Sites"))),#,width=3),
                      column(9, #mainPanel(
                             tabsetPanel(
                               tabPanel("Sites For Review",tableOutput('outputTableIssues_test'),
                                        p("These sites are identified from your original uploaded file because they either"),
                                        p("1) attached to too many stream geometries (with differing WQ Standards information) within a buffered area"),
                                        p("2) required a large (300 m) buffer to attach to stream geometries and should be reviewed or"),
                                        p("3) did not attach to any streams within a large (300 m) buffer and will need further review in ArcGIS.")),
                               tabPanel("Map",
                                        leafletOutput("issueMap"),
                                        hr(),
                                        h4("Based on the map, which ID305B's would you like to keep for each site?"),
                                        h5("Please select only the ID305B's you wish to keep. Unselected rows will be dropped from further analyses."),
                                        fluidRow(dataTableOutput('userSelectionTable'))),
                               tabPanel("User Selection",tableOutput("subsetTable"))
                             ))
                      
                      ),
             tabPanel('Final Results',
                      sidebarPanel(
                        h4(strong('Instructions:')),
                        #merge results button
                        p("Click the 'Generate Final Results' button after you have reviewed all sites in the Basic Tool and Advanced Mapping tab."),
                        actionButton('mergeTables','Generate Final Results'),
                        hr(),
                        #download results button
                        p('Click the Download Results button after you have completed and reviewed all analyses
                          to save the results to a location on your computer.'),
                        downloadButton("downloadResults","Download Final Results"),width=3),
                      mainPanel(
                        tabsetPanel(
                          tabPanel("Basic Tool Results",tableOutput('resultsTable2')),
                          tabPanel("Advanced Mapping Results",tableOutput('subsetTable2')),
                          tabPanel("Final Results",dataTableOutput('comboResults'))))),
             tabPanel('IR Stations Table',
                      column(2,wellPanel(
                        h4(strong('Instructions:')),
                        p("Navigate through the drop down list of StationID's to assign additional station information. Add all necessary information in the 'Station Information' tab prior to pressing the Add Entry button."),
                        p("You can review your work prior to downloading results in the 'Review' tab."),
                        uiOutput("choose_Station"),
                        hr(),
                        actionButton('addEntry','Add Entry'),
                        hr(),
                        fileInput('uploadPrevSession','Upload Previous Session',accept='.csv',width='100%'))),
                      column(9,
                             tabsetPanel(
                               tabPanel('Station Information',
                                        fluidRow(
                                          # bunch of select inputs
                                          column(6,
                                                 numericInput('depth',h5('Depth'),value=0.3),
                                                 h5('AU ID #1'),
                                                 verbatimTextOutput('ID305Bselection'),
                                                 textInput('ID305B_2',label=h5('AU ID #2')),
                                                 textInput('ID305B_3',label=h5('AU ID #3'))
                                          ),
                                          column(6,
                                                 selectInput('stationType1',h5('Station Type 1'),choices=paste(STA_TYPE_CODE[,1],STA_TYPE_CODE[,2],sep="  |  ")),
                                                 selectInput('stationType2',h5('Station Type 2'),choices=paste(STA_TYPE_CODE[,1],STA_TYPE_CODE[,2],sep="  |  ")),
                                                 selectInput('stationType3',h5('Station Type 3'),choices=paste(STA_TYPE_CODE[,1],STA_TYPE_CODE[,2],sep="  |  "))
                                          )),
                                        hr(),
                                        fluidRow(
                                          column(4,
                                                 h4(strong('Conventional Water Column')),
                                                 textInput('tempViolation',label=h5('Temperature Violations')), 
                                                 textInput('tempSample',label=h5('Temperature Samples')), 
                                                 selectInput('tempStatus',h5('Temperature Status'),choices=paste(tblkp_AMB_STAT_CODES[,1],tblkp_AMB_STAT_CODES[,2],sep='  |  ')),
                                                 textInput('doViolation',label=h5('DO Violations')), 
                                                 textInput('doSample',label=h5('DO Samples')), 
                                                 selectInput('doStatus',h5('DO Status'),choices=paste(tblkp_AMB_STAT_CODES[,1],tblkp_AMB_STAT_CODES[,2],sep='  |  ')),
                                                 textInput('pHViolation',label=h5('pH Violations')), 
                                                 textInput('pHSample',label=h5('pH Samples')), 
                                                 selectInput('pHStatus',h5('pH Status'),choices=paste(tblkp_AMB_STAT_CODES[,1],tblkp_AMB_STAT_CODES[,2],sep='  |  ')),
                                                 hr(),
                                                 h4(strong('Water Column')),
                                                 textInput('WCmetalsViolation',label=h5('Metals Violations')), 
                                                 selectInput('WCmetalsStatus',h5('Metals Status'),choices=paste(tblkp_AMB_STAT_CODES[,1],tblkp_AMB_STAT_CODES[,2],sep='  |  ')),
                                                 textInput('WCtoxicsViolation',label=h5('Toxics Violations')), 
                                                 selectInput('WCtoxicsStatus',h5('Toxics Status'),choices=paste(tblkp_AMB_STAT_CODES[,1],tblkp_AMB_STAT_CODES[,2],sep='  |  '))
                                          ),
                                          column(4,
                                                 h4(strong('Bacteria Data')),
                                                 textInput('eColiViolation',label=h5('eColi Violations')), 
                                                 textInput('eColiSample',label=h5('eColi Samples')), 
                                                 selectInput('eColiStatus',h5('eColi Status'),choices=paste(tblkp_AMB_STAT_CODES[,1],tblkp_AMB_STAT_CODES[,2],sep='  |  ')),
                                                 textInput('enteroViolation',label=h5('Enterococci Violations')), 
                                                 textInput('enteroSample',label=h5('Enterococci Samples')), 
                                                 selectInput('enteroStatus',h5('Enterococci Status'),choices=paste(tblkp_AMB_STAT_CODES[,1],tblkp_AMB_STAT_CODES[,2],sep='  |  ')),
                                                 hr(),
                                                 h4(strong('Sediment Data')),
                                                 textInput('SmetalsViolation',label=h5('Metals Violations')), 
                                                 selectInput('SmetalsStatus',h5('Metals Status'),choices=paste(tblkp_AMB_STAT_CODES[,1],tblkp_AMB_STAT_CODES[,2],sep='  |  ')),
                                                 textInput('StoxicsViolation',label=h5('Toxics Violations')), 
                                                 selectInput('StoxicsStatus',h5('Toxics Status'),choices=paste(tblkp_AMB_STAT_CODES[,1],tblkp_AMB_STAT_CODES[,2],sep='  |  '))
                                          ),
                                          column(4,
                                                 h4(strong('Fish Tissue')),
                                                 textInput('FTmetalsViolation',label=h5('Metals Violations')), 
                                                 selectInput('FTmetalsStatus',h5('Metals Status'),choices=paste(tblkp_AMB_STAT_CODES[,1],tblkp_AMB_STAT_CODES[,2],sep='  |  ')),
                                                 textInput('FTtoxicsViolation',label=h5('Toxics Violations')), 
                                                 selectInput('FTtoxicsStatus',h5('Toxics Status'),choices=paste(tblkp_AMB_STAT_CODES[,1],tblkp_AMB_STAT_CODES[,2],sep='  |  ')),
                                                 hr(),
                                                 h4(strong('Nutrients')),
                                                 textInput('tpExceedance',label=h5('TP Exceedances')), 
                                                 textInput('tpSample',label=h5('TP Samples')), 
                                                 selectInput('tpStatus',h5('TP Status'),choices=paste(tblkp_AMB_STAT_CODES[,1],tblkp_AMB_STAT_CODES[,2],sep='  |  ')),
                                                 textInput('chlAExceedance',label=h5('Chlorophyll A Exceedances')), 
                                                 textInput('chlASample',label=h5('Chlorophyll A Samples')), 
                                                 selectInput('chlAStatus',h5('Chlorophyll A Status'),choices=paste(tblkp_AMB_STAT_CODES[,1],tblkp_AMB_STAT_CODES[,2],sep='  |  ')),
                                                 hr(),
                                                 h4(strong('Benthics')),
                                                 selectInput('benthicStatus',h5('Benthic Status'),choices=paste(tblkp_BIO_STAT_CODES[,1],tblkp_BIO_STAT_CODES[,2],sep='  |  '))
                                          )),
                                        hr(),
                                        fluidRow(
                                          column(10,textInput('comments',label=h4(strong('Station Comments')))))
                               ),
                               tabPanel('Do Some Sweet Analysis',h4('This will be an awesome area to pull in mon data, run analysis, then output results to review table for user. Stay Tuned.')),
                               tabPanel('Review & Download',tableOutput('review'),
                                        downloadButton("downloadStationTable","Download IR Stations Table")))
                      )),
             tabPanel('About',fluidRow(column(12,
                                              h5("This app was created for the DEQ Assessors to automate the Stations Table 
                                                 building process."),
                                              h5("Users need to input a .csv file of sites they wish to associate with water
                                                 quality standards with column headers matching the exampleCSV.csv file downloaded
                                                 with the original zip file of all necessary data. Users will follow the 
                                                 instructions on each page of the app and progress from the Basic Tool tab to
                                                 the Advanced Mapping tab (if any geometry issues are identified) and finally 
                                                 to the Final Results tab to download the data and store it locally. The app 
                                                 does not save data between user sessions, so please download all results upon 
                                                 finishing each analysis."),
                                              br(),
                                              h5("Please contact Emma Jones at emma.jones@deq.virginia.gov for troubleshooing
                                                 assistance and any additional information."))))
                                              ))