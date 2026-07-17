# =====================================================================
# 05_benchmarking.R
#
# Ajuste (benchmarking) de las estimaciones Arc-FH para que, ponderadas
# por poblacion, coincidan con el estimador directo a nivel departamental
# (columna 'fh_benchmark' en la base). Se usa un benchmarking de razon
# (ratio benchmarking, ver Rao & Molina 2015, cap. 7): dentro de cada
# departamento-anio, se reescala cada estimacion municipal por el
# cociente entre el directo departamental y el promedio ponderado de
# las estimaciones Arc-FH del departamento.
#
# Requiere: 04_estimation_fh_arcsin.R ya ejecutado.
# =====================================================================

dep_direct <- base %>%
  dplyr::filter(!is.na(informalidad_adj)) %>%
  dplyr::group_by(codigo_depto, anno) %>%
  dplyr::summarise(
    directo_dpto = stats::weighted.mean(informalidad_adj, w = pob_total, na.rm = TRUE),
    .groups = "drop"
  )

fh_con_pob <- fh_arcsin_resultados %>%
  dplyr::left_join(base[, c("codigo", "anno", "codigo_depto", "pob_total")],
                    by = c("codigo", "anno"))

bench <- fh_con_pob %>%
  dplyr::left_join(dep_direct, by = c("codigo_depto", "anno")) %>%
  dplyr::group_by(codigo_depto, anno) %>%
  dplyr::mutate(
    fh_dpto_ponderado = stats::weighted.mean(fharcsin_est_repro, w = pob_total, na.rm = TRUE),
    factor_bench = ifelse(is.na(directo_dpto) | fh_dpto_ponderado == 0, 1,
                           directo_dpto / fh_dpto_ponderado),
    fh_benchmark_repro = pmin(pmax(fharcsin_est_repro * factor_bench, 0), 100)
  ) %>%
  dplyr::ungroup()

readr::write_csv(
  bench[, c("codigo", "anno", "fharcsin_est_repro", "fh_benchmark_repro")],
  file.path(dir$estimates, "fh_benchmark_resultados.csv")
)

message("Benchmarking departamental aplicado. Ejemplo de factores (2021):")
print(utils::head(bench[bench$anno == 2021, c("codigo_depto", "factor_bench")] %>% dplyr::distinct()))
