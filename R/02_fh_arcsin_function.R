# =====================================================================
# 02_fh_arcsin_function.R
#
# Implementacion del modelo de Fay-Herriot con transformacion arcoseno
# (Arc-FH), siguiendo Schmid, Tzavidis, Munnich y Chambers (2017), tal
# como se describe en la Seccion "Transformed Fay-Herriot estimators"
# del paper. Cuatro pasos:
#   (i)   transformar el estimador directo:      nu_m = asin(sqrt(theta_m))
#   (ii)  aproximar la varianza muestral:         sigma2_eps_m = 1/(4*n_tilde_m)
#   (iii) estimar el modelo FH clasico para nu_m y sigma2_eps_m
#   (iv)  des-transformar:                        theta_hat = sin(nu_hat)^2
#
# sigma2_u se estima por maxima verosimilitud (perfil de verosimilitud
# sobre el componente de varianza, en el espiritu de Li & Lahiri, 2010).
#
# La incertidumbre (IC) se obtiene por bootstrap parametrico simple,
# siguiendo la logica de bootstrapping "hacia atras" descrita en el
# paper (Casas-Cordero, Encina & Lahiri, 2016).
# =====================================================================

FH_arcsin <- function(direct_pct, eff_n, X, sigma2_u_bounds = c(1e-8, 2),
                       B = 200, seed = 123) {
  # direct_pct : vector del estimador directo EN PORCENTAJE (0-100), con NA
  #              para las areas no muestreadas.
  # eff_n      : tamano de muestra efectivo (ajustado por efecto de diseno).
  #              En la base este es 'num_obser_freq_adj'.
  # X          : matriz de covariables (incluir columna de 1's para el
  #              intercepto), UNA FILA POR AREA, mismo orden que direct_pct.
  #
  # Devuelve una lista con: area_est (vector, todas las areas), Low, Up,
  # gamma, beta, sigma2_u.

  stopifnot(nrow(X) == length(direct_pct))
  set.seed(seed)

  nu <- asin(sqrt(pmin(pmax(direct_pct, 0), 100) / 100))
  sigma2_eps <- 1 / (4 * eff_n)

  is_sampled <- !is.na(nu) & !is.na(sigma2_eps) & stats::complete.cases(X)
  Xs  <- X[is_sampled, , drop = FALSE]
  nus <- nu[is_sampled]
  s2e <- sigma2_eps[is_sampled]

  # --- (iii) estimacion ML de sigma2_u por perfil de verosimilitud ---
  neg_loglik <- function(sigma2_u) {
    if (sigma2_u < 0) return(1e10)
    V <- sigma2_u + s2e
    W <- 1 / V
    XtWX <- t(Xs) %*% (Xs * W)
    beta <- solve(XtWX, t(Xs) %*% (nus * W))
    resid <- nus - Xs %*% beta
    0.5 * sum(log(V)) + 0.5 * sum((resid^2) * W)
  }
  opt <- stats::optimize(neg_loglik, interval = sigma2_u_bounds)
  sigma2_u <- opt$minimum

  V <- sigma2_u + s2e
  W <- 1 / V
  XtWX <- t(Xs) %*% (Xs * W)
  beta <- solve(XtWX, t(Xs) %*% (nus * W))

  gamma_s <- sigma2_u / (sigma2_u + s2e)
  synth_s <- as.vector(Xs %*% beta)
  nu_fh_s <- gamma_s * nus + (1 - gamma_s) * synth_s

  # --- prediccion sintetica para TODAS las areas (incl. no muestreadas) ---
  ok_all <- stats::complete.cases(X)
  synth_all <- rep(NA_real_, nrow(X))
  synth_all[ok_all] <- as.vector(X[ok_all, , drop = FALSE] %*% beta)

  nu_final <- synth_all
  nu_final[is_sampled] <- nu_fh_s
  theta_hat <- sin(pmin(pmax(nu_final, 0), pi / 2))^2 * 100

  gamma_all <- rep(0, nrow(X))
  gamma_all[is_sampled] <- gamma_s

  # --- (iv) bootstrap parametrico para el error estandar / IC ---
  boot_mat <- matrix(NA_real_, nrow = nrow(X), ncol = B)
  for (b in seq_len(B)) {
    u_star <- stats::rnorm(nrow(Xs), 0, sqrt(sigma2_u))
    nu_star_true <- as.vector(Xs %*% beta) + u_star
    eps_star <- stats::rnorm(length(nu_star_true), 0, sqrt(s2e))
    nu_star_obs <- nu_star_true + eps_star

    V_b <- sigma2_u + s2e
    W_b <- 1 / V_b
    beta_b <- tryCatch(
      solve(t(Xs) %*% (Xs * W_b), t(Xs) %*% (nu_star_obs * W_b)),
      error = function(e) beta
    )
    gamma_b <- sigma2_u / (sigma2_u + s2e)
    nu_fh_b <- gamma_b * nu_star_obs + (1 - gamma_b) * as.vector(Xs %*% beta_b)

    pred_all_b <- rep(NA_real_, nrow(X))
    pred_all_b[ok_all] <- as.vector(X[ok_all, , drop = FALSE] %*% beta_b)
    pred_all_b[is_sampled] <- nu_fh_b
    boot_mat[, b] <- sin(pmin(pmax(pred_all_b, 0), pi / 2))^2 * 100
  }
  se_boot <- apply(boot_mat, 1, stats::sd, na.rm = TRUE)

  list(
    area_est = theta_hat,
    se       = se_boot,
    Low      = pmax(theta_hat - 1.96 * se_boot, 0),
    Up       = pmin(theta_hat + 1.96 * se_boot, 100),
    gamma    = gamma_all,
    beta     = beta,
    sigma2_u = sigma2_u,
    is_sampled = is_sampled
  )
}
