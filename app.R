# Load required libraries
library(shiny)
library(DT)
library(ggplot2)
library(dplyr)
library(rsconnect)
library(RColorBrewer)
library(plotly)  # For interactive plots

# Define function to check if running on shinyapps.io
is_shinyapps <- function() {
  return(!is.null(Sys.getenv("SHINYIO_USER")))
}

# Define function to get file path based on environment
get_data_file_path <- function() {
  if (is_shinyapps()) {
    # If running on shinyapps.io, use relative path
    return("job_placement.csv")
  } else {
    # If running locally, construct full path
    base_folder <- "D:/Trent University/R ONLINE LECTURERS/Assignments/Rshiny_Jobplacements/"
    filename <- "job_placement.csv"
    return(file.path(base_folder, filename))
  }
}

# Read the CSV file
data <- read.csv(get_data_file_path())

# Define UI
ui <- fluidPage(
  titlePanel("Job Placement Data Explorer"),
  tags$head(
    tags$style(
      HTML(
        "
        .sidebar {
          position: fixed;
          top: 50px;
          left: 0;
          bottom: 0;
          width: 250px; /* Adjust width as needed */
          overflow-y: auto; /* Enable scrolling if content exceeds the height */
          background-color: #f8f9fa; /* Background color of the sidebar */
          padding: 20px;
        }
        "
      )
    ),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1")
  ),
  sidebarLayout(
    sidebarPanel(
      class = "sidebar", # Add class to the sidebar panel
      selectInput("college", "Select College:", c("All", unique(data$college_name)), selected = "All", multiple = TRUE),
      selectInput("gender", "Select Gender:", c("All", unique(data$gender))),
      selectInput("stream", "Select Stream:", c("All", unique(data$stream))),
      sliderInput("age", "Select Age Range:", min = min(data$age), max = max(data$age), value = c(min(data$age), max(data$age))),
      sliderInput("salary", "Select Salary Range:", min = min(data$salary), max = max(data$salary), value = c(min(data$salary), max(data$salary))),
      selectInput("placement_status", "Select Placement Status:", c("All", unique(data$placement_status))),
      actionButton("reset", "Reset Filters")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Plots",
                 plotlyOutput("barplot_college_placed"),
                 plotlyOutput("pie_chart_placed"),
                 plotlyOutput("pie_chart_unplaced"),
                 plotlyOutput("histogram"),
                 plotlyOutput("heatmap")
        ),
        tabPanel("Table", DTOutput("table")),
        tabPanel("Summary", verbatimTextOutput("summary"))
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  # Filter data based on user input
  filtered_data <- reactive({
    filtered <- data
    if (input$gender != "All") {
      filtered <- filtered[filtered$gender == input$gender, ]
    }
    if (!"All" %in% input$college) {
      filtered <- filtered[filtered$college_name %in% input$college, ]
    }
    if (input$stream != "All") {
      filtered <- filtered[filtered$stream == input$stream, ]
    }
    if (input$placement_status != "All") {
      filtered <- filtered[filtered$placement_status == input$placement_status, ]
    }
    filtered <- filtered[filtered$age >= input$age[1] & filtered$age <= input$age[2], ]
    filtered <- filtered[filtered$salary >= input$salary[1] & filtered$salary <= input$salary[2], ]
    return(filtered)
  })
  
  # Render the filtered data table
  output$table <- renderDT({
    datatable(filtered_data())
  })
  
  # Bar plot for Count of Placed Students by College
  output$barplot_college_placed <- renderPlotly({
    req(nrow(filtered_data()) > 0)
    
    # Filter data based on input parameters
    filtered <- filtered_data()
    if ("All" %in% input$college) {
      # If "All" is selected, include all colleges
      filtered <- filtered
    } else {
      # Only include selected colleges
      filtered <- filtered[filtered$college_name %in% input$college, ]
    }
    if (input$gender != "All") {
      filtered <- filtered[filtered$gender == input$gender, ]
    }
    if (input$stream != "All") {
      filtered <- filtered[filtered$stream == input$stream, ]
    }
    if (input$placement_status != "All") {
      filtered <- filtered[filtered$placement_status == input$placement_status, ]
    }
    filtered <- filtered[filtered$age >= input$age[1] & filtered$age <= input$age[2], ]
    filtered <- filtered[filtered$salary >= input$salary[1] & filtered$salary <= input$salary[2], ]
    
    # Filter data for placed students
    placed_data <- filtered[filtered$placement_status == "Placed", ]
    
    # If there's no placed data, show "No Data Available"
    if (nrow(placed_data) == 0) {
      p <- plot_ly(x = "", y = "", type = "scatter", mode = "markers", marker = list(size = 1)) %>%
        layout(title = "No students placed with the filters selected")
    } else {
      # Create a table of counts of placed students by college
      college_counts <- table(placed_data$college_name)
      
      # Convert the table to data frame
      college_counts_df <- as.data.frame(college_counts)
      colnames(college_counts_df) <- c("College", "Placed Count")
      
      # Sort the data frame by placed count
      college_counts_df <- college_counts_df[order(college_counts_df$`Placed Count`, decreasing = TRUE), ]
      
      # Create the bar plot with count labels
      p <- plot_ly(college_counts_df, x = ~reorder(College, `Placed Count`), y = ~`Placed Count`, type = 'bar', 
                   text = ~paste(`Placed Count`), marker = list(color = 'skyblue')) %>%
        layout(title = "Count of Placed Students by College", xaxis = list(title = "College"), yaxis = list(title = "Placed Count"))
    }
    p
  })
  
  # Pie chart for Stream by Placement Status (Placed)
  output$pie_chart_placed <- renderPlotly({
    req(nrow(filtered_data()) > 0)
    stream_counts <- table(filtered_data()[filtered_data()$placement_status == "Placed", "stream"])
    if (sum(stream_counts) > 0) {
      pie_chart <- plot_ly(labels = names(stream_counts), values = stream_counts, type = 'pie') %>%
        layout(title = "Pie Chart of Stream (Placed)")
    } else {
      pie_chart <- plot_ly(x = "", y = "", type = "scatter", mode = "markers", marker = list(size = 1)) %>%
        layout(title = "No Data Available with the filters you selected")
    }
    pie_chart
  })
  
  # Pie chart for Stream by Placement Status (Unplaced)
  output$pie_chart_unplaced <- renderPlotly({
    req(nrow(filtered_data()) > 0)
    stream_counts <- table(filtered_data()[filtered_data()$placement_status == "Not Placed", "stream"])
    if (sum(stream_counts) > 0) {
      pie_chart <- plot_ly(labels = names(stream_counts), values = stream_counts, type = 'pie') %>%
        layout(title = "Pie Chart of Stream (Unplaced)")
    } else {
      pie_chart <- plot_ly(x = "", y = "", type = "scatter", mode = "markers", marker = list(size = 1)) %>%
        layout(title = "No Data Available")
    }
    pie_chart
  })
  
  
  # Render histogram
  output$histogram <- renderPlotly({
    gg <- ggplot(filtered_data(), aes(x = salary)) + geom_histogram(fill = "maroon", color = "black") +
      labs(title = "Salary Distribution", x = "Salary", y = "Frequency")
    ggplotly(gg)
  })
  
  
  # Render heatmap
  output$heatmap <- renderPlotly({
    gg <- ggplot(filtered_data(), aes(x = gpa, y = years_of_experience, fill = salary)) +
      geom_tile() +
      scale_fill_gradientn(colors = brewer.pal(9, "Oranges"), na.value = "grey90") +
      labs(title = "Average Salary by GPA and Years of Experience (Heatmap)",
           x = "GPA", y = "Years of Experience", fill = "Average Salary") +
      theme_minimal()
    ggplotly(gg)
  })
  
  # Render summary statistics
  output$summary <- renderPrint({
    summary(filtered_data())
  })
  
  # Reset filters
  observeEvent(input$reset, {
    updateSelectInput(session, "college", selected = "All")
    updateSelectInput(session, "gender", selected = "All")
    updateSelectInput(session, "stream", selected = "All")
    updateSliderInput(session, "age", value = c(min(data$age), max(data$age)))
    updateSliderInput(session, "salary", value = c(min(data$salary), max(data$salary)))
    updateSelectInput(session, "placement_status", selected = "All")
  })
}

# Run the application
shinyApp(ui = ui, server = server)
