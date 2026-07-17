# =====================================================================
# 04_estimation_fh_arcsin.R
#
# Corre el modelo Arc-FH (script 02) para 2011, 2016 y 2021, usando las
# covariables seleccionadas por BIC (script 03) para cada ano. Genera
# 'fharcsin_est', 'Low' y 'Up' -- columnas que la base INICIAL ya NO
# trae (se removieron a proposito, ver 01_load_data.R) y que este
# script agrega de verdad a 'base' para que los pasos siguientes
# (6-11) las puedan usar.
#
# Requiere: 00_packages.R, 01_load_data.R, 02_fh_arcsin_function.R,
#           03_variable_selection_bic.R ya ejecutados (ver run_all.R).
# =====================================================================

anios <- c(2011, 2016, 2021)
resultados_fh <- list()
seleccion_fh <- list()

for (yr in anios) {

  message("== Arc-FH ", yr, " ==")
  dyr <- base[base$anno == yr, ]

  sel <- select_vars_bic(dyr)
  seleccion_fh[[as.character(yr)]] <- sel
  message("  Variables seleccionadas (BIC): ", paste(sel$selected, collapse = ", "),
          "  | R2 = ", round(sel$r2, 3), " | n = ", sel$n_used)

  covars_yr <- sel$selected
  X <- as.matrix(cbind(Intercept = 1, dyr[, covars_yr]))

  fh_out <- FH_arcsin(
    direct_pct = dyr$informalidad_adj,
    eff_n      = dyr$num_obser_freq_adj,
    X          = X,
    B          = 200
  )

  out <- data.frame(
    codigo = dyr$codigo,
    anno   = yr,
    fharcsin_est_repro = fh_out$area_est,
    Low_repro  = fh_out$Low,
    Up_repro   = fh_out$Up,
    gamma      = fh_out$gamma,
    muestreado = fh_out$is_sampled
  )
  resultados_fh[[as.character(yr)]] <- out
}

fh_arcsin_resultados <- do.call(rbind, resultados_fh)

# --- agregar las columnas calculadas a 'base' para los pasos siguientes ---
base <- dplyr::left_join(
  base,
  fh_arcsin_resultados[, c("codigo", "anno", "fharcsin_est_repro", "Low_repro", "Up_repro")],
  by = c("codigo", "anno")
)
base$fharcsin_est <- base$fharcsin_est_repro
base$Low <- base$Low_repro
base$Up  <- base$Up_repro

# --- comparacion opcional contra la base original (con resultados ya calculados) ---
ref_path <- file.path(dir$reference, "informalidad_municipal_base_completa_con_resultados.csv")
if (file.exists(ref_path)) {
  referencia <- readr::read_delim(ref_path, delim = ";", show_col_types = FALSE)
  chequeo <- merge(fh_arcsin_resultados, referencia[, c("codigo", "anno", "fharcsin_est")],
                    by = c("codigo", "anno"))
  chequeo <- chequeo[stats::complete.cases(chequeo[, c("fharcsin_est_repro", "fharcsin_est")]), ]
  correlacion <- stats::cor(chequeo$fharcsin_est_repro, chequeo$fharcsin_est)
  mae <- mean(abs(chequeo$fharcsin_est_repro - chequeo$fharcsin_est))
  message("Correlacion reproduccion vs. base original (referencia_original/): ", round(correlacion, 3),
          " | MAE = ", round(mae, 2), " pp")
  # Nota: no se espera una correlacion perfecta si el conjunto exacto de
  # covariables/semilla de bootstrap del estudio original difiere del
  # usado aqui; una correlacion > 0.95 valida que la metodologia esta
  # correctamente implementada (ver validacion en validacion_python/).
} else {
  message("No se encontro '", ref_path, "': se omite la comparacion contra la base original.")
}

readr::write_csv(fh_arcsin_resultados, file.path(dir$estimates, "fh_arcsin_resultados.csv"))
saveRDS(seleccion_fh, file.path(dir$estimates, "fh_arcsin_seleccion_variables.rds"))
