# =====================================================================
# 09_cluster_stability_table.R
#
# Tabla 1 del paper: caracteristicas generales de los municipios segun
# si mantienen el MISMO tipo de cluster LISA (HH/LL/HL/LH) en TODOS los
# anios disponibles (2011, 2016, 2021), comparado contra el grupo "NA"
# (sin significancia o que cambia de tipo de cluster en el periodo).
#
# Usa 'lisa_clusters_nombres' de la base (o el resultado de
# 07_lisa_clusters.R si ya se corrio con un shapefile).
#
# ACTUALIZACION: se encontro en Dropbox/SAE_informalidad/output/ el
# archivo de hectareas de cultivos de coca (UNODC/SIMCI), ya incluido
# en este paquete en data/external/coca/coca_hectareas.csv (columnas
# codigo, anno, coca_ha; municipios sin monitoreo SIMCI se tratan como
# coca_ha = 0). Se fusiona automaticamente abajo.
#
# LIMITACION QUE SIGUE PENDIENTE: el paper tambien usa variables de
# pobreza (NBI, IPM) y pobreza moderada/extrema, que NO se encontraron
# en ningun lugar del proyecto (ni en Dropbox/output ni en data/). Para
# completar la tabla, conseguir esas variables por municipio (fuente:
# DNP) y agregarlas a 'vars_tabla1' abajo.
# =====================================================================

vars_tabla1 <- c(
  "t_crea", "promleccri", "prommatema", "promglobal",
  "dismdo", "disbogota", "pdependiente", "coca_ha"
  # agregar aqui cuando esten disponibles: "ubn", "mpi", "pobreza_moderada", "pobreza_extrema"
)

coca_path <- file.path(dir$data_ext, "coca", "coca_hectareas.csv")
if (file.exists(coca_path)) {
  coca <- readr::read_csv(coca_path, show_col_types = FALSE)
  base <- dplyr::left_join(base, coca, by = c("codigo", "anno"))
  base$coca_ha[is.na(base$coca_ha) & base$anno %in% c(2011, 2016, 2021)] <- 0
  message("Hectareas de coca fusionadas desde ", coca_path)
} else {
  message("No se encontro '", coca_path, "': 'coca_ha' se omite de la Tabla 1.")
}

vars_tabla1 <- vars_tabla1[vars_tabla1 %in% names(base)]

cluster_col <- if ("lisa_clusters_nombres_repro" %in% names(base)) {
  "lisa_clusters_nombres_repro"
} else {
  "lisa_clusters_nombres"
}

wide_cluster <- base %>%
  dplyr::select(codigo, anno, dplyr::all_of(cluster_col)) %>%
  tidyr::pivot_wider(names_from = anno, values_from = dplyr::all_of(cluster_col),
                      names_prefix = "cl_")

wide_cluster <- wide_cluster %>%
  dplyr::mutate(
    n_tipos = apply(dplyr::across(dplyr::starts_with("cl_")), 1,
                     function(x) length(unique(stats::na.omit(x)))),
    tiene_na = apply(dplyr::across(dplyr::starts_with("cl_")), 1,
                      function(x) any(is.na(x)) || any(x %in% c("NS", NA))),
    clase_estable = dplyr::case_when(
      n_tipos == 1 & !tiene_na & cl_2011 == "HH" ~ "HH",
      n_tipos == 1 & !tiene_na & cl_2011 == "LL" ~ "LL",
      n_tipos == 1 & !tiene_na & cl_2011 == "HL" ~ "HL",
      n_tipos == 1 & !tiene_na & cl_2011 == "LH" ~ "LH",
      TRUE ~ "NA"
    )
  )

datos_estables <- base %>%
  dplyr::filter(anno == 2021) %>%
  dplyr::select(codigo, dplyr::all_of(vars_tabla1)) %>%
  dplyr::left_join(wide_cluster[, c("codigo", "clase_estable")], by = "codigo")

resumen <- datos_estables %>%
  dplyr::group_by(clase_estable) %>%
  dplyr::summarise(dplyr::across(dplyr::all_of(vars_tabla1), ~ mean(., na.rm = TRUE)),
                    n = dplyr::n(), .groups = "drop")

# t-test de cada grupo (HH/LL/HL/LH) contra el grupo NA para cada variable
t_test_vs_na <- function(var) {
  na_vals <- datos_estables[[var]][datos_estables$clase_estable == "NA"]
  sapply(c("HH", "LL", "HL", "LH"), function(cl) {
    grp_vals <- datos_estables[[var]][datos_estables$clase_estable == cl]
    if (length(grp_vals) < 2 || length(na_vals) < 2) return(NA_real_)
    tryCatch(stats::t.test(grp_vals, na_vals)$p.value, error = function(e) NA_real_)
  })
}
pvalues <- sapply(vars_tabla1, t_test_vs_na)

readr::write_csv(resumen, file.path(dir$tables, "tabla1_clusters_estables_medias.csv"))
saveRDS(pvalues, file.path(dir$tables, "tabla1_clusters_estables_pvalues.rds"))

message("Tabla 1 (medias por tipo de cluster estable) guardada en output/tables/.")
print(resumen)
