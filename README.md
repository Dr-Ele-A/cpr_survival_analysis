# Household Socioeconomic Circumstances and Age of First Registration on the Welsh Child Protection Register: A Survival Analysis Using Linked Administrative and Census Data

This repository documents a population-based survival analysis of household deprivation and the timing of first observed registration on the Welsh Child Protection Register (CPR). It separates code that must run inside the Secure Anonymised Information Linkage (SAIL) trusted research environment from public plotting code that uses only aggregate or model-derived exports prepared for disclosure review.

> [!IMPORTANT]
> Before public release, verify the source coding used by both deprivation measures in SAIL. The current profile code can classify records with missing or no-code values across all four source domains as `None`; this is not necessarily equivalent to observed non-deprivation and may affect profile-based hazard ratios, impact fractions, and lower survival panels. The count code also maps `No code` to zero, which must be confirmed as substantively correct. Until this review is complete, treat all headline estimates as provisional, with the profile outputs most directly implicated. See [Variable dictionary and analysis notes](docs/variable_dictionary.md#analysis-definition-requiring-review).

## Key outputs

### Hazard ratios by household-deprivation profile

![Forest plot of hazard ratios for combinations of household deprivation domains across unadjusted, demography-adjusted, and fully adjusted models](outputs/forestplot_m_hh_deprv_dms_adjustment_stack.png)

Points show hazard ratios (HRs) or adjusted hazard ratios (aHRs); horizontal intervals show 95% confidence intervals. The public forest-plot script uses the same colour mapping as the population impact-fraction figures.

### Registration-risk trajectories by deprivation count and profile

![Six-panel cumulative-risk display for first observed CPR registration by deprivation count and deprivation-domain profile](outputs/surv_hh_deprv_all_stp_adj.png)

This is a byte-identical copy of the release-formatted figure produced in SAIL. The curves were smoothed for disclosure control and include small tail perturbations applied to the display only. They are not competing-risk cumulative-incidence estimates, and the adjusted panels are conditional model predictions rather than population-standardized risks. The secure original is not used as a GitHub image dependency.

## Extended abstract

**Background and objective.** Socioeconomic inequalities are consistently observed in statutory child-protection activity, but area-level measures may conceal household circumstances relevant to families. Child Protection Register (CPR) registration is an administrative response shaped by family need, referral, assessment, professional judgement, service capacity, and recording; it is not a direct measure of maltreatment onset or prevalence. This study examined household deprivation breadth and composition in relation to age at first observed CPR registration in Wales, supplemented by risk trajectories and specified deprivation-reduction scenarios.

**Methods.** This population-based linked administrative-data cohort comprised 106,365 eligible live births in Wales from 1 January 2010 to 31 December 2012. Children were followed from birth until first observed CPR registration, death, or 31 May 2021. Records were linked through Child Wellbeing: The Cohort for Health within the Secure Anonymised Information Linkage Databank. Maternal 2011 Census household circumstances were represented by a count of four deprivation domains—education, employment, health and disability, and housing—and by their recorded combinations. Cox models used child age as the time scale and estimated hazard ratios across exposure-only, demography-adjusted, and fully adjusted stages. Risk curves, Schoenfeld-residual diagnostics, and directly standardized age-six population attributable fractions supplemented the hazard ratios. Fully adjusted analyses included 89,177 complete cases. Analysis was conducted in R within the trusted research environment; only aggregate and model-derived outputs intended for disclosure-controlled release were exported.

**Results.** There were 2,158 first observed registrations (2.03%). Among 89,191 children with a deprivation count, 37,282 (41.80%) experienced at least one deprived domain. Relative to no recorded deprived domains, fully adjusted hazard ratios rose from 1.88 (95% confidence interval 1.60–2.22) for one domain to 2.60 (2.18–3.11), 3.42 (2.78–4.21), and 4.04 (2.75–5.94) for two, three, and four domains. The employment-plus-health profile had a fully adjusted hazard ratio of 3.39 (2.72–4.21), comparable to or greater than several three-domain profiles. Risk curves separated early and generally widened across childhood. Scenario analyses gave greater population impact to common one- and two-domain groups than to the rare four-domain group, illustrating that population impact depends on prevalence as well as relative association. Proportional-hazards tests indicated time variation in selected associations, so some hazard ratios are follow-up-weighted summaries rather than age-constant effects. Estimates remain provisional pending the deprivation source-code review described above.

**Interpretation.** Household deprivation breadth and composition were associated with first observed CPR registration after adjustment. Strengths were the large linked cohort, household-level measurement, parallel count and profile analyses, and complementary diagnostics. Limitations included a single Census snapshot not uniformly pre-birth, administrative outcome ascertainment, complete-case selection, residual confounding, possible mediator adjustment, censored deaths and incomplete capture after migration, sparse profiles, and provisional 100-repetition bootstrap intervals. Release-formatted curves are not competing-risk cumulative-incidence estimates; attributable fractions are model-based scenario summaries, not demonstrated preventable proportions. Findings support attention to material circumstances and coordinated family assistance without deterministic use of deprivation in individual child-protection decisions.

## Study overview

- **Design:** population-based linked administrative-data cohort.
- **Population:** 106,365 eligible live births in Wales during 2010–2012.
- **Follow-up:** birth to first observed CPR registration, death, or 31 May 2021.
- **Primary exposures:** maternal household deprivation count (zero to four domains) and the recorded combination of education, employment, health/disability, and housing deprivation.
- **Outcome:** first observed CPR registration for any recorded reason.
- **Analysis:** Cox proportional-hazards models with child age as the time scale; staged adjustment; risk curves; proportional-hazards diagnostics; and age-six scenario-specific population attributable fractions (PAFs).

The outcome reflects recorded statutory activity, not the onset or prevalence of child maltreatment. The analyses are observational. Adjustment stages describe conditional associations and are not a causal decomposition.

Here, a PAF is the model-estimated relative change from observed age-six CPR risk to risk under one stated counterfactual reassignment—for example, moving a specified deprivation-count category to a lower category while leaving other categories unchanged. A positive 5% estimate means the model predicts approximately 5% lower age-six risk under that scenario than under the observed exposure distribution; a negative estimate means higher predicted risk. These conditional scenario contrasts are not observed intervention effects or percentages of registrations proven preventable.

## Secure-to-public workflow

| Stage | Location | What happens | Public reproducibility boundary |
|---|---|---|---|
| Linked-data preparation and modelling | `sail_sdc/scripts/` | Cohort construction, Census linkage, variable derivation, Cox models, diagnostics, impact fractions, and survival curves | Requires approved access to individual-level linked data in SAIL; cannot be reproduced from this repository alone |
| Disclosure-control staging | `sail_sdc/outputs/` | Aggregate tables, model summaries, diagnostics, and candidate release figures are prepared for review | The repository allowlists only the five aggregate/model-output tables needed by public plotting scripts; allowlisting does not record approval |
| Public figure generation | `scripts/` | Allowlisted aggregate/model tables are converted into forest plots and attributable-fraction figures | Reproducible outside SAIL with R after the tables are approved for release |
| Public deliverables | `outputs/` | PNG/PDF figures and auditable plotting datasets | Suitable for repository display only after release approval is confirmed |

Individual-level data, linkage identifiers, dates, small-cell working tables, and R workspace images must not be copied into the public workflow. The `.gitignore` applies a deny-by-default rule to `sail_sdc/outputs/` and common row-level data formats.

## Repository structure

```text
.
├── README.md
├── cpr_survival_analysis.Rproj
├── docs/
│   └── variable_dictionary.md
├── outputs/
│   └── README.md
├── scripts/
│   ├── README.md
│   ├── forestplot_m_hh_deprv_dms.R
│   ├── forestplot_m_hh_deprv_no.R
│   └── plot_paf_from_sdc_tables.R
└── sail_sdc/
    ├── README.md
    ├── scripts/
    │   └── README.md
    └── outputs/
        └── README.md
```

See the folder READMEs for file-level inputs, outputs, and execution constraints. The [variable dictionary](docs/variable_dictionary.md) documents analysis variables and exported-table fields using only definitions supported by the code, manuscript, labels, or observed metadata.

## Reproducing public figures

From the repository root, run:

```text
Rscript scripts/plot_paf_from_sdc_tables.R
Rscript scripts/forestplot_m_hh_deprv_no.R
Rscript scripts/forestplot_m_hh_deprv_dms.R
```

The scripts locate the project root from their own file path. They can therefore be launched from another working directory when the command supplies an absolute or otherwise valid path to the script.

Required public packages are `tidyverse`, `readxl`, `patchwork`, and their dependencies. The plotting scripts were validated with R 4.5.1, tidyverse 2.0.0, readxl 1.4.5, ggplot2 3.5.2, patchwork 1.3.2, and scales 1.4.0. Package versions are not currently locked; consult the generated session-information files when exact rendering differences matter.

The public PAF script reads the two aggregate workbooks at `sail_sdc/outputs/paf_dprv_count.xlsx` (sheets `dprv_no_2_non`, `dprv_rdtn_by1`, and `dprv_rdtn_by2`) and `sail_sdc/outputs/paf_dprv_dms.xlsx` (sheets `dprv_dms_2_non` and `dprv_dms_rmvl`). It does not require `graphPAF` or individual-level data. The forest scripts read the supplied bivariate and multivariable model tables in the same directory. Current input hashes and unconfirmed approval status are recorded in [sail_sdc/outputs/README.md](sail_sdc/outputs/README.md). See [scripts/README.md](scripts/README.md) for the complete file contract.

## Data access, disclosure control, and responsible use

Individual-level linked data are held in the SAIL Databank and are not publicly available. Access requires the relevant information-governance and project approvals. This repository does not provide, and must not be used to reconstruct, person-level data.

Only disclosure-controlled aggregate or model-derived material should be exported from SAIL. A file's presence in a local `sail_sdc/outputs/` directory does not by itself establish approval for public release. Before publishing the repository, confirm the release status of every allowlisted table and public figure with the responsible SAIL review process.

The deprivation measures have not been validated here for individual prediction. They should not be used as deterministic labels or to intensify surveillance of families. Scenario-specific impact fractions are conditional, model-based contrasts; they are not percentages of registrations guaranteed to be prevented by an intervention.

## Citation, licence, and project metadata

The repository is journal-independent. A final citation, author list, persistent identifier, funding statement, ethics/information-governance reference, contact details, and software licence have not been supplied and are therefore not invented here. Add approved metadata before public release. In the absence of a licence file, no permission to reuse the code or outputs should be assumed.
