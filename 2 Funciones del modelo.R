# ==============================================================================
# MODELO DE EVALUACIÓN DE IMPACTO URBANO EN EL VALOR DEL SUELO
# Script basado en especificaciones de elasticidad y rampa de decaimiento
# ==============================================================================

# ------------------------------------------------------------------------------
# 2. FUNCIONES DEL MODELO (RF-03, RF-04, RNF-03)
# ------------------------------------------------------------------------------

# RF-01 & RNF-04: Carga y validación de datos
load_data <- function(raster_path, elast_path, mapping_path) {
  # Cargar ráster
  r_clas <- rast(raster_path)
  
  # Cargar CSVs
  df_elast <- read_csv(elast_path, show_col_types = FALSE)
  df_map <- read_csv(mapping_path, show_col_types = FALSE)
  
  # Validar columnas requeridas (RNF-04)
  req_cols <- c("tipo", "elasticidad", "desv", "dist", "rampa")
  if (!all(req_cols %in% colnames(df_elast))) {
    stop("Error: El archivo de elasticidades no contiene todas las columnas requeridas.")
  }
  
  return(list(raster = r_clas, elasticidades = df_elast, mapeo = df_map))
}

# RF-02 & RF-03: Cálculo de impacto con rampa
calculate_impact <- function(raster_base, intervention_shp, elast_val, rampa_val) {
  
  # RNF-02: Verificar y reproyectar si es necesario
  if (st_crs(intervention_shp) != st_crs(raster_base)) {
    intervention_shp <- st_transform(intervention_shp, st_crs(raster_base))
  }
  
  # RF-02: Calcular distancia euclidiana desde el polígono a cada píxel
  # Convertimos el polígono a formato terra para mayor velocidad (RNF-01)
  v_interv <- vect(intervention_shp)
  dist_raster <- distance(raster_base, v_interv)
  
  # RF-03: Aplicar fórmula de decaimiento
  # Impacto = Elasticidad * max(0, 1 - (Distancia/100 * Rampa))
  # Nota: Rampa se recibe como 0.16 (16%)
  impact_raster <- elast_val * (1 - (dist_raster / 100) * rampa_val)
  
  # Truncar valores negativos a cero (Límite de efecto)
  impact_raster[impact_raster < 0] <- 0
  
  return(impact_raster)
}

# RF-04: Estimación de incertidumbre
estimate_uncertainty <- function(impact_raster, desv_val, dist_type, confidence = 0.95) {
  # Calculamos el multiplicador basado en la distribución
  alpha <- 1 - confidence
  
  if (dist_type == "normal") {
    multiplier <- qnorm(1 - alpha/2)
  } else if (dist_type == "t") {
    # Usamos grados de libertad arbitrarios (ej. 30) o simplificado
    multiplier <- qt(1 - alpha/2, df = 30)
  } else {
    multiplier <- 1.96 # Default Normal
  }
  
  # Margen de error = multiplicador * desv
  # El impacto ya tiene el factor de decaimiento aplicado, 
  # asumimos que la desviación también decae proporcionalmente
  error_raster <- multiplier * desv_val * (impact_raster / max(values(impact_raster), na.rm=TRUE))
  
  return(error_raster)
}