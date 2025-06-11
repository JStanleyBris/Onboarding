library(tidyverse)
library(survey)      # for weighted analyses
library(tableone)    # for checking balance
library(cobalt)      # for Love plots and diagnostics

##https://ehsanx.github.io/TMLEworkshop/iptw.html#step-3-balance-checking

df <- readr::read_csv("output/dataset.csv.gz", col_types = readr::cols(
    first_co_amox_date = col_date(format = "%Y-%m-%d"),
    first_fluoroquinolone_date = col_date(format = "%Y-%m-%d"),
    first_tendinitis_diagnosis_date = col_date(format = "%Y-%m-%d"),
    first_neuropathy_diagnosis_date = col_date(format = "%Y-%m-%d"),
    date_cohort_prescription = col_date(format = "%Y-%m-%d"),
    date_of_death = col_date(format = "%Y-%m-%d"),
    coamox_exp = col_logical(),
    fluoroquinolone_exp = col_logical()
    )
    )

#Need to separately make imd_decile an ordered factor
df$imd_decile <- factor(df$imd_decile,
                        levels = as.character(1:10),
                        ordered = TRUE)

#Start with iptw for sex and present of hypertension only then expand

#Set variables
baseline_vars <- c("sex", "has_diabetes")

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
df$weight <- with(df, ifelse(fluoroquinolone_exp == 1,
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
