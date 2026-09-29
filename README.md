# Customer Intelligence Scan — Demo

## Archivos

- `app.R` — app Shiny con cinco pestañas, en este orden: **Pirámide valor**,
  **Comportamiento**, **Experiencia y Fidelización**, **Captación** y
  **Contactabilidad** (al final). Cada vista tiene sus propios filtros (todas
  abren en 2022, salvo Captación que no tiene filtro y Contactabilidad que
  abre en 2024 porque es el único año con esos datos). Una vista nueva se
  agrega como otro `nav_panel()` en el mismo archivo.
- `data_vista1.xlsx` — tu archivo de datos (ya es un resumen agregado por año/tier,
  sin datos de clientes individuales, así que no requiere anonimización).

## Vista 1 — cómo se calculó cada elemento

- **KPIs (Total Ventas, Total Margen, Total Clientes):** se toman de la fila `Tot`
  del año seleccionado en el filtro. Total Margen se muestra en USD.
- **Filtro de año:** cambia `input$anio`, y todo (KPIs + 5 gráficos) se recalcula
  filtrando `Annual == input$anio`.
- **Gráfico 1 (Ventas y Margen por Tier):** barras agrupadas, Ventas y Margen USD,
  para los tiers 1 a 4 (se excluye la fila `Tot`).
- **Gráfico 2 (Clientes por Tier):** barras, campo `Clientes`.
- **Gráficos 3-5 (pies de share):** participación de cada tier en Ventas, Margen
  USD y Clientes, respectivamente.

## Vista 2 — Indicadores Comportamiento

- **Filtro:** Año (abre en 2024). No hay filtro de Tier: los Tiers se comparan
  directamente en los gráficos.
- **Dos partes (pestañas Parte 1 y Parte 2):** ambas repiten los encabezados; la
  Parte 1 trae los primeros cuatro gráficos (Compra anual, Margen USD, Margen %,
  Ticket) y la Parte 2 los últimos cuatro (Frecuencia, Productos, Precio, Pagos).
- **Primera fila (total del año, fila `Tot`):** Cantidad de clientes (`Clientes`),
  Compra anual cliente (`Compra_anual`), Margen cliente USD (`Marg_Cli_USD`),
  Margen cliente % (`Marg_Cli_Porc`).
- **Segunda fila (total del año):** Ticket promedio (`Ticket_Prom`), Frecuencia
  (`Frecuencia`), Productos cliente (`Pdtos_compra`), Precio promedio
  (`Precio_prom_pdtos_cli`).
- **Gráficos comparativos por Tier:** un gráfico de barras por cada indicador
  (excepto Cantidad de clientes, que ya está en la Vista 1) más Pago Crédito
  (`Pago_CD`) vs Pago OFP (`Pago_OFP`) en %. Muestran Tier 1 a 4 y una barra gris
  de "Total" como referencia.

## Vista 3 — Experiencia Cliente & fidelización

- **Filtro:** solo Año (abre en 2024), igual que la Vista 2.
- **NPS total y por Tier:** barras con el campo `NPS`, comparando Tier 1 a 4 y el
  Total.
- **Recompra total y por Tier:** barras con el campo `Recompra` (en %), misma
  comparación.
- **Nube de palabras:** cuenta cuántas veces aparece cada palabra/tema del
  campo `Cuali_NPS` entre los Tiers 1 a 4 del año seleccionado (no incluye la
  fila `Tot`, para no duplicar el conteo). El texto se separa por comas —y
  también por un apóstrofe suelto, porque algunas celdas del archivo traían dos
  comentarios pegados sin coma entre ellos.
- Requiere el paquete adicional `wordcloud` (imagen estática) — deliberadamente NO
  `wordcloud2`, porque ese paquete usa un widget de JavaScript que entra en
  conflicto con Plotly cuando comparten la misma pestaña: rompía los gráficos
  de NPS y Recompra, que quedaban en blanco sin ningún aviso.

## Vista 4 — Contactabilidad

- **Filtro:** solo Año (abre en 2024). En el archivo actual, `Contactable`,
  `Mail` y `WSP` solo tienen datos para 2024 — 2022 y 2023 vienen vacíos, así
  que si seleccionas esos años el gráfico avisa que no hay datos en vez de
  mostrarse en blanco sin explicación.
- **Tres gráficos comparativos por Tier:** Contactabilidad (`Contactable`),
  Mail (`Mail`) y Whatsapp (`WSP`), los tres en %, comparando Tier 1 a 4 y el
  Total.

## Vista 5 — Captación

- **Sin filtros:** a diferencia de las demás vistas, esta muestra la evolución
  año a año usando solo la fila `Tot` (total de la empresa) — no compara por
  Tier ni permite elegir un año, porque el punto es ver la tendencia completa
  (2022, 2023, 2024 en el archivo actual).
- **Clientes nuevos:** líneas con `Clientes_Nuevos` (cantidad, eje izquierdo) y
  `Clientes_Nuevos_Porc` (% del total, eje derecho).
- **Ventas de clientes nuevos:** barras con `Ventas.USD_Clientes_Nuevos` (eje
  izquierdo) y línea con `Ventas.Porc_Clientes_Nuevos` (% del total, eje
  derecho).
- **Recompra de clientes nuevos:** barras con `Recompra_Nuevos`, en %.

## Cómo correrlo en tu computadora

Requiere R instalado. Paquetes necesarios:

```r
install.packages(c("shiny", "bslib", "dplyr", "readxl", "plotly", "scales",
                    "wordcloud"))
```

Con `app.R` y `data_vista1.xlsx` en la misma carpeta:

```r
shiny::runApp("app.R")
```

## Publicar en Posit Connect Cloud (paso a paso)

1. **Crea un repositorio en GitHub** y sube estos dos archivos (`app.R` y
   `data_vista1.xlsx`) en la raíz del repo — no dentro de una subcarpeta.
2. Ve a **connect.posit.cloud** e inicia sesión con tu cuenta de GitHub
   (la primera vez te pedirá autorizar el acceso a tus repositorios).
3. En tu página de inicio, haz clic en el botón de **Publicar** y selecciona
   **Shiny** como tipo de contenido.
4. Elige el repositorio que acabas de crear, confirma la rama (`main`) y
   selecciona **`app.R`** como archivo principal.
5. Haz clic en **Publish**. Connect Cloud detecta e instala automáticamente
   los paquetes de R que usa el código (no necesitas un archivo de
   dependencias como en Python) — verás el log de instalación en pantalla.
6. Al terminar el build obtienes una URL pública (algo como
   `tuusuario.share.connect.posit.cloud/app`). Ese es el link que le
   compartes al cliente — se ve igual en celular y en computador.

Cada vez que agreguemos una vista nueva: actualiza `app.R` en tu computadora,
haz commit y push a GitHub, y en Connect Cloud usa la opción de **republicar**
(o el push-to-publish automático si lo activaste) para reflejar el cambio en
el mismo link, sin crear uno nuevo.
