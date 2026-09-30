# Released SAIL outputs and variable dictionary

Every analytical output currently stored in this folder is disclosure-controlled and cleared by SAIL for public use and publication. The folder contains no row-level linked data. The catalogue below describes the released files. The integrated variable dictionary is derived from repository code, variable labels, exported-table metadata, and the associated manuscript.

## Output catalogue

### Public plotting inputs

| File | Purpose outside SAIL |
|--|----|
| `bivar_coxph_cpr_all.csv` | Unadjusted model estimates used by both forest-plot scripts |
| `multivar_coxph_cpr_demo.xlsx` | Demography-adjusted estimates; `demo2a` is the count model and `demo2b` the profile model |
| `multivar_coxph_cpr_full.xlsx` | Fully adjusted estimates; `full_2a` is the count model and `full_2b` the profile model |
| `paf_dprv_count.xlsx` | Age-indexed attributable-fraction estimates; sheets `dprv_no_2_non`, `dprv_rdtn_by1`, and `dprv_rdtn_by2` |
| `paf_dprv_dms.xlsx` | Age-indexed attributable-fraction estimates; sheets `dprv_dms_2_non` and `dprv_dms_rmvl` |

### Model summaries, diagnostics, tables, and figures

| File or group | Content |
|--|---|
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
| `surv_hh_deprv_all_stp_adj.png` | Stitched household-deprivation survival/risk curves |

### Key adjusted registration-risk curves

#### Household composition

![Adjusted CPR-registration risk curves by household composition](surv_hh_comp_all_stp_adj.png)

These curves compare model-estimated risk of first CPR registration by the numbers of dependent children and adults in the household across unadjusted, demography-adjusted, and fully adjusted specifications. They make household-structure patterning visible and provide important context for interpreting deprivation-related differences in registration risk.

#### Maternal demographic characteristics

![Adjusted CPR-registration risk curves by maternal demographic characteristics](surv_m_demo_all_stp_adj.png)

These curves compare model-estimated risk of first CPR registration by maternal age, highest qualification, and marital or civil-partnership status across the same adjustment stages. Their persistence or attenuation after adjustment underscores the salience of maternal demographic patterning and contextualizes the study's household-deprivation estimates.

## Variable dictionary

### Naming conventions

| Prefix or suffix | Meaning supported by the code |
|-|---|
| `c_` | Child-level field |
| `m_` | Maternal or maternal-household field |
| `hh` | Household |
| `_flg` | Flag/indicator; the source coding is not assumed unless shown in code |
| `_cat` | Categorized value |
| `_date`, `_wob` | Date or week-of-birth field; secure only |
| `_n` | Count |
| `_pe` | Encrypted/anonymized linkage field; secure only |

### Analysis outcome and follow-up

| Variable | Definition or derivation | Values/units evidenced in the repository |
|--|---|--|
| `c_cpr_evnt` | Numeric CPR-event indicator derived from the harmonized register flag | `1` for `True`; `0` for `False` |
| `c_frst_cpr` | Logical indicator that the child's first observed endpoint was CPR registration | `TRUE`/`FALSE` |
| `c_frst_evnt_cat` | First endpoint category used to define follow-up | `CPR`, `Death`, `Study End` |
| `c_age_1st_evnt` | Time from birth to first observed CPR registration, death, or administrative end, according to `c_frst_evnt_cat` | Years |
| `c_dth_age_yrs` | Age at recorded death | Years |
| `c_stdy_end_age_yrs` | Age at 31 May 2021 | Years |
| `c_CHILD_PROTECTION_REGISTER` | Harmonized source register flag before event-variable renaming | `True`/`False`; missing values are set to `False` in the current code |

For CRCS records, a registration start date is available. Some earlier CINW events use the annual collection date when no precise registration date is present; therefore `c_age_1st_evnt` can represent first annual observation rather than exact registration onset.

### Household-deprivation exposures

| Variable | Definition or derivation | Values |
|-|---|---|
| `m_hh_deprv_no` | Count derived from the 2011 Census `DEPRIVED` field across education, employment, health/disability, and housing domains | Factor `0`–`4`; current code maps `No code` to `0` |
| `m_hh_deprv_dms` | Concatenated names of domains coded as deprived in `DEPEDHUK11`, `DEPEMHUK11`, `DEPHDHUK11`, and `DEPHSHUK11` | `None` plus 15 non-empty combinations of `education`, `employment`, `health`, and `housing` |
| `hh_edu_dprvd` | Temporary helper for household education deprivation | `education` when the source contains `Yes`; otherwise missing under current code |
| `hh_emp_dprvd` | Temporary helper for household employment deprivation | `employment` when the source contains `Yes`; otherwise missing under current code |
| `hh_hlt_dprvd` | Temporary helper for household health/disability deprivation | `health` when the source contains `Yes`; otherwise missing under current code |
| `hh_hous_dprvd` | Temporary helper for household housing deprivation | `housing` when the source contains `Yes`; otherwise missing under current code |

The count and profile are used in separate models because the count is determined by the domain configuration.

### Adjustment and descriptive variables

| Variable | Supported meaning/derivation | Coded values or notes |
|-|---|---|
| `c_brth_yr_cat` | Child year of birth | Factor derived from `c_wob`; analytic window 2010–2012 |
| `c_sex` | Child sex | Released levels `M`, `F`; four records in an unusable/sparse category were excluded |
| `c_ethn` | Child ethnicity collapsed from birth-record ethnicity | `White`, `Asian`, `Black`, `Mixed`, `Other`, `Unknown` |
| `c_cgm` | Child congenital-anomaly flag | Released levels `No`, `Yes` |
| `c_ptb` | Child preterm-birth flag | Released levels `No`, `Yes` |
| `c_bw` | Child birth-weight category | `Low` below 2500, `Normal` from 2500 to below 4000, `Heavy` at 4000 or above; the stored unit is not documented here |
| `m_age` | Maternal age at the child's birth | Years, calculated from maternal and child birth dates |
| `m_age_cat` | Maternal age at birth category | `16-17`, `18-19`, `20-24`, `25-29`, `30plus`; births to mothers under 16 are excluded |
| `m_ethnic` | Maternal ethnicity from Census field `AETHPUK11` | Source categories retained/reordered; `No code required` is converted to missing |
| `m_edu` | Maternal highest qualification from `HLQPUK11` | `Level 4`, `Level 3`, `Apprenticeship`, `Level 2`, `Level 1`, `Others`, `None`; `No qualifications` and `Not applicable` become `None` |
| `m_hh_child_depndt` | Number of dependent children in the Census family, from `DPCFAMUK11` | `0`, `1`, `2`, `3+`; current code maps `No code` to `0` |
| `m_hh_adult` | Number of adults in the Census household, from `ADTHUK11` | `0/1`, `2`, `3+`; `2` is the reference |
| `m_mar_status` | Maternal marital/civil-partnership status from `MARSTAT` with shortened labels | `Married` is the reference; code explicitly shortens same-sex, separated, single, and widowed labels |
| `m_fam_status` | Child-family status from `CFSPUK11` with label prefixes/suffixes removed | Observed exported categories include married/cohabiting couple, lone parent, same-sex civil partnership, no children, and communal establishment; `No code required` becomes missing |
| `m_uk_stay_len` | Length of UK residence from `LRESPUK11` | `UK-born`, `10+ yrs`, `5 - <10 yrs`, `<5 yrs`; `No code required` becomes missing |
| `m_twns2011` | Maternal Townsend 2011 deprivation quintile | Reversed in the final analysis so labels run from least to most deprived |
| `m_alc` | Timing of a recorded maternal alcohol problem relative to pregnancy | `never`, `pre-pregnancy`, `pregnancy` |
| `m_lrn` | Maternal learning-difficulty/disability flag | Released levels `No`, `Yes` |
| `m_mnt` | Timing of a recorded maternal mental-health problem relative to pregnancy | `never`, `pre-pregnancy`, `pregnancy` |
| `m_htn` | Timing of recorded maternal hypertension relative to pregnancy | `never`, `pre-pregnancy`, `pregnancy`; described but not included in the fully adjusted model list |
| `m_sbm` | Timing of recorded maternal substance use relative to pregnancy | `never`, `pre-pregnancy`, `pregnancy` |
| `m_smk` | Harmonized maternal smoking status | `Non`, `Ex`, `Smk`, `Unknown` |

**m_edu** (renamed from `Highest qualification, HLQPUK11`), describes the substantive attainment categories that represent the highest educational qualification reported rather than years of schooling. In broad terms, `Level 1` covers lower secondary or foundation qualifications (for example, one to four GCSEs or equivalent); `Level 2` covers five or more GCSE passes at the former A*–C standard or equivalent intermediate vocational qualifications; `apprenticeship` identifies a recognised apprenticeship; `Level 3` covers advanced secondary qualifications such as two or more A levels or equivalent; and `Level 4 or above` covers degree-level, higher-degree and professional qualifications. `Other` includes vocational or work-related qualifications and qualifications gained outside the UK whose level was not stated or could not be assigned to the standard hierarchy. These categories are UK-specific equivalence groupings and should not be read as direct international schooling-year equivalents. Detailed mappings are available from the Office for National Statistics (ONS).

### Model roles

| Stage | Variables |
|-|---|
| Unadjusted | One deprivation exposure only (`m_hh_deprv_no` or `m_hh_deprv_dms`) |
| Demography adjusted | `c_sex`, `c_ethn`, `m_age_cat`, `m_edu`, `m_hh_child_depndt`, `m_hh_adult`, `m_mar_status`, and one deprivation exposure |
| Fully adjusted | Demography-adjusted set plus `c_cgm`, `c_ptb`, `c_bw`, `m_alc`, `m_lrn`, `m_mnt`, `m_sbm`, and `m_smk` |

The `a` models (`demo2a`, `full_2a`) use deprivation count. The `b` models (`demo2b`, `full_2b`) use deprivation profile. Model adjustment is not a causal decomposition; some adjusted variables may lie on pathways from disadvantage to registration.

### Upstream secure cohort fields

The reconstructed `sail_sdc/scripts/5a - make cohort and events.R` selects the following fields into `d_cohort_clean.qs`. These are secure-only. Definitions below are limited to the code's aliases and comments; consult the authoritative SAIL/source data dictionaries for code sets and precise operational definitions.

#### Linkage, birth, and maternal baseline fields

| Variable | Code-supported description                                                  |
|-|-----------------------------------------------------------------------------|
| `c_alf_pe` | Encrypted/anonymized child linkage field                                    |
| `c_alf_sts_cd` | Child linkage status code; code set not included                            |
| `c_wob` | Child week/date of birth, renamed from `wob_cb`                             |
| `c_stillbirth_flg` | Stillbirth flag                                                             |
| `c_sex` | Child sex, renamed from `sex_cb`                                            |
| `c_ethnicity_nm` | Child ethnicity name from the birth source                                  |
| `c_birth_weight` | Recorded child birth weight                                                 |
| `c_gest_age` | Recorded gestational age                                                    |
| `c_preterm_birth_flg` | Preterm birth flag                                                          |
| `c_apgar_score` | Recorded Apgar score                                                        |
| `labour_onset_nm` | Labour onset source category; code set not included                         |
| `delivery_nm` | Delivery source category; code set not included                             |
| `welsh_birth_flg` | Welsh birth flag                                                            |
| `has_m` | Indicator of a linked/available mother record                               |
| `m_alf_pe` | Encrypted/anonymized maternal linkage field                                 |
| `m_alf_sts_cd` | Maternal linkage status code; code set not included                         |
| `m_wob` | Maternal week/date of birth                                                 |
| `m_multiple_gestation_flg` | Multiple gestation flag                                                     |
| `m_prev_livebirths` | Number of previous live births                                              |
| `m_parity` | Recorded maternal parity                                                    |
| `m_breast_feeding_flg` | Breastfeeding flag                                                          |
| `m_smoking_cat` | Source smoking category before harmonization                                |
| `m_lsoa2011_cd` | Maternal 2011 LSOA code; potentially identifying geography and never public |
| `m_wimd2014_decile` | Maternal WIMD 2014 decile                                                   |
| `m_wimd2019_decile` | Maternal WIMD 2019 decile                                                   |
| `m_townsend2011_quintile` | Maternal Townsend 2011 quintile                                             |
| `m_birth_country_nm` | Maternal birth country name                                                 |
| `f_birth_country_nm` | Paternal birth country name                                                 |
| `m_death_date` | Maternal death date                                                         |

#### Household fields

| Variable | Code-supported description |
|-|---|
| `m_ralf_pe` | Encrypted/anonymized residential-linkage field, renamed from `ralf_pe` |
| `m_hh_n` | Household size/count, renamed from `household_n` |
| `m_hh_age_min` | Minimum recorded household age |
| `m_hh_age_avg` | Average recorded household age |
| `m_hh_age_max` | Maximum recorded household age |
| `m_hh_child_n` | Number of children in the household |
| `m_hh_adult_n` | Number of adults in the household |
| `m_hh_adult_male_18_59_n` | Count of male adults aged 18–59 |
| `m_hh_adult_male_60_pl_n` | Count of male adults aged 60 or older |
| `m_hh_adult_female_18_59_n` | Count of female adults aged 18–59 |
| `m_hh_adult_female_60_pl_n` | Count of female adults aged 60 or older |

#### Maternal and child health fields

| Variable | Code-supported description                                              |
|--|-------------------------------------------------------------------------|
| `m_gp_flg` | Maternal general practice coverage/record flag                          |
| `m_gp_reg_end_date` | Maternal GP registration end date                                       |
| `m_gp_first_att_date` | Maternal first GP attendance date                                       |
| `m_gp_att_n` | Maternal GP attendance count                                            |
| `m_alc_flg`, `m_alc_cat`, `m_alc_date` | Maternal alcohol problem flag, source category, and date                |
| `m_htn_flg`, `m_htn_cat`, `m_htn_date` | Maternal hypertension flag, source category, and date                   |
| `m_lrn_flg`, `m_lrn_cat`, `m_lrn_date` | Maternal learning-difficulty/disability flag, source category, and date |
| `m_mnt_flg`, `m_mnt_cat`, `m_mnt_date` | Maternal mental health flag, source category, and date                  |
| `m_smk_flg`, `m_smk_cat`, `m_smk_date` | Maternal smoking flag, source category, and date                        |
| `m_sbm_flg`, `m_sbm_cat`, `m_sbm_date` | Maternal substance use flag, source category, and date                  |
| `c_gp_flg` | Child general practice coverage/record flag                             |
| `c_gp_reg_end_date` | Child GP registration end date                                          |
| `c_gp_first_att_date` | Child first GP attendance date                                          |
| `c_gp_att_n` | Child GP attendance count                                               |
| `c_cgm_flg`, `c_cgm_cat`, `c_cgm_date` | Child congenital anomaly flag, source category, and date                |

### Exported table fields

#### Cox model inputs to the forest plots

| Field | Meaning |
|-|---|
| `Exposure` | Display label for the bivariate exposure |
| `group` / `variable` | Analysis-variable name |
| `Parameter` | Encoded model parameter/level identifier |
| `label` | Human-readable factor level in multivariable workbooks |
| `Coefficient` | Exponentiated Cox coefficient (HR/aHR) |
| `SE` | Standard error reported by the model table |
| `CI` | Confidence level or formatted interval field, depending on source table |
| `CI_low`, `CI_high` | Numeric lower and upper 95% confidence limits |
| `z` | Cox-model z statistic where exported |
| `p` | Model p value; reference rows can be missing |
| `frq` | Cohort frequency in the bivariate export |
| `n_perc` | Formatted count and percentage in multivariable exports |
| `sig` | Significance annotation in the bivariate export |

#### Attributable fraction workbooks

| Field | Meaning                                                                               |
|--|---------------------------------------------------------------------------------------|
| `adj_lvl` | Adjustment stage                                                                      |
| `variable` | Exposure variable (`m_hh_deprv_no` or `m_hh_deprv_dms`)                               |
| `level_from`, `level_to` | Observed source level and counterfactual destination level                            |
| `excluded_levels` | Levels excluded from a scenario, if any                                               |
| `removed_dimension` | Named domain removed in a domain removal scenario                                     |
| `dprv_rdctn_no` | Requested numerical reduction in deprivation count                                    |
| `deprivation_count_from`, `deprivation_count_to` | Numeric source and destination counts                                                 |
| `scenario` | Readable transition such as `3 -> 2` or `employment+health -> health`                 |
| `Time` | Follow-up age/time in years; public figures filter to `6`                             |
| `Estimated_PAF` | Model-based population attributable fraction stored as a proportion, not a percentage |
| `CI` | Formatted confidence interval text                                                    |
| `conf.low`, `conf.high` | Numeric lower and upper 95% interval bounds                                           |

The public plot multiplies `Estimated_PAF`, `conf.low`, and `conf.high` by 100. Each displayed scenario reassigns only its named source category while leaving other exposure categories unchanged. The resulting PAF is the model-estimated relative change in age-six CPR risk between the observed data and that counterfactual dataset. A positive 5% value indicates approximately 5% lower predicted risk under the named reassignment; a negative value indicates higher predicted risk. It is a conditional model summary, not an observed intervention effect or a percentage of registrations demonstrated to be preventable.

#### Public forest plotting datasets

| Field | Meaning |
|-|---|
| `model` | Unadjusted, demography-adjusted, or fully adjusted stage |
| `level` | Deprivation count or exact domain profile |
| `hr`, `ci_low`, `ci_high` | HR/aHR and numeric 95% confidence limits |
| `p`, `p_group` | Numeric p value and shape-display group |
| `n`, `n_perc` | Available count or formatted count/percentage from source tables |
| `hr_ci` | Formatted HR/aHR and interval label |
| `y_base`, `y_offset`, `y_plot` | Plotting positions for stacked model estimates |
| `level_label` | Human-readable level annotation retained for auditability |
| `deprv_dms` | Number of named deprived domains in a profile; profile plot only |

### Household deprivation data quality limitation

The household-deprivation coding was double-checked against the available linked Census fields and retained as the final analysis specification. A source-data limitation remains: the manuscript's descriptive table reports 51,909 children with deprivation count zero and 17,174 with a missing count, compared with 68,981 with profile `None` and 102 with a missing profile. The 15 non-`None` profiles sum to 37,282—the number with at least one observed deprived domain—while profile `None` exceeds count zero by 17,072.

In the implemented derivation, each helper retains a domain name for source values coded `Yes`; other values yield missing helpers. Concatenation removes missing helpers and assigns `None` when all four helpers are missing. Consequently, `m_hh_deprv_dms == "None"` can include observed non-deprivation alongside missing, unlinked, or no-code records. The count derivation separately maps the source `No code` category to zero deprived domains. These operational categories reflect limitations of the available linked data and should be considered when interpreting estimates that use `None` or zero as the reference.
