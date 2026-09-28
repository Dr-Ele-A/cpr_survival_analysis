# ================================================================
# Publication-quality stacked forest plot for m_hh_deprv_no
# Cox proportional hazards model HR/aHR estimates
#
# Inputs:
#   sail_sdc/outputs/bivar_coxph_cpr_all.csv
#   sail_sdc/outputs/multivar_coxph_cpr_demo.xlsx   sheet: demo2a
#   sail_sdc/outputs/multivar_coxph_cpr_full.xlsx   sheet: full_2a
#
# Outputs:
#   outputs/forestplot_m_hh_deprv_no_adjustment_stack.png
#   outputs/forestplot_m_hh_deprv_no_adjustment_stack.pdf
#   outputs/forestplot_m_hh_deprv_no_plot_data.csv
#   outputs/forestplot_m_hh_deprv_no_sessionInfo.txt
# ================================================================

library(tidyverse)
# readxl is used with explicit readxl::read_excel() calls below.

# ---- 2. Project paths --------------------------------------------------------

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

project_dir <- find_project_dir()

data_dir <- file.path(project_dir, "sail_sdc", "outputs")
output_dir <- file.path(project_dir, "outputs")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
}

input_files <- c(
  bivar = file.path(data_dir, "bivar_coxph_cpr_all.csv"),
  demo = file.path(data_dir, "multivar_coxph_cpr_demo.xlsx"),
  full = file.path(data_dir, "multivar_coxph_cpr_full.xlsx")
)

missing_files <- input_files[!file.exists(input_files)]

if (length(missing_files) > 0) {
  stop(
    "The following input file(s) were not found:\n",
    paste(missing_files, collapse = "\n"),
    call. = FALSE
  )
}

# ---- 3. User-controlled plot settings ---------------------------------------

target_variable <- "m_hh_deprv_no"

model_levels <- c(
  "Unadjusted",
  "Demography adjusted",
  "Fully adjusted"
)

# Colour-blind friendly palette.
model_colours <- c(
  "Unadjusted" = "#1B9E77",
  "Demography adjusted" = "#D95F02",
  "Fully adjusted" = "#7570B3"
)

significance_levels <- c(
  "p < 0.01 / reference",
  "p < 0.05",
  "p < 0.10",
  "p >= 0.10"
)

significance_shapes <- c(
  "p < 0.01 / reference" = 18,
  "p < 0.05" = 16,              # shape 1: filled circle
  "p < 0.10" = 17,     # shape 2: filled triangle
  "p >= 0.10" = 15 # shape 3: filled square
)

# Vertical offsets stack the three models within each deprivation level.
# Positive offset is higher on the y-axis.
model_offsets <- tibble(
  model = factor(model_levels, levels = model_levels),
  y_offset = c(0.15, 0.00, -0.15)
)

# ---- 4. Helper functions -----------------------------------------------------

check_required_cols <- function(data, required_cols, data_name) {
  missing_cols <- setdiff(required_cols, names(data))

  if (length(missing_cols) > 0) {
    stop(
      data_name, " is missing required column(s): ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(data)
}

format_hr_ci <- function(hr, ci_low, ci_high) {
  if_else(
    is.na(ci_low) | is.na(ci_high),
    sprintf("%2.2f (reference)", hr),
    sprintf("%2.2f (%2.2f, %2.2f)", hr, ci_low, ci_high)
  )
}

make_level_label <- function(level) {
  level <- as.character(level)
  case_when(
    level == "0" ~ "0 (reference)",
    level == "1" ~ "1 deprivation indicator",
    TRUE ~ paste(level, "deprivation indicators")
  )
}

# ---- 5. Read data ------------------------------------------------------------

bivar_raw <- readr::read_csv(
  input_files[["bivar"]],
  show_col_types = FALSE
)

demo_raw <- readxl::read_excel(
  input_files[["demo"]],
  sheet = "demo2a"
)

full_raw <- readxl::read_excel(
  input_files[["full"]],
  sheet = "full_2a"
)

check_required_cols(
  bivar_raw,
  c("group", "Parameter", "Coefficient", "CI_low", "CI_high", "p", "frq"),
  "bivar_coxph_cpr_all.csv"
)

check_required_cols(
  demo_raw,
  c("variable", "label", "Coefficient", "CI_low", "CI_high", "p", "n_perc"),
  "multivar_coxph_cpr_demo.xlsx / demo2a"
)

check_required_cols(
  full_raw,
  c("variable", "label", "Coefficient", "CI_low", "CI_high", "p", "n_perc"),
  "multivar_coxph_cpr_full.xlsx / full_2a"
)

# ---- 6. Standardise and combine the three model outputs ----------------------

unadjusted <- bivar_raw |>
  filter(group == target_variable) |>
  transmute(
    model = "Unadjusted",
    level = as.character(Parameter),
    hr = as.numeric(Coefficient),
    ci_low = as.numeric(CI_low),
    ci_high = as.numeric(CI_high),
    p = as.numeric(p),
    n = as.integer(frq),
    n_perc = NA_character_
  )

demo_adjusted <- demo_raw |>
  filter(variable == target_variable) |>
  transmute(
    model = "Demography adjusted",
    level = as.character(label),
    hr = as.numeric(Coefficient),
    ci_low = as.numeric(CI_low),
    ci_high = as.numeric(CI_high),
    p = as.numeric(p),
    n = NA_integer_,
    n_perc = as.character(n_perc)
  )

full_adjusted <- full_raw |>
  filter(variable == target_variable) |>
  transmute(
    model = "Fully adjusted",
    level = as.character(label),
    hr = as.numeric(Coefficient),
    ci_low = as.numeric(CI_low),
    ci_high = as.numeric(CI_high),
    p = as.numeric(p),
    n = NA_integer_,
    n_perc = as.character(n_perc)
  )

forest_data_raw <- bind_rows(
  unadjusted,
  demo_adjusted,
  full_adjusted
)

if (nrow(forest_data_raw) == 0) {
  stop(
    "No rows were found for target variable: ",
    target_variable,
    call. = FALSE
  )
}

# Stop early if the plotting scale is invalid.
if (any(forest_data_raw$hr <= 0, na.rm = TRUE) ||
    any(forest_data_raw$ci_low <= 0, na.rm = TRUE) ||
    any(forest_data_raw$ci_high <= 0, na.rm = TRUE)) {
  stop(
    "HR and CI limits must be positive for a log-scale forest plot.",
    call. = FALSE
  )
}

# Ensure deprivation levels are ordered numerically where possible.
level_order <- forest_data_raw |>
  distinct(level) |>
  mutate(level_number = suppressWarnings(readr::parse_number(level))) |>
  arrange(level_number, level) |>
  pull(level)

level_positions <- tibble(
  level = level_order,
  # Reversed y positions put the reference level at the top.
  y_base = rev(seq_along(level_order)),
  level_label = make_level_label(level)
)

# level_positions %>% View

forest_data <- forest_data_raw |>
  mutate(
    model = factor(model, levels = model_levels),
    level = factor(level, levels = level_order),
    p_group = case_when(
      is.na(p) | p < 0.01 ~ "p < 0.01 / reference",
      !is.na(p) & p < 0.05 ~ "p < 0.05",
      !is.na(p) & p < 0.10 ~ "p < 0.10",
      TRUE ~ "p >= 0.10"
    ),
    p_group = factor(p_group, levels = significance_levels),
    hr_ci = format_hr_ci(hr, ci_low, ci_high)
  ) |>
  left_join(level_positions, by = c("level" = "level")) |>
  left_join(model_offsets, by = "model") |>
  mutate(
    y_plot = y_base + y_offset
  )

# Save the plotting dataset so the estimates used in the figure are auditable.
plot_data_file <- file.path(output_dir, "forestplot_m_hh_deprv_no_plot_data.csv")

forest_data |>
  arrange(level, model) |>
  write_csv(plot_data_file)

message("Plotting data saved to: ", plot_data_file)

# ---- 7. Build publication-quality forest plot --------------------------------

max_estimate <- max(
  forest_data$hr,
  forest_data$ci_high,
  na.rm = TRUE
)

# max_estimate

min_estimate <- min(
  forest_data$hr,
  forest_data$ci_low,
  na.rm = TRUE
)

x_min <- floor(min_estimate)
x_max <- ceiling(max_estimate)
text_x <- ceiling(max_estimate)

y_max <- max(level_positions$y_base)

forest_plot <- ggplot(forest_data, aes(y = y_plot)) +
  geom_hline(
    data = level_positions,
    aes(yintercept = y_base),
    colour = "grey92",
    linewidth = 0.35
  ) +
  geom_vline(
    xintercept = 1,
    linetype = "dashed",
    colour = "grey35",
    linewidth = 0.55
  ) +
  geom_segment(
    data = forest_data |> filter(!is.na(ci_low), !is.na(ci_high)),
    aes(
      x = ci_low,
      xend = ci_high,
      yend = y_plot,
      colour = model
    ),
    linewidth = 0.85,
    lineend = "round",
    na.rm = TRUE
  ) +
  geom_point(
    aes(
      x = hr,
      colour = model,
      shape = p_group
    ),
    size = 3.3,
    stroke = 0.8,
    na.rm = TRUE
  ) +
  geom_text(
    aes(
      x = text_x,
      label = hr_ci
    ),
    hjust = 0,
    size = 3.2,
    colour = "grey10",
    na.rm = TRUE
  ) +
  annotate(
    "text",
    x = text_x,
    y = y_max + 0.55,
    label = "HR/aHR (95% CI)",
    hjust = 0,
    fontface = "bold",
    size = 3.4,
    colour = "grey10"
  ) +
  scale_colour_manual(
    name = "Model adjustment",
    values = model_colours,
    breaks = model_levels,
    drop = FALSE
  ) +
  scale_shape_manual(
    name = "Significance",
    values = significance_shapes,
    breaks = significance_levels,
    drop = T
  ) +
  scale_x_continuous(
    limits = c(x_min, text_x),
    breaks = scales::breaks_width(4),
    expand = expansion(add = c(0.5, -0.25)) #-ve so line do not overlap RHS text
  ) +
  scale_y_continuous(
    breaks = level_positions$y_base,
    labels = level_positions$level,
    limits = c(0.45, y_max + 0.75),
    expand = expansion(mult = c(0.02, 0.02))
  ) +
  labs(
    title = "Hazard ratios for maternal household deprivation count",
    # subtitle = "m_hh_deprv_no across increasing Cox model adjustment",
    x = "Hazard ratio",
    y = "Count of household deprivation dimensions",
    caption = paste(
      "Points are HR/aHR estimates; whiskers are 95% confidence intervals.",
      "Vertical dashed line marks HR = 1.",
      "Reference category: 0 deprivation indicators.",
      sep = " "
    )
  ) +
  guides(
    colour = guide_legend(order = 1, override.aes = list(linewidth = 1.2, size = 3.5)),
    shape = guide_legend(order = 2)
  ) +
  coord_cartesian(clip = "off") +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 14, colour = "grey10"),
    plot.subtitle = element_text(size = 11, colour = "grey25"),
    plot.caption = element_text(size = 8.5, colour = "grey35", hjust = 0),
    axis.title.x = element_text(face = "bold", margin = margin(t = 8)),
    axis.title.y = element_text(face = "bold", margin = margin(r = 8)),
    axis.text.y = element_text(colour = "grey10"),
    axis.text.x = element_text(colour = "grey10"),
    panel.grid.major.y = element_blank(),
    # panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(colour = "grey88", linewidth = 0.3),
    legend.position = "bottom",
    legend.box = "vertical",
    legend.title = element_text(face = "bold"),
    plot.margin = margin(t = 12, r = 110, b = 12, l = 12)
  )

# Print to the active graphics device if running interactively.
print(forest_plot)

# ---- 8. Save outputs ---------------------------------------------------------

png_file <- file.path(output_dir, "forestplot_m_hh_deprv_no_adjustment_stack.png")
pdf_file <- file.path(output_dir, "forestplot_m_hh_deprv_no_adjustment_stack.pdf")
session_file <- file.path(output_dir, "forestplot_m_hh_deprv_no_sessionInfo.txt")

ggsave(
  filename = png_file,
  plot = forest_plot,
  width = 9.5,
  height = 6.5,
  units = "in",
  dpi = 600,
  bg = "white"
)

ggsave(
  filename = pdf_file,
  plot = forest_plot,
  width = 9.5,
  height = 6.5,
  units = "in",
  bg = "white"
)

capture.output(sessionInfo(), file = session_file)

message("Forest plot saved to: ", png_file)
message("Forest plot saved to: ", pdf_file)
message("Session information saved to: ", session_file)

# ---- 9. Reproducibility note -------------------------------------------------
# For a fully reproducible project library, consider running this once in the
# project root:
#
# install.packages("renv")
# renv::init()
# renv::snapshot()
#
# Then future reruns can use renv::restore() to recreate the package versions.
