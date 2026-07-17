# =====================================================================
# 10_figures_maps.R
#
# Figura 1: mapas de informalidad municipal 2005/2011/2016/2021.
# Figura 3: mapas de clusters LISA 2005/2011/2016/2021.
#
# ESTILO: se replica el de los scripts originales 9.all_maps.R (Figura
# 1: paleta hcl.colors(5,"RdYlBu",rev=TRUE,alpha=0.7), cortes tipo
# Jenks por anio via BAMMtools::getJenksBreaks(), contorno de
# departamentos superpuesto, theme_void(), leyenda comun abajo via
# ggpubr::ggarrange) y 10.clusters_lisa.R bloque "(B) Kari" (Figura 3:
# colores HH=#FF0000/LL=#0000FF/LH=#a7adf9/HL=#f4ada8/NS=#eeeeee,
# incluye el anio 2005, tambien compuesto con ggarrange y leyenda
# comun). No se usan tmap/rgeoda (no disponibles) pero se buscan los
# mismos colores y la misma composicion final.
#
# NOTA sobre las etiquetas de la Figura 1 (fidelidad con una
# inconsistencia del original): 9.all_maps.R calcula los cortes de
# Jenks POR ANIO (cada panel usa sus propios cortes para colorear),
# pero la leyenda compartida de los 4 paneles se etiqueta con los
# cortes de UN SOLO anio (2005, o el primero disponible), forzando el
# primer corte a 0 y la primera etiqueta a "< 55%". Esto significa que
# las etiquetas de la leyenda no describen exactamente los cortes de
# cada panel individual -- es una inconsistencia menor que ya existia
# en el codigo original y aqui se reproduce tal cual.
#
# NOTA CRITICA -- PANEL BALANCEADO (municipios en blanco iguales en
# todos los anios, para que los mapas sean comparables): el codigo
# original (9.all_maps.R) fuerza a NA un municipio en TODOS los anios
# si le falta la estimacion en CUALQUIERA de ellos (comentario del
# autor: "Esto se hace para que todos los años tengan los mismos NA").
# Aqui se reproduce igual: se calcula que municipios tienen estimacion
# valida en TODOS los anios del mapa, y el resto queda en blanco (NA)
# en TODOS los paneles, no solo en el anio donde falta. La Figura 3
# hereda el mismo panel balanceado porque usa los resultados ya
# balanceados de 07_lisa_clusters.R.
#
# *** REQUIERE ***
#  (a) el shapefile de municipios usado en 07_lisa_clusters.R
#      (data/external/shapefiles/MGN_MPIO/),
#  (b) el shapefile de departamentos (data/external/shapefiles/MGN_DPTO/),
#      usado solo para dibujar el contorno departamental (opcional: si
#      no esta, los mapas se generan sin ese contorno), y
#  (c) para el panel 2005, el estimador directo de informalidad del
#      Censo (data/external/census2005/informalidad_2005.csv).
#
# Sin (a), este script no genera nada. Sin (b) o (c) genera lo que SI
# se puede con los datos disponibles y avisa de lo que falta.
# =====================================================================

shp_path <- file.path(dir$data_ext, "shapefiles", "MGN_MPIO")
dpto_path <- file.path(dir$data_ext, "shapefiles", "MGN_DPTO")
census2005_path <- file.path(dir$data_ext, "census2005", "informalidad_2005.csv")

if (!dir.exists(shp_path) || length(list.files(shp_path, pattern = "\\.shp$")) == 0) {

  warning("No hay shapefile en '", shp_path, "': se omiten los mapas (Figuras 1 y 3). ",
          "Ver instrucciones en 07_lisa_clusters.R.")

} else if (!requireNamespace("BAMMtools", quietly = TRUE) || !requireNamespace("ggpubr", quietly = TRUE)) {

  warning("Se requieren los paquetes 'BAMMtools' y 'ggpubr' (ver 00_packages.R) para reproducir ",
          "el estilo original de las Figuras 1 y 3; se omiten ambas.")

} else {

  mpios <- sf::st_read(shp_path, quiet = TRUE)
  codigo_col <- intersect(c("MPIO_CDPMP", "DIVIPOLA", "codigo", "COD_MPIO"), names(mpios))[1]
  mpios$codigo <- as.character(mpios[[codigo_col]])

  # Contorno departamental (solo para dibujar por encima; opcional)
  if (dir.exists(dpto_path) && length(list.files(dpto_path, pattern = "\\.shp$")) > 0) {
    shape_dpto <- sf::st_read(dpto_path, quiet = TRUE)
    dpto_col <- intersect(c("DPTO_CCDGO"), names(shape_dpto))[1]
    if (!is.na(dpto_col)) {
      # excluir San Andres y Providencia del contorno, igual que el original
      shape_dpto <- shape_dpto[shape_dpto[[dpto_col]] != "88", ]
    }
  } else {
    warning("No se encontro el shapefile de departamentos en '", dpto_path, "': ",
            "los mapas se generan sin el contorno departamental.")
    shape_dpto <- NULL
  }

  agregar_contorno_dpto <- function(g) {
    if (!is.null(shape_dpto)) g <- g + ggplot2::geom_sf(data = shape_dpto, fill = NA, color = "black", linewidth = 0.15, alpha = 0)
    g
  }

  # =====================================================================
  # Figura 1: mapa de informalidad por anio
  # =====================================================================

  datos_mapa <- base[, c("codigo", "anno", "fharcsin_est")]
  datos_mapa$codigo <- sprintf("%05d", as.numeric(datos_mapa$codigo))

  tiene_2005 <- file.exists(census2005_path)
  if (tiene_2005) {
    censo05 <- readr::read_csv(census2005_path, show_col_types = FALSE)
    censo05 <- data.frame(codigo = sprintf("%05d", as.numeric(censo05$codigo)), anno = 2005,
                           fharcsin_est = censo05$informalidad_2005)
    datos_mapa <- rbind(datos_mapa, censo05)
  } else {
    warning("No se encontro '", census2005_path, "': la Figura 1 se genera SOLO para ",
            "2011/2016/2021 (sin el panel de 2005).")
  }

  anios_mapa <- if (tiene_2005) c(2005, 2011, 2016, 2021) else c(2011, 2016, 2021)

  # --- panel balanceado: un municipio sin estimacion valida en CUALQUIER
  # anio queda en blanco (NA) en TODOS los anios, para que los mapas sean
  # comparables entre si -- igual que 9.all_maps.R. Ver nota critica arriba.
  ancho_mapa <- tidyr::pivot_wider(datos_mapa, id_cols = "codigo", names_from = "anno",
                                    values_from = "fharcsin_est", names_prefix = "anio_")
  cols_anio_mapa <- paste0("anio_", anios_mapa)
  cols_anio_mapa <- cols_anio_mapa[cols_anio_mapa %in% names(ancho_mapa)]
  codigos_balanceados_mapa <- ancho_mapa$codigo[stats::complete.cases(ancho_mapa[, cols_anio_mapa])]
  datos_mapa$fharcsin_est[!(datos_mapa$codigo %in% codigos_balanceados_mapa)] <- NA
  message("Panel balanceado Figura 1: ", length(codigos_balanceados_mapa),
          " municipios con estimacion valida en los ", length(cols_anio_mapa), " anios del mapa.")

  geo_mapa <- merge(mpios, datos_mapa, by = "codigo")

  # Paleta identica a 9.all_maps.R
  paleta_informalidad <- grDevices::hcl.colors(5, "RdYlBu", rev = TRUE, alpha = 0.7)

  # Cortes tipo Jenks por anio (5 clases via 6 cortes), igual que el original
  cortes_por_anio <- lapply(anios_mapa, function(yr) {
    vals <- geo_mapa$fharcsin_est[geo_mapa$anno == yr]
    BAMMtools::getJenksBreaks(vals, 6)
  })
  names(cortes_por_anio) <- as.character(anios_mapa)

  # Etiquetas de la leyenda comun: derivadas de los cortes del primer
  # anio disponible (2005 si existe), con la primera etiqueta forzada a
  # "< 55%", igual que 9.all_maps.R (breaks_time2 / labs_time_plot[1]).
  cortes_leyenda <- round(cortes_por_anio[[as.character(anios_mapa[1])]], 2)
  etiquetas_leyenda <- paste0("(", cortes_leyenda[1:5], "%-", cortes_leyenda[2:6], "%]")
  etiquetas_leyenda[1] <- "< 55%"

  hacer_mapa_informalidad <- function(anno_yr) {
    cortes_yr <- cortes_por_anio[[as.character(anno_yr)]]
    cortes_yr[1] <- 0  # igual que 9.all_maps.R (breaks_time2005[1] <- 0, etc.)
    d <- geo_mapa[geo_mapa$anno == anno_yr, ]
    d$clase <- cut(d$fharcsin_est, breaks = cortes_yr, dig.lab = 5, include.lowest = TRUE)
    g <- ggplot2::ggplot() +
      ggplot2::geom_sf(data = d, ggplot2::aes(fill = clase), color = NA) +
      ggplot2::scale_fill_manual(values = paleta_informalidad, drop = FALSE,
                                  na.value = "darkgray", labels = etiquetas_leyenda, name = "") +
      ggplot2::labs(title = as.character(anno_yr)) +
      ggplot2::theme_void() +
      ggplot2::theme(legend.position = "bottom",
                      legend.text = ggplot2::element_text(size = 10),
                      plot.title = ggplot2::element_text(size = 16, hjust = 0.5))
    agregar_contorno_dpto(g)
  }

  mapas_informalidad <- lapply(anios_mapa, hacer_mapa_informalidad)

  fig1 <- ggpubr::ggarrange(
    plotlist = mapas_informalidad, common.legend = TRUE, legend = "bottom",
    nrow = if (length(anios_mapa) <= 2) 1 else 2,
    ncol = if (length(anios_mapa) <= 2) length(anios_mapa) else 2
  )

  ggplot2::ggsave(file.path(dir$figures, "figura1_mapa_informalidad.jpg"),
                   fig1, width = 9, height = if (length(anios_mapa) > 2) 8 else 5, dpi = 300, bg = "white")

  message("Figura 1 guardada en output/figures/ (paleta y cortes Jenks igual al codigo original, panel balanceado).")

  # =====================================================================
  # Figura 3: mapas de clusters LISA (incluye 2005, panel balanceado)
  # =====================================================================

  lisa_csv <- file.path(dir$estimates, "lisa_resultados.csv")
  resultados_lisa <- if (exists("lisa_resultados") && is.data.frame(lisa_resultados)) {
    lisa_resultados
  } else if (file.exists(lisa_csv)) {
    readr::read_csv(lisa_csv, show_col_types = FALSE)
  } else {
    NULL
  }

  if (is.null(resultados_lisa)) {
    warning("No hay resultados LISA disponibles (correr primero 07_lisa_clusters.R); se omite la Figura 3.")
  } else {

    datos_lisa <- resultados_lisa[, c("codigo", "anno", "lisa_clusters_nombres_repro")]
    names(datos_lisa)[3] <- "cluster"
    datos_lisa$codigo <- sprintf("%05d", as.numeric(datos_lisa$codigo))
    datos_lisa$cluster[is.na(datos_lisa$cluster)] <- "NS"

    geo_lisa <- merge(mpios, datos_lisa, by = "codigo")
    anios_lisa <- sort(unique(datos_lisa$anno))

    # Colores exactos del codigo original (ver 'grafica_dif' /
    # scale_fill_manual en 10.clusters_lisa.R bloque "(B) Kari").
    colores_lisa <- c(HH = "#FF0000", LL = "#0000FF", LH = "#a7adf9", HL = "#f4ada8", NS = "#eeeeee")

    hacer_mapa_lisa <- function(anno_yr) {
      d <- geo_lisa[geo_lisa$anno == anno_yr, ]
      g <- ggplot2::ggplot() +
        ggplot2::geom_sf(data = d, ggplot2::aes(fill = cluster), color = NA) +
        ggplot2::scale_fill_manual(values = colores_lisa, na.value = "#D3D3D3",
                                    limits = names(colores_lisa), name = "",
                                    labels = c("Alto-Alto", "Bajo-Bajo", "Bajo-Alto", "Alto-Bajo", "No significativo")) +
        ggplot2::labs(title = as.character(anno_yr)) +
        ggplot2::theme_void() +
        ggplot2::theme(legend.position = "bottom", plot.title = ggplot2::element_text(size = 16, hjust = 0.5))
      agregar_contorno_dpto(g)
    }

    mapas_lisa <- lapply(anios_lisa, hacer_mapa_lisa)

    fig3 <- ggpubr::ggarrange(
      plotlist = mapas_lisa, common.legend = TRUE, legend = "bottom",
      nrow = if (length(anios_lisa) <= 2) 1 else 2,
      ncol = if (length(anios_lisa) <= 2) length(anios_lisa) else 2
    )

    ggplot2::ggsave(file.path(dir$figures, "figura3_mapa_clusters_lisa.jpg"),
                     fig3, width = 9, height = if (length(anios_lisa) > 2) 8 else 5, dpi = 300, bg = "white")

    message("Figura 3 guardada en output/figures/ (colores LISA originales, panel balanceado, ",
            length(anios_lisa), " anios incluyendo 2005 si estaba disponible).")
  }
}
