library(tidyverse)
library(survey)      # for weighted analyses
library(tableone)    # for checking balance
library(cobalt)      # for Love plots and diagnostics
library(lubridate)
library(splines)
library(survminer)

#Positivity - need a non-zero probability of receiving each treatment - IPTW points here - https://bpb-us-w2.wpmucdn.com/u.osu.edu/dist/e/58955/files/2023/11/Best-practices-IPTW.pdf

##https://ehsanx.github.io/TMLEworkshop/iptw.html#step-3-balance-checking

#Read formatted data
df <- readr::read_csv("output/dataset_formatted_cohort.csv")

#Start with iptw for sex and present of hypertension only then expand

#Set variables

#bmi, ethnicity, imd coming out as messing with completeness with dummy - "latest_ethnicity_group", "imd_decile", "last_bmi"

baseline_vars <- c("sex", "has_diabetes", "harmful_alcohol", "has_had_cancer", "has_chronic_liver_disease", "has_chronic_resp_disease",
"has_dementia", "has_hiv", "has_heart_failure", "has_hemiplegia", "has_multiple_sclerosis", "has_rheumatoid_arthritis", "has_solid_organ_transplant",              
"has_stroke_tia", "has_aaa", "has_ckd", "has_coronary_hd", "has_hypertension", "has_peptic_ulcer", "has_pvd",  "corticosteroid_60d_before_abx",
"drug_linked_to_neuropathy_60d_before_abx")  
                                    
# To think about - "age" - splines. Code below
#"imd_decile" - consider to be a factor but look for evidence that it is linear. Might need to impute as some missing data
#"last_bmi" - group it(?) - this isn't working as currrently don't have bmi sorted
#"never_smoker" -eg work out what to do with smoking - again to do with Rose/Will
#"n_hosp_appt_6m",
#  "year_cohort_prescription" - look at how prescribing changes over time to decide            

#Look at whether age can be used alone or should be modelled with a spline

# Model 1: Age as linear
model_linear <- glm(fluoroquinolone_exp ~ age, data = df, family = binomial)

# Model 2: Age as quadratic polynomial
model_poly <- glm(fluoroquinolone_exp ~ poly(age, 2, raw = TRUE), data = df, family = binomial)

# Model 3: Age as spline (natural spline with 4 degrees of freedom)
model_spline <- glm(fluoroquinolone_exp ~ ns(age, df = 4), data = df, family = binomial)

# Build data frame for predictions
df_preds <- df %>%
  select(age) %>%
  arrange(age) %>%
  distinct() %>%
  mutate(
    # Response scale (predicted probabilities)
    linear_response   = predict(model_linear, newdata = ., type = "response"),
    poly_response     = predict(model_poly, newdata = ., type = "response"),
    spline_response   = predict(model_spline, newdata = ., type = "response"),
    
    # Link scale (log-odds)
    linear_link       = predict(model_linear, newdata = ., type = "link"),
    poly_link         = predict(model_poly, newdata = ., type = "link"),
    spline_link       = predict(model_spline, newdata = ., type = "link")
  )

# Convert to long format for ggplot (includes scale and model)
df_long <- df_preds %>%
  pivot_longer(
    cols = -age,
    names_to = c("model", "scale"),
    names_sep = "_",
    values_to = "predicted_value"
  ) %>%
  mutate(
    model = recode(model,
                   linear = "Linear",
                   poly = "Quadratic",
                   spline = "Spline"),
    scale = recode(scale,
                   response = "Predicted Probability",
                   link = "Logit (Linear Predictor)")
  )

# Plot: compare response vs link scale using facets
age_spline_check <- ggplot(df_long, aes(x = age, y = predicted_value, color = model)) +
  geom_line(size = 1.2) +
  facet_wrap(~ scale, scales = "free_y") +
  labs(title = "Fluoroquinolone Exposure by Age",
       x = "Age", y = "Value",
       color = "Model") +
  theme_minimal()

AIC_table <- tibble(
  Model = c("Linear", "Quadratic", "Spline (ns, df=4)"),
  AIC = c(
    AIC(model_linear),
    AIC(model_poly),
    AIC(model_spline)
  )
)

ggsave(plot = age_spline_check,
filename = "age_spline_check.png",
path = here::here("output/cohort")
)

AIC_table %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/cohort/aictable_agespline.md")

#imd_decile check

imd_decile_roughcheck <- df %>%
group_by(imd_decile) %>%
summarise(p_fq = mean(fluoroquinolone_exp, na.rm = TRUE)) %>%
ggplot(aes (x = imd_decile, y = p_fq)) +
geom_point(size = 3, color = "steelblue") +
scale_x_discrete(drop = FALSE) +
labs(title= "IMD Decile vs Probability of fq exp")

ggsave(plot = imd_decile_roughcheck,
filename = "imd_decile_rough_check.png",
path = here::here("output/cohort")
)

#bmi check
# # Fit logistic regression model
# #bmi_model <- glm(fluoroquinolone_exp ~ last_bmi, data = df, family = binomial())

# # Create a prediction dataframe over the range of observed BMI
# #bmi_range <- data.frame(last_bmi = seq(min(df$last_bmi, na.rm = TRUE),
#                                        max(df$last_bmi, na.rm = TRUE),
#                                        length.out = 100))

# # Get predicted log-odds (type = "link")
# #bmi_range$log_odds <- predict(bmi_model, newdata = bmi_range, type = "link")

# # Plot
# bmi_cont_plot<- ggplot(bmi_range, aes(x = last_bmi, y = log_odds)) +
#   geom_line(color = "darkblue", size = 1) +
#   labs(title = "Log-odds of fluoroquinolone exposure vs BMI",
#        x = "Last BMI",
#        y = "Log-odds (logit)") +
#   theme_minimal()


# # BMI cat now
# bmi_cat_model <- glm(fluoroquinolone_exp ~ bmi_cat, data = df, family = binomial())

# # Create dataframe for prediction
# bmi_cat_levels <- data.frame(bmi_cat = levels(df$bmi_cat))

# # Predict log-odds for each BMI category
# bmi_cat_levels$log_odds <- predict(bmi_cat_model, newdata = bmi_cat_levels, type = "link")

# # Plot
# bmi_cat_plot<- ggplot(bmi_cat_levels, aes(x = bmi_cat, y = log_odds)) +
#   geom_col(fill = "steelblue") +
#   labs(title = "Log-odds of fluoroquinolone exposure by BMI category",
#        x = "BMI Category",
#        y = "Log-odds (logit)") +
#   theme_minimal()

# ggsave(plot = bmi_cont_plot,
# filename = "bmi_cont_check.png",
# path = here::here("output/cohort")
# )

# ggsave(plot = bmi_cat_plot,
# filename = "bmi_cat_check.png",
# path = here::here("output/cohort")
# )

# Fit a basic logistic regression - for n hosp appt in 6m
model_simple <- glm(fluoroquinolone_exp ~ n_hosp_appt_6m,
                    family = binomial(), data = df)

# Predict log-odds (type = "link" gives the linear predictor, i.e. log-odds)
df$log_odds <- predict(model_simple, type = "link")

# Plot
n_hosp_logoddsplot<- ggplot(df, aes(x = n_hosp_appt_6m, y = log_odds)) +
  geom_point(alpha = 0.3, size = 1) +
  geom_smooth(method = "loess", se = FALSE, color = "blue") +
  labs(title = "Log-odds of Fluoroquinolone Treatment vs Hospital Appointments",
       x = "Number of hospital appointments (6 months)",
       y = "Predicted log-odds of treatment")


ggsave(plot = n_hosp_logoddsplot,
filename = "n_hosp_logoddsplot.png",
path = here::here("output/cohort")
)

ps.formula <- as.formula(paste("fluoroquinolone_exp ~",
                               paste(baseline_vars,
                                     collapse = "+")))

# This is a workaround until decided re: imputation(?)

# Subset complete cases
df_complete <- df %>% drop_na(all_of(c("fluoroquinolone_exp", baseline_vars)))

#Estimate propensity score
ps_model <- glm(ps.formula,
                family = binomial(),
                data = df_complete)

# Predict
df_complete$ps <- predict(ps_model, type = "response")


#Look at responses
summary(df_complete$ps)

#Look at overlap
png(filename = here::here("output/cohort", "ps_density_plot.png"), width = 800, height = 600)

plot(density(df_complete$ps[df_complete$fluoroquinolone_exp==TRUE]), 
     col = "red", main = "")
lines(density(df_complete$ps[df_complete$fluoroquinolone_exp==FALSE]), 
      col = "blue", lty = 2)
legend("topright", c("FQ","No FQ"), 
       col = c("red", "blue"), lty=1:2)

dev.off()

# Marginal probability of treatment
p_treat <- mean(df_complete$fluoroquinolone_exp)

#Calculate the stabilized treatment weight - less variance
df_complete$weight <- with(df_complete, ifelse(fluoroquinolone_exp == TRUE,
                             p_treat / ps, #IPTW for treated individuals
                             (1 - p_treat) / (1 - ps))) #IPTW for untreated individuals


#Generate weights for use in balance checking

require(WeightIt)
W.out <- weightit(ps.formula, 
                    data = df_complete, 
                    estimand = "ATE",
                    method = "ps")
summary(W.out$weights)

# Create a table for balance checking

require(cobalt)
bal.tab(W.out, un = TRUE, 
        thresholds = c(m = .1))

weightit(formula = ps.formula, data = df_complete, method = "ps", 
   estimand = "ATE")

#Plot the balancing

png(filename = here::here("output/cohort", "ps_love_plot.png"), width = 800, height = 600)

love.plot(W.out, binary = "std",
          thresholds = c(m = .1),
          abs = TRUE, 
          var.order = "unadjusted", 
          line = TRUE)

dev.off()

#Then once balanced run coxph

iptw_cox_model <- coxph(Surv(time_tendinitis, event_tendinitis) ~ fluoroquinolone_exp,
                   data = df_complete,
                   weights = weight,
                   robust = TRUE)


#Try simple coxph

iptw_cox_model_2 <- coxph(Surv(time_tendinitis, event_tendinitis) ~ fluoroquinolone_exp,
                   data = df_complete)


#Plot

model_summary <- summary(iptw_cox_model_2)

# Extract HR and CI
hr <- model_summary$coefficients[, "exp(coef)"]
conf_low <- model_summary$conf.int[, "lower .95"]
conf_high <- model_summary$conf.int[, "upper .95"]
term <- rownames(model_summary$coefficients)

#Look at df_complete

df_complete %>%
group_by(fluoroquinolone_exp, event_tendinitis) %>%
summarise(count = n()) %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/cohort/n_events_tendinitis.md")


# Save as plain text
capture.output(summary(iptw_cox_model_2),
               file = here::here("output/cohort/iptw_cox_model_summary.txt"))


# Make a tidy dataframe
forest_df <- tibble(term, hr, conf_low, conf_high)

forest_df %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/cohort/forest_df.md")

# Plot
iptw_forest <- ggplot(forest_df, aes(x = term, y = hr, ymin = conf_low, ymax = conf_high)) +
  geom_pointrange(color = "steelblue") +
  geom_hline(yintercept = 1, linetype = "dashed") +
  scale_y_log10() +
  ylab("Hazard Ratio (log scale)") +
  xlab("") +
  theme_minimal() +
  ggtitle("Hazard Ratio from IPTW Cox Model")


ggsave(plot = iptw_forest,
filename = "iptw_forest.png",
path = here::here("output/cohort")
)

