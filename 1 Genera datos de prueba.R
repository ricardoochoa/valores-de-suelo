# ==============================================================================
# MODELO DE EVALUACIÓN DE IMPACTO URBANO EN EL VALOR DEL SUELO
# Script basado en especificaciones de elasticidad y rampa de decaimiento
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. GENERACIÓN DE DATOS SINTÉTICOS (PARA PRUEBAS)
# ------------------------------------------------------------------------------

generate_synthetic_data <- function() {
  message("Generando datos sintéticos para pruebas...")
  
  # 1.1 Crear un ráster de clasificación (1km x 1km, resolución 10m)
  # Categorías: 1: Residencial, 2: Comercial, 3: Industrial, 4: Cuerpo Agua, 5: Baldío
  r <- rast(nrows=100, ncols=100, xmin=0, xmax=1000, ymin=0, ymax=1000, 
            crs="EPSG:32614") 
  set.seed(42)
  values(r) <- sample(1:5, ncell(r), replace=TRUE)
  writeRaster(r, "clasificacion.tif", overwrite=TRUE)
  
  # 1.2 Crear CSV de elasticidades
  elasticidades <- data.frame(
    tipo = c("area_verde", "cuerpo_agua", "techo_verde"),
    elasticidad = c(0.04, 0.08, 0.02),
    desv = c(0.005, 0.01, 0.003),
    dist = c("normal", "normal", "t"),
    rampa = c(0.16, 0.16, 0.16)
  )
  write_csv(elasticidades, "elasticidades.csv")
  
  # 1.3 Crear un polígono de intervención
  coords <- matrix(c(400,400, 600,400, 600,600, 400,600, 400,400), ncol=2, byrow=TRUE)
  pol <- st_polygon(list(coords)) %>% st_sfc(crs="EPSG:32614") %>% st_sf()
  st_write(pol, "intervencion_centro.geojson", delete_dsn=TRUE, quiet=TRUE)
  
  # 1.4 Crear CSV de mapeo
  mapeo <- data.frame(
    espacial = "intervencion_centro.geojson",
    tipo = "area_verde"
  )
  write_csv(mapeo, "mapeo_intervenciones.csv")
  
  message("Datos sintéticos creados exitosamente.")
}
