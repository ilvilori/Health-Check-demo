# Diagnóstico Express — Demo

## Archivos

- `app.R` — app Shiny. Por ahora tiene la **Vista 1: Pirámide de valor clientes**.
  Cuando definamos la Vista 2 se agrega como un nuevo `nav_panel()` en el mismo archivo.
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

## Cómo correrlo en tu computadora

Requiere R instalado. Paquetes necesarios:

```r
install.packages(c("shiny", "bslib", "dplyr", "readxl", "plotly", "scales"))
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
