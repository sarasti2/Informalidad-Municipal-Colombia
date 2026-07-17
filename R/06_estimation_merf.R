# =====================================================================
# 06_estimation_merf.R
#
# Estimacion SAE por Mixed Effects Random Forest (MERF), siguiendo
# Krennmair & Schmid (2022) y el paquete SAEforest, tal como se cita
# en el paper (Seccion "Limitation of the FH family models"). MERF
# reemplaza la parte "sintetica" lineal (X*beta) del modelo Fay-Herriot
# por un bosque aleatorio, permitiendo relaciones no lineales entre la
# informalidad y las covariables.
#
# NOTA: en el codigo original (1-Estimation_and_results.R), MERF
# tambien se entrena directamente sobre la base municipal agregada
# (base_final_sin_outlayers.xlsx, la misma tabla de covariables que
# alimenta el modelo FH) -- NO sobre microdatos de la GEIH a nivel de
# persona/hogar. Alla se llama a
# SAEforest_model(Y = inform_2011, X = X_covar_2011, dName = "municipio",
#                 smp_data = base_2011, pop_data = base_2011)
# con smp_data y pop_data iguales a la misma tabla municipio-anio, y
# los resultados se guardan por anio (2011/2016/2021_resultados_merf.dta).
#
# IMPORTANTE (funcion de bajo nivel): SAEforest_model() es un wrapper
# alrededor de SAEforest::MERFranger(), pero MERFranger() NO tiene los
# argumentos 'formula'/'dName'/'OOsample' (eso solo existe en el
# wrapper SAEforest_model, que exige un objeto 'smp_data'/'pop_data'
# con columnas de dominio). La firma real de MERFranger() es:
#   MERFranger(Y, X, random, data, importance = "none",
#              initialRandomEffects = 0, ErrorTolerance = 1e-04,
#              MaxIterations = 25, na.rm = TRUE, ...)
# donde 'random' sigue la sintaxis de efectos aleatorios de lme4::lmer.
#
# NOTA CRITICA sobre el grupo de efectos aleatorios: dentro de cada
# anio, la base solo tiene UNA fila por municipio con estimador directo
# valido (~436-445 de 1103-1120), y 'codigo' (DIVIPOLA) es unico por
# fila. lme4 no puede estimar un intercepto aleatorio por dominio si el
# numero de niveles del grupo es igual al numero de observaciones
# ("number of levels of each grouping factor must be < number of
# observations"). El codigo original evita este error porque usa
# dName = "municipio" (el NOMBRE, no el codigo DIVIPOLA) como variable
# de agrupacion, y varios municipios de distintos departamentos
# comparten el mismo nombre (p.ej. mas de un "La Union" en Colombia):
# ~12 de los ~436-445 municipios muestreados por anio tienen un nombre
# duplicado, lo que apenas alcanza para que 'niveles < observaciones'
# se cumpla. Esto parece ser un efecto colateral accidental de usar el
# nombre en vez del codigo unico como dominio (agrupa erroneamente
# municipios no relacionados que comparten nombre), no una decision de
# diseño deliberada -- pero, para efectos de esta replicacion, aqui se
# reproduce EXACTAMENTE ese comportamiento del codigo original: se
# agrupa por 'municipio' (nombre), no por 'codigo'.
#
# Requiere: 00_packages.R, 01_load_data.R.
# =====================================================================

covars_merf_full <- c(
  "t_crea", "gandina", "gcaribe", "gpacifica", "gorinoquia", "gamazonia",
  "altura", "dismdo", "disbogota", "distancia_mercado",
  "va_actividad_primaria", "va_actividad_secundaria", "va_actividad_terciaria",
  "formal_rate", "pprimary", "psecondary", "pterciary",
  "ruralidad", "vacancy_rate", "pmujerpet", "salario_bas",
  "pgroup1", "pgroup2", "pgroup3", "pgroup4", "pgroup5", "pgroup6",
  "areakm2", "pregimen_subsidiado",
  "promleccri", "promglobal", "prommatema"
)
covars_merf_full <- covars_merf_full[covars_merf_full %in% names(base)]

merf_by_year <- list()
merf_modelos_por_anio <- list()

if (requireNamespace("SAEforest", quietly = TRUE)) {

  for (yr in c(2011, 2016, 2021)) {

    # Mismos recortes de covariables que el codigo original por anio
    covars_yr <- covars_merf_full
    if (yr %in% c(2011, 2016)) {
      covars_yr <- setdiff(covars_yr, c("promleccri", "promglobal", "prommatema"))
    }
    if (yr == 2011) {
      covars_yr <- setdiff(covars_yr, "vacancy_rate")
    }

    dyr <- base[base$anno == yr, c("codigo", "municipio", "informalidad_adj", covars_yr)]
    dyr <- dyr[stats::complete.cases(dyr), ]
    # Grupo de efectos aleatorios = nombre del municipio, igual que el
    # codigo original (dName = "municipio"); ver nota arriba.
    dyr$municipio <- factor(dyr$municipio)

    modelo_yr <- tryCatch(
      SAEforest::MERFranger(
        Y        = dyr$informalidad_adj,
        X        = dyr[, covars_yr],
        random   = "(1 | municipio)",
        data     = dyr,
        importance = "impurity"
      ),
      error = function(e) {
        warning("SAEforest::MERFranger fallo para el anio ", yr, ": ",
                conditionMessage(e), ". Revisar version del paquete / especificacion.")
        NULL
      }
    )

    if (!is.null(modelo_yr)) {
      pred_yr <- as.numeric(stats::predict(modelo_yr, dyr))
      merf_by_year[[as.character(yr)]] <- data.frame(
        codigo = as.character(dyr$codigo),
        anno   = yr,
        MERF_resultados_repro = pmin(pmax(pred_yr, 0), 100)
      )
      # Se guarda el modelo ajustado (no solo las predicciones): la
      # Tabla 2 (08_variable_importance_rf.R) reutiliza directamente la
      # importancia de variables del bosque de este modelo MERF, tal
      # como hace el codigo original (model$MERFmodel$Forest$variable.importance).
      merf_modelos_por_anio[[as.character(yr)]] <- modelo_yr
      message("MERF ", yr, ": modelo ajustado con ", length(covars_yr),
              " covariables sobre ", nrow(dyr), " municipios (",
              length(unique(dyr$municipio)), " nombres de municipio unicos).")
    }
  }

} else {
  warning("Paquete SAEforest no disponible: se omite 06_estimation_merf.R. ",
          "Instalar con devtools::install_github('krennpa/SAEforest') (ver 00_packages.R).")
}

if (length(merf_modelos_por_anio) > 0) {
  saveRDS(merf_modelos_por_anio, file.path(dir$estimates, "merf_modelos_por_anio.rds"))
}

merf_resultados <- NULL
if (length(merf_by_year) > 0) {
  merf_resultados <- do.call(rbind, merf_by_year)
  merf_resultados$codigo <- as.numeric(merf_resultados$codigo)
}

if (!is.null(merf_resultados)) {
  readr::write_csv(merf_resultados, file.path(dir$estimates, "merf_resultados.csv"))

  # --- agregar la columna calculada a 'base' para los pasos siguientes ---
  base <- dplyr::left_join(base, merf_resultados, by = c("codigo", "anno"))
  base$MERF_resultados <- base$MERF_resultados_repro

  # --- comparacion opcional contra la base original (con resultados ya calculados) ---
  ref_path <- file.path(dir$reference, "informalidad_municipal_base_completa_con_resultados.csv")
  if (file.exists(ref_path)) {
    referencia <- readr::read_delim(ref_path, delim = ";", show_col_types = FALSE)
    chequeo_merf <- merge(merf_resultados, referencia[, c("codigo", "anno", "MERF_resultados")],
                           by = c("codigo", "anno"))
    chequeo_merf <- chequeo_merf[stats::complete.cases(chequeo_merf), ]
    if (nrow(chequeo_merf) > 10) {
      message("Correlacion MERF reproducido vs. base original (referencia_original/): ",
              round(stats::cor(chequeo_merf$MERF_resultados_repro, chequeo_merf$MERF_resultados), 3))
    }
  } else {
    message("No se encontro '", ref_path, "': se omite la comparacion contra la base original.")
  }
}
