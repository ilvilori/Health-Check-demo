# app.R — Customer Intelligence Scan
# Orden de pestañas: Pirámide valor, Comportamiento, Experiencia y
# Fidelización, Captación, Contactabilidad.
#
# Lee data_vista1.xlsx (debe estar en la misma carpeta / repo que este
# archivo). Cada vista tiene sus propios filtros, así que pueden abrir con
# valores por defecto distintos.vvvvv

#shiny::runApp("app.R")
#install.packages("rsconnect")
library(rsconnect)
#writeManifest()
library(shiny)
library(bslib)
library(dplyr)
library(readxl)
library(plotly)
library(scales)
library(wordcloud)

# ---------- datos ----------
datos <- read_excel("data_vista1.xlsx") |>
  select(
    Annual, Tier, Ventas, Margen, Margen_USD = `Margen USD`, Clientes,
    Compra_anual, Frecuencia, Pdtos_compra, Ticket_Prom,
    Marg_Cli_USD, Marg_Cli_Porc, Precio_prom = Precio_prom_pdtos_cli,
    Pago_CD, Pago_OFP, NPS, Recompra, Cuali_NPS,
    Contactable, Mail, WSP,
    Clientes_Nuevos, Clientes_Nuevos_Porc,
    Ventas_USD_Nuevos = `Ventas.USD_Clientes_Nuevos`,
    Ventas_Porc_Nuevos = `Ventas.Porc_Clientes_Nuevos`,
    Recompra_Nuevos
  ) |>
  mutate(Tier = as.character(Tier))

anios <- sort(unique(datos$Annual))

paleta_tier <- c("1" = "#2B5F5A", "2" = "#1C2D42", "3" = "#C98A3B", "4" = "#B4483A")

fmt_usd  <- function(x) scales::dollar(x, accuracy = 1, scale_cut = scales::cut_short_scale())
fmt_usd2 <- function(x) scales::dollar(x, accuracy = 0.01)
fmt_pct  <- function(x) scales::percent(x, accuracy = 0.1)
fmt_n    <- function(x) format(round(x), big.mark = ",")
fmt_dec  <- function(x) formatC(x, format = "f", digits = 2)

# Tamaños (ajústalos aquí si quieres afinarlos)
ALTO_KPI_V1     <- "63px"   # Vista 1: encabezados
ALTO_GRAFICO_V1 <- "145px"  # Vista 1: gráficos, a un tercio del alto original
ALTO_KPI        <- "66px"   # Vista 2: encabezados más chicos, para caber sin scroll
ALTO_GRAFICO    <- "128px"  # Vista 2: gráficos más chicos, para caber sin scroll

css_vista2 <- "
  .vb-compacto-v1 .card-body { padding: 0.25rem 0.6rem; }
  .vb-compacto-v1 .value-box-title { font-size: 0.78rem; }
  .vb-compacto-v1 .value-box-value { font-size: 1.4rem; line-height: 1.15; }
  .vb-compacto .card-body { padding: 0.2rem 0.6rem; }
  .vb-compacto .value-box-title { font-size: 0.65rem; }
  .vb-compacto .value-box-value { font-size: 1.15rem; line-height: 1.1; }
  .cmp-card .card-header { padding: 0.2rem 0.6rem; font-size: 0.72rem; }
  .cmp-card .card-body { padding: 0.15rem; }
"

# Encabezados de la Vista 2 (se repiten en las dos partes; el sufijo evita
# ids duplicados en Shiny)
kpis_vista2 <- function(sufijo = "") {
  id <- function(x) paste0("v2_", x, sufijo)
  tagList(
    layout_column_wrap(width = 1/4,
      value_box("Cantidad de clientes", textOutput(id("clientes")), height = ALTO_KPI, class = "vb-compacto"),
      value_box("Compra anual cliente", textOutput(id("compra")), height = ALTO_KPI, class = "vb-compacto"),
      value_box("Margen cliente USD", textOutput(id("marg_usd")), height = ALTO_KPI, class = "vb-compacto"),
      value_box("Margen cliente %", textOutput(id("marg_pct")), height = ALTO_KPI, class = "vb-compacto")
    ),
    layout_column_wrap(width = 1/4,
      value_box("Ticket promedio", textOutput(id("ticket")), height = ALTO_KPI, class = "vb-compacto"),
      value_box("Frecuencia", textOutput(id("frecuencia")), height = ALTO_KPI, class = "vb-compacto"),
      value_box("Productos cliente", textOutput(id("productos")), height = ALTO_KPI, class = "vb-compacto"),
      value_box("Precio promedio", textOutput(id("precio")), height = ALTO_KPI, class = "vb-compacto")
    )
  )
}

# ---------- UI ----------
ui <- page_navbar(
  title = "Customer Intelligence Scan",
  theme = bs_theme(bootswatch = "materia", primary = "#2B5F5A"),
  header = tags$head(tags$style(HTML(css_vista2))),

  # ===== Vista 1 =====
  nav_panel("Pirámide valor",
    layout_sidebar(
      sidebar = sidebar(
        title = "Filtros",
        selectInput("anio", "Año", choices = anios, selected = 2022)
      ),
      layout_column_wrap(width = 1/3,
        value_box("Total Ventas", textOutput("kpi_ventas"), height = ALTO_KPI_V1, class = "vb-compacto-v1"),
        value_box("Total Margen", textOutput("kpi_margen"), height = ALTO_KPI_V1, class = "vb-compacto-v1"),
        value_box("Total Clientes", textOutput("kpi_clientes"), height = ALTO_KPI_V1, class = "vb-compacto-v1")
      ),
      layout_column_wrap(width = 1/2,
        card(card_header("Ventas y Margen por Tier"), plotlyOutput("plot_ventas_margen", height = ALTO_GRAFICO_V1)),
        card(card_header("Clientes por Tier"), plotlyOutput("plot_clientes", height = ALTO_GRAFICO_V1))
      ),
      layout_column_wrap(width = 1/3,
        card(card_header("Share de Ventas"), plotlyOutput("pie_ventas", height = ALTO_GRAFICO_V1)),
        card(card_header("Share de Margen"), plotlyOutput("pie_margen", height = ALTO_GRAFICO_V1)),
        card(card_header("Share de Clientes"), plotlyOutput("pie_clientes", height = ALTO_GRAFICO_V1))
      )
    )
  ),

  # ===== Vista 2 =====
  nav_panel("Comportamiento",
    layout_sidebar(
      sidebar = sidebar(
        title = "Filtros",
        selectInput("anio2", "Año", choices = anios, selected = 2022),
        helpText("Los indicadores superiores muestran el total del año seleccionado.",
                 "Los gráficos comparan los cuatro Tiers frente al total.")
      ),
      navset_pill(
        nav_panel("Parte 1",
          kpis_vista2(""),
          layout_column_wrap(width = 1/2,
            card(class = "cmp-card", card_header("Compra anual cliente por Tier"), plotlyOutput("cmp_compra", height = ALTO_GRAFICO)),
            card(class = "cmp-card", card_header("Margen cliente USD por Tier"), plotlyOutput("cmp_marg_usd", height = ALTO_GRAFICO)),
            card(class = "cmp-card", card_header("Margen cliente % por Tier"), plotlyOutput("cmp_marg_pct", height = ALTO_GRAFICO)),
            card(class = "cmp-card", card_header("Ticket promedio por Tier"), plotlyOutput("cmp_ticket", height = ALTO_GRAFICO))
          )
        ),
        nav_panel("Parte 2",
          kpis_vista2("_b"),
          layout_column_wrap(width = 1/2,
            card(class = "cmp-card", card_header("Frecuencia por Tier"), plotlyOutput("cmp_frecuencia", height = ALTO_GRAFICO)),
            card(class = "cmp-card", card_header("Productos cliente por Tier"), plotlyOutput("cmp_productos", height = ALTO_GRAFICO)),
            card(class = "cmp-card", card_header("Precio promedio por Tier"), plotlyOutput("cmp_precio", height = ALTO_GRAFICO)),
            card(class = "cmp-card", card_header("Pago Crédito y OFP por Tier"), plotlyOutput("cmp_pagos", height = ALTO_GRAFICO))
          )
        )
      )
    )
  ),

  # ===== Vista 3 =====
  nav_panel("Experiencia y Fidelización",
    layout_sidebar(
      sidebar = sidebar(
        title = "Filtros",
        selectInput("anio3", "Año", choices = anios, selected = 2022),
        helpText("Los gráficos comparan los cuatro Tiers frente al total.",
                 "La nube de palabras agrupa los comentarios de los Tiers 1 a 4.")
      ),
      layout_column_wrap(width = 1/2,
        card(class = "cmp-card", card_header("NPS total y por Tier"), plotlyOutput("cmp_nps", height = ALTO_GRAFICO)),
        card(class = "cmp-card", card_header("Recompra total y por Tier"), plotlyOutput("cmp_recompra", height = ALTO_GRAFICO))
      ),
      card(card_header("Comentarios del NPS (nube de palabras)"), plotOutput("nube_nps", height = "320px"))
    )
  ),

  # ===== Vista 5 =====
  nav_panel("Captación",
    p("Evolución anual clientes nuevos (Total empresa, sin filtro de año o Tier).",
      style = "color: var(--bs-secondary-color); margin: 4px 0 14px;"),
    layout_column_wrap(width = 1/1,
      card(class = "cmp-card", card_header("Clientes nuevos: cantidad y % del total"), plotlyOutput("cap_clientes", height = ALTO_GRAFICO))
    ),
    layout_column_wrap(width = 1/2,
      card(class = "cmp-card", card_header("Ventas de clientes nuevos: USD y % del total"), plotlyOutput("cap_ventas", height = ALTO_GRAFICO)),
      card(class = "cmp-card", card_header("Recompra de clientes nuevos"), plotlyOutput("cap_recompra", height = ALTO_GRAFICO))
    )
  ),

  # ===== Vista 4 =====
  nav_panel("Contactabilidad",
    layout_sidebar(
      sidebar = sidebar(
        title = "Filtros",
        selectInput("anio4", "Año", choices = anios, selected = 2024),
        helpText("Los gráficos comparan los cuatro Tiers frente al total.",
                 "Solo 2024 tiene datos de contactabilidad en el archivo actual.")
      ),
      layout_column_wrap(width = 1/3,
        card(class = "cmp-card", card_header("Contactabilidad por Tier"), plotlyOutput("cmp_contactable", height = ALTO_GRAFICO)),
        card(class = "cmp-card", card_header("Mail por Tier"), plotlyOutput("cmp_mail", height = ALTO_GRAFICO)),
        card(class = "cmp-card", card_header("Whatsapp por Tier"), plotlyOutput("cmp_wsp", height = ALTO_GRAFICO))
      )
    )
  )
)

# ---------- server ----------
server <- function(input, output, session) {

  # ================= Vista 1 =================
  datos_anio <- reactive({
    datos |> filter(Annual == input$anio)
  })

  total <- reactive({
    datos_anio() |> filter(Tier == "Tot")
  })

  por_tier <- reactive({
    datos_anio() |> filter(Tier != "Tot") |> arrange(Tier)
  })

  output$kpi_ventas   <- renderText({ fmt_usd(total()$Ventas) })
  output$kpi_margen   <- renderText({ fmt_usd(total()$Margen_USD) })
  output$kpi_clientes <- renderText({ fmt_n(total()$Clientes) })

  output$plot_ventas_margen <- renderPlotly({
    d <- por_tier()
    plot_ly(d, x = ~Tier) |>
      add_trace(y = ~Ventas, type = "bar", name = "Ventas", marker = list(color = "#1C2D42")) |>
      add_trace(y = ~Margen_USD, type = "bar", name = "Margen", marker = list(color = "#9E9E9E")) |>
      layout(barmode = "group", yaxis = list(title = "USD"), xaxis = list(title = "Tier")%>%
               config(
                 displayModeBar = FALSE
               ))
  })

  output$plot_clientes <- renderPlotly({
    d <- por_tier()
    plot_ly(d, x = ~Tier, y = ~Clientes, type = "bar",
            marker = list(color = paleta_tier[d$Tier])) |>
      layout(yaxis = list(title = "Clientes"), xaxis = list(title = "Tier")%>%
               config(
                 displayModeBar = FALSE
               ))
  })

  hacer_pie <- function(campo) {
    d <- por_tier()
    plot_ly(d, labels = ~paste("Tier", Tier), values = d[[campo]], type = "pie",
            hole = 0.5, marker = list(colors = paleta_tier[d$Tier]))
  }
  output$pie_ventas   <- renderPlotly({ hacer_pie("Ventas") })
  output$pie_margen   <- renderPlotly({ hacer_pie("Margen_USD") })
  output$pie_clientes <- renderPlotly({ hacer_pie("Clientes") })

  # ================= Vista 2 =================
  datos2 <- reactive({
    req(input$anio2)
    datos |>
      filter(Annual == input$anio2) |>
      mutate(Etiqueta = factor(if_else(Tier == "Tot", "Total", paste("Tier", Tier)),
                               levels = c("Tier 1", "Tier 2", "Tier 3", "Tier 4", "Total")))
  })

  total2 <- reactive({ datos2() |> filter(Tier == "Tot") })

  # ---- indicadores superiores (fila "Tot" del año), en ambas partes ----
  kpi_defs <- list(
    clientes   = function(t) fmt_n(t$Clientes),
    compra     = function(t) fmt_usd2(t$Compra_anual),
    marg_usd   = function(t) fmt_usd2(t$Marg_Cli_USD),
    marg_pct   = function(t) fmt_pct(t$Marg_Cli_Porc),
    ticket     = function(t) fmt_usd2(t$Ticket_Prom),
    frecuencia = function(t) fmt_dec(t$Frecuencia),
    productos  = function(t) fmt_dec(t$Pdtos_compra),
    precio     = function(t) fmt_usd2(t$Precio_prom)
  )
  for (nm in names(kpi_defs)) {
    for (suf in c("", "_b")) {
      local({
        n <- nm; s <- suf
        output[[paste0("v2_", n, s)]] <- renderText({ kpi_defs[[n]](total2()) })
      })
    }
  }

  # ---- comparativos por Tier (Tier 1-4 + Total como referencia en gris) ----
  colores_cmp <- unname(c(paleta_tier[c("1", "2", "3", "4")], "#8A8F9A"))

  barras_tier <- function(campo, formato, pct = FALSE) {
    d <- datos2() |> arrange(Etiqueta)
    y <- d[[campo]]
    p <- plot_ly(d, x = ~Etiqueta, y = y, type = "bar",
                 marker = list(color = colores_cmp),
                 text = formato(y), textposition = "outside",
                 hoverinfo = "x+text") |>
      layout(margin = list(t = 8, b = 24, l = 36, r = 8), font = list(size = 10),
             xaxis = list(title = ""),
             yaxis = list(title = "", range = c(0, max(y) * 1.25),
                          tickformat = if (pct) ".0%" else NULL))%>%
      config(
        displayModeBar = FALSE
      )
    p
  }

  output$cmp_compra     <- renderPlotly({ barras_tier("Compra_anual", fmt_usd2) })
  output$cmp_marg_usd   <- renderPlotly({ barras_tier("Marg_Cli_USD", fmt_usd2) })
  output$cmp_marg_pct   <- renderPlotly({ barras_tier("Marg_Cli_Porc", fmt_pct, pct = TRUE) })
  output$cmp_ticket     <- renderPlotly({ barras_tier("Ticket_Prom", fmt_usd2) })
  output$cmp_frecuencia <- renderPlotly({ barras_tier("Frecuencia", fmt_dec) })
  output$cmp_productos  <- renderPlotly({ barras_tier("Pdtos_compra", fmt_dec) })
  output$cmp_precio     <- renderPlotly({ barras_tier("Precio_prom", fmt_usd2) })

  output$cmp_pagos <- renderPlotly({
    d <- datos2() |> arrange(Etiqueta)
    plot_ly(d, x = ~Etiqueta) |>
      add_trace(y = ~Pago_CD, type = "bar", name = "Pago Crédito",
                marker = list(color = "#1C2D42"),
                text = fmt_pct(d$Pago_CD), textposition = "outside", hoverinfo = "x+text") |>
      add_trace(y = ~Pago_OFP, type = "bar", name = "Pago OFP",
                marker = list(color = "#C98A3B"),
                text = fmt_pct(d$Pago_OFP), textposition = "outside", hoverinfo = "x+text") |>
      layout(barmode = "group", margin = list(t = 8, b = 24, l = 36, r = 8),
             font = list(size = 10), xaxis = list(title = ""),
             yaxis = list(title = "", tickformat = ".0%", range = c(0, 1.3)),
             legend = list(orientation = "h", x = 0, y = 1.2))%>%
      config(
        displayModeBar = FALSE
      )
  })

  # ================= Vista 3 =================
  datos3 <- reactive({
    req(input$anio3)
    datos |>
      filter(Annual == input$anio3) |>
      mutate(Etiqueta = factor(if_else(Tier == "Tot", "Total", paste("Tier", Tier)),
                               levels = c("Tier 1", "Tier 2", "Tier 3", "Tier 4", "Total")))
  })

  output$cmp_nps <- renderPlotly({
    d <- datos3() |> arrange(Etiqueta)
    validate(need(nrow(d) > 0, "Sin datos para este año."))
    y <- d$NPS
    plot_ly(d, x = ~Etiqueta, y = y, type = "bar",
            marker = list(color = colores_cmp),
            text = round(y, 1), textposition = "outside", hoverinfo = "x+text") |>
      layout(margin = list(t = 8, b = 24, l = 36, r = 8), font = list(size = 10),
             xaxis = list(title = ""),
             yaxis = list(title = "", range = c(0, max(y, na.rm = TRUE) * 1.2)))%>%
      config(
        displayModeBar = FALSE
      )
  })

  output$cmp_recompra <- renderPlotly({
    d <- datos3() |> arrange(Etiqueta)
    validate(need(nrow(d) > 0, "Sin datos para este año."))
    y <- d$Recompra
    plot_ly(d, x = ~Etiqueta, y = y, type = "bar",
            marker = list(color = colores_cmp),
            text = fmt_pct(y), textposition = "outside", hoverinfo = "x+text") |>
      layout(margin = list(t = 8, b = 24, l = 36, r = 8), font = list(size = 10),
             xaxis = list(title = ""),
             yaxis = list(title = "", tickformat = ".0%", range = c(0, max(y, na.rm = TRUE) * 1.3)))%>%
      config(
        displayModeBar = FALSE
      )
  })

  # Cuali_NPS trae palabras/temas separados por coma (a veces por un apóstrofe
  # suelto cuando dos celdas quedaron pegadas); se cuenta cuántas veces
  # aparece cada palabra entre los Tiers 1 a 4 del año seleccionado.
  output$nube_nps <- renderPlot({
    texto <- datos3() |> filter(Tier %in% c("1", "2", "3", "4")) |> pull(Cuali_NPS)
    palabras <- texto |>
      strsplit("[,']") |>
      unlist() |>
      trimws()
    palabras <- palabras[palabras != "" & !is.na(palabras)]
    frecuencia <- as.data.frame(table(palabras), stringsAsFactors = FALSE) |>
      rename(word = palabras, freq = Freq) |>
      arrange(desc(freq))
    validate(need(nrow(frecuencia) > 0, "No hay comentarios para este año."))
    par(mar = c(0, 0, 0, 0))
    wordcloud::wordcloud(
      words = frecuencia$word, freq = frecuencia$freq,
      scale = c(3.2, 0.9), min.freq = 1, random.order = FALSE, rot.per = 0,
      colors = rep(c("#2B5F5A", "#1C2D42", "#C98A3B", "#B4483A"), length.out = nrow(frecuencia))
    )
  })

  # ================= Vista 4 =================
  datos4 <- reactive({
    req(input$anio4)
    datos |>
      filter(Annual == input$anio4) |>
      mutate(Etiqueta = factor(if_else(Tier == "Tot", "Total", paste("Tier", Tier)),
                               levels = c("Tier 1", "Tier 2", "Tier 3", "Tier 4", "Total")))
  })

  barra_pct_tier <- function(campo) {
    d <- datos4() |> arrange(Etiqueta)
    validate(need(nrow(d) > 0, "Sin datos para este año."))
    y <- d[[campo]]
    validate(need(!all(is.na(y)), "Este año no tiene datos de contactabilidad."))
    plot_ly(d, x = ~Etiqueta, y = y, type = "bar",
            marker = list(color = colores_cmp),
            text = fmt_pct(y), textposition = "outside", hoverinfo = "x+text") |>
      layout(margin = list(t = 8, b = 24, l = 36, r = 8), font = list(size = 10),
             xaxis = list(title = ""),
             yaxis = list(title = "", tickformat = ".0%", range = c(0, max(y, na.rm = TRUE) * 1.3)))%>%
      config(
        displayModeBar = FALSE
      )
  }

  output$cmp_contactable <- renderPlotly({ barra_pct_tier("Contactable") })
  output$cmp_mail        <- renderPlotly({ barra_pct_tier("Mail") })
  output$cmp_wsp         <- renderPlotly({ barra_pct_tier("WSP") })

  # ================= Vista 5 =================
  # Serie de tiempo con el Total de la empresa (fila "Tot") en cada año,
  # sin filtro de año ni comparación por Tier.
  datos_captacion <- reactive({
    datos |> filter(Tier == "Tot") |> arrange(Annual) |> mutate(Annual = factor(Annual))
  })

  output$cap_clientes <- renderPlotly({
    d <- datos_captacion()
    plot_ly(d, x = ~Annual) |>
      add_trace(y = ~Clientes_Nuevos, type = "bar", name = "Clientes nuevos",
                yaxis = "y1", marker = list(color = "#2B5F5A")) |>
      add_trace(y = ~Clientes_Nuevos_Porc, type = "scatter", mode = "lines+markers",
                name = "% del total", yaxis = "y2",
                line = list(color = "#C98A3B", dash = "dot"), marker = list(color = "#C98A3B")) |>
      layout(margin = list(t = 8, b = 24, l = 48, r = 48), font = list(size = 10),
             xaxis = list(title = ""),
             yaxis = list(title = "Clientes"),
             yaxis2 = list(title = "% del total", overlaying = "y", side = "right", tickformat = ".0%"),
             legend = list(orientation = "h", x = 0, y = 1.15))%>%
      config(
        displayModeBar = FALSE
      )
  })

  output$cap_ventas <- renderPlotly({
    d <- datos_captacion()
    plot_ly(d, x = ~Annual) |>
      add_trace(y = ~Ventas_USD_Nuevos, type = "bar", name = "Ventas (USD)",
                yaxis = "y1", marker = list(color = "#1C2D42")) |>
      add_trace(y = ~Ventas_Porc_Nuevos, type = "scatter", mode = "lines+markers",
                name = "% del total", yaxis = "y2",
                line = list(color = "#C98A3B", dash = "dot"), marker = list(color = "#C98A3B")) |>
      layout(margin = list(t = 8, b = 24, l = 56, r = 48), font = list(size = 10),
             xaxis = list(title = ""),
             yaxis = list(title = "USD"),
             yaxis2 = list(title = "% del total", overlaying = "y", side = "right", tickformat = ".0%"),
             legend = list(orientation = "h", x = 0, y = 1.15))%>%
      config(
        displayModeBar = FALSE
      )
  })

  output$cap_recompra <- renderPlotly({
    d <- datos_captacion()
    y <- d$Recompra_Nuevos
    plot_ly(d, x = ~Annual, y = y, type = "bar",
            marker = list(color = "#5B8C87"),
            text = fmt_pct(y), textposition = "outside", hoverinfo = "x+text") |>
      layout(margin = list(t = 8, b = 24, l = 36, r = 8), font = list(size = 10),
             xaxis = list(title = ""),
             yaxis = list(title = "", tickformat = ".0%", range = c(0, max(y, na.rm = TRUE) * 1.3)))%>%
      config(
        displayModeBar = FALSE
      )
  })

}

shinyApp(ui, server)
