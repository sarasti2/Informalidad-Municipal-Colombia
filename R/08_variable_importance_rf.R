# =====================================================================
# 08_variable_importance_rf.R
#
# Tabla 2 del paper: relevancia de variables auxiliares para estimar la
# informalidad municipal.
#
# NOTA IMPORTANTE (metodologia corregida): en el codigo original
# (1-Estimation_and_results.R, seccion "3.2 Graficas de importancia de
# las variables"), la Tabla 2 NO se calcula con un randomForest nuevo
# entrenado sobre fharcsin_est -- se extrae DIRECTAMENTE de los modelos
# MERF ya ajustados en la seccion 2 del script original:
#   feature_importance <- as.numeric(model$MERFmodel$Forest$variable.importance)
#   feature_names <- attr(model$MERFmodel$Forest$variable.importance, "names")
# para model2011, model2016 y model2021 (los mismos objetos usados para
# generar 'MERF_resultados').
#
# Aqui se replica exactamente eso: se reutilizan los modelos MERF
# ajustados por 06_estimation_merf.R (objeto 'merf_modelos_por_anio',
# disponible en la misma sesion de run_all.R, o cargado desde
# output/estimates/merf_modelos_por_anio.rds si este script se corre
# de forma independiente). La importancia usada es "impurity" (la
# misma medida con la que se ajustaron los modelos en el paso 6).
# =====================================================================

if (!exists("merf_modelos_por_anio") || length(merf_modelos_por_anio) == 0) {
  rds_path <- file.path(dir$estimates, "merf_modelos_por_anio.rds")
  if (file.exists(rds_path)) {
    merf_modelos_por_anio <- readRDS(rds_path)
    message("Modelos MERF cargados desde ", rds_path)
  } else {
    stop("No hay modelos MERF disponibles ('merf_modelos_por_anio'). ",
         "Correr primero 06_estimation_merf.R (en la misma sesion o guardando el .rds).")
  }
}

tabla2_importancia <- list()

for (yr in c(2011, 2016, 2021)) {
  yr_chr <- as.character(yr)

  if (is.null(merf_modelos_por_anio[[yr_chr]])) {
    warning("No hay modelo MERF ajustado para el anio ", yr, "; se omite de la Tabla 2.")
    next
  }

  modelo_yr <- merf_modelos_por_anio[[yr_chr]]
  imp <- modelo_yr$Forest$variable.importance

  if (is.null(imp)) {
    warning("El modelo MERF de ", yr, " no tiene 'variable.importance' ",
            "(revisar que 06_estimation_merf.R haya usado importance = 'impurity').")
    next
  }

  imp_df <- data.frame(
    anno = yr,
    variable = names(imp),
    importancia = as.numeric(imp)
  )
  imp_df <- imp_df[order(-imp_df$importancia), ]
  imp_df$ranking <- seq_len(nrow(imp_df))
  tabla2_importancia[[yr_chr]] <- utils::head(imp_df, 10)
}

tabla2_importancia <- do.call(rbind, tabla2_importancia)
readr::write_csv(tabla2_importancia, file.path(dir$tables, "tabla2_importancia_variables.csv"))
message("Tabla 2 (importancia de variables, desde los modelos MERF) guardada en output/tables/.")
print(tabla2_importancia)
