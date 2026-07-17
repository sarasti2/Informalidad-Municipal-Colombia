# =====================================================================
# 03_variable_selection_bic.R
#
# Seleccion de covariables para el modelo Arc-FH, siguiendo la Seccion
# 5.6 "Pre-selection of auxiliary variables" del paper:
#   1) restringir la muestra al 50% de municipios con mayor tamano
#      muestral (para reducir el ruido de la seleccion de variables);
#   2) regresion de nu = asin(sqrt(informalidad_adj/100)) sobre las
#      covariables candidatas;
#   3) seleccion stepwise usando BIC (k = log(n)).
#
# Se corre de forma independiente para cada ano (2011, 2016, 2021).
# Nota: 'vacancy_rate' no esta disponible para 2011 (ver Seccion 5.5
# del paper) y se excluye automaticamente ese ano.
# =====================================================================

# Universo de covariables candidatas presentes en la base procesada.
# Ajustar este vector si la base final incluye mas/menos variables.
covars_candidatas <- c(
  "pregimen_subsidiado", "formal_rate", "vacancy_rate",
  "psecondary", "pterciary", "pprimary",
  "salario_bas", "vabpc",
  "disbogota", "dismdo", "distancia_mercado",
  "pruralpet", "pmujerpet", "pdependiente", "ruralidad",
  "t_crea", "altura", "areakm2",
  "gandina", "gcaribe", "gpacifica", "gorinoquia", "gamazonia"
)

select_vars_bic <- function(data_year, covars = covars_candidatas) {

  covars <- covars[covars %in% names(data_year)]
  # variables sin variacion o completamente NA se excluyen
  covars <- covars[sapply(data_year[covars], function(x) {
    !all(is.na(x)) && stats::sd(x, na.rm = TRUE) > 0
  })]

  # 1) restringir al 50% con mayor tamano muestral, entre los MUESTREADOS
  sampled <- data_year[!is.na(data_year$informalidad_adj), ]
  n_keep <- ceiling(nrow(sampled) / 2)
  sampled <- sampled[order(-sampled$num_obser_freq_adj), ][seq_len(n_keep), ]

  # 2) variable dependiente transformada
  sampled$nu <- asin(sqrt(pmin(pmax(sampled$informalidad_adj, 0), 100) / 100))

  form_full <- stats::as.formula(paste("nu ~", paste(covars, collapse = " + ")))
  dat_reg <- sampled[, c("nu", covars)]
  dat_reg <- dat_reg[stats::complete.cases(dat_reg), ]

  fit_null <- stats::lm(nu ~ 1, data = dat_reg)
  fit_full <- stats::lm(form_full, data = dat_reg)

  # 3) seleccion stepwise bidireccional con penalizacion BIC (k = log(n))
  fit_bic <- stats::step(
    fit_null,
    scope = list(lower = fit_null, upper = fit_full),
    direction = "both",
    k = log(nrow(dat_reg)),
    trace = 0
  )

  list(
    selected = setdiff(names(stats::coef(fit_bic)), "(Intercept)"),
    model    = fit_bic,
    r2       = summary(fit_bic)$r.squared,
    n_used   = nrow(dat_reg)
  )
}
