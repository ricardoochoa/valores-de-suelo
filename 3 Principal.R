# ==============================================================================
# MODELO DE EVALUACIÓN DE IMPACTO URBANO EN EL VALOR DEL SUELO
# Script basado en especificaciones de elasticidad y rampa de decaimiento
# ==============================================================================

# Cargar librerías necesarias
if (!require("pacman")) install.packages("pacman")
pacman::p_load(terra, sf, tidyverse)

# Cargar funciones
source("1 Genera datos de prueba.R")
source("2 Funciones del modelo.R")

# ------------------------------------------------------------------------------
# 3. EJECUCIÓN PRINCIPAL
# ------------------------------------------------------------------------------

if (!file.exists("clasificacion.tif")) generate_synthetic_data()

data <- load_data("clasificacion.tif", "elasticidades.csv", "mapeo_intervenciones.csv")

impacto_total <- data$raster * 0
names(impacto_total) <- "cambio_porcentual"

for (i in 1:nrow(data$mapeo)) {
  file_geom <- data$mapeo$espacial[i]
  tipo_int <- data$mapeo$tipo[i]
  params <- data$elasticidades %>% filter(tipo == tipo_int)
  
  if (nrow(params) > 0) {
    message(paste("Procesando intervención:", tipo_int))
    geom <- st_read(file_geom, quiet = TRUE)
    
    # El impacto ahora considera si el píxel es apto según su clasificación
    impacto_interv <- calculate_impact(data$raster, geom, params$elasticidad, params$rampa)
    impacto_total <- impacto_total + impacto_interv
  }
}

writeRaster(impacto_total, "resultado_cambio_valor.tif", overwrite=TRUE)

# Resumen de resultados
cambio_medio <- global(impacto_total, "mean", na.rm=TRUE)[1,1]
cat(sprintf("\nCambio promedio en toda el área: %.4f%%\n", cambio_medio * 100))

# Visualización comparativa
par(mfrow=c(1,2))
plot(data$raster, main="Uso de Suelo Actual\n(1:Res, 2:Com, 3:Ind, 4:Agua)")
plot(impacto_total, main="Impacto en Valor\n(Solo en Res y Com)")
