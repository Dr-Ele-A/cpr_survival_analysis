# Counterfactual graphPAF helpers for household deprivation exposures
#
# This script contains three intervention estimators and matching bar-plot
# helpers.  The calculation helpers return a tibble and also write the same
# table as a CSV file.  The plot helpers accept either a named list of those
# tibbles (for example, unadjusted, demographic and fully adjusted models) or
# one tibble that already has an `adjustment` column.

library(tidyverse)
library(graphPAF)

# Convert graphPAF::impact_fraction(..., ci = TRUE) output to a tidy table.
tidy_graphpaf_if <- function(if_obj) {
  if ("time_vec" %in% names(if_obj)) {
    out <- tibble(
      Time = as.numeric(if_obj$time_vec),
      Estimated_PAF = as.numeric(if_obj$estimate),
      CI = as.character(if_obj$confidence_interval)
    )
  } else {
    out <- tibble(
      Time = NA_real_,
      Estimated_PAF = as.numeric(if_obj$estimate),
      CI = as.character(if_obj$confidence_interval)
    )
  }

  ci_match <- str_match(
    out$CI,
    "([-+]?(?:[0-9]*\\.)?[0-9]+(?:[eE][-+]?[0-9]+)?)\\s*,\\s*([-+]?(?:[0-9]*\\.)?[0-9]+(?:[eE][-+]?[0-9]+)?)"
  )

  out %>%
    mutate(
      conf.low = as.numeric(ci_match[, 2]),
      conf.high = as.numeric(ci_match[, 3])
    )
}

# Prepare a factor exposure while preserving the row names used by model data.
prepare_paf_factor_data <- function(data, fct_var_chr) {
  if (!is.data.frame(data)) {
    stop("`data` must be a dataframe containing the variables used to fit `ftd_mdl`.")
  }

  if (!fct_var_chr %in% names(data)) {
    stop("`fct_var` was not found in `data`.")
  }

  if (!is.factor(data[[fct_var_chr]])) {
    stop("`fct_var` must be a factor, as it was when the model was fitted.")
  }

  data <- as.data.frame(data)
  data_row_names <- row.names(data)
  data[[fct_var_chr]] <- forcats::fct_drop(data[[fct_var_chr]])
  row.names(data) <- data_row_names

  list(
    data = data,
    data_row_names = data_row_names,
    fct_lvls = levels(data[[fct_var_chr]])
  )
}

# Create a counterfactual dataset by moving one factor level to another.
move_paf_factor_level <- function(data,
                                  fct_var_chr,
                                  fct_lvls,
                                  level_from,
                                  level_to,
                                  data_row_names) {
  exposure <- as.character(data[[fct_var_chr]])
  exposure[exposure == level_from] <- level_to

  new_data <- data
  new_data[[fct_var_chr]] <- if (is.ordered(data[[fct_var_chr]])) {
    ordered(exposure, levels = fct_lvls)
  } else {
    factor(exposure, levels = fct_lvls)
  }

  row.names(new_data) <- data_row_names
  new_data
}

# Shared checks required by graphPAF for Cox proportional-hazards models.
validate_graphpaf_arguments <- function(ftd_mdl, t_vector, calculation_method) {
  if (inherits(ftd_mdl, "coxph") && is.null(t_vector)) {
    stop("`t_vector` must be supplied when `ftd_mdl` is a Cox proportional hazards model.")
  }

  if (inherits(ftd_mdl, "coxph") && calculation_method != "D") {
    stop("For Cox proportional hazards models, graphPAF requires `calculation_method = \"D\"`.")
  }

  # graphPAF's bootstrap code expects this option to be available.
  if (is.null(getOption("boot.ncpus"))) {
    options(boot.ncpus = 1)
  }
}

# Estimate one counterfactual scenario and append its scenario description.
estimate_paf_scenario <- function(ftd_mdl,
                                  data,
                                  new_data,
                                  calculation_method,
                                  boot_rep,
                                  t_vector,
                                  ci_level,
                                  ci_type,
                                  verbose) {
  graphPAF::impact_fraction(
    model = ftd_mdl,
    data = data,
    new_data = new_data,
    calculation_method = calculation_method,
    ci = TRUE,
    boot_rep = boot_rep,
    t_vector = t_vector,
    ci_level = ci_level,
    ci_type = ci_type,
    verbose = verbose
  ) %>%
    tidy_graphpaf_if()
}

# Write a calculation table and create its parent directory when required.
write_paf_csv <- function(paf_tbl, output_dir, output_file) {
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  readr::write_csv(paf_tbl, file.path(output_dir, output_file))
  paf_tbl
}

# Make a file-system-safe default output name from an exposure name.
safe_paf_name <- function(x) {
  x %>%
    str_replace_all("[^A-Za-z0-9]+", "_") %>%
    str_remove_all("^_|_$")
}

# Estimate PAFs after moving each eligible factor level to one chosen level.
calc_deprv_level_paf <- function(ftd_mdl,
                                 data,
                                 fct_var,
                                 ref_lvl,
                                 excld_lvl = NULL,
                                 boot_rep = 100,
                                 t_vector = NULL,
                                 calculation_method = "D",
                                 ci_level = 0.95,
                                 ci_type = "norm",
                                 verbose = FALSE,
                                 output_dir = "outputs",
                                 output_file = NULL) {
  fct_var_chr <- rlang::as_name(rlang::ensym(fct_var))
  prepared <- prepare_paf_factor_data(data, fct_var_chr)
  ref_lvl <- as.character(ref_lvl)
  excld_lvl <- as.character(excld_lvl)

  if (length(ref_lvl) != 1 || !ref_lvl %in% prepared$fct_lvls) {
    stop("`ref_lvl` must be one observed level of `fct_var`.")
  }

  if (length(setdiff(excld_lvl, prepared$fct_lvls)) > 0) {
    stop("All values in `excld_lvl` must be observed levels of `fct_var`.")
  }

  levels_to_move <- setdiff(prepared$fct_lvls, c(ref_lvl, excld_lvl))
  if (length(levels_to_move) == 0) {
    stop("No eligible factor levels remain after excluding `ref_lvl` and `excld_lvl`.")
  }

  validate_graphpaf_arguments(ftd_mdl, t_vector, calculation_method)

  paf_tbl <- map_dfr(levels_to_move, function(level_from) {
    new_data <- move_paf_factor_level(
      data = prepared$data,
      fct_var_chr = fct_var_chr,
      fct_lvls = prepared$fct_lvls,
      level_from = level_from,
      level_to = ref_lvl,
      data_row_names = prepared$data_row_names
    )

    estimate_paf_scenario(
      ftd_mdl = ftd_mdl,
      data = prepared$data,
      new_data = new_data,
      calculation_method = calculation_method,
      boot_rep = boot_rep,
      t_vector = t_vector,
      ci_level = ci_level,
      ci_type = ci_type,
      verbose = verbose
    ) %>%
      mutate(
        variable = fct_var_chr,
        level_from = level_from,
        level_to = ref_lvl,
        excluded_levels = if_else(
          length(excld_lvl) == 0,
          NA_character_,
          str_c(excld_lvl, collapse = "; ")
        ),
        scenario = str_c(level_from, " -> ", ref_lvl),
        .before = 1
      )
  })

  if (is.null(output_file)) {
    output_file <- str_c(safe_paf_name(fct_var_chr), "_level_paf.csv")
  }

  write_paf_csv(paf_tbl, output_dir, output_file)
}

# Estimate PAFs after reducing each deprivation-count level by a fixed amount.
calc_dprv_no_rdctn_paf <- function(ftd_mdl,
                                   data,
                                   fct_var,
                                   dprv_rdctn_no,
                                   excld_lvl = NULL,
                                   boot_rep = 100,
                                   t_vector = NULL,
                                   calculation_method = "D",
                                   ci_level = 0.95,
                                   ci_type = "norm",
                                   verbose = FALSE,
                                   output_dir = "outputs",
                                   output_file = NULL) {
  fct_var_chr <- rlang::as_name(rlang::ensym(fct_var))
  prepared <- prepare_paf_factor_data(data, fct_var_chr)

  # The count exposure must be represented by a factor with whole-number levels.
  deprivation_counts <- suppressWarnings(as.numeric(prepared$fct_lvls))
  if (anyNA(deprivation_counts) || any(!is.finite(deprivation_counts)) ||
      any(deprivation_counts < 0) || any(deprivation_counts != floor(deprivation_counts)) ||
      anyDuplicated(deprivation_counts)) {
    stop("`fct_var` must be a factor with unique, non-negative integer deprivation-count levels.")
  }

  if (length(dprv_rdctn_no) != 1 || is.na(dprv_rdctn_no) ||
      !is.numeric(dprv_rdctn_no) || dprv_rdctn_no < 1 ||
      dprv_rdctn_no != floor(dprv_rdctn_no)) {
    stop("`dprv_rdctn_no` must be one positive whole number.")
  }

  if (dprv_rdctn_no > max(deprivation_counts)) {
    stop("`dprv_rdctn_no` cannot exceed the largest deprivation count in `fct_var`.")
  }

  excld_lvl <- suppressWarnings(as.numeric(as.character(excld_lvl)))
  if (anyNA(excld_lvl) || any(excld_lvl != floor(excld_lvl)) ||
      length(setdiff(excld_lvl, deprivation_counts)) > 0) {
    stop("`excld_lvl` must contain observed whole-number deprivation-count levels.")
  }

  level_lookup <- tibble(
    level_label = prepared$fct_lvls,
    deprivation_count = as.integer(deprivation_counts)
  )

  scenarios <- level_lookup %>%
    filter(deprivation_count > 0, !deprivation_count %in% excld_lvl) %>%
    transmute(
      level_from = level_label,
      deprivation_count_from = deprivation_count,
      deprivation_count_to = pmax(deprivation_count - dprv_rdctn_no, 0L),
      level_to = level_lookup$level_label[
        match(deprivation_count_to, level_lookup$deprivation_count)
      ]
    )

  if (nrow(scenarios) == 0) {
    stop("No deprivation-count levels remain after applying `excld_lvl`.")
  }

  if (anyNA(scenarios$level_to)) {
    missing_targets <- scenarios %>%
      filter(is.na(level_to)) %>%
      pull(deprivation_count_to) %>%
      unique() %>%
      str_c(collapse = ", ")
    stop(
      "Every counterfactual target count must be an observed factor level. Missing: ",
      missing_targets,
      "."
    )
  }

  validate_graphpaf_arguments(ftd_mdl, t_vector, calculation_method)

  paf_tbl <- pmap_dfr(scenarios, function(level_from,
                                           deprivation_count_from,
                                           deprivation_count_to,
                                           level_to) {
    new_data <- move_paf_factor_level(
      data = prepared$data,
      fct_var_chr = fct_var_chr,
      fct_lvls = prepared$fct_lvls,
      level_from = level_from,
      level_to = level_to,
      data_row_names = prepared$data_row_names
    )

    estimate_paf_scenario(
      ftd_mdl = ftd_mdl,
      data = prepared$data,
      new_data = new_data,
      calculation_method = calculation_method,
      boot_rep = boot_rep,
      t_vector = t_vector,
      ci_level = ci_level,
      ci_type = ci_type,
      verbose = verbose
    ) %>%
      mutate(
        variable = fct_var_chr,
        dprv_rdctn_no = dprv_rdctn_no,
        level_from = level_from,
        level_to = level_to,
        deprivation_count_from = deprivation_count_from,
        deprivation_count_to = deprivation_count_to,
        excluded_levels = if_else(
          length(excld_lvl) == 0,
          NA_character_,
          str_c(excld_lvl, collapse = "; ")
        ),
        scenario = str_c(deprivation_count_from, " -> ", deprivation_count_to),
        .before = 1
      )
  })

  if (is.null(output_file)) {
    output_file <- str_c(
      safe_paf_name(fct_var_chr),
      "_reduction_",
      dprv_rdctn_no,
      "_paf.csv"
    )
  }

  write_paf_csv(paf_tbl, output_dir, output_file)
}

# Split one observed deprivation-combination level into its component domains.
split_deprivation_domains <- function(level, none_lvl, separator) {
  if (identical(level, none_lvl)) {
    return(character())
  }

  str_split(level, fixed(separator))[[1]] %>%
    str_trim() %>%
    discard(~ .x == "")
}

# Produce an order-independent lookup key for a deprivation-domain combination.
domain_combination_key <- function(domains, separator) {
  if (length(domains) == 0) {
    return("")
  }

  str_c(sort(domains), collapse = separator)
}

# Estimate PAFs after removing one deprivation domain at a time.
calc_dprv_dms_rmvl_paf <- function(ftd_mdl,
                                   data,
                                   fct_var,
                                   excld_lvl = NULL,
                                   none_lvl = "None",
                                   separator = "+",
                                   boot_rep = 100,
                                   t_vector = NULL,
                                   calculation_method = "D",
                                   ci_level = 0.95,
                                   ci_type = "norm",
                                   verbose = FALSE,
                                   output_dir = "outputs",
                                   output_file = NULL) {
  fct_var_chr <- rlang::as_name(rlang::ensym(fct_var))
  prepared <- prepare_paf_factor_data(data, fct_var_chr)
  none_lvl <- as.character(none_lvl)
  excld_lvl <- as.character(excld_lvl)

  if (length(none_lvl) != 1 || !none_lvl %in% prepared$fct_lvls) {
    stop("`none_lvl` must be one observed no-deprivation level of `fct_var`.")
  }

  if (length(separator) != 1 || !nzchar(separator)) {
    stop("`separator` must be one non-empty character string.")
  }

  level_components <- map(
    prepared$fct_lvls,
    split_deprivation_domains,
    none_lvl = none_lvl,
    separator = separator
  )
  names(level_components) <- prepared$fct_lvls

  invalid_levels <- prepared$fct_lvls[
    map_lgl(level_components, ~ length(.x) != length(unique(.x)))
  ]
  if (length(invalid_levels) > 0) {
    stop(
      "Each deprivation domain may appear only once in a factor level. Invalid: ",
      str_c(invalid_levels, collapse = ", "),
      "."
    )
  }

  available_domains <- level_components %>%
    unlist(use.names = FALSE) %>%
    unique() %>%
    sort()

  if (length(available_domains) == 0) {
    stop("`fct_var` contains no deprivation domains to remove.")
  }

  if (length(setdiff(excld_lvl, available_domains)) > 0) {
    stop("`excld_lvl` must contain unitary deprivation domains present in `fct_var`.")
  }

  domains_to_remove <- setdiff(available_domains, excld_lvl)
  if (length(domains_to_remove) == 0) {
    stop("No deprivation domains remain after applying `excld_lvl`.")
  }

  # Match targets by their component set, so the factor-level order need not be
  # alphabetical (for example, both `employment+health` and `health+employment`).
  level_keys <- map_chr(level_components, domain_combination_key, separator = separator)
  if (anyDuplicated(level_keys)) {
    stop("Each observed deprivation-domain combination must occur only once in `fct_var`.")
  }

  scenarios <- map_dfr(domains_to_remove, function(removed_dimension) {
    source_index <- which(
      map_lgl(level_components, ~ removed_dimension %in% .x)
    )

    target_keys <- map_chr(
      level_components[source_index],
      ~ domain_combination_key(setdiff(.x, removed_dimension), separator)
    )

    tibble(
      removed_dimension = removed_dimension,
      level_from = prepared$fct_lvls[source_index],
      target_key = target_keys,
      level_to = prepared$fct_lvls[match(target_keys, level_keys)]
    )
  })

  if (anyNA(scenarios$level_to)) {
    missing_targets <- scenarios %>%
      filter(is.na(level_to)) %>%
      transmute(scenario = str_c(level_from, " after removing ", removed_dimension)) %>%
      pull(scenario) %>%
      str_c(collapse = "; ")
    stop(
      "Every post-removal combination must be an observed factor level. Missing targets for: ",
      missing_targets,
      "."
    )
  }

  validate_graphpaf_arguments(ftd_mdl, t_vector, calculation_method)

  paf_tbl <- pmap_dfr(scenarios, function(removed_dimension,
                                           level_from,
                                           target_key,
                                           level_to) {
    new_data <- move_paf_factor_level(
      data = prepared$data,
      fct_var_chr = fct_var_chr,
      fct_lvls = prepared$fct_lvls,
      level_from = level_from,
      level_to = level_to,
      data_row_names = prepared$data_row_names
    )

    estimate_paf_scenario(
      ftd_mdl = ftd_mdl,
      data = prepared$data,
      new_data = new_data,
      calculation_method = calculation_method,
      boot_rep = boot_rep,
      t_vector = t_vector,
      ci_level = ci_level,
      ci_type = ci_type,
      verbose = verbose
    ) %>%
      mutate(
        variable = fct_var_chr,
        removed_dimension = removed_dimension,
        level_from = level_from,
        level_to = level_to,
        excluded_levels = if_else(
          length(excld_lvl) == 0,
          NA_character_,
          str_c(excld_lvl, collapse = "; ")
        ),
        scenario = str_c(level_from, " -> ", level_to),
        .before = 1
      )
  })

  if (is.null(output_file)) {
    output_file <- str_c(safe_paf_name(fct_var_chr), "_domain_removal_paf.csv")
  }

  write_paf_csv(paf_tbl, output_dir, output_file)
}

# Combine calculation outputs and select one follow-up time for a bar plot.
prepare_paf_plot_data <- function(paf_results, adjustment_levels, time_point) {
  if (is.data.frame(paf_results)) {
    paf_tbl <- as_tibble(paf_results)
    if (!"adjustment" %in% names(paf_tbl)) {
      paf_tbl <- paf_tbl %>% mutate(adjustment = "Model")
    }
  } else if (is.list(paf_results)) {
    result_names <- names(paf_results)
    if (is.null(result_names) || any(!nzchar(result_names))) {
      if (is.null(adjustment_levels) || length(adjustment_levels) != length(paf_results)) {
        stop("A named `paf_results` list or matching `adjustment_levels` is required.")
      }
      result_names <- adjustment_levels
    }

    paf_tbl <- map2_dfr(paf_results, result_names, function(result, adjustment_label) {
      as_tibble(result) %>% mutate(adjustment = adjustment_label)
    })
  } else {
    stop("`paf_results` must be a dataframe or a named list of dataframes.")
  }

  required_columns <- c("Estimated_PAF", "conf.low", "conf.high")
  if (length(setdiff(required_columns, names(paf_tbl))) > 0) {
    stop("`paf_results` must contain `Estimated_PAF`, `conf.low` and `conf.high`.")
  }

  if ("Time" %in% names(paf_tbl) && any(!is.na(paf_tbl$Time))) {
    if (is.null(time_point)) {
      distinct_times <- paf_tbl %>% filter(!is.na(Time)) %>% pull(Time) %>% unique()
      if (length(distinct_times) != 1) {
        stop("Supply `time_point` when the PAF tables contain more than one follow-up time.")
      }
      time_point <- distinct_times
    }

    paf_tbl <- paf_tbl %>% filter(Time == time_point)
    if (nrow(paf_tbl) == 0) {
      stop("No PAF estimates were found for `time_point = ", time_point, ".")
    }
  }

  if (is.null(adjustment_levels)) {
    adjustment_levels <- unique(paf_tbl$adjustment)
  }

  paf_tbl %>%
    mutate(
      adjustment = factor(adjustment, levels = adjustment_levels),
      af_pct = 100 * Estimated_PAF,
      lower_pct = 100 * conf.low,
      upper_pct = 100 * conf.high
    )
}

# Save one plot in both requested formats.
save_paf_plot <- function(plot, output_dir, output_stem, width, height) {
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  ggsave(
    filename = file.path(output_dir, str_c(output_stem, ".png")),
    plot = plot,
    width = width,
    height = height,
    dpi = 600,
    bg = "white"
  )
  ggsave(
    filename = file.path(output_dir, str_c(output_stem, ".pdf")),
    plot = plot,
    width = width,
    height = height,
    bg = "white"
  )

  invisible(plot)
}

# Common styling for side-by-side AF estimates and their confidence intervals.
paf_bar_layers <- function() {
  dodge <- position_dodge(width = 0.75)

  list(
    geom_col(
      position = dodge,
      width = 0.65,
      colour = "grey25",
      linewidth = 0.25
    ),
    geom_errorbar(
      aes(ymin = lower_pct, ymax = upper_pct),
      position = dodge,
      width = 0.10,
      linewidth = 0.45,
      colour = "black"
    ),
    geom_hline(
      yintercept = 0,
      linetype = "dashed",
      colour = "grey35",
      linewidth = 0.4
    ),
    paletteer::scale_fill_paletteer_d("RColorBrewer::Dark2"),
    scale_y_continuous(
      labels = scales::label_number(accuracy = 1, suffix = "%"),
      expand = expansion(mult = c(0.08, 0.12))
    ),
    theme_classic(base_size = 12),
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 11),
      axis.title = element_text(face = "bold"),
      axis.text = element_text(colour = "black"),
      legend.position = "bottom",
      legend.title = element_text(face = "bold"),
      panel.grid.major.y = element_line(colour = "grey85", linewidth = 0.25)
    )
  )
}

# Plot PAFs from calc_deprv_level_paf, one bar per model adjustment.
plot_deprv_level_paf <- function(paf_results,
                                 time_point = NULL,
                                 adjustment_levels = NULL,
                                 output_dir = "outputs",
                                 output_stem = "deprivation_level_paf",
                                 title = "AF after moving household deprivation levels",
                                 subtitle = "Counterfactual PAF estimates with 95% confidence intervals") {
  paf_tbl <- prepare_paf_plot_data(paf_results, adjustment_levels, time_point)

  if (!"scenario" %in% names(paf_tbl)) {
    stop("`paf_results` must contain a `scenario` column.")
  }

  paf_tbl <- paf_tbl %>%
    mutate(scenario = factor(scenario, levels = unique(scenario)))

  plot <- ggplot(paf_tbl, aes(x = scenario, y = af_pct, fill = adjustment)) +
    paf_bar_layers() +
    scale_x_discrete(labels = function(x) str_wrap(x, width = 16)) +
    labs(
      title = title,
      subtitle = subtitle,
      x = "Original -> counterfactual deprivation level",
      y = "Attributable fraction (%)",
      fill = "Model adjustment"
    ) +
    theme(axis.text.x = element_text(angle = 35, hjust = 1, vjust = 1))

  save_paf_plot(plot, output_dir, output_stem, width = 9, height = 5.5)
}

# Plot PAFs from calc_dprv_no_rdctn_paf, one bar per model adjustment.
plot_dprv_no_rdctn_paf <- function(paf_results,
                                   time_point = NULL,
                                   adjustment_levels = NULL,
                                   output_dir = "outputs",
                                   output_stem = "deprivation_count_reduction_paf",
                                   title = "AF after reducing household deprivation counts",
                                   subtitle = "Counterfactual PAF estimates with 95% confidence intervals") {
  paf_tbl <- prepare_paf_plot_data(paf_results, adjustment_levels, time_point)

  if (!"scenario" %in% names(paf_tbl)) {
    stop("`paf_results` must contain a `scenario` column.")
  }

  paf_tbl <- paf_tbl %>%
    mutate(scenario = factor(scenario, levels = unique(scenario)))

  plot <- ggplot(paf_tbl, aes(x = scenario, y = af_pct, fill = adjustment)) +
    paf_bar_layers() +
    labs(
      title = title,
      subtitle = subtitle,
      x = "Original -> counterfactual deprivation count",
      y = "Attributable fraction (%)",
      fill = "Model adjustment"
    )

  save_paf_plot(plot, output_dir, output_stem, width = 6, height = 5.5)
}

# Plot PAFs from calc_dprv_dms_rmvl_paf in a 2 x 2 domain-removal layout.
plot_dprv_dms_rmvl_paf <- function(paf_results,
                                   time_point = NULL,
                                   adjustment_levels = NULL,
                                   output_dir = "outputs",
                                   output_stem = "deprivation_domain_removal_paf",
                                   title = "AF after removing household deprivation domains",
                                   subtitle = "Counterfactual PAF estimates with 95% confidence intervals") {
  paf_tbl <- prepare_paf_plot_data(paf_results, adjustment_levels, time_point)

  required_columns <- c("removed_dimension", "level_from")
  if (length(setdiff(required_columns, names(paf_tbl))) > 0) {
    stop("`paf_results` must contain `removed_dimension` and `level_from` columns.")
  }

  paf_tbl <- paf_tbl %>%
    mutate(
      removed_dimension = factor(
        removed_dimension,
        levels = unique(removed_dimension)
      ),
      level_from = factor(level_from, levels = unique(level_from))
    )

  plot <- ggplot(paf_tbl, aes(x = level_from, y = af_pct, fill = adjustment)) +
    paf_bar_layers() +
    facet_wrap(~ removed_dimension, nrow = 2, ncol = 2, scales = "free_x") +
    scale_x_discrete(
      labels = function(x) {
        x %>%
          str_replace_all("\\+", " + ") %>%
          str_to_title() %>%
          str_wrap(width = 18)
      }
    ) +
    labs(
      title = title,
      subtitle = subtitle,
      x = "Original deprivation-domain combination",
      y = "Attributable fraction (%)",
      fill = "Model adjustment"
    ) +
    theme(
      axis.text.x = element_text(angle = 35, hjust = 1, vjust = 1),
      strip.background = element_rect(fill = "grey95", colour = "grey70"),
      strip.text = element_text(face = "bold"),
      panel.spacing = grid::unit(0.8, "lines")
    )

  save_paf_plot(plot, output_dir, output_stem, width = 14, height = 9)
}

# -------------------------------------------------------------------------
# Example workflow
# -------------------------------------------------------------------------
#
# paf_no_unadj <- calc_dprv_no_rdctn_paf(
#   ftd_mdl = deprv_no_unadj_cxph,
#   data = ehr_cpr_cens11_cohrt,
#   fct_var = m_hh_deprv_no,
#   dprv_rdctn_no = 1,
#   t_vector = seq.int(0, 11)
# )
#
# paf_no_plot <- plot_dprv_no_rdctn_paf(
#   paf_results = list(
#     "Unadjusted" = paf_no_unadj,
#     "Demography adjusted" = paf_no_demography,
#     "Fully adjusted" = paf_no_full
#   ),
#   time_point = 6
# )
#
# paf_dms_unadj <- calc_dprv_dms_rmvl_paf(
#   ftd_mdl = deprv_dms_unadj_cxph,
#   data = ehr_cpr_cens11_cohrt,
#   fct_var = m_hh_deprv_dms,
#   t_vector = seq.int(0, 11)
# )
#
# paf_dms_plot <- plot_dprv_dms_rmvl_paf(
#   paf_results = list("Unadjusted" = paf_dms_unadj),
#   time_point = 6
# )
