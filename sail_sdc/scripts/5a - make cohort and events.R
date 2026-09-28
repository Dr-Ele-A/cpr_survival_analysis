# Reconstructed from the dedicated video:
#   5a - make cohort and events_r.mp4

# source("r_clear_and_load.r")
rm(list=setdiff(ls(), "conn")); gc()

# Load data ====================================================================
cat("Load data\n")

# "data/d_child_birth_clean.qs" was obtained from the script "1b - create sb_child_birth.sql", after some processing in r
d_cb <-
    qread("data/d_child_birth_clean.qs") %>%
    select(-starts_with("mis")) %>%
    rename(
        sex_cb = sex,
        wob_cb = wob
    )

# "data/d_child_looked_after_clean_wide.qs" was obtained from the scripts "2a - create sb_lacw_child.sql", "2b - create sb_lacw_episode.sql" and "2c - boost lacw linkage.sql" after some processing in r
d_cla_wide <-
    qread("data/d_child_looked_after_clean_wide.qs") %>%
    rename(
        sex_cla = sex,
        wob_cla = wob
    ) %>%
    mutate(
        is_cla = 1,
        c_alf_pe = boosted_alf,
        has_lacw_alf = not_na(alf)
    ) %>%
    filter(not_na(c_alf_pe)) %>%
    # due to alf matching only use those looked after from 2006/07 onwards
    filter(last_year_code >= 200607)

d_cla_alf_n <- d_cla_wide %>% count(c_alf_pe, name = "n_alf")

d_cla_wide <-
    d_cla_wide %>%
    left_join(d_cla_alf_n, by = "c_alf_pe") %>%
    filter(n_alf == 1) %>%
    assert(is_uniq, c_alf_pe)

d_cla_wide %>% View

# "data/d_child_mother_health_clean.qs" was obtained from "1e - create sb_mother_health.sql" after some processing in r
d_cmh <- qread("data/d_child_mother_health_clean.qs")

# "data/d_child_health_clean.qs" was obtained from "1c - create sb_child_health.sql" after some processing in r
d_ch <- qread("data/d_child_health_clean.qs") %>%
    rename(
        c_gp_flg            = gp_flg,
        c_gp_reg_end_date   = gp_reg_end_date,
        c_gp_first_att_date = gp_first_att_date,
        c_gp_att_n          = gp_att_n,
        c_cgm_flg           = cgm_flg,
        c_cgm_cat           = cgm_cat,
        c_cgm_date          = cgm_date
        # c_dvd_flg         = dev_delay_flg,
        # c_dvd_cat         = dev_delay_cat,
        # c_dvd_date        = dev_delay_date
    )

# "data/d_mother_household_raw.qs" was obtained using "1f - create sb_mother_household.sql" after some processing in r
d_mhh <- qread("data/d_mother_household_raw.qs") %>%
    select(
        m_alf_pe                    = alf_pe,
        wob                         = c_wob,
        m_ralf_pe                   = ralf_pe,
        m_hh_n                      = household_n,
        m_hh_age_min                = household_age_min,
        m_hh_age_avg                = household_age_avg,
        m_hh_age_max                = household_age_max,
        m_hh_child_n                = child_n,
        m_hh_adult_n                = adult_n,
        m_hh_adult_male_18_59_n     = adult_male_18_59_n,
        m_hh_adult_male_60_pl_n     = adult_male_60_pl_n,
        m_hh_adult_female_18_59_n   = adult_female_18_59_n,
        m_hh_adult_female_60_pl_n   = adult_female_60_pl_n
    )

# Join =========================================================================
cat("Join\n")

nrow_cb <- nrow(d_cb)

d_cohort <-
    d_cb %>%
    left_join(d_cla_wide, by = "c_alf_pe") %>%
    left_join(d_ch, by = "c_alf_pe") %>%
    left_join(d_cmh, by = c("c_alf_pe", "m_alf_pe")) %>%
    left_join(d_mhh, by = c("m_alf_pe", "wob")) %>%
    mutate(
        is_cla = replace_na(is_cla, 0),
        is_cla_cat = factor(is_cla, 0:1, c("Not looked after in 2016-2018", "Looked after in 2016-2018"))
    ) %>%
    verify(nrow(.) == nrow_cb)

# Select columns ===============================================================
cat("Select columns\n")

d_cohort <-
    d_cohort %>%
    select(
        # child birth-related measures
        c_alf_pe,
        c_alf_sts_cd,
        c_wob                  = wob_cb,
        c_stillbirth_flg       = stillbirth_flg,
        c_sex                  = sex_cb,
        c_ethnicity_nm         = ethnicity_nm,
        c_birth_weight         = birth_weight,
        c_gest_age             = gestational_age,
        c_preterm_birth_flg    = preterm_birth_flg,
        c_apgar_score          = apgar_score,
        # the birth
        labour_onset_nm,
        delivery_nm,
        welsh_birth_flg,
        # mother birth-related measures
        has_m,
        m_alf_pe,
        m_alf_sts_cd,
        m_wob,
        m_multiple_gestation_flg,
        m_prev_livebirths,
        m_parity,
        m_breast_feeding_flg,
        m_smoking_cat,
        m_lsoa2011_cd,
        m_wimd2014_decile,
        m_wimd2019_decile,
        m_townsend2011_quintile,
        m_birth_country_nm,
        f_birth_country_nm,
        m_death_date,
        # mother household measures
        m_ralf_pe,
        m_hh_n,
        m_hh_age_min,
        m_hh_age_avg,
        m_hh_age_max,
        m_hh_child_n,
        m_hh_adult_n,
        m_hh_adult_male_18_59_n,
        m_hh_adult_male_60_pl_n,
        m_hh_adult_female_18_59_n,
        m_hh_adult_female_60_pl_n,
        # mother health-related measures prior to birth
        m_gp_flg,
        m_gp_reg_end_date,
        m_gp_first_att_date,
        m_gp_att_n,
        m_alc_flg,
        m_alc_cat,
        m_alc_date,
        m_htn_flg,
        m_htn_cat,
        m_htn_date,
        m_lrn_flg,
        m_lrn_cat,
        m_lrn_date,
        m_mnt_flg,
        m_mnt_cat,
        m_mnt_date,
        m_smk_flg,
        m_smk_cat,
        m_smk_date,
        m_sbm_flg,
        m_sbm_cat,
        m_sbm_date,
        # child health
        c_gp_flg,
        c_gp_reg_end_date,
        c_gp_first_att_date,
        c_gp_att_n,
        c_cgm_flg,
        c_cgm_cat,
        c_cgm_date,
        # c_dvd_flg,
        # c_dvd_cat,
        # c_dvd_date,
        # child looked after summaries
        c_lac_first_start_date        = first_start_date,
        c_lac_first_start_reason_code = first_start_reason_code,
        c_lac_first_start_reason_cat  = first_start_reason_cat,
        c_lac_first_legal_status      = first_legal_status,
        c_lac_first_placement         = first_placement,
        c_lac_first_end_date          = first_end_date,
        c_lac_first_end_reason_code   = first_end_reason_code,
        c_lac_first_end_reason_cat    = first_end_reason_cat,
        c_lac_any_short_term          = any_short_term,
        # child death
        c_death_date,
        c_death_neonatal_flg,
        c_death_birth_asphyxia_flg,
        c_death_short_gestation_flg,
        c_death_sids_flg,
        c_death_diag_1_cd,
        # child residence
        c_residence_start_date,
        c_residence_end_date_1day,
        c_residence_end_date_28day
    )

# Save =========================================================================
cat("Save\n")

qsave(d_cohort, "data/d_cohort_clean.qs")

beep()
