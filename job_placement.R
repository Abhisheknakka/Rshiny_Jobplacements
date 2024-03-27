# Load required libraries

# git commit


library(shiny)
library(DT)
library(ggplot2)
library(dplyr)

base_folder <- "C:/Users/nsnai/OneDrive/Documents/Rshiny_Jobplacements/"
input_folder <- paste0(base_folder,"input_files/")

#base_folder <- "D:/Trent University/R ONLINE LECTURERS/Assignments/TERM PROJECT/"

filename <- "job_placement.csv"

data <- read.csv(paste0(base_folder,filename))

# Define UI
ui <- fluidPage(
  titlePanel("Job Placement Data Explorer"),
  sidebarLayout(
    sidebarPanel(
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
                 plotOutput("histogram"),
                 plotOutput("scatterplot"),
                 plotOutput("boxplot_gpa"),
                 plotOutput("boxplot_salary"),
                 plotOutput("barplot_gender"),
                 plotOutput("barplot_degree"),
                 plotOutput("barplot_stream"),
                 plotOutput("barplot_experience")
        ),
        tabPanel("Summary", verbatimTextOutput("summary"))
      )
    )
  )
)

# Define server logic
server <- function(input, output) {
  
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
  
  # Render histogram
  output$histogram <- renderPlot({
    ggplot(filtered_data(), aes(x = salary)) + geom_histogram(fill = "skyblue", color = "black") +
      labs(title = "Salary Distribution", x = "Salary", y = "Frequency")
  })
  
  # Render scatterplot
  output$scatterplot <- renderPlot({
    ggplot(filtered_data(), aes(x = gpa, y = salary, color = placement_status)) + geom_point() +
      labs(title = "GPA vs Salary", x = "GPA", y = "Salary", color = "Placement Status")
  })
  
  # Boxplot for GPA
  output$boxplot_gpa <- renderPlot({
    ggplot(filtered_data(), aes(x = placement_status, y = gpa, fill = placement_status)) +
      geom_boxplot() +
      labs(title = "Boxplot of GPA by Placement Status", x = "Placement Status", y = "GPA")
  })
  
  # Boxplot for Salary
  output$boxplot_salary <- renderPlot({
    ggplot(filtered_data(), aes(x = placement_status, y = salary, fill = placement_status)) +
      geom_boxplot() +
      labs(title = "Boxplot of Salary by Placement Status", x = "Placement Status", y = "Salary")
  })
  
  # Barplot for Gender
  output$barplot_gender <- renderPlot({
    ggplot(filtered_data(), aes(x = gender, fill = placement_status)) +
      geom_bar(position = "dodge") +
      labs(title = "Barplot of Gender by Placement Status", x = "Gender", y = "Count", fill = "Placement Status")
  })
  
  # Barplot for Degree
  output$barplot_degree <- renderPlot({
    ggplot(filtered_data(), aes(x = degree, fill = placement_status)) +
      geom_bar(position = "dodge") +
      labs(title = "Barplot of Degree by Placement Status", x = "Degree", y = "Count", fill = "Placement Status")
  })
  
  # Barplot for Stream
  output$barplot_stream <- renderPlot({
    ggplot(filtered_data(), aes(x = stream, fill = placement_status)) +
      geom_bar(position = "dodge") +
      labs(title = "Barplot of Stream by Placement Status", x = "Stream", y = "Count", fill = "Placement Status") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  # Barplot for Experience
  output$barplot_experience <- renderPlot({
    ggplot(filtered_data(), aes(x = years_of_experience, fill = placement_status)) +
      geom_bar(position = "dodge") +
      labs(title = "Barplot of Years of Experience by Placement Status", x = "Years of Experience", y = "Count", fill = "Placement Status")
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
