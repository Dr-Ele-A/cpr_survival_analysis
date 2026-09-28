# Secure output staging and release allowlist

This folder is the output area for SAIL-only analysis. Most files are local secure-environment artefacts and are ignored by Git. A small set of aggregate/model-derived tables prepared for disclosure-controlled export is allowlisted because the public plotting scripts require it.

Version-control inclusion does not replace formal disclosure-control approval. Confirm the release status of each allowlisted file before pushing the repository.

## Public plotting inputs allowlisted by `.gitignore`

| File | Purpose outside SAIL | SHA-256 | Approval recorded here? |
|---|---|---|---|
| `bivar_coxph_cpr_all.csv` | Unadjusted model estimates used by both forest-plot scripts | `6B1A6CBD0AB3C8C3F39FBA4BD27DB62BE7387D62715E0C5434C3B3CF4F6ECE44` | No—confirm before publication |
| `multivar_coxph_cpr_demo.xlsx` | Demography-adjusted estimates; `demo2a` is the count model and `demo2b` the profile model | `863CAE2D91C276CF8003574AEB708DAA37CFA6E1FBE2AD1202A1C54E1F3EF7F0` | No—confirm before publication |
| `multivar_coxph_cpr_full.xlsx` | Fully adjusted estimates; `full_2a` is the count model and `full_2b` the profile model | `FE496F6C7D292EFB321F38D6BC5FFBB4A6BB764054CC607C77248D74E1C1D951` | No—confirm before publication |
| `paf_dprv_count.xlsx` | Age-indexed attributable-fraction estimates; sheets `dprv_no_2_non`, `dprv_rdtn_by1`, and `dprv_rdtn_by2` | `A64E862F17AC6FECDD01BD9F85419498084EDE7885C667F033CC96D1FF94D818` | No—confirm before publication |
| `paf_dprv_dms.xlsx` | Age-indexed attributable-fraction estimates; sheets `dprv_dms_2_non` and `dprv_dms_rmvl` | `C985FA09F8B8814C0B9661C10579B0DDCAFA91DC3EC1E8B7185AE47F2F7A4829` | No—confirm before publication |

These files contain no encrypted linkage identifiers in their current exported schemas. Their fields are documented in [../../docs/variable_dictionary.md](../../docs/variable_dictionary.md#exported-table-fields). The hashes describe the files inspected on 28 September 2026; update the row and repeat disclosure review if an input changes.

## Other current secure outputs (ignored by default)

| File or group | Content |
|---|---|
| `bivar_coxph_cpr_perf.csv` | Bivariate-model performance summaries |
| `multivar_coxph_cpr_demo_perf.csv` | Demography-adjusted model-performance summaries |
| `multivar_coxph_full_cpr_perf.csv` | Fully adjusted model-performance summaries |
| `bivar_cpr_zph_lvl_tbls.xlsx` | Factor-level proportional-hazards diagnostics for bivariate models |
| `multivar_demo_cpr_zph_tbls.xlsx` | Whole-variable proportional-hazards diagnostics for demography-adjusted models |
| `multivar_demo_cpr_zph_lvl_tbls.xlsx` | Factor-level diagnostics for demography-adjusted models |
| `multivar_full_cpr_zph_tbls.xlsx` | Whole-variable diagnostics for fully adjusted models |
| `multivar_full_cpr_zph_lvl_tbls.xlsx` | Factor-level diagnostics for fully adjusted models |
| `cars_corr_all_plt.csv` and `.png` | Pairwise categorical-association results and heatmap |
| `coxph_bivar_mdl_tbl_all.docx` | Formatted bivariate Cox-model table |
| `coxph_demog_mdl_tbl_all.docx` | Formatted demography-adjusted model table |
| `coxph_full_adj_mdl_tbl_all.docx` | Formatted fully adjusted model table |
| `coxph_mdl_tbl_1_all.docx` | Combined staged model table for deprivation count |
| `coxph_mdl_tbl_3_all.docx` | Combined staged model table for deprivation profiles |
| `cpr_birth_cohort_2010_2012.docx` | Descriptive cohort-characteristics table |
| `zph_demo_demo2a_plts.png`, `zph_demo_demo2b_plts.png` | Demography-adjusted proportional-hazards diagnostic plots |
| `zph_full_2a_plts.png`, `zph_full_2b_plts.png` | Fully adjusted proportional-hazards diagnostic plots |
| `surv_c_demo_all_stp_adj.png` | Stitched child-demographic survival/risk curves |
| `surv_m_demo_all_stp_adj.png` | Stitched maternal-demographic survival/risk curves |
| `surv_hh_comp_all_stp_adj.png` | Stitched household-composition survival/risk curves |
| `surv_hh_deprv_all_stp_adj.png` | Stitched household-deprivation survival/risk curves; current candidate public copy is byte-identical (SHA-256 `A10394B16127FA2DE061DBC6674FC180B6BD1EB5DCD28E18A8963097D69D99CB`); approval reference not recorded here |

Do not unignore these files as a group. Add a file to the public repository only after confirming that it is necessary, disclosure-controlled, documented, and free of person-level or sensitive metadata.
