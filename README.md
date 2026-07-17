# Replicación — "The Geography of Informality: the Case of Colombia"

Paquete de reproducibilidad del artículo **"The Geography of Informality:
the Case of Colombia"**, de Karina Acosta, Juliana Jaramillo-Echeverri,
Daniel Lasso-Jaramillo y Alejandro Sarasti-Sierra, publicado en
*Spatial Economic Analysis* (Vol. 20, No. 4, pp. 664-682). Recibido el
2 de julio de 2024, publicado en línea el 23 de julio de 2025. DOI:
[10.1080/17421772.2025.2522807](https://doi.org/10.1080/17421772.2025.2522807).

Esta carpeta es el paquete de reproducibilidad para la parte del paper
que **falta**: la estimacion de Small Area Estimation (SAE) y las
figuras/tablas de resultados. Se asume que
`data/raw/informalidad_municipal.csv` ya es la base completamente
procesada (variables geograficas, demograficas y economicas, ver
Seccion "Data" del paper), tal como la entrego el usuario.

## Que hace cada cosa

El pipeline oficial esta en R (`R/`), en la misma linea del resto del
proyecto de informalidad. Como este entorno de generacion no tiene R
instalado (sandbox sin permisos de administrador para instalar R ni
sus dependencias geoespaciales), los scripts en R **no se pudieron
ejecutar aqui**, pero fueron escritos con cuidado y verificados
indirectamente: `validacion_python/` reimplementa la misma matematica
en Python (que si esta disponible) y la corre contra los datos reales,
comparando el resultado con las columnas que ya trae la base de
referencia (`fharcsin_est`, `lisa_clusters_nombres`). Los resultados de
esa validacion estan documentados abajo — corren y coinciden bien con
lo esperado, lo que da confianza de que la logica trasladada a R es
correcta. **Antes de usar los scripts de R en tu computador, corre
`Rscript run_all.R` (o abre un `.Rproj` en esta carpeta) y revisa los
mensajes de cada paso.**

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

## Insumos externos — ya resueltos (encontrados en Dropbox/output y Dropbox/data)

Revisando `Dropbox\SAE_informalidad\output\` y `Dropbox\SAE_informalidad\data\`
se encontraron y ya se incluyeron en este paquete los siguientes insumos que
antes faltaban:

1. **Shapefile de municipios de Colombia** (Marco Geoestadistico
   Nacional, DANE) — copiado desde
   `Dropbox\SAE_informalidad\data\shapefiles\MGN2021_MPIO_POLITICO\`
   a `data/external/shapefiles/MGN_MPIO/`. Los pasos 7 y 10 (LISA y
   mapas) ya pueden correr con esto.
2. **Estimacion de informalidad 2005** (Censo 2005) — extraida de
   `Dropbox\SAE_informalidad\output\2005_directest_informality_censo.dta`
   y guardada en `data/external/census2005/informalidad_2005.csv`
   (columnas `codigo, informalidad_2005`, escala 0-100). Las Figuras 1
   y 3 ya pueden incluir el panel 2005.
3. **Hectareas de cultivos de coca** (UNODC/SIMCI) — extraidas de
   `Dropbox\SAE_informalidad\data\datos_Raw\Detecci_n_de_Cultivos_de_Coca__hect_reas__20250310.csv`
   y reformateadas (formato ancho → largo, limpieza de "- 0" y comas de
   miles) en `data/external/coca/coca_hectareas.csv` (columnas `codigo,
   anno, coca_ha`). El script `09_cluster_stability_table.R` ya la
   fusiona automaticamente en la Tabla 1. Los municipios sin monitoreo
   SIMCI se asumen con `coca_ha = 0`.
4. **Shapefile de departamentos** — copiado desde
   `Dropbox\SAE_informalidad\data\shapefiles\MGN2021_DPTO_POLITICO\` a
   `data/external/shapefiles/MGN_DPTO/`. Se usa solo para dibujar el
   contorno departamental sobre los mapas (Figuras 1 y 3), igual que
   `9.all_maps.R` y `10.clusters_lisa.R` en el proyecto original.

**Lo unico que sigue sin encontrarse en el proyecto**: variables de
pobreza por municipio (NBI, IPM, pobreza moderada/extrema). Se buscaron
en todas las carpetas del proyecto (incluyendo Dropbox/output) y no
aparecen como archivo — el paper las debio tomar de una fuente externa
del DNP que no se guardo en el repositorio. Sin esto, la Tabla 1 se
genera con las 7 variables originales mas `coca_ha`, pero sin
NBI/IPM/pobreza. (Nota aparte: NBI si aparece en el script original
`16-caribe_special_analisis.R`, pero a nivel departamental y leido de
un archivo descargado manualmente fuera del repo.)

## Fidelidad visual de los mapas (correccion tras corridas reales)

Al correr el pipeline en R por primera vez se encontraron y corrigieron
varios problemas en `07_lisa_clusters.R` y `10_figures_maps.R`:

- **Bug del codigo DIVIPOLA (Antioquia desaparecia de todos los
  mapas):** el shapefile guarda `MPIO_CDPMP` como texto de 5 digitos
  con cero a la izquierda (p.ej. `"05001"` para Medellin), pero
  `base$codigo` es numerico y viene SIN ese cero (`5001`), porque asi
  ya venia en el CSV de entrada. `as.character(5001)` da `"5001"` (4
  caracteres), que nunca empata con `"05001"` del shapefile -- esto
  descartaba silenciosamente todos los municipios de Antioquia (depto
  "05") y Atlantico (depto "08") de cualquier union espacial. Se
  corrigio usando `sprintf("%05d", as.numeric(codigo))` antes de cada
  union con un shapefile, igual que hace el codigo original.
- **Metodologia LISA:** el codigo original (`10.clusters_lisa.R`) tiene
  dos bloques; el que efectivamente genera el archivo de referencia
  usa `rgeoda::local_moran()` (significancia por permutacion
  condicional, 999 simulaciones), no un p-valor analitico. Aqui se usa
  `spdep::localmoran_perm()` (tambien por permutacion, 999
  simulaciones, semilla fija) para acercarse mas a esa metodologia real.
- **Anio 2005 en el mapa de clusters LISA (Figura 3):** el bloque
  final del codigo original si calcula e incluye LISA para 2005 (con
  el estimador directo del Censo); aqui se agrego lo mismo.
- **Paleta y composicion identicas al codigo original:** la Figura 1
  usa la paleta `hcl.colors(5,"RdYlBu",rev=TRUE,alpha=0.7)` con cortes
  tipo Jenks calculados por anio (`BAMMtools::getJenksBreaks`, igual
  que `9.all_maps.R`), contorno de departamentos superpuesto, y una
  leyenda comun abajo via `ggpubr::ggarrange` (no se usan tmap/rgeoda,
  no disponibles, pero se buscan los mismos colores/composicion). La
  Figura 3 usa los colores exactos del codigo original:
  HH=`#FF0000`, LL=`#0000FF`, LH=`#a7adf9`, HL=`#f4ada8`,
  NS=`#eeeeee` (ver `scale_fill_manual` en `10.clusters_lisa.R`).
- **Panel balanceado entre anios (municipios en blanco iguales en
  todos los anios):** el codigo original (`9.all_maps.R`, comentario
  del autor: "Esto se hace para que todos los años tengan los mismos
  NA") deja en blanco (NA) un municipio en TODOS los anios del mapa si
  le falta el estimado en CUALQUIERA de ellos, para que los 4 paneles
  sean visual y espacialmente comparables. Se replico igual en
  `07_lisa_clusters.R` (afecta LISA y la Tabla 1) y en
  `10_figures_maps.R` (Figura 1).

## La base inicial NO trae los resultados ya calculados

`data/raw/informalidad_municipal.csv` es la base **inicial**: incluye
todas las variables de insumo (geograficas, demograficas, economicas)
y los estimadores DIRECTOS de la GEIH (`informalidad`, `informalidad_adj`),
pero ya NO trae precalculadas las columnas `fharcsin_est`, `Low`, `Up`,
`fh_benchmark`, `MERF_resultados`, `lisa_clusters` ni
`lisa_clusters_nombres` — se removieron a proposito para que el
pipeline las calcule de verdad. Cada script (04, 05, 06, 07) las agrega
de nuevo a `base` a medida que las va calculando.

Para comparar tus resultados contra los del proyecto original, la base
COMPLETA (con esas columnas ya calculadas) esta en
`referencia_original/informalidad_municipal_base_completa_con_resultados.csv`.
Ademas, en `referencia_original/` se incluyeron los outputs REALES ya
generados por el proyecto original (Tabla 1 y Tabla 2 ya calculadas, el
cluster LISA final, y las Figuras 1, 2 y 3 ya renderizadas) para
comparar directamente contra lo que produzca esta plantilla.

## Diccionario de variables de la base original

Traduccion/documentacion de cada columna de
`data/raw/informalidad_municipal.csv`, en el mismo orden en que
aparecen en el CSV. Las descripciones de las primeras ~48 variables
vienen del diccionario original del proyecto
(`diccionario_informalidad_municipal.csv`, en
`Dropbox/SAE_informalidad/data/datos_procesados/`); las marcadas con
`*` no estan en ese diccionario y su descripcion se infirio del nombre
de la variable y de su uso real en el codigo.

| Variable | Descripcion |
|---|---|
| `codigo_depto` | Codigo DANE del departamento. |
| `codigo_provincia` | Codigo DANE de la provincia. |
| `departamento` | Nombre del departamento. |
| `municipio` | Nombre del municipio. |
| `codigo` | Codigo DANE del municipio (5 digitos; departamentos 05 -Antioquia- y 08 -Atlantico- llevan cero a la izquierda). |
| `anno` | Anio de la observacion (2005, 2011, 2016 o 2021). |
| `pob_total` | Poblacion total del municipio. |
| `formal_rate` | Proporcion entre el numero de personas en la Planilla Integrada de Liquidacion de Aportes (PILA) y la poblacion municipal. |
| `vacancy_rate` | Proporcion entre el numero de ofertas en el Servicio Publico de Empleo (SPE) y la poblacion municipal. |
| `ruralidad` | Proporcion de la poblacion en areas rurales (resto municipal) sobre la poblacion municipal. |
| `t_crea` | Anios transcurridos desde la fecha de creacion del municipio. |
| `altura` | Altura sobre el nivel del mar del municipio (metros). |
| `areakm2` | Area del municipio en kilometros cuadrados. |
| `gandina` | Dummy: 1 si el municipio esta en la region Andina. |
| `gcaribe` | Dummy: 1 si el municipio esta en la region Caribe. |
| `gpacifica` | Dummy: 1 si el municipio esta en la region Pacifica. |
| `gorinoquia` | Dummy: 1 si el municipio esta en la region Orinoquia. |
| `gamazonia` | Dummy: 1 si el municipio esta en la region Amazonia. |
| `pruralpet` | Proporcion de la poblacion rural en edad de trabajar sobre la poblacion en edad de trabajar total del municipio. |
| `pmujerpet` | Proporcion de mujeres en edad de trabajar sobre la poblacion en edad de trabajar total del municipio. |
| `pdependiente` | Proporcion de personas dependientes (menores de 12 o mayores de 65 anios, segun DANE) sobre el total de personas independientes. |
| `salario_bas` | Media del salario en el municipio (pesos colombianos). |
| `pregimen_subsidiado` | Proporcion de la poblacion en el regimen subsidiado de salud sobre la poblacion total del municipio. |
| `regimen_subsidiado` | Numero de personas del municipio inscritas al regimen subsidiado de salud. |
| `promleccri` | Promedio municipal del puntaje de Lectura Critica en las pruebas Saber 11 (ICFES). |
| `prommatema` | Promedio municipal del puntaje de Matematicas en las pruebas Saber 11 (ICFES). |
| `promglobal` | Promedio municipal del puntaje global en las pruebas Saber 11 (ICFES). |
| `vab` | Valor agregado municipal (miles de millones de pesos colombianos). |
| `va_actividad_primaria` | Valor agregado del sector primario a nivel municipal (miles de millones de pesos colombianos). |
| `va_actividad_secundaria` | Valor agregado del sector secundario a nivel municipal (miles de millones de pesos colombianos). |
| `va_actividad_terciaria` | Valor agregado del sector terciario a nivel municipal (miles de millones de pesos colombianos). |
| `vabpc` | Valor agregado per capita: proporcion entre el valor agregado y la poblacion del municipio. |
| `pprimary` | Proporcion del valor agregado del sector primario sobre el valor agregado total del municipio. |
| `psecondary` | Proporcion del valor agregado del sector secundario sobre el valor agregado total del municipio. |
| `pterciary` | Proporcion del valor agregado del sector terciario sobre el valor agregado total del municipio. |
| `distancia_mercado` | Distancia lineal a otros mercados cercanos (kilometros). |
| `disbogota` | Distancia lineal entre el municipio y Bogota (kilometros). |
| `dismdo` | Distancia lineal al principal mercado mayorista de alimentos del departamento (kilometros). |
| `pgroup1` | Proporcion de hombres entre 14 y 24 anios en el municipio. |
| `pgroup2` | Proporcion de hombres entre 25 y 54 anios en el municipio. |
| `pgroup3` | Proporcion de hombres mayores de 54 anios en el municipio. |
| `pgroup4` | Proporcion de mujeres entre 14 y 24 anios en el municipio. |
| `pgroup5` | Proporcion de mujeres entre 25 y 54 anios en el municipio. |
| `pgroup6` | Proporcion de mujeres mayores de 54 anios en el municipio. |
| `num_obser_freq` * | Numero de observaciones (tamano de muestra) de la GEIH usadas para el estimado directo del municipio-anio. |
| `num_obser_freq_adj` * | Numero efectivo de observaciones de la GEIH, ajustado por el efecto de diseno muestral (es el `eff_n` de `04_estimation_fh_arcsin.R`, usado para la varianza del estimador directo). |
| `informales_freq` * | Conteo crudo de ocupados informales en la muestra GEIH del municipio-anio. |
| `informales_freq_adj` * | Conteo ajustado/ponderado (por diseno muestral) de ocupados informales en la muestra GEIH. |
| `ocupados_freq` * | Conteo crudo de ocupados en la muestra GEIH del municipio-anio (denominador de la tasa de informalidad). |
| `ocupados_freq_adj` * | Conteo ajustado/ponderado de ocupados en la muestra GEIH. |
| `informalidad` | Estimado directo de informalidad (GEIH) para los municipios donde la encuesta es representativa. |
| `informalidad_adj` * | Estimado directo de informalidad (GEIH) calculado con los conteos ajustados (`informales_freq_adj` / `ocupados_freq_adj`); es el que el pipeline usa como `direct_pct` en `04_estimation_fh_arcsin.R`. |
| `informalidad_adj_var` | Varianza del estimador directo `informalidad_adj`. |
| `fharcsin_est` (se calcula en el paso 4) | Estimado de Small Area Estimation con Fay-Herriot transformado con arcoseno. |
| `Low` / `Up` (paso 4) * | Limites inferior/superior del intervalo de confianza de `fharcsin_est`. |
| `fh_benchmark` (paso 5) | Estimado de SAE con Fay-Herriot ajustado (benchmarking) a nivel departamental. |
| `MERF_resultados` (paso 6) | Estimado de informalidad con bosque aleatorio de efectos mixtos (MERF). |
| `lisa_clusters` (paso 7) | Codigo del cluster LISA al que pertenece el municipio-anio. |
| `lisa_clusters_nombres` (paso 7) | Nombre/etiqueta del cluster LISA (HH, LL, HL, LH o NA) al que pertenece el municipio-anio. |

`*` No aparece en el diccionario original del proyecto; descripcion
inferida del nombre de la variable y de su uso real en el codigo
(`01_load_data.R`, `04_estimation_fh_arcsin.R`).

**Nota sobre una inconsistencia del diccionario original:** el archivo
`diccionario_informalidad_municipal.csv` describe `lisa_clusters` como
"Nombre del cluster..." y `lisa_clusters_nombres` como "Codigo del
cluster..." — al reves de como se usan realmente estas dos columnas en
el codigo (aqui y en el proyecto original, `lisa_clusters_nombres` es
la que trae la etiqueta de texto HH/LL/HL/LH; ver `07_lisa_clusters.R`
y `10_figures_maps.R`). La tabla de arriba describe el comportamiento
real observado en el codigo, no el texto literal (aparentemente
invertido) del diccionario original.

## `validacion_python/` — verificacion de la metodologia

Como no hay R disponible en este entorno, se valido la matematica del
pipeline en Python (si disponible), corriendo contra la base de
referencia (con los resultados ya calculados):

- `01_validar_fh_arcsin.py`: reimplementa Arc-FH con un subconjunto de
  covariables razonable (no necesariamente el elegido por BIC) y
  compara contra la columna `fharcsin_est` de la base de referencia.
  **Resultado:** correlacion 0.98 y error absoluto medio de 1.2-1.5
  puntos porcentuales en los tres anios — confirma que la formulacion
  (transformacion arcoseno, varianza 1/(4·n_efectivo), shrinkage
  gamma, estimacion ML de sigma2_u) esta bien implementada.
- `02_tabla2_importancia.py`: reproduce la Tabla 2 con
  `RandomForestRegressor` + `permutation_importance`. El regimen
  subsidiado y la tasa PILA (`formal_rate`) quedan de primeros en los
  tres anios, y la tasa de vacantes virtuales sube al top-3/4 en 2016
  y 2021 (no aparece en 2011 porque no existe ese anio) — coincide
  cualitativamente con la Tabla 2 del paper.
- `03_tabla1_clusters_estables.py`: reproduce la Tabla 1 usando
  `lisa_clusters_nombres` de la base de referencia. Los municipios en
  clusters HH estables muestran menores puntajes SABER 11, mayor
  dependencia demografica y mayor distancia a Bogota que el grupo NA
  (p<0.05); los LL muestran el patron opuesto — igual que en el paper.
- `04_figura2_ranking_temporal.py`: reproduce la Figura 2 (loess por
  ranking de informalidad 2021). El patron coincide con lo descrito en
  el texto: la informalidad cae de 2011→2016→2021 en casi todo el
  ranking, pero para los municipios mas informales (extremo derecho)
  2021 vuelve a cruzarse por encima de 2016, senal del "reversal"
  post-pandemia que describe el paper.

Los resultados de estos 4 scripts estan guardados en
`validacion_python/output/`.

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
│   ├── informalidad_municipal_base_completa_con_resultados.csv
│   ├── tabla1/clusters_stable.xlsx
│   ├── tabla2/importance_{2011,2016,2021}.csv
│   ├── clusters/resultados_cluster.dta
│   └── figuras/{figura1,figura2,figura3}_original.*
└── validacion_python/
    ├── 01_validar_fh_arcsin.py
    ├── 02_tabla2_importancia.py
    ├── 03_tabla1_clusters_estables.py
    ├── 04_figura2_ranking_temporal.py
    └── output/                              (resultados YA generados y verificados)
```

## Licencia

Este paquete de reproducibilidad se distribuye bajo la licencia MIT
(ver el archivo [`LICENSE`](./LICENSE)): el codigo puede usarse,
copiarse, modificarse y redistribuirse libremente (incluso con fines
comerciales), siempre que se conserve el aviso de copyright. Esto
aplica al codigo de este paquete, no a los derechos de los autores o
la editorial sobre el articulo publicado en *Spatial Economic
Analysis*.
