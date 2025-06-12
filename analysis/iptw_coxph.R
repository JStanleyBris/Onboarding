library(tidyverse)
library(survey)      # for weighted analyses
library(tableone)    # for checking balance
library(cobalt)      # for Love plots and diagnostics
library(lubridate)
library(splines)

##https://ehsanx.github.io/TMLEworkshop/iptw.html#step-3-balance-checking

#Read formatted data
df <- readr::read_csv("output/dataset_formatted_cohort.csv")

#Start with iptw for sex and present of hypertension only then expand

#Set variables
baseline_vars <- c("sex", "has_diabetes", "harmful_alcohol", "has_had_cancer", "has_chronic_liver_disease", "has_chronic_resp_disease",
"has_dementia", "has_hiv", "has_heart_failure", "has_hemiplegia", "has_multiple_sclerosis", "has_rheumatoid_arthritis", "has_solid_organ_transplant",              
"has_stroke_tia", "has_aaa", "has_ckd", "has_coronary_hd", "has_hypertension", "has_peptic_ulcer", "has_pvd",  "corticosteroid_60d_before_abx",
"drug_linked_to_neuropathy_60d_before_abx")  
                                    
# To think about - "age", "imd_decile", "last_bmi", "latest_ethnicity_group", "never_smoker" -eg work out what to do with smoking, "n_hosp_appt_6m",
#  "year_cohort_prescription"             

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
  distinct() %>%  # Just one row per age (for smooth plot)
  mutate(
    pred_linear = predict(model_linear, newdata = ., type = "response"),
    pred_poly   = predict(model_poly, newdata = ., type = "response"),
    pred_spline = predict(model_spline, newdata = ., type = "response")
  )

# Convert to long format for ggplot
df_long <- df_preds %>%
  pivot_longer(
    cols = starts_with("pred_"),
    names_to = "model",
    values_to = "predicted_prob"
  ) %>%
  mutate(model = recode(model,
                        pred_linear = "Linear",
                        pred_poly = "Quadratic",
                        pred_spline = "Spline"))

# Plot predicted probabilities by age
age_spline_check <- ggplot(df_long, aes(x = age, y = predicted_prob, color = model)) +
  geom_line(size = 1.2) +
  labs(title = "Predicted Probability of Fluoroquinolone Exposure by Age",
       x = "Age", y = "Predicted Probability",
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
path = here::here("output")
)

AIC_table %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/aictable_agespline.md")

ps.formula <- as.formula(paste("fluoroquinolone_exp ~",
                               paste(baseline_vars,
                                     collapse = "+")))

#Estimate propensity score
ps_model <- glm(ps.formula,
                family = binomial(),
                data = df)

df$ps <- predict(ps_model, type = "response")

#Look at responses
summary(df$ps)

#Look at overlap
png(filename = here::here("output", "ps_density_plot.png"), width = 800, height = 600)

plot(density(df$ps[df$fluoroquinolone_exp==TRUE]), 
     col = "red", main = "")
lines(density(df$ps[df$fluoroquinolone_exp==FALSE]), 
      col = "blue", lty = 2)
legend("topright", c("FQ","No FQ"), 
       col = c("red", "blue"), lty=1:2)

dev.off()

# Marginal probability of treatment
p_treat <- mean(df$fluoroquinolone_exp)

#Calculate the stabilized treatment weight - less variance
df$weight <- with(df, ifelse(fluoroquinolone_exp == TRUE,
                             p_treat / ps, #IPTW for treated individuals
                             (1 - p_treat) / (1 - ps))) #IPTW for untreated individuals


#Generate weights for use in balance checking

require(WeightIt)
W.out <- weightit(ps.formula, 
                    data = df, 
                    estimand = "ATE",
                    method = "ps")
summary(W.out$weights)

# Create a table for balance checking

require(cobalt)
bal.tab(W.out, un = TRUE, 
        thresholds = c(m = .1))

weightit(formula = ps.formula, data = df, method = "ps", 
   estimand = "ATE")

#Plot the balancing

png(filename = here::here("output", "ps_love_plot.png"), width = 800, height = 600)

love.plot(W.out, binary = "std",
          thresholds = c(m = .1),
          abs = TRUE, 
          var.order = "unadjusted", 
          line = TRUE)

dev.off()

#Then once balanced run coxph

iptw_cox_model <- coxph(Surv(time_tendinitis, event_tendinitis) ~ fluoroquinolone_exp,
                   data = df,
                   weights = weight,
                   robust = TRUE)

summary(iptw_cox_model)