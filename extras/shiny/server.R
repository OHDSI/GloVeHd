library(shiny)
library(DT)
library(dplyr)

shinyServer(function(input, output, session) {
  updateSelectizeInput(session, 'inputConcept', choices = autoCompleteList, server = TRUE)
  
  output$similarConceptsTable <- renderDataTable({
    inputString <- input$inputConcept
    if (is.null(inputString)) {
      return(NULL)
    }
    conceptId <- gsub("\\)$", "", gsub("^.*\\(", "", inputString))
    if (conceptId == "") {
      return(NULL)
    } else {
      query <- conceptVectors[as.character(conceptId), , drop = FALSE]
      cos_sim <- text2vec::sim2(x = conceptVectors, y = query, method = "cosine", norm = "l2")
      similarity <- head(sort(cos_sim[,1], decreasing = TRUE), 25)
      similarity <- tibble(similarity = similarity, conceptId = as.numeric(names(similarity)))
      result <- similarity %>% 
        inner_join(attr(conceptVectors, "conceptReference"), by = "conceptId") %>%
        arrange(desc(similarity)) 
      table <- datatable(result,
                          options = list(
                            paging =TRUE,
                            pageLength =  25),
                          rownames= FALSE
      ) %>% formatStyle("similarity",
                       background = styleColorBar(range(result$similarity), 'lightblue'),
                       backgroundSize = '98% 88%',
                       backgroundRepeat = 'no-repeat',
                       backgroundPosition = 'center') %>%
        formatRound("similarity", digits=3)
      return(table)
    }
    
  }) 
  
})

