# Replicación — "The Geography of Informality: the Case of Colombia"

Paquete de reproducibilidad del artículo **"The Geography of Informality:
the Case of Colombia"**, de Karina Acosta, Juliana Jaramillo-Echeverri,
Daniel Lasso-Jaramillo y Alejandro Sarasti-Sierra, publicado en
*Spatial Economic Analysis* (Vol. 20, No. 4, pp. 664-682). Recibido el
2 de julio de 2024, publicado en línea el 23 de julio de 2025. DOI:
[10.1080/17421772.2025.2522807](https://doi.org/10.1080/17421772.2025.2522807).

Esta carpeta es el paquete de reproducibilidad, contiene la estimacion de Small Area Estimation (SAE) y las
figuras/tablas de resultados. Se asume que
`data/raw/informalidad_municipal.csv` ya es la base completamente
procesada (variables geograficas, demograficas y economicas, ver
Seccion "Data" del paper), tal como la entrego el usuario.



## Orden de ejecucion (R/)

| # | Script | Que produce |
|---|--------|--------------|
| 0 | `00_packages.R` | instala/carga los paquetes necesarios |
| 1 | `01_load_data.R` | carga `data/raw/informalidad_municipal.csv` |
| 2 | `02_fh_arcsin_function.R` | define `FH_arcsin()` (Schmid et al. 2017) |
| 3 | `03_variable_selection_bic.R` | seleccion de covariables por BIC (Seccion 5.6) |
| 4 | `04_estimation_fh_arcsin.R` | corre Arc-FH 2011/2016/2021 → `fharcsin_est`, `Low`, `Up` |
| 5 | `05_benchmarking.R` | ajuste (benchmarking) a nivel departamental → `fh_benchmark` |
| 6 | `06_estimation_merf.R` | estimacion MERF (SAEforest) → `MERF_resultados` |
| 7 | `07_lisa_clusters.R` | clusters LISA 2005/2011/2016/2021 → `lisa_clusters_nombres` (usa el shapefile, ya incluido) |
| 8 | `08_variable_importance_rf.R` | **Tabla 2** — importancia de variables (desde los modelos MERF del paso 6) |
| 9 | `09_cluster_stability_table.R` | **Tabla 1** — caracteristicas de clusters estables (incluye `coca_ha`) |
| 10 | `10_figures_maps.R` | **Figuras 1 y 3** — mapas (usa los shapefiles de municipios/departamentos y el panel 2005, ya incluidos) |
| 11 | `11_figure_temporal_ranking.R` | **Figura 2** — cambio temporal por ranking |
| 12 | `12_graph_difference_sae_dir.R` | **Figura A2 (apendice)** — MERF vs. directo por departamento; es el resultado del paper donde el MERF se usa explicitamente |

Cada script (04, 06 y 07) agrega su resultado de vuelta a `base` para
que los pasos siguientes lo puedan usar (por ejemplo, `MERF_resultados`
calculado en el paso 6 alimenta directamente el paso 12, y los modelos
MERF ajustados en el paso 6 alimentan directamente la Tabla 2 del paso
8). El paso 7 tambien calcula LISA para 2005 (a partir del panel
censal externo, que no esta en `base`) y lo deja disponible para el
paso 10, aunque no se fusiona de vuelta en `base`.

Ejecutar todo con `run_all.R` desde la raiz de esta carpeta:

```r
setwd("ruta/a/Replicacion_SAE_Informalidad")
source("run_all.R")
```

## Insumos externos 

1. **Shapefile de municipios de Colombia** (Marco Geoestadistico
   Nacional, DANE) 
2. **Estimacion de informalidad 2005** (Censo 2005) 
3. **Hectareas de cultivos de coca** (UNODC/SIMCI) 
4. **Shapefile de departamentos** 

## Estructura de carpetas

```
Replicacion_SAE_Informalidad/
├── README.md
├── run_all.R
├── data/
│   ├── raw/informalidad_municipal.csv        (base INICIAL, sin fharcsin_est/MERF/lisa)
│   └── external/
│       ├── shapefiles/MGN_MPIO/          (shapefile municipios DANE, YA incluido)
│       ├── shapefiles/MGN_DPTO/          (shapefile departamentos DANE, YA incluido)
│       ├── census2005/informalidad_2005.csv   (YA incluido)
│       └── coca/coca_hectareas.csv            (YA incluido)
├── R/                                       (pipeline oficial, no ejecutado aqui)
├── output/{estimates,tables,figures}/       (donde el pipeline en R guarda resultados)
├── referencia_original/                     (outputs REALES del proyecto original)
   ├── informalidad_municipal_base_completa_con_resultados.csv
   ├── tabla1/clusters_stable.xlsx
   ├── tabla2/importance_{2011,2016,2021}.csv
   ├── clusters/resultados_cluster.dta
   └── figuras/{figura1,figura2,figura3}_original.*




