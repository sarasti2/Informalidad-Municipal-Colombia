# =====================================================================
# 00_packages.R
# Instala (si hace falta) y carga los paquetes usados en todo el pipeline.
# =====================================================================

required_packages <- c(
  "dplyr", "tidyr", "readr", "stringr", "forcats",   # manejo de datos
  "ggplot2", "scales",                                # graficas
  "randomForest",                                     # Tabla 2 (importancia de variables)
  "SAEforest",                                         # MERF (paso 6)
  "spdep", "sf",                                       # LISA y mapas (pasos 7 y 10, requieren shapefile)
  "broom",
  "BAMMtools",                                         # cortes tipo Jenks para la Figura 1 (igual que 9.all_maps.R)
  "ggpubr"                                             # ggarrange() para componer los mapas con leyenda comun
)

# SAEforest se instala desde GitHub (no siempre esta disponible en CRAN
# con la version/funcion MERFranger() que usa este pipeline).
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools", repos = "https://cloud.r-project.org")
}
if (!requireNamespace("SAEforest", quietly = TRUE)) {
  message("Instalando SAEforest desde GitHub (krennpa/SAEforest)...")
  devtools::install_github("krennpa/SAEforest")
}

# El resto de paquetes se instala normalmente desde CRAN (se excluye
# SAEforest de este paso porque ya se maneja arriba via GitHub).
installed <- rownames(installed.packages())
to_install <- setdiff(required_packages, c(installed, "SAEforest"))

if (length(to_install) > 0) {
  message("Instalando paquetes faltantes: ", paste(to_install, collapse = ", "))
  install.packages(to_install, repos = "https://cloud.r-project.org")
}

invisible(lapply(required_packages, function(p) {
  ok <- suppressWarnings(suppressMessages(require(p, character.only = TRUE)))
  if (!ok) warning("No se pudo cargar el paquete: ", p,
                    " (revisa la instalacion; los pasos que lo requieren se saltaran).")
}))
