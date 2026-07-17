# =====================================================================
# 07_lisa_clusters.R
#
# Local Indicators of Spatial Association (LISA, Anselin 1995) sobre
# la estimacion Arc-FH de informalidad, para detectar clusters HH / LL
# / HL / LH (Seccion "Local indicators of spatial association - LISA"
# del paper). Usa matriz de contiguidad tipo reina (queen) de primer
# orden.
#
# *** REQUIERE UN SHAPEFILE DE MUNICIPIOS DE COLOMBIA ***
# Colocar el shapefile (formato .shp con sus .dbf/.shx/.prj) en:
#   data/external/shapefiles/MGN_MPIO/
# Se puede descargar gratis el "Marco Geoestadistico Nacional" (MGN)
# en el geoportal del DANE: https://geoportal.dane.gov.co
# El shapefile debe tener una columna con el codigo DIVIPOLA de 5
# digitos (departamento+municipio) que empate con 'codigo' de la base.
#
# ACTUALIZACION: el shapefile ya se encontro en el proyecto (Dropbox\
# SAE_informalidad\data\shapefiles\MGN2021_MPIO_POLITICO\) y ya viene
# incluido en este paquete en data/external/shapefiles/MGN_MPIO/.
#
# NOTA DE METODOLOGIA (correccion tras corridas reales): el codigo
# original (10.clusters_lisa.R) tiene DOS bloques ("(A) Juli" y
# "(B) Kari"); el que efectivamente genera el archivo de referencia
# 'clusters/resultados_cluster.dta' es el bloque (B), que usa
# rgeoda::queen_weights() + rgeoda::local_moran() (LISA de GeoDa, con
# significancia por PERMUTACION condicional, 999 permutaciones por
# defecto) -- NO spdep::localmoran() con p-valor analitico (normal
# asintotico). Ademas, el bloque (B) excluye explicitamente 3 codigos
# antes de construir vecinos: "88001" (San Andres), "88564"
# (Providencia) y "97666" (corregimiento/isla en Amazonas/Vaupes), que
# no tienen vecinos terrestres validos. Ese mismo bloque (B) TAMBIEN
# calcula LISA para 2005 (usando el estimador directo del Censo 2005),
# ademas de 2011/2016/2021.
#
# NOTA CRITICA -- PANEL BALANCEADO (municipios en blanco iguales en
# todos los anios, para que los mapas sean comparables): el codigo
# original construye 'data_small_combined' con un INNER JOIN de los 4
# anios (2005, 2011, 2016, 2021) antes de correr LISA -- literalmente
# "Esto se hace para que todos los años tengan los mismos NA" (2018
# comentario del autor) y luego "Volvemos a las bases originales ya
# todas con la misma cantidad de observaciones". Es decir: un municipio
# que no tiene estimacion valida en CUALQUIERA de los 4 anios queda
# excluido de TODOS los 4 anios, no solo del anio en el que falta. Asi
# el conjunto de municipios "en blanco" es identico en los 4 paneles y
# las comparaciones visuales/espaciales entre anios son validas (mismo
# universo de municipios, misma estructura de vecinos). Aqui se
# reproduce exactamente: se calcula la interseccion de codigos con
# estimacion valida en los 4 anios ANTES de correr LISA, y esa misma
# interseccion se usa en 10_figures_maps.R para la Figura 1.
#
# Aqui se reproduce lo mas fielmente posible con las herramientas de
# spdep disponibles: se excluyen esos mismos 3 codigos, y se usa
# spdep::localmoran_perm() (LISA por permutacion condicional, nsim =
# 999, semilla fija) en vez de spdep::localmoran(), usando el p-valor
# "Pr(folded) Sim" (el analogo de spdep a la significancia por
# permutacion "folded" que usa GeoDa/rgeoda).
#
# NOTA CRITICA sobre el codigo DIVIPOLA (bug corregido tras corrida
# real: Antioquia no aparecia en ningun mapa): el shapefile guarda
# 'MPIO_CDPMP' como texto de 5 digitos con cero a la izquierda cuando
# corresponde (p.ej. "05001" para Medellin), pero 'base$codigo' es
# numerico y viene SIN ese cero a la izquierda (5001), porque asi ya
# venia en el CSV de entrada. as.character(5001) da "5001" (4
# caracteres), que NUNCA empata con "05001" del shapefile -- esto
# descartaba SILENCIOSAMENTE todos los municipios de Antioquia (depto
# "05") y Atlantico (depto "08") de cualquier merge/union espacial. El
# codigo original evita esto con sprintf("%05d", as.numeric(codigo))
# antes de unir con el shapefile (ver 10.clusters_lisa.R,
# 14-public_db_creation.R); aqui se hace lo mismo.
#
# 'base' NO tiene filas para anno == 2005 (el panel modelado con SAE es
# solo 2011/2016/2021); por eso el resultado LISA de 2005 se calcula
# aparte, a partir de data/external/census2005/informalidad_2005.csv,
# y se guarda en el mismo 'lisa_resultados' (CSV + objeto en sesion)
# para que 10_figures_maps.R lo pueda usar en la Figura 3, aunque NO se
# intenta fusionar de vuelta en 'base' (no hay donde encajarlo).
#
# Usa 'base$fharcsin_est' calculado por el script 04 (ya NO viene
# precalculado en la base inicial, ver 01_load_data.R) y agrega el
# resultado como 'lisa_clusters_nombres' para que los pasos 9-11 lo
# puedan usar (solo para 2011/2016/2021).
# =====================================================================

shp_path <- file.path(dir$data_ext, "shapefiles", "MGN_MPIO")
census2005_path <- file.path(dir$data_ext, "census2005", "informalidad_2005.csv")

if (dir.exists(shp_path) && length(list.files(shp_path, pattern = "\\.shp$")) > 0) {

  mpios <- sf::st_read(shp_path, quiet = TRUE)
  # Ajustar el nombre de la columna de codigo DIVIPOLA segun el shapefile real
  codigo_col <- intersect(c("MPIO_CDPMP", "DIVIPOLA", "codigo", "COD_MPIO"), names(mpios))[1]
  stopifnot(!is.na(codigo_col))
  mpios$codigo <- as.character(mpios[[codigo_col]])

  # Municipios/islas sin vecinos terrestres validos, excluidos por el
  # codigo original antes de calcular la matriz de vecinos.
  codigos_excluir <- c("88001", "88564", "97666")

  # --- reunir el estimador de informalidad de los 4 anios (2005 + 2011/2016/2021) ---
  valores_por_anio <- list()
  for (yr in c(2011, 2016, 2021)) {
    d <- base[base$anno == yr, c("codigo", "fharcsin_est")]
    d$codigo <- sprintf("%05d", as.numeric(d$codigo))
    valores_por_anio[[as.character(yr)]] <- d
  }
  tiene_2005 <- file.exists(census2005_path)
  if (tiene_2005) {
    censo05 <- readr::read_csv(census2005_path, show_col_types = FALSE)
    valores_por_anio[["2005"]] <- data.frame(
      codigo = sprintf("%05d", as.numeric(censo05$codigo)),
      fharcsin_est = censo05$informalidad_2005
    )
  } else {
    message("No se encontro '", census2005_path, "': se omite el panel 2005 del mapa LISA (Figura 3).")
  }

  # --- panel balanceado: interseccion de codigos con estimacion valida en TODOS los anios ---
  # (igual que 'data_small_combined <- inner_join(...)' del codigo original,
  # ver nota critica arriba: "para que todos los años tengan los mismos NA")
  codigos_validos_por_anio <- lapply(valores_por_anio, function(d) d$codigo[!is.na(d$fharcsin_est)])
  codigos_balanceados <- Reduce(intersect, codigos_validos_por_anio)
  codigos_balanceados <- setdiff(codigos_balanceados, codigos_excluir)
  message("Panel balanceado LISA: ", length(codigos_balanceados),
          " municipios con estimacion valida en los ", length(valores_por_anio), " anios disponibles.")

  # --- funcion auxiliar: calcula LISA para un data.frame codigo/fharcsin_est ---
  calcular_lisa <- function(dyr, anno_lbl) {
    geo_yr <- merge(mpios, dyr, by = "codigo")
    geo_yr <- geo_yr[!is.na(geo_yr$fharcsin_est), ]
    if (nrow(geo_yr) < 10) {
      warning("Muy pocas observaciones geo-referenciadas para el anio ", anno_lbl, "; se omite LISA.")
      return(NULL)
    }

    nb <- spdep::poly2nb(geo_yr, queen = TRUE)
    # islas / municipios sin vecinos se excluyen del test (spdep las deja con 0 vecinos)
    lw <- spdep::nb2listw(nb, style = "W", zero.policy = TRUE)

    # LISA por permutacion condicional (999 simulaciones), como el
    # bloque (B) del codigo original via rgeoda::local_moran(); ver
    # nota de metodologia arriba.
    local_i <- spdep::localmoran_perm(
      geo_yr$fharcsin_est, lw, nsim = 999,
      zero.policy = TRUE, iseed = 12345
    )

    z_val   <- scale(geo_yr$fharcsin_est)[, 1]
    z_lag   <- spdep::lag.listw(lw, geo_yr$fharcsin_est, zero.policy = TRUE)
    z_lag_s <- scale(z_lag)[, 1]
    p_col   <- grep("folded", colnames(local_i), value = TRUE)[1]
    p_val   <- local_i[, p_col]

    cluster_tipo <- dplyr::case_when(
      p_val >= 0.05          ~ "NS",
      z_val >= 0 & z_lag_s >= 0 ~ "HH",
      z_val < 0  & z_lag_s < 0  ~ "LL",
      z_val >= 0 & z_lag_s < 0  ~ "HL",
      z_val < 0  & z_lag_s >= 0 ~ "LH",
      TRUE ~ NA_character_
    )

    data.frame(codigo = geo_yr$codigo, anno = anno_lbl, lisa_clusters_nombres_repro = cluster_tipo)
  }

  lisa_por_anio <- list()
  for (anno_nombre in names(valores_por_anio)) {
    dyr <- valores_por_anio[[anno_nombre]]
    dyr <- dyr[dyr$codigo %in% codigos_balanceados, ]
    resultado <- calcular_lisa(dyr, as.numeric(anno_nombre))
    if (!is.null(resultado)) lisa_por_anio[[anno_nombre]] <- resultado
  }

  lisa_resultados <- do.call(rbind, lisa_por_anio)
  readr::write_csv(lisa_resultados, file.path(dir$estimates, "lisa_resultados.csv"))
  message("LISA calculado para ", nrow(lisa_resultados), " observaciones municipio-anio ",
          "(panel balanceado, incluye 2005 si el panel censal estaba disponible).")

  # --- agregar la columna calculada a 'base' para los pasos siguientes ---
  # (solo 2011/2016/2021: 'base' no tiene filas de 2005, esas quedan
  # unicamente en 'lisa_resultados' para uso directo en 10_figures_maps.R)
  lisa_para_base <- lisa_resultados[lisa_resultados$anno != 2005, ]
  lisa_para_base$codigo <- as.numeric(lisa_para_base$codigo)
  base <- dplyr::left_join(base, lisa_para_base, by = c("codigo", "anno"))
  base$lisa_clusters_nombres <- base$lisa_clusters_nombres_repro

  # --- comparacion opcional contra la base original (con resultados ya calculados) ---
  ref_path <- file.path(dir$reference, "informalidad_municipal_base_completa_con_resultados.csv")
  if (file.exists(ref_path)) {
    referencia <- readr::read_delim(ref_path, delim = ";", show_col_types = FALSE)
    chequeo_lisa <- merge(lisa_para_base, referencia[, c("codigo", "anno", "lisa_clusters_nombres")],
                           by = c("codigo", "anno"))
    chequeo_lisa <- chequeo_lisa[stats::complete.cases(chequeo_lisa), ]
    if (nrow(chequeo_lisa) > 10) {
      coincidencia <- mean(chequeo_lisa$lisa_clusters_nombres_repro == chequeo_lisa$lisa_clusters_nombres)
      message("Coincidencia LISA reproducido vs. base original (referencia_original/, 2011/2016/2021): ",
              round(100 * coincidencia, 1), "%")
    }
  } else {
    message("No se encontro '", ref_path, "': se omite la comparacion contra la base original.")
  }

} else {
  warning(
    "No se encontro shapefile en '", shp_path, "'. \n",
    "Se omite el calculo de LISA (07_lisa_clusters.R) y el mapa de clusters (Figura 3). \n",
    "Descargue el shapefile MGN de municipios del DANE y coloquelo en esa carpeta para habilitar este paso."
  )
}
