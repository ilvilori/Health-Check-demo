# app.R — Diagnóstico Express
# Vista 1: Pirámide de valor de clientes
#
# Lee data_vista1.xlsx (debe estar en la misma carpeta / repo que este
# archivo). Cuando tengamos más vistas, cada una se agrega como un nuevo
# nav_panel() en la UI y sus outputs correspondientes en el server.

library(shiny)
library(bslib)
library(dplyr)
library(readxl)
library(plotly)
library(scales)

# ---------- datos ----------
datos <- read_excel("data_vista1.xlsx") |>
  select(Annual, Tier, Ventas, Margen, Margen_USD = `Margen USD`, Clientes) |>
  mutate(Tier = as.character(Tier))

anios <- sort(unique(datos$Annual))

paleta_tier <- c("1" = "#2B5F5A", "2" = "#5B8C87", "3" = "#C98A3B", "4" = "#B4483A")

fmt_usd <- function(x) scales::dollar(x, accuracy = 1, scale_cut = scales::cut_short_scale())
fmt_n   <- function(x) format(round(x), big.mark = ",")

# ---------- UI ----------
ui <- page_navbar(
  title = "Diagnóstico Express",
  theme = bs_theme(bootswatch = "flatly", primary = "#2B5F5A"),
  sidebar = sidebar(
    title = "Filtros",
    selectInput("anio", "Año", choices = anios, selected = max(anios))
  ),
  nav_panel("Pirámide de valor clientes",
    layout_column_wrap(width = 1/3,
      value_box("Total Ventas", textOutput("kpi_ventas")),
      value_box("Total Margen", textOutput("kpi_margen")),
      value_box("Total Clientes", textOutput("kpi_clientes"))
    ),
    layout_column_wrap(width = 1/2,
      card(card_header("Ventas y Margen por Tier"), plotlyOutput("plot_ventas_margen")),
      card(card_header("Clientes por Tier"), plotlyOutput("plot_clientes"))
    ),
    layout_column_wrap(width = 1/3,
      card(card_header("Share de Ventas"), plotlyOutput("pie_ventas")),
      card(card_header("Share de Margen"), plotlyOutput("pie_margen")),
      card(card_header("Share de Clientes"), plotlyOutput("pie_clientes"))
    )
  )
)

# ---------- server ----------
server <- function(input, output, session) {

  datos_anio <- reactive({
    datos |> filter(Annual == input$anio)
  })

  total <- reactive({
    datos_anio() |> filter(Tier == "Tot")
  })

  por_tier <- reactive({
    datos_anio() |> filter(Tier != "Tot") |> arrange(Tier)
  })

  # ---- KPIs (fila "Tot" del año seleccionado) ----
  output$kpi_ventas   <- renderText({ fmt_usd(total()$Ventas) })
  output$kpi_margen   <- renderText({ fmt_usd(total()$Margen_USD) })
  output$kpi_clientes <- renderText({ fmt_n(total()$Clientes) })

  # ---- Gráfico 1: Ventas y Margen (USD) por Tier ----
  output$plot_ventas_margen <- renderPlotly({
    d <- por_tier()
    plot_ly(d, x = ~Tier) |>
      add_trace(y = ~Ventas, type = "bar", name = "Ventas", marker = list(color = "#2B5F5A")) |>
      add_trace(y = ~Margen_USD, type = "bar", name = "Margen", marker = list(color = "#C98A3B")) |>
      layout(barmode = "group", yaxis = list(title = "USD"), xaxis = list(title = "Tier"))
  })

  # ---- Gráfico 2: Clientes por Tier ----
  output$plot_clientes <- renderPlotly({
    d <- por_tier()
    plot_ly(d, x = ~Tier, y = ~Clientes, type = "bar",
            marker = list(color = paleta_tier[d$Tier])) |>
      layout(yaxis = list(title = "Clientes"), xaxis = list(title = "Tier"))
  })

  # ---- Gráficos 3-5: pies de share por Tier ----
  hacer_pie <- function(campo) {
    d <- por_tier()
    plot_ly(d, labels = ~paste("Tier", Tier), values = d[[campo]], type = "pie",
            hole = 0.5, marker = list(colors = paleta_tier[d$Tier]))
  }
  output$pie_ventas   <- renderPlotly({ hacer_pie("Ventas") })
  output$pie_margen   <- renderPlotly({ hacer_pie("Margen_USD") })
  output$pie_clientes <- renderPlotly({ hacer_pie("Clientes") })
}

shinyApp(ui, server)
