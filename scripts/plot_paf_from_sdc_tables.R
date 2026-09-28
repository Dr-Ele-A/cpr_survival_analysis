# Reproduce the public PAF figures from disclosure-controlled SAIL exports.
#
# Inputs:
#   sail_sdc/outputs/paf_dprv_count.xlsx
#   sail_sdc/outputs/paf_dprv_dms.xlsx
#
# Outputs:
#   outputs/paf_pdrv_no_all_stch_plts.png
#   outputs/paf_pdrv_no_all_stch_plts.pdf
#   outputs/paf_dms_all_stch_plts.png
#   outputs/paf_dms_all_stch_plts.pdf

required_packages <- c(
  "dplyr",
  "ggplot2",
  "patchwork",
  "readxl",
  "scales",
  "stringr"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Install the following package(s) before running this script: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(patchwork)
  library(stringr)
})

find_project_dir <- function() {
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  start_dir <- if (length(file_arg) > 0) {
    dirname(normalizePath(
      sub("^--file=", "", file_arg[[1]]),
      winslash = "/",
      mustWork = TRUE
    ))
  } else {
    getwd()
  }

  candidate <- normalizePath(start_dir, winslash = "/", mustWork = TRUE)

  repeat {
    if (file.exists(file.path(candidate, "cpr_survival_analysis.Rproj"))) {
      return(candidate)
    }

    parent <- dirname(candidate)
    if (identical(parent, candidate)) {
      stop("Could not locate the project root.", call. = FALSE)
    }
    candidate <- parent
  }
}

check_required_columns <- function(data, required_columns, source_name) {
  missing_columns <- setdiff(required_columns, names(data))
  if (length(missing_columns) > 0) {
    stop(
      source_name,
      " is missing required column(s): ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(data)
}

read_paf_sheet <- function(path, sheet, adjustment_levels, adjustment_labels = NULL) {
  available_sheets <- readxl::excel_sheets(path)
  if (!sheet %in% available_sheets) {
    stop(
      "Sheet '", sheet, "' was not found in ", basename(path), ".",
      call. = FALSE
    )
  }

  data <- readxl::read_excel(path, sheet = sheet)
  check_required_columns(
    data,
    c(
      "adj_lvl",
      "scenario",
      "Time",
      "Estimated_PAF",
      "conf.low",
      "conf.high"
    ),
    paste0(basename(path), " / ", sheet)
  )

  data <- data |>
    rename(adjustment = adj_lvl)

  if (!is.null(adjustment_labels)) {
    data <- data |>
      mutate(adjustment = recode(adjustment, !!!adjustment_labels))
  }

  data |>
    filter(Time == 6) |>
    mutate(
      adjustment = factor(adjustment, levels = adjustment_levels),
      scenario = factor(scenario, levels = unique(scenario)),
      af_pct = 100 * Estimated_PAF,
      lower_pct = 100 * conf.low,
      upper_pct = 100 * conf.high
    )
}

paf_colours <- c("#1B9E77", "#D95F02", "#7570B3")

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
    scale_fill_manual(values = paf_colours),
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

plot_count_paf <- function(data, title) {
  ggplot(data, aes(x = scenario, y = af_pct, fill = adjustment)) +
    paf_bar_layers() +
    labs(
      title = title,
      subtitle = "Counterfactual PAF estimates with 95% confidence intervals",
      x = "Original -> counterfactual deprivation count",
      y = "Attributable fraction (%)",
      fill = "Model adjustment"
    )
}

plot_level_paf <- function(data) {
  ggplot(data, aes(x = scenario, y = af_pct, fill = adjustment)) +
    paf_bar_layers() +
    scale_x_discrete(labels = function(x) str_wrap(x, width = 16)) +
    labs(
      title = "AF after moving household deprivation levels",
      subtitle = "Counterfactual PAF estimates with 95% confidence intervals",
      x = "Original -> counterfactual deprivation level",
      y = "Attributable fraction (%)",
      fill = "Model adjustment"
    ) +
    theme(axis.text.x = element_text(angle = 35, hjust = 1, vjust = 1))
}

plot_domain_removal_paf <- function(data) {
  check_required_columns(
    data,
    c("removed_dimension", "level_from"),
    "paf_dprv_dms.xlsx / dprv_dms_rmvl"
  )

  data <- data |>
    mutate(
      removed_dimension = factor(
        removed_dimension,
        levels = unique(removed_dimension)
      ),
      level_from = factor(level_from, levels = unique(level_from))
    )

  ggplot(data, aes(x = level_from, y = af_pct, fill = adjustment)) +
    paf_bar_layers() +
    facet_wrap(~ removed_dimension, nrow = 2, ncol = 2, scales = "free_x") +
    scale_x_discrete(
      labels = function(x) {
        x |>
          str_replace_all("\\+", " + ") |>
          str_to_title() |>
          str_wrap(width = 18)
      }
    ) +
    labs(
      title = "AF after removing household deprivation domains",
      subtitle = "Counterfactual PAF estimates with 95% confidence intervals",
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
}

save_plot_pair <- function(plot, output_dir, stem, width, height) {
  ggsave(
    filename = file.path(output_dir, paste0(stem, ".png")),
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = 300,
    bg = "white"
  )
  ggsave(
    filename = file.path(output_dir, paste0(stem, ".pdf")),
    plot = plot,
    width = width,
    height = height,
    units = "in",
    bg = "white"
  )
}

project_dir <- find_project_dir()
input_dir <- file.path(project_dir, "sail_sdc", "outputs")
output_dir <- file.path(project_dir, "outputs")

input_files <- c(
  count = file.path(input_dir, "paf_dprv_count.xlsx"),
  domains = file.path(input_dir, "paf_dprv_dms.xlsx")
)

missing_files <- input_files[!file.exists(input_files)]
if (length(missing_files) > 0) {
  stop(
    "The following input file(s) were not found:\n",
    paste(missing_files, collapse = "\n"),
    call. = FALSE
  )
}

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
}

count_adjustment_levels <- c(
  "Unadjusted",
  "Demography adjusted",
  "Fully adjusted"
)
count_adjustment_labels <- c(
  "Demography-Adjusted" = "Demography adjusted",
  "Fully-Adjusted" = "Fully adjusted"
)

count_to_zero <- read_paf_sheet(
  input_files[["count"]],
  "dprv_no_2_non",
  count_adjustment_levels,
  count_adjustment_labels
)
count_by_one <- read_paf_sheet(
  input_files[["count"]],
  "dprv_rdtn_by1",
  count_adjustment_levels,
  count_adjustment_labels
)
count_by_two <- read_paf_sheet(
  input_files[["count"]],
  "dprv_rdtn_by2",
  count_adjustment_levels,
  count_adjustment_labels
)

count_plot <- (
  plot_count_paf(
    count_to_zero,
    "AF after reducing household deprivation counts to Zero"
  ) |
    plot_count_paf(
      count_by_one,
      "AF after reducing household deprivation counts by 1"
    ) |
    plot_count_paf(
      count_by_two,
      "AF after reducing household deprivation counts by 2"
    )
) +
  plot_layout(
    guides = "collect",
    axes = "collect",
    axis_titles = "collect"
  ) &
  theme(legend.position = "bottom")

save_plot_pair(
  count_plot,
  output_dir,
  "paf_pdrv_no_all_stch_plts",
  width = 18,
  height = 6
)

domain_adjustment_levels <- c(
  "Unadjusted",
  "Demography-Adjusted",
  "Fully-Adjusted"
)

domains_to_none <- read_paf_sheet(
  input_files[["domains"]],
  "dprv_dms_2_non",
  domain_adjustment_levels
)
domain_removal <- read_paf_sheet(
  input_files[["domains"]],
  "dprv_dms_rmvl",
  domain_adjustment_levels
)

domain_plot <- (
  (
    plot_level_paf(domains_to_none) +
      theme(plot.margin = grid::unit(c(0, 0, 0.5, 0), "in"))
  ) /
    plot_domain_removal_paf(domain_removal)
) +
  plot_layout(
    guides = "collect",
    axis_titles = "collect",
    heights = c(1, 3)
  ) &
  theme(legend.position = "bottom")

save_plot_pair(
  domain_plot,
  output_dir,
  "paf_dms_all_stch_plts",
  width = 14,
  height = 15
)

message("PAF figures saved to: ", output_dir)
