# =====================================================================
# 12_graph_difference_sae_dir.R
#
# Compara, a nivel departamental, la estimacion SAE por Random Forest
# (MERF, calculada en el script 06) contra el estimador directo de la
# GEIH. Es el equivalente al script original
# 'Dropbox/SAE_informalidad/codigo/12-graph_difference_sae_dir.r' y a
# la Figura A2 del apendice del paper ("we compared aggregated SAE
# results with direct estimates at the department level").
#
# Este es el resultado del paper donde el MERF (no el Arc-FH) se usa
# explicitamente como el estimador SAE de comparacion.
#
# Requiere: 01_load_data.R y 06_estimation_merf.R ya ejecutados
# (MERF_resultados debe existir en 'base').
# =====================================================================

if (!"MERF_resultados" %in% names(base)) {

  warning("'MERF_resultados' no esta en 'base' (corre primero 06_estimation_merf.R). ",
          "Se omite 12_graph_difference_sae_dir.R.")

} else {

  # --- promedio departamental ponderado por poblacion ---
  dpt_directo <- base %>%
    dplyr::filter(!is.na(informalidad_adj)) %>%
    dplyr::group_by(codigo_depto, departamento, anno) %>%
    dplyr::summarise(directo_dpto = stats::weighted.mean(informalidad_adj, w = pob_total, na.rm = TRUE),
                      .groups = "drop")

  dpt_merf <- base %>%
    dplyr::filter(!is.na(MERF_resultados)) %>%
    dplyr::group_by(codigo_depto, departamento, anno) %>%
    dplyr::summarise(merf_dpto = stats::weighted.mean(MERF_resultados, w = pob_total, na.rm = TRUE),
                      .groups = "drop")

  comparacion_dpto <- dplyr::inner_join(dpt_directo, dpt_merf, by = c("codigo_depto", "departamento", "anno"))

  readr::write_csv(comparacion_dpto, file.path(dir$estimates, "comparacion_dpto_directo_vs_merf.csv"))

  for (yr in c(2011, 2016, 2021)) {

    dat_yr <- comparacion_dpto[comparacion_dpto$anno == yr, ]
    if (nrow(dat_yr) == 0) next

    dat_long <- tidyr::pivot_longer(dat_yr, cols = c("directo_dpto", "merf_dpto"),
                                     names_to = "estimador", values_to = "informalidad")
    dat_long$estimador <- factor(dat_long$estimador,
                                  levels = c("directo_dpto", "merf_dpto"),
                                  labels = c("Directo (GEIH)", "SAE - MERF"))

    orden_dpto <- dat_yr$departamento[order(dat_yr$directo_dpto)]
    dat_long$departamento <- factor(dat_long$departamento, levels = orden_dpto)

    fig <- ggplot2::ggplot(dat_long, ggplot2::aes(x = departamento, y = informalidad,
                                                    color = estimador, shape = estimador)) +
      ggplot2::geom_point(size = 2.4) +
      ggplot2::coord_flip() +
      ggplot2::labs(title = paste0(yr, ": informalidad directa vs. SAE (MERF), por departamento"),
                    x = NULL, y = "Informalidad (%)", color = NULL, shape = NULL) +
      ggplot2::theme_minimal()

    ggplot2::ggsave(file.path(dir$figures, paste0(yr, "dpt_direct_vs_merf.png")),
                     fig, width = 7, height = 8, dpi = 300)
  }

  message("Comparacion directo vs. MERF por departamento guardada en output/estimates/ y output/figures/.")
}
