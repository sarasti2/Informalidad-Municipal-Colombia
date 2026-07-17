# =====================================================================
# run_all.R  -- script maestro
#
# Ejecuta todo el pipeline de replicacion en el orden correcto. Correr
# SIEMPRE con el working directory en la raiz de este proyecto
# (Replicacion_SAE_Informalidad/), por ejemplo:
#
#   setwd("ruta/a/Replicacion_SAE_Informalidad")
#   source("run_all.R")
# =====================================================================

paso <- function(msg) message("\n===== ", msg, " =====")

paso("0. Paquetes")
source("R/00_packages.R")

paso("1. Cargar datos")
source("R/01_load_data.R")

paso("2. Funcion Arc-FH")
source("R/02_fh_arcsin_function.R")

paso("3. Seleccion de variables (BIC)")
source("R/03_variable_selection_bic.R")

paso("4. Estimacion Arc-FH (2011, 2016, 2021)")
source("R/04_estimation_fh_arcsin.R")

paso("5. Benchmarking departamental")
tryCatch(source("R/05_benchmarking.R"), error = function(e) warning(e))

paso("6. Estimacion MERF")
tryCatch(source("R/06_estimation_merf.R"), error = function(e) warning(e))

paso("7. Clusters LISA (requiere shapefile)")
tryCatch(source("R/07_lisa_clusters.R"), error = function(e) warning(e))

paso("8. Importancia de variables -- Tabla 2")
source("R/08_variable_importance_rf.R")

paso("9. Tabla de estabilidad de clusters -- Tabla 1")
tryCatch(source("R/09_cluster_stability_table.R"), error = function(e) warning(e))

paso("10. Mapas -- Figuras 1 y 3 (requieren shapefile)")
tryCatch(source("R/10_figures_maps.R"), error = function(e) warning(e))

paso("11. Figura 2 (ranking temporal)")
source("R/11_figure_temporal_ranking.R")

paso("12. MERF vs. directo por departamento -- Figura A2 (apendice)")
tryCatch(source("R/12_graph_difference_sae_dir.R"), error = function(e) warning(e))

message("\nListo. Revisar output/estimates, output/tables y output/figures.")
