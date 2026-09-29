# Secure SAIL workflow

`sail_sdc/` contains the part of the analysis designed for the SAIL trusted research environment. The code depends on approved access to linked individual-level health, mortality, Census, household, and social-care records. It is retained to make the analytical workflow inspectable, but it is not a public-data pipeline and cannot be rerun from a repository clone alone.

## Boundary rules

1. Run cohort construction, linkage, recoding, modelling, diagnostics, and disclosure-control preparation only in the approved secure environment.
2. Never commit row-level data, linkage identifiers, dates, geography, R workspace images, database extracts, or unscreened result tables.
3. `sail_sdc/outputs/` contains aggregate and model-derived files cleared by SAIL for public use and publication; every analytical output is available to Git.
4. Use the public scripts in `../scripts/` with the released aggregate/model-derived tables in `outputs/`.
5. Keep the secure original and public copy of a released figure byte-identical.

The repository `.gitignore` excludes row-level data formats, local R state, secrets, and temporary files. It explicitly keeps every file under `sail_sdc/outputs/` available to Git.

## Workflow summary

1. `scripts/5a - make cohort and events.R` documents an upstream, reconstructed cohort-building step that reads row-level `.qs` objects and writes `data/d_cohort_clean.qs`.
2. `scripts/ea_cpr_reg_surv_sdc_cln_v2.Rmd` builds the analysis cohort, links Census and CPR information, derives variables, fits Cox models, assesses proportional hazards, estimates scenario-specific attributable fractions, and creates release-formatted figures.
3. `scripts/calc_deprv_counterfactual_paf_graphpaf.R` supplies the counterfactual attributable-fraction helpers and original bar-plot styling used by the R Markdown analysis.
4. Disclosure-controlled aggregate/model-derived results are published in `outputs/`; the public scripts consume the relevant tables directly.

See [scripts/README.md](scripts/README.md) and [outputs/README.md](outputs/README.md) for file-level detail.

## Release-formatted survival figure

`outputs/surv_hh_deprv_all_stp_adj.png` was produced for public release after applying LOESS smoothing (span 0.15, 25 fitted points per stratum) and small Gaussian perturbations at the final three time points. The changes affect only the display, not the fitted models. Because the secure code did not set a random seed for the perturbations, the public repository uses an identical copy at `../outputs/surv_hh_deprv_all_stp_adj.png` rather than attempting to recreate it outside SAIL.

## Household-deprivation data-quality limitation

The exposure coding was double-checked against the available source fields and retained as the final analysis specification. The manuscript reports 51,909 children with deprivation count zero and 17,174 with a missing count, compared with 68,981 with profile `None` and 102 with a missing profile. The 15 non-`None` profiles sum to 37,282—the number with at least one observed deprived domain—while profile `None` exceeds count zero by 17,072.

In the implemented derivation, helper values retain domain names for source values coded `Yes`; concatenation removes missing helpers and assigns `None` when all four helpers are missing. Consequently, `m_hh_deprv_dms == "None"` can include observed non-deprivation alongside missing, unlinked, or no-code records. The count derivation separately maps the source `No code` category to zero deprived domains. These features reflect limitations of the available linked Census data and should be considered when interpreting estimates that use `None` or zero as the reference.

## Environment-specific dependencies

The main R Markdown file references SAIL-mounted `S:` and `P:` paths and saves R workspaces during execution. These paths and workspace objects are intentionally not portable.
