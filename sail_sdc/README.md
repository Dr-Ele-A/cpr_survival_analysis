# Secure SAIL workflow

`sail_sdc/` contains the part of the analysis designed for the SAIL trusted research environment. The code depends on approved access to linked individual-level health, mortality, Census, household, and social-care records. It is retained to make the analytical workflow inspectable, but it is not a public-data pipeline and cannot be rerun from a repository clone alone.

## Boundary rules

1. Run cohort construction, linkage, recoding, modelling, diagnostics, and disclosure-control preparation only in the approved secure environment.
2. Never commit row-level data, linkage identifiers, dates, geography, R workspace images, database extracts, or unscreened result tables.
3. Treat `sail_sdc/outputs/` as secure staging. Export a file only after the applicable disclosure-control review.
4. Use the public scripts in `../scripts/` only with reviewed aggregate/model-derived tables.
5. Keep the secure original and candidate public copy of a reviewed figure byte-identical unless a replacement is reviewed.

The repository `.gitignore` denies all files in `sail_sdc/outputs/` by default and then allowlists only the five tabular inputs needed to reproduce the public PAF and forest figures, plus the folder README. This configuration is a safeguard, not evidence that a file has current release approval.

## Workflow summary

1. `scripts/5a - make cohort and events.R` documents an upstream, reconstructed cohort-building step that reads row-level `.qs` objects and writes `data/d_cohort_clean.qs`.
2. `scripts/ea_cpr_reg_surv_sdc_cln_v2.Rmd` builds the analysis cohort, links Census and CPR information, derives variables, fits Cox models, assesses proportional hazards, estimates scenario-specific attributable fractions, and creates release-formatted figures.
3. `scripts/calc_deprv_counterfactual_paf_graphpaf.R` supplies the counterfactual impact-fraction helpers and original bar-plot styling used by the R Markdown analysis.
4. Aggregate/model-derived results are staged in `outputs/`; after review, selected tables can be consumed by the public scripts. Their presence or Git allowlisting does not prove approval.

See [scripts/README.md](scripts/README.md) and [outputs/README.md](outputs/README.md) for file-level detail.

## Release-formatted survival figure

`outputs/surv_hh_deprv_all_stp_adj.png` was produced in a release-formatted form after applying LOESS smoothing (span 0.15, 25 fitted points per stratum) and small Gaussian perturbations at the final three time points. The changes affect only the display, not the fitted models. Because the secure code did not set a random seed for the perturbations, the candidate public repository uses a byte-identical copy at `../outputs/surv_hh_deprv_all_stp_adj.png` rather than attempting to recreate it outside SAIL. Both current copies have SHA-256 `A10394B16127FA2DE061DBC6674FC180B6BD1EB5DCD28E18A8963097D69D99CB`.

## Analysis definition requiring review

The current derivation of `m_hh_deprv_dms` assigns a domain label only when the source domain contains `Yes`; ordinary `No`, `No code`, and other unmatched values become missing helper values. Concatenation then strips missing helpers and maps an all-missing result to `None`. In the manuscript table, profile `None` exceeds count zero by 17,072 records, consistent with missing/no-code records entering the profile reference. Separately, the count derivation maps the source `No code` category to zero; the code alone does not establish that this is substantively equivalent to no deprivation.

Review the four source-domain mappings and the count recode in SAIL. Rerun all profile-based outputs and, if the count mapping changes, all count-based models, attributable fractions, survival plots, forest plots, manuscript estimates, and descriptive counts. Do not resolve this discrepancy by relabelling documentation alone.

## Environment-specific dependencies

The main R Markdown file references SAIL-mounted `S:` and `P:` paths and saves R workspaces during execution. These paths and workspace objects are intentionally not portable. The `.RData`, `.Rhistory`, and `.Rproj.user/` files found in the local project are ignored and should not be uploaded.
