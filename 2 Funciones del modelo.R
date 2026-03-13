# ==============================================================================
# MODELO DE EVALUACIÓN DE IMPACTO URBANO EN EL VALOR DEL SUELO
# Script basado en especificaciones de elasticidad y rampa de decaimiento
# ==============================================================================

# ------------------------------------------------------------------------------
# 2. FUNCIONES DEL MODELO (RF-03, RF-04, RNF-03)
# ------------------------------------------------------------------------------

load_data <- function(raster_path, elast_path, mapping_path) {
  r_clas <- rast(raster_path)
  df_elast <- read_csv(elast_path, show_col_types = FALSE)
  df_map <- read_csv(mapping_path, show_col_types = FALSE)
  return(list(raster = r_clas, elasticidades = df_elast, mapeo = df_map))
}

# NUEVA FUNCIÓN: Define qué usos de suelo son sensibles al aumento de valor
# En este caso, solo Residencial (1) y Comercial (2) capturan valor.
is_land_use_sensitive <- function(land_use_raster) {
  # Creamos una máscara booleana: TRUE si es 1 o 2, FALSE en caso contrario
  mask <- land_use_raster == 1 | land_use_raster == 2
  return(mask)
}

calculate_impact <- function(raster_base, intervention_shp, elast_val, rampa_val) {
  
  if (st_crs(intervention_shp) != st_crs(raster_base)) {
    intervention_shp <- st_transform(intervention_shp, st_crs(raster_base))
  }
  
  v_interv <- vect(intervention_shp)
  dist_raster <- distance(raster_base, v_interv)
  
  # Cálculo base de decaimiento por distancia
  impact_raster <- elast_val * (1 - (dist_raster / 100) * rampa_val)
  impact_raster[impact_raster < 0] <- 0
  
  # --- MEJORA: SENSIBILIDAD AL USO DEL SUELO ---
  # Solo aplicamos el impacto donde el suelo es sensible (Residencial/Comercial)
  sensibilidad <- is_land_use_sensitive(raster_base)
  impacto_sensible <- impact_raster * sensibilidad
  
  return(impacto_sensible)
}

estimate_uncertainty <- function(impact_raster, desv_val, dist_type, confidence = 0.95) {
  alpha <- 1 - confidence
  multiplier <- if(dist_type == "normal") qnorm(1 - alpha/2) else qt(1 - alpha/2, df = 30)
  
  # El error solo existe donde hay impacto
  max_val <- max(values(impact_raster), na.rm=TRUE)
  factor_decaimiento <- if(max_val > 0) impact_raster / max_val else 0
  error_raster <- multiplier * desv_val * factor_decaimiento
  
  return(error_raster)
}
