# Secure analysis scripts

These scripts contain SAIL-only workflow code. They are published for analytical transparency, while their row-level data dependencies remain inside the trusted research environment.

## Files

### `5a - make cohort and events.R`

Reconstructed upstream cohort-building code. It reads five row-level `.qs` inputs covering child birth, looked-after status, child/maternal health, and maternal household information; joins them through encrypted linkage fields; selects cohort variables; and writes `data/d_cohort_clean.qs`.

The file is not standalone: package/helper setup is absent, the original `r_clear_and_load.r` source call is commented, and the upstream SQL/R preparation files are not in this repository. Treat it as provenance for variable lineage, not as a public reproduction script.

### `ea_cpr_reg_surv_sdc_cln_v2.Rmd`

Main secure analysis notebook. It:

- reads the linked cohort and CPR/social-care sources;
- restricts the 2010–2012 Welsh live-birth cohort and defines follow-up;
- links maternal 2011 Census household variables;
- derives deprivation counts, domain profiles, covariates, and event variables;
- produces descriptive summaries and association diagnostics;
- fits unadjusted, demography-adjusted, and fully adjusted Cox models;
- checks proportional hazards;
- estimates graphPAF-based, category-specific counterfactual attributable fractions;
- creates survival and diagnostic figures for disclosure-controlled public release.

The notebook contains SAIL drive paths and interactive operations. It is not expected to knit sequentially outside its original environment.

### `calc_deprv_counterfactual_paf_graphpaf.R`

Helper functions for:

- moving one deprivation level to a reference level;
- reducing deprivation counts by one or two;
- removing a named deprivation domain from a source profile;
- tidying `graphPAF::impact_fraction()` results;
- constructing the PAF bar charts.

The shared PAF palette is `RColorBrewer::Dark2`; with three model stages the colours are green `#1B9E77`, orange `#D95F02`, and purple `#7570B3`.

## Model stages

- **Unadjusted:** exposure-only Cox model.
- **Demography adjusted:** child sex and ethnicity; maternal age and qualification; dependent-child count, adult count, and marital status; plus one deprivation specification.
- **Fully adjusted:** the demographic block plus congenital anomalies, preterm birth, birth-weight category, and maternal alcohol, learning-difficulty/disability, mental-health, substance-use, and smoking variables.

The two deprivation representations are modelled separately: `demo2a`/`full_2a` use `m_hh_deprv_no`, while `demo2b`/`full_2b` use `m_hh_deprv_dms`.

## Known execution notes

- The main R Markdown code calls `save.image()` repeatedly; workspace images remain untracked.
- Public plotting does not source this helper, so it does not require `graphPAF` or secure model objects.
- The household-deprivation profile uses `None` as an operational category that can include observed non-deprivation alongside missing, unlinked, or no-code records; this known source-data limitation is documented in `../outputs/README.md`.
