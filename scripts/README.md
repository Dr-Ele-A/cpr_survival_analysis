# Public plotting scripts

The scripts in this folder run outside the SAIL trusted research environment. They use only aggregate or model-derived inputs prepared for disclosure-controlled export from `sail_sdc/outputs/` and write candidate public figures to `outputs/`. Confirm the approval status recorded outside this repository before publication.

Each script discovers the repository root by locating `cpr_survival_analysis.Rproj` from its own file path. It can be invoked from the project root as shown below, or from another working directory if the command supplies a valid path to the script. No script reads individual-level data.

## Scripts

| Script | Inputs | Outputs |
|---|---|---|
| `plot_paf_from_sdc_tables.R` | `paf_dprv_count.xlsx`: `dprv_no_2_non`, `dprv_rdtn_by1`, `dprv_rdtn_by2`; `paf_dprv_dms.xlsx`: `dprv_dms_2_non`, `dprv_dms_rmvl` | `paf_pdrv_no_all_stch_plts.{png,pdf}`; `paf_dms_all_stch_plts.{png,pdf}` |
| `forestplot_m_hh_deprv_no.R` | `bivar_coxph_cpr_all.csv`; `demo2a` in `multivar_coxph_cpr_demo.xlsx`; `full_2a` in `multivar_coxph_cpr_full.xlsx` | Count forest plot in PNG/PDF; plotting-data CSV; session information |
| `forestplot_m_hh_deprv_dms.R` | `bivar_coxph_cpr_all.csv`; `demo2b` in `multivar_coxph_cpr_demo.xlsx`; `full_2b` in `multivar_coxph_cpr_full.xlsx` | Profile forest plot in PNG/PDF; plotting-data CSV; session information |

All input filenames above are resolved under `sail_sdc/outputs/`; all output filenames are resolved under the public `outputs/` folder.

## Run

From a shell with `Rscript` available:

```text
Rscript scripts/plot_paf_from_sdc_tables.R
Rscript scripts/forestplot_m_hh_deprv_no.R
Rscript scripts/forestplot_m_hh_deprv_dms.R
```

On the validation machine, R 4.5.1 was installed at `C:/Program Files/R/R-4.5.1/bin/Rscript.exe` but was not on `PATH`.

## Packages

- Impact-fraction plots: `dplyr`, `ggplot2`, `patchwork`, `readxl`, `scales`, and `stringr`.
- Forest plots: `tidyverse` and `readxl`.

The public PAF script reconstructs the plotting layer only. It does not recalculate population attributable fractions and therefore does not require `graphPAF`. Estimates are filtered to age six (`Time == 6`), converted from proportions to percentages for display, and plotted with the first three colours from `RColorBrewer::Dark2`: `#1B9E77`, `#D95F02`, and `#7570B3`. A positive value is the model-estimated relative reduction in age-six CPR risk under the named counterfactual reassignment; it is not a demonstrated intervention effect.

## Output fidelity

The PAF layouts, labels, factor order, dimensions, and styling are extracted from `sail_sdc/scripts/ea_cpr_reg_surv_sdc_cln_v2.Rmd` and `calc_deprv_counterfactual_paf_graphpaf.R`. PNGs are written at 300 dpi: 18 × 6 inches for deprivation counts and 14 × 15 inches for deprivation-domain profiles. PDFs use the same physical dimensions.

Small byte-level rendering differences can arise across R versions, graphics devices, fonts, and package versions. Validation should therefore check dimensions, labels, values, ordering, palette, and visual equivalence rather than requiring identical file hashes.

## Input safety

Do not point these scripts at row-level or unscreened secure exports. The version-control allowlist is deliberately limited to the five files needed for these figures. Confirm disclosure-control approval before publishing any replacement input or output.
