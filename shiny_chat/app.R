library(shiny)
library(shinyjs)
library(shinyalert)
library(tidyverse)
library(shinythemes)
library(mongolite)
library(shinyWidgets)

library(openai)


source("secret.R")

Vero = "You are Vero. An AI team member that is expert in teamwork and collaboration. Start each message with an integer from 0 to 100 that represent your certainty in the message. Separate this number with blank space from the rest og the message. If you do not feel it is necessary to answer, report low certainty. Also you are en export on survival and you know that A sextant. I think this item is one of the least important. A shaving mirror. I think this item is one of the most important. A quantity of mosquito netting. I think this item is one of the least important. A 5 gallon can of water. I think this item is one of the most important. A case of army rations. I think this item is one of the most important. Maps of the Pacific Ocean. I think this item is one of the least important. A floating seat cushion. I think this item is neither the most nor the least important. A 2 gallon can of oil/petrol mixture. I think this item is one of the most important. A small transistor radio. I think this item is one of the least important. 20 square feet of opaque plastic sheeting. I think this item is neither the most nor the least important. Shark repellent. I think this item is neither the most nor the least important. One quart of 160 percent proof rum. I think this item is neither the most nor the least important. 15 ft nylon rope. I think this item is neither the most nor the least important. 2 boxes of chocolate bars. I think this item is neither the most nor the least important. A fishing kit. I think this item is neither the most nor the least important. Limit your reply to a few sentences."

current_time <- function(){
  Sys.time() |> 
    as.POSIXlt(format="%H:%M:%OS") |> 
    format("%H:%M:%OS")
}

user_name_color <- function(user_name, color){
  str_glue('<span style="color:{color}">{user_name}</span>', 
           color = color,
           user_name = user_name)
}

Sys.setenv(
  OPENAI_API_KEY = OPENAI_API_KEY
)


connection_string = paste0('mongodb+srv://',
                           user_mongo, ':',
                           pass_mongo,
                           '@cluster0.9xhplvh.mongodb.net/?retryWrites=true&w=majority')

mongo_batch = mongo(collection="chat_experiment",
                    db="test_0", url=connection_string)

# mongo_prompt_state = mongo(collection="prompt_state_experiment",
#                     db="test_0", url=connection_string)


val <- reactiveValues(txt = NULL, 
                      txt_html = NULL,
                      users = c(),
                      # user_color = NULL,
                      likert_1_state = FALSE,
                      likert_2_state = FALSE,
                      prompt_state = TRUE,
                      new_usr = NULL, 
                      usr_left =NULL,
                      prompt_message  = NULL)

intro <- "In this chat you will be matched with a conversation partner <br> 
Please, do not share any personal information, and be polite<br>"

if (file.exists("chat_txt.Rds")) {
  val$txt <- readRDS("chat_txt.Rds")
  val$txt_html <- readRDS("chat_txt.Rds")
} else {
  val$txt <- intro
  val$txt_html <- intro
}

jsCode <- "// send message on enter
jQuery(document).ready(function(){
  jQuery('#text_msg').keypress(function(evt){
    if (evt.keyCode == 13){
      // Enter, simulate clicking send
      jQuery('#send').click();
      jQuery('#text_msg').html('hihihi');
    }
  });
})

// auto scroll to bottom
var oldContent = null;
window.setInterval(function() {
  var elem = document.getElementById('chat_div');
  if (oldContent != elem.innerHTML){
    scrollToBottom();
  }
  oldContent = elem.innerHTML;
}, 300);

// Scroll to the bottom of the chat window.
function scrollToBottom(){
  var elem = document.getElementById('chat_div');
  elem.scrollTop = elem.scrollHeight;
}"

ui <- fluidPage(
  theme = shinytheme("superhero"),
  shinyjs::useShinyjs(),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
  ),
  extendShinyjs(text = jsCode, functions = c()),
  # extendShinyjs(script = "./www/hidedivs.js", text = jsCode, 
  #               functions = c("init")),
  div(
    id = "header_div",
  fluidRow(
    column(width = 6,
           h5("Experimental chat")),
    column(
      width = 6,
      align = "right",
      br(),
      htmlOutput("logged_usr")
    )
  )),
  div(style = "height : 400px;",
      fluidRow(
        column(
          width = 9,
            div(
              id = "chat_div",
              style = 'overflow-x: scroll;
              height : 400px;',
              htmlOutput("chat_window_html")
              ),
          # ),
          # style = "height : 400px;",
          # verbatimTextOutput("chat_window"),
          # tags$head(tags$style("")),
          uiOutput("notify")
        ),
        div(
          id = "active_users_div",
          column(width = 3,
          h5("Active Users"),
          hr(),
          textOutput("users")))

      )
  ),
  fluidRow(
  div(
    id = "prompt_btn_div",
    column(width = 12,
    actionButton("prompt_btn", "Get prompt",
                        width = "100%"),
    )
  ),
  div(
    id = "slider_pre_div",
    tags$style(type = "text/css", ".irs-grid-pol.small {height: 0px;}"),
    column(
      width = 9,
    sliderTextInput(
      inputId = "slider_pre_1",
      label = "Talking to strangers is a challenging task", 
      grid = T,
      width = "100%",
      force_edges = TRUE,
      choices = c("Strongly disagree", "Disagree", 
                  "Neither agree nor disagree", 
                  "Agree", "Strongly agree")
      )
    ),
    column(
      width = 3,
      actionButton("sumbit_1_btn", "submit",
                   width = "100%"),
    )
  ),
  div(
    id = "slider_post_div",
    tags$style(type = "text/css", ".irs-grid-pol.small {height: 0px;}"),
    column(
      width = 9,
      sliderTextInput(
        inputId = "slider_post_1",
        label = "How did the prompts affect the conversation?", 
        grid = TRUE,
        width = "100%",
        force_edges = TRUE,
        choices = c("Prompts made it better", 
                    "Prompts did not change anything", 
                    "Prompts made it worse")
      )
    ),
    column(
      width = 3,
      actionButton("sumbit_2_btn", "submit",
                   width = "100%"),
    )
  )
  ),
  fluidRow(column(
    width = 9,
    textInput("text_msg", "", 
              value = "", width = "100%",
              placeholder = "Enter you message"),
  ),
  column(width = 3,
         br(),
         actionButton("send", "Send",
                      width = "100%")))
)

server <- function(input, output, session) {
  
  # on session start
  runjs("// hide bunch of divs
shinyjs.init = function(){
    $('#slider_pre_div').hide();
    $('#slider_post_div').hide();
    $('#header_div').hide();
    $('#active_users_div').hide();
  }
  
shinyjs.init()")
  
  # // $('#prompt_btn_div').hide();
  # JS bad code practice
  # state_prompt_logs <- data.frame(
  #   timestamp = Sys.time(),
  #   element = "prompt_button",
  #   state = FALSE
  # )
  # mongo_prompt_state$insert(state_prompt_logs)
  # val$mongo_prompt_state = FALSE
  
  
  
  
  # shinyjs::hide("prompt_btn")
  # shinyjs::hide("active_users_div")
  # shinyjs::hide("header_div")
  # shinyjs::hide("slider_pre_div")
  
  # session-specific color
  user_color <-  "#5DADE2" 
  Users_show <- FALSE
  
  
  # renaming your user name ----
  observeEvent("", {
    username <- paste0("Username", round(runif(1, 10000, 99999)))
    shinyalert(
      inputId = "username" ,
      "Welcome to Anonymous Chat",
      html = TRUE,
      text = tagList(
        textInput("uname", "Please rename yourself", value = username),
      ),
      closeOnEsc = FALSE,
      closeOnClickOutside = FALSE,
      showCancelButton = FALSE,
      showConfirmButton = TRUE
    )
  })
  # ----
  
  # to display new user joined ----
  observeEvent(input$username, {
    val$users <- c(val$users, input$uname)
    paste0("New user joined : ", input$uname) -> new_usr
    # showNotification(new_usr,
    #                  duration = 3,
    #                  type = "message")
    print(new_usr)
    print(val$users)
    
    if (input$uname == "Moderator") {
      user_color <<-  "#EC7063"
    } else if (input$uname == "user_2") {
      user_color <<- "#45B39D"
    } else {
      user_color <<- "#5DADE2" 
    }
  })
  
  output$users <- renderText({paste(val$users, collapse = '\n')})
  # ----
  
  output$logged_usr <- renderText({
    paste("<b>", input$uname, "</b>")
  })
  
  # sending msg ----
  observeEvent(input$send, {
    
    # if the txt msg is empty
    if (input$text_msg == "") {
      shinyalert(
        "Oops!", "Can't send a blank message",
        type = "error", closeOnEsc = TRUE,
        timer = 3000, closeOnClickOutside = TRUE,
        showCancelButton = FALSE, showConfirmButton = TRUE
      )
    } else if (input$text_msg == "!delete") {
      val_txt <- intro
      val$txt_html <- intro
      saveRDS(val$txt_html, "chat_txt.Rds")
      updateTextInput(session, "text_msg", value = "")
      
      # output$chat_window <- renderText({val$txt})
      
      output$chat_window_html <- renderUI({
        HTML(str_glue("<html> <p>", val$txt_html, "</p> </html>"))
      })
      
      
    } else if (input$text_msg == "!dump"){
      
      logs <- data.frame(
        timestamp = Sys.time(),
        text = isolate(val$txt)
      )
      
      mongo_batch$insert(logs)
      
      updateTextInput(session, "text_msg", value = "")
    } else if (input$text_msg == "!show_users") {
      shinyjs::show("active_users_div")
      shinyjs::show("header_div")
    } 
    ## likert scales
    else if (input$text_msg == "!show_likert_1") {
      val$likert_1_state = TRUE
      updateTextInput(session, "text_msg", value = "")
    } else if (input$text_msg == "!hide_likert_1") {
      val$likert_1_state = FALSE
      updateTextInput(session, "text_msg", value = "")
    } else if (input$text_msg == "!show_likert_2") {
      val$likert_2_state = TRUE
      updateTextInput(session, "text_msg", value = "")
    } else if (input$text_msg == "!hide_likert_2") {
      val$likert_2_state = FALSE
      updateTextInput(session, "text_msg", value = "")
    } 
    ## prompts
    else if (input$text_msg == "!hide_prompt") {
      
      # state_prompt_logs <- data.frame(
      #   timestamp = Sys.time(),
      #   element = "prompt_button",
      #   state = FALSE
      # )
      # 
      # mongo_prompt_state$insert(state_prompt_logs)
      val$prompt_state = FALSE
      
      updateTextInput(session, "text_msg", value = "")
    } else if (input$text_msg == "!show_prompt") {
      
      # state_prompt_logs <- data.frame(
      #   timestamp = Sys.time(),
      #   element = "prompt_button",
      #   state = TRUE
      # )
      # 
      # mongo_prompt_state$insert(state_prompt_logs)
      
      val$prompt_state = TRUE
      
      updateTextInput(session, "text_msg", value = "")
    } else if (input$text_msg |>  startsWith("!prompt")) {
      
      val$prompt_message <- isolate(input$text_msg)
      updateTextInput(session, "text_msg", value = "")
      
      
      
    } else if (input$text_msg |>  startsWith("!color")) {
      user_color <<- isolate(input$text_msg) |> str_remove("!color ")
      updateTextInput(session, "text_msg", value = "")
    } else {
      if(object.size(val$txt)>50000){
        val$txt <- intro
        val$txt_html <- intro
      }
      new <- paste(current_time(), "#", 
                   # input$uname,
                   user_name_color(user_name = input$uname, color = user_color),
                   ":" , input$text_msg)
      
      val$txt <- str_glue(val$txt, new, sep = '\n')
      
      val$txt_html <- str_glue(val$txt_html, new, " <br>")
      
      updateTextInput(session, "text_msg", value = "")
      
      saveRDS(val$txt_html, "chat_txt.Rds")
      
      
      tibble(
        # content = Vero,
        content = "You are AVGST Bot. An AI system that is an expert in communication and self disclosure. Each message starts with user_id and followed by a message text. You will generate short prompts for self-disclosure and communication, that are relevant for the previous discussion and are one or two sentences maximum. These are example of such prompts: Given the choice of anyone in the world, whom would you want as a dinner guest? Would you like to be famous? In what way? Before making a telephone call, do you ever rehearse what you are going to say? Why? What would constitute a perfect day for you? When did you last sing to yourself? To someone else? If you were able to live to the age of 90 and retain either the mind or body of a 30-year-old for the last 60 years of your life, which would you want? Do you have a secret hunch about how you will die? If a crystal ball could tell you the truth about yourself, your life, the future, or anything else, what would you want to know? Is there something that you've dreamed of doing for a long time? Why haven't you done it? What is the greatest accomplishment of your life? What do you value most in a friendship? What is your most treasured memory? What is your most terrible memory? If you knew that in one year you would die suddenly, would you change anything about the way you are now living? Why? What does friendship mean to you? What roles do love and affection play in your life?  Alternate sharing something you consider a positive characteristic of your partner. Share a total of 2 items.)",
        role = "system") |> 
        bind_rows(
          tibble(content = isolate(val$txt_html) |> str_split(pattern = "\\n") |>  unlist()) |>
            filter(content != "") |>
            mutate(role = "user") 
        ) |> 
        purrr::transpose() -> l
      
      gpt <- create_chat_completion(
        model = "gpt-4",
        messages = l
      )
      
      val$prompt_message <- gpt[["choices"]][["message.content"]]
      
      updateActionButton(inputId = "prompt_btn",
                         label = isolate(val$prompt_message))
    }
  })
  
  ### generating prompt
  
  observeEvent(input$prompt_btn, {
    
    # tibble(
    #   # content = Vero,
    #   content = "You are AVGST Bot. An AI system that is an expert in communication and self disclosure. Each message starts with user_id and followed by a message text. You will generate short prompts for self-disclosure and communication, that are relevant for the previous discussion and are one or two sentences maximum. These are example of such prompts: Given the choice of anyone in the world, whom would you want as a dinner guest? Would you like to be famous? In what way? Before making a telephone call, do you ever rehearse what you are going to say? Why? What would constitute a perfect day for you? When did you last sing to yourself? To someone else? If you were able to live to the age of 90 and retain either the mind or body of a 30-year-old for the last 60 years of your life, which would you want? Do you have a secret hunch about how you will die? If a crystal ball could tell you the truth about yourself, your life, the future, or anything else, what would you want to know? Is there something that you've dreamed of doing for a long time? Why haven't you done it? What is the greatest accomplishment of your life? What do you value most in a friendship? What is your most treasured memory? What is your most terrible memory? If you knew that in one year you would die suddenly, would you change anything about the way you are now living? Why? What does friendship mean to you? What roles do love and affection play in your life?  Alternate sharing something you consider a positive characteristic of your partner. Share a total of 2 items.)",
    #        role = "system") |>
    #   bind_rows(
    #     tibble(content = isolate(val$txt_html) |> str_split(pattern = "\\n") |>  unlist()) |>
    #       filter(content != "") |>
    #       mutate(role = "user")
    # ) |>
    #   purrr::transpose() -> l
    # 
    # gpt <- create_chat_completion(
    #   model = "gpt-4",
    #   messages = l
    # )
    updateActionButton(inputId = "prompt_btn",
                       label = "Waiting for new messages")
    
    
    new <- paste(current_time(), "#", "Prompt", ":" , isolate(val$prompt_message))
    
    val$txt <- str_glue(val$txt, new, sep = '\n')
    
    val$txt_html <- str_glue(val$txt_html, new, " <br>")
    
    updateTextInput(session, "text_msg", value = "")
    
    saveRDS(val$txt_html, "chat_txt.Rds")
  })
  
  # output$chat_window <- renderText({ val$txt })
  
  output$chat_window_html <- renderUI({
    HTML(str_glue(val$txt_html))
  })
  # ----
  
  # update the active user list on exit ----
  session$onSessionEnded(function(){
    isolate({
      val$users <- val$users[val$users != input$uname]
      paste0("user : ", input$uname, " left the room") -> usr_left
      print(usr_left)
      print(val$users)
    })
  })
  # ----
  
  
  ## submit liker scale
  observeEvent(input$sumbit_1_btn,{
    new <- paste(current_time(), "#",
                 user_name_color(user_name = input$uname, color = user_color),
                 ":", "Talking to strangers is a challenging task: ", input$slider_pre_1)
    
    val$txt <- str_glue(val$txt, new, sep = '\n')
    val$txt_html <- str_glue(val$txt_html, new, " <br>")
    updateTextInput(session, "text_msg", value = "")
    saveRDS(val$txt_html, "chat_txt.Rds")
    
    val$likert_1_state <- FALSE
  })
  
  observeEvent(input$sumbit_2_btn,{
    new <- paste(current_time(), "#",
                 user_name_color(user_name = input$uname, color = user_color),
                 ":", "How did the prompts affect the conversation?: ", input$slider_post_1)
    
    val$txt <- str_glue(val$txt, new, sep = '\n')
    val$txt_html <- str_glue(val$txt_html, new, " <br>")
    updateTextInput(session, "text_msg", value = "")
    saveRDS(val$txt_html, "chat_txt.Rds")
    
    val$likert_2_state <- FALSE
  })
  
  # show or hide interface 
  observeEvent(val$prompt_state, {
    # invalidateLater(5000, session)
    # prompt_state <- mongo_prompt_state$find('{"element": "prompt_button"}', sort = '{"timestamp": -1}', limit = 1) |> 
    #   pull(state)
    
    if (val$prompt_state == TRUE) {
      shinyjs::show("prompt_btn_div")
    } else if (val$prompt_state == FALSE) {
      shinyjs::hide("prompt_btn_div")
    } else {
      shinyjs::show("prompt_btn_div")
    }
  })
  
  
  observeEvent(val$likert_1_state, {
    if (val$likert_1_state == TRUE) {
      shinyjs::show("slider_pre_div")
    } else if (val$likert_1_state == FALSE) {
      shinyjs::hide("slider_pre_div")
    } else {
      shinyjs::hide("slider_pre_div")
    }
  })
  
  observeEvent(val$likert_2_state, {
    if (val$likert_2_state == TRUE) {
      shinyjs::show("slider_post_div")
    } else if (val$likert_2_state == FALSE) {
      shinyjs::hide("slider_post_div")
    } else {
      shinyjs::hide("slider_post_div")
    }
  })
  
}

shinyApp(ui, server)