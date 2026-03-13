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
# 3. EJECUCIÓN PRINCIPAL (MAIN)
# ------------------------------------------------------------------------------

# Ejecutar generación de datos si no existen
if (!file.exists("clasificacion.tif")) generate_synthetic_data()

# 1. Cargar insumos
data <- load_data("clasificacion.tif", "elasticidades.csv", "mapeo_intervenciones.csv")

# Inicializar ráster de impacto total (ceros)
impacto_total <- data$raster * 0
names(impacto_total) <- "cambio_porcentual"

# 2. Procesar cada intervención definida en el mapeo
for (i in 1:nrow(data$mapeo)) {
  file_geom <- data$mapeo$espacial[i]
  tipo_int <- data$mapeo$tipo[i]
  
  # Obtener parámetros de la tabla de elasticidades
  params <- data$elasticidades %>% filter(tipo == tipo_int)
  
  if (nrow(params) > 0) {
    message(paste("Procesando intervención:", tipo_int))
    
    # Cargar geometría
    geom <- st_read(file_geom, quiet = TRUE)
    
    # Calcular impacto determinista
    impacto_interv <- calculate_impact(
      data$raster, 
      geom, 
      params$elasticidad, 
      params$rampa
    )
    
    # Sumar al acumulado (puedes cambiar a 'max' según lógica de negocio)
    impacto_total <- impacto_total + impacto_interv
    
    # Calcular error (para el reporte final)
    error_interv <- estimate_uncertainty(impacto_interv, params$desv, params$dist)
  }
}

# 3. RF-05: Salidas
# Exportar Ráster
writeRaster(impacto_total, "resultado_cambio_valor.tif", overwrite=TRUE)

# Reporte Numérico
cambio_medio <- global(impacto_total, "mean", na.rm=TRUE)[1,1]
cambio_max   <- global(impacto_total, "max", na.rm=TRUE)[1,1]

cat("\n============================================\n")
cat("REPORTE DE CAMBIO EN VALOR DE PROPIEDAD\n")
cat("============================================\n")
cat(sprintf("Cambio promedio esperado: %.2f%%\n", cambio_medio * 100))
cat(sprintf("Cambio máximo observado: %.2f%%\n", cambio_max * 100))
cat("Archivo generado: resultado_cambio_valor.tif\n")
cat("============================================\n")

# Visualización rápida (opcional)
plot(impacto_total, main="Incremento Porcentual del Valor del Suelo")
