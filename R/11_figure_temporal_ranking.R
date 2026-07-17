# =====================================================================
# 11_figure_temporal_ranking.R
#
# Figura 2 del paper: cambios en la informalidad municipal 2005-2021,
# ordenando los municipios segun su nivel de informalidad en 2021 y
# ajustando un polinomio local (loess) por anio, con bandas de
# confianza del 95%.
#
# Esta figura NO requiere shapefile, por lo que se puede generar
# completamente con los datos disponibles (2011/2016/2021). Si se
# cuenta con la estimacion 2005 (ver 10_figures_maps.R), colocarla en
# data/external/census2005/informalidad_2005.csv para incluirla.
# =====================================================================

datos_fig2 <- base[, c("codigo", "anno", "fharcsin_est")]

census2005_path <- file.path(dir$data_ext, "census2005", "informalidad_2005.csv")
if (file.exists(census2005_path)) {
  censo05 <- readr::read_csv(census2005_path, show_col_types = FALSE)
  datos_fig2 <- rbind(datos_fig2, data.frame(codigo = censo05$codigo, anno = 2005,
                                              fharcsin_est = censo05$informalidad_2005))
} else {
  message("Nota: Figura 2 se genera SOLO para 2011/2016/2021 (no se encontro el insumo de 2005).")
}

ranking_2021 <- base[base$anno == 2021, c("codigo", "fharcsin_est")]
ranking_2021 <- ranking_2021[order(ranking_2021$fharcsin_est), ]
ranking_2021$rank <- seq_len(nrow(ranking_2021))

datos_fig2 <- merge(datos_fig2, ranking_2021[, c("codigo", "rank")], by = "codigo")
datos_fig2 <- datos_fig2[!is.na(datos_fig2$fharcsin_est), ]
datos_fig2$anno <- factor(datos_fig2$anno)

fig2 <- ggplot2::ggplot(datos_fig2, ggplot2::aes(x = rank, y = fharcsin_est, color = anno, fill = anno)) +
  ggplot2::geom_smooth(method = "loess", se = TRUE, alpha = 0.15) +
  ggplot2::labs(
    x = "Ranking municipal (ordenado por informalidad 2021)",
    y = "Informalidad estimada (%)",
    color = "Ano", fill = "Ano",
    title = "Cambios en la informalidad laboral municipal"
  ) +
  ggplot2::theme_minimal()

ggplot2::ggsave(file.path(dir$figures, "figura2_cambio_temporal_ranking.jpg"),
                 fig2, width = 8, height = 5.5, dpi = 300)

message("Figura 2 guardada en output/figures/figura2_cambio_temporal_ranking.jpg")
