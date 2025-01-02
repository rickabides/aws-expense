# Load required libraries
library(shiny)
library(tidyverse)
library(forecast)
library(lubridate)
library(conflicted)
library(zoo)
library(shinyjs)

conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")

# UI
ui <- fluidPage(
  useShinyjs(),
  titlePanel("AWS Service Expense Tracker with File Upload"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload AWS Expense File (CSV)", 
                accept = c(".csv")),
      selectInput("selected_service", "Select Service:", 
                  choices = NULL),
      sliderInput("forecast_horizon", "Forecast Horizon (Days):", 
                  min = 7, max = 90, value = 30),
      actionButton("update", "Update Forecast"),
      downloadButton("download_forecast", "Download Forecast Data")
    ),
    mainPanel(
      div(id = "error_message", style = "color: red;"),
      tabsetPanel(
        tabPanel("Historical Data", plotOutput("expensePlot")),
        tabPanel("Forecast", plotOutput("forecastPlot")),
        tabPanel("Forecast Data", tableOutput("forecastTable")),
        tabPanel("Anomaly Detection", plotOutput("anomalyPlot"))
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Data processing with error handling
  uploaded_data <- reactive({
    req(input$file)
    
    tryCatch({
      raw_data <- read.csv(input$file$datapath)
      validate(need(ncol(raw_data) > 1, "Invalid file format"))
      
      raw_data <- raw_data[-1, ]
      colnames(raw_data)[1] <- "Date"
      
      processed_data <- raw_data %>%
        mutate(Date = as.Date(Date, format = "%Y-%m-%d")) %>%
        pivot_longer(cols = -Date, names_to = "Service", values_to = "Cost") %>%
        mutate(Cost = as.numeric(Cost)) %>%
        filter(!is.na(Cost)) %>%
        arrange(Date)
      
      updateSelectInput(session, "selected_service", 
                        choices = unique(processed_data$Service))
      
      hide("error_message")
      return(processed_data)
      
    }, error = function(e) {
      html("error_message", paste("Error:", e$message))
      return(NULL)
    })
  })
  
  # Filtered data with validation
  filtered_data <- reactive({
    req(uploaded_data(), input$selected_service)
    data <- uploaded_data() %>% 
      filter(Service == input$selected_service)
    
    validate(need(nrow(data) >= 3, 
                  "Insufficient data points for analysis"))
    return(data)
  })
  
  # Time series conversion
  ts_data <- reactive({
    req(filtered_data())
    ts(filtered_data()$Cost, 
       start = c(year(min(filtered_data()$Date)), 
                 month(min(filtered_data()$Date))), 
       frequency = 12)
  })
  
  # Historical plot
  output$expensePlot <- renderPlot({
    req(filtered_data())
    ggplot(filtered_data(), aes(x = Date, y = Cost)) +
      geom_line(color = "blue") +
      geom_point(color = "red") +
      labs(title = paste("Historical Expenses for", 
                         input$selected_service),
           x = "Date", y = "Cost") +
      theme_minimal()
  })
  
  # Forecast model with progress indicator
  forecast_model <- reactive({
    req(input$update, ts_data())
    withProgress(message = 'Fitting model...', {
      auto.arima(ts_data())
    })
  })
  
  # Cached forecast results
  forecast_results <- reactive({
    req(forecast_model())
    isolate({
      withProgress(message = 'Generating forecast...', {
        forecast(forecast_model(), h = input$forecast_horizon)
      })
    })
  }) %>% 
    bindCache(input$selected_service, input$forecast_horizon)
  
  # Forecast plot
  output$forecastPlot <- renderPlot({
    req(forecast_results())
    plot(forecast_results(), 
         main = paste("Forecast for", input$selected_service))
  })
  
  # Forecast table
  output$forecastTable <- renderTable({
    req(forecast_results())
    as.data.frame(forecast_results())
  })
  
  # Download handler
  output$download_forecast <- downloadHandler(
    filename = function() {
      paste("forecast-", input$selected_service, ".csv", sep = "")
    },
    content = function(file) {
      write.csv(as.data.frame(forecast_results()), file)
    }
  )
  
  # Anomaly detection with improved calculation
  output$anomalyPlot <- renderPlot({
    req(filtered_data())
    
    anomaly_data <- filtered_data() %>%
      mutate(
        rolling_mean = zoo::rollmean(Cost, k = 3, fill = NA),
        rolling_sd = zoo::rollapply(Cost, 3, sd, fill = NA),
        z_score = (Cost - rolling_mean) / rolling_sd,
        is_anomaly = abs(z_score) > 2
      ) %>%
      replace_na(list(is_anomaly = FALSE))
    
    ggplot(anomaly_data, aes(x = Date, y = Cost)) +
      geom_line(color = "blue") +
      geom_point(aes(color = is_anomaly), size = 2) +
      scale_color_manual(values = c("TRUE" = "red", "FALSE" = "black"),
                         labels = c("TRUE" = "Anomaly", "FALSE" = "Normal")) +
      labs(title = paste("Anomaly Detection for", input$selected_service),
           x = "Date", y = "Cost",
           color = "Data Point Type") +
      theme_minimal() +
      theme(legend.position = "bottom")
  })
}

# Run the app
shinyApp(ui = ui, server = server)