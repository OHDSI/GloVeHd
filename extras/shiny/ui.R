library(shiny)
library(DT)

shinyUI(
  fluidPage(
    titlePanel("Finding similar concepts using Global Vectors (GloVe)"),
    fluidRow(
      column(12, 
             selectizeInput(inputId = "inputConcept", 
                            label = 'Input concept', 
                            choices = NULL),

             dataTableOutput(
               outputId = "similarConceptsTable"
             )
      )
            
    )
  )
)
