# Load required libraries

library(shiny)
library(DT)
library(ggplot2)
library(dplyr)


if (Sys.getenv("GITHUB_ACTIONS") == "true") {
  # Running on GitHub Pages
  base_folder <- ""
  input_folder <- "input_files"
} else {
  # Running locally
  base_folder <- "D:/Trent University/R ONLINE LECTURERS/Assignments/Rshiny_Jobplacements/"
  input_folder <- paste0(base_folder, "input_files")
}

# Define the filename
filename <- "job_placement.csv"

# Construct the full path to the CSV file
full_path <- file.path(input_folder, filename)

# Read the CSV file
data <- read.csv(full_path)

print("data loaded")

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
    )
  ),
  sidebarLayout(
    sidebarPanel(
      class = "sidebar", # Add class to the sidebar panel
      selectInput("gender", "Select Gender:", c("All", unique(data$gender))),
      selectInput("degree", "Select Degree:", c("All", unique(data$degree))),
      selectInput("stream", "Select Stream:", c("All", unique(data$stream))),
      sliderInput("age", "Select Age Range:", min = min(data$age), max = max(data$age), value = c(min(data$age), max(data$age))),
      sliderInput("salary", "Select Salary Range:", min = min(data$salary), max = max(data$salary), value = c(min(data$salary), max(data$salary))),
      selectInput("placement_status", "Select Placement Status:", c("All", unique(data$placement_status))),
      actionButton("reset", "Reset Filters")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Table", DTOutput("table")),
        tabPanel("Plots",
                 plotOutput("pie_chart_placed"),
                 plotOutput("pie_chart_unplaced"),
                 plotOutput("histogram"),
                 plotOutput("scatterplot"),
                 plotOutput("line_chart"),
                 plotOutput("boxplot_salary")
        ),
        tabPanel("Summary", verbatimTextOutput("summary"))
      )
    )
  )
)

# Define server logic
server <- function(input, output,session) {
  
  # Filter data based on user input
  filtered_data <- reactive({
    filtered <- data
    if (input$gender != "All") {
      filtered <- filtered[filtered$gender == input$gender, ]
    }
    if (input$degree != "All") {
      filtered <- filtered[filtered$degree == input$degree, ]
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
  
  # Pie chart for Stream by Placement Status (Placed)
  output$pie_chart_placed <- renderPlot({
    req(nrow(filtered_data()) > 0)
    stream_counts <- table(filtered_data()[filtered_data()$placement_status == "Placed", "stream"])
    if (sum(stream_counts) > 0) {
      pie(stream_counts, labels = paste(names(stream_counts), " (", round(100 * stream_counts / sum(stream_counts), 1), "%)"), main = "Pie Chart of Stream (Placed)")
    } else {
      plot(1, type = "n", xlab = "", ylab = "", main = "No Data Available")
    }
  })
  
  # Pie chart for Stream by Placement Status (Unplaced)
  output$pie_chart_unplaced <- renderPlot({
    req(nrow(filtered_data()) > 0)
    stream_counts <- table(filtered_data()[filtered_data()$placement_status == "Not Placed", "stream"])
    if (sum(stream_counts) > 0) {
      pie(stream_counts, labels = paste(names(stream_counts), " (", round(100 * stream_counts / sum(stream_counts), 1), "%)"), main = "Pie Chart of Stream (Unplaced)")
    } else {
      plot(1, type = "n", xlab = "", ylab = "", main = "No Data Available")
    }
  })
  
  
  # Render histogram
  output$histogram <- renderPlot({
    ggplot(filtered_data(), aes(x = salary)) + geom_histogram(fill = "maroon", color = "black") +
      labs(title = "Salary Distribution", x = "Salary", y = "Frequency")
  })
  
  # Render scatterplot
  output$scatterplot <- renderPlot({
    ggplot(filtered_data(), aes(x = gpa, y = salary, color = placement_status)) + geom_point() +
      labs(title = "GPA vs Salary", x = "GPA", y = "Salary", color = "Placement Status")
  })
  
  # Line chart: GPA vs Salary
  output$line_chart <- renderPlot({
    ggplot(filtered_data(), aes(x = gpa, y = salary)) +
      geom_point() +
      geom_smooth(method = "lm", se = FALSE, color = "blue") +
      labs(title = "Scatter Plot with  Line: GPA vs Salary", x = "GPA", y = "Salary")
  })
  

  # Boxplot for Salary by Placement Status
  output$boxplot_salary <- renderPlot({
    ggplot(filtered_data(), aes(x = placement_status, y = salary, fill = placement_status)) +
      geom_boxplot() +
      labs(title = "Boxplot of Salary by Placement Status", x = "Placement Status", y = "Salary")
  })
  
  
  # Render summary statistics
  output$summary <- renderPrint({
    summary(filtered_data())
  })
  
  # Reset filters
  observeEvent(input$reset, {
    updateSelectInput(session, "gender", selected = "All")
    updateSelectInput(session, "degree", selected = "All")
    updateSelectInput(session, "stream", selected = "All")
    updateSliderInput(session, "age", value = c(min(data$age), max(data$age)))
    updateSliderInput(session, "salary", value = c(min(data$salary), max(data$salary)))
    updateSelectInput(session, "placement_status", selected = "All")
  })
}

# Run the application
shinyApp(ui = ui, server = server)

