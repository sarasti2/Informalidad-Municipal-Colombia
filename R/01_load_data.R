# =====================================================================
# 01_load_data.R
# Carga la base INICIAL (informalidad_municipal.csv) y define rutas.
#
# Supuesto de este ejercicio: la base ya esta completamente procesada
# en cuanto a variables geograficas, demograficas y economicas (ver
# seccion "Data" del paper), e incluye los estimadores DIRECTOS de
# informalidad (informalidad, informalidad_adj) que vienen de la GEIH.
# Lo que falta -y es justamente lo que este pipeline calcula- es:
#   (a) la estimacion SAE (Arc-FH en el paso 4, MERF en el paso 6),
#   (b) los clusters LISA (paso 7), y
#   (c) las figuras/tablas de resultados (pasos 8-11).
#
# IMPORTANTE: esta base YA NO trae precalculadas las columnas
# 'fharcsin_est', 'Low', 'Up', 'fh_benchmark', 'MERF_resultados',
# 'lisa_clusters' ni 'lisa_clusters_nombres' -- se removieron a
# proposito para que el pipeline las calcule de verdad, en vez de
# limitarse a copiar un resultado que ya venia en el archivo. Cada
# script (04, 05, 06, 07) las agrega de nuevo a 'base' a medida que las
# va calculando, para que los pasos siguientes (8-11) las puedan usar.
#
# Si quieres comparar tus resultados contra los del proyecto original,
# la base COMPLETA (con esas columnas ya calculadas) esta en
# referencia_original/informalidad_municipal_base_completa_con_resultados.csv
#
# IMPORTANTE: correr siempre con el working directory en la raiz del
# proyecto (Replicacion_SAE_Informalidad/), p. ej. abriendo un .Rproj
# ahi o con setwd() explicito antes de source(run_all.R).
# =====================================================================

dir <- list(
  root      = getwd(),
  data_raw  = file.path(getwd(), "data", "raw"),
  data_ext  = file.path(getwd(), "data", "external"),
  reference = file.path(getwd(), "referencia_original"),
  output    = file.path(getwd(), "output"),
  estimates = file.path(getwd(), "output", "estimates"),
  figures   = file.path(getwd(), "output", "figures"),
  tables    = file.path(getwd(), "output", "tables")
)

lapply(dir[c("estimates", "figures", "tables")], function(d) dir.create(d, showWarnings = FALSE, recursive = TRUE))

base <- readr::read_delim(
  file.path(dir$data_raw, "informalidad_municipal.csv"),
  delim = ";", locale = readr::locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

# Chequeo rapido de la estructura esperada (solo variables de insumo;
# fharcsin_est/MERF_resultados/lisa_clusters se calculan mas adelante)
stopifnot(all(c("codigo", "anno", "informalidad", "informalidad_adj",
                 "informalidad_adj_var", "num_obser_freq_adj") %in% names(base)))

message("Base inicial cargada: ", nrow(base), " filas (municipio-anno), ",
        length(unique(base$codigo)), " municipios, anos: ",
        paste(sort(unique(base$anno)), collapse = ", "))
