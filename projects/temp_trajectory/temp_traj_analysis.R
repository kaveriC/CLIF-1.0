library(tidyverse)
install.packages("radiant.data")
library(radiant.data)
install.packages("remotes")
library(flipTime)

#Load ICU Cohort and other files
icu_cohort <- read_csv("C:/Users/manour/Desktop/Mortality Model/icu_cohort.csv")
vitals <- read_csv("C:/Users/manour/Desktop/CLIF/Vitals/finalvitalsCLIF.csv")
encounter <- read_csv("C:/Users/manour/Desktop/CLIF/Demographics/encounterpatientid.csv")
ventilator <- read_csv("C:/Users/manour/Desktop/CLIF/Respiratory/ventCLIF.csv")

ventilator <- left_join(ventilator, encounter, by = "patient_id")%>%
  filter(device_name =="Vent")%>%
  select(encounter_id)%>%distinct()%>%deframe()

#load Locations and demographics
location <- read_csv("C:/Users/manour/Desktop/CLIF/Location/locationCLIF.csv")%>%
  filter(location_name=="ICU")%>%
  distinct()

#load demographics: this is a merged data set of patient_demographics, limited_identifiers, and encounters_demographics_disposition
mergeddemographics <- read_csv("C:/Users/manour/Desktop/CLIF/Demographics/mergeddemographics.csv")

#filter vitals to vital_name temp_c
vitals<- vitals%>%
  filter(vital_name == "temp_c")

#Merging datasets
merged_data <- merge(vitals, location, by = "encounter_id")
merged_data <- merge(merged_data, mergeddemographics, by = "encounter_id")
merged_data <- inner_join(merged_data, icu_cohort, by = "encounter_id")

merged_data <- merged_data %>%
  distinct()

#TABLE FUNCTIONS
med = function(v)
{
  a=  paste(median(v), " (", deframe(quantile(v)[2]), "-", deframe(quantile(v)[4]), ")", sep = "")
  return(a)
}

counts = function(v)
{
  a=  paste(sum(v, na.rm=TRUE), " (", round(mean(v, na.rm=TRUE)*100, digits=1), ")", sep = "")
  return(a)
}

mean_r = function(v)
{
  a=  paste(round(mean(v), digits=1), " (", round(sd(v), digits=1), ")", sep = "")
  return(a)
}

#Data preprocessing and algorithm creation for temperature trajectories
temp_algorithm <- merged_data %>%
  filter(vital_name == "temp_c") %>%
  rename(temperature = vital_value) %>%
  mutate(temperature = ifelse(temperature < 32 | temperature > 44, NA, temperature)) %>%
  filter(!is.na(temperature)) %>%
  mutate(
    temperature = scale(temperature), #standardizing temperature; we will not be standardizing at the end (we want raw temps from each site)
    temp_time = as.POSIXct(recorded_dttm, format = "%m/%d/%Y %H:%M:%S"),
    in_time = as.POSIXct(in_time, format = "%m/%d/%Y %H:%M:%S") 
  ) %>%
  filter(temp_time >= in_time) %>%
  group_by(encounter_id) %>%
  mutate(first_temp = min(temp_time[temp_time >= in_time])) %>%
  mutate(hours_from_adm = as.numeric(temp_time - first_temp) / 3600) %>%
  filter(hours_from_adm < 73 & hours_from_adm >= 0) %>%
  select(encounter_id, hours_from_adm, temperature) %>%
  mutate(hours_from_adm = round(hours_from_adm, digits = 0)) %>%
  group_by(encounter_id, hours_from_adm) %>%
  summarise(temperature = first(temperature)) %>% #left_join with group assignment; hsr hfr ht or nt
  rename(adm = hours_from_adm) %>%
  filter(!is.na(temperature)) %>%
  ungroup() %>%
  mutate(traj1 = -0.89548 - 0.00298 * adm + 0.00010 * (adm^2), #quadratic equation for each traj 
         traj2 = -0.00667 + 0.00050 * adm - 0.00001 * (adm^2),
         traj3 = 1.35157 - 0.06946 * adm + 0.00065 * (adm^2),
         traj4 = 1.22203 - 0.00590 * adm - 0.00007 * (adm^2)) %>%
  group_by(encounter_id) %>%
  mutate(error1 = (temperature - traj1)^2,
         error2 = (temperature - traj2)^2,
         error3 = (temperature - traj3)^2,
         error4 = (temperature - traj4)^2) %>%
  summarise(sum1 = sum(error1), sum2 = sum(error2), sum3 = sum(error3), sum4 = sum(error4)) %>%
  mutate(
    lowest = pmin(sum1, sum2) |> pmin(sum3) |> pmin(sum4),
    model  = case_when(
      lowest == sum1 ~ as.integer(4),
      lowest == sum2 ~ as.integer(3),
      lowest == sum3 ~ as.integer(2),
      lowest == sum4 ~ as.integer(1),
      TRUE ~ NA_integer_
    )
  )%>% select(encounter_id, model) 

icu_encounters <- location %>%
  filter(location_name == "ICU") %>%
  pull(encounter_id)

#Table creation for algorithm analysis
table_alg <- temp_algorithm %>%
  left_join(mergeddemographics) %>%
  filter(!is.na(age_at_admission)) %>%
  mutate(vent = ifelse(encounter_id %in% ventilator, 1, 0)) %>%
  mutate(icu = ifelse(encounter_id %in% icu_encounters, 1, 0)) %>%
  mutate(death = ifelse(disposition %in% c("Dead"), 1, 0)) %>% 
  mutate(HSR = ifelse(model == 1, 1, 0)) %>%  # Renaming model1 to HSR
  mutate(HFR = ifelse(model == 2, 1, 0)) %>%  # Renaming model2 to HFR
  mutate(NT = ifelse(model == 3, 1, 0)) %>%   # Renaming model3 to NT
  mutate(HT = ifelse(model == 4, 1, 0))       # Renaming model4 to HT

#Table creation for each temp traj 0-72 hours
table<- table_alg%>%
  inner_join(merged_data, by = "encounter_id")%>%
  rename(temperature = vital_value) %>%
  mutate(
    temp_time = as.POSIXct(recorded_dttm, format = "%m/%d/%Y %H:%M:%S"),
    in_time = as.POSIXct(in_time, format = "%m/%d/%Y %H:%M:%S") 
  ) %>%
  filter(temp_time >= in_time) %>%
  group_by(encounter_id) %>%
  mutate(first_temp = min(temp_time[temp_time >= in_time])) %>%
  mutate(hours_from_adm = as.numeric(temp_time - first_temp) / 3600) %>%
  filter(hours_from_adm < 73 & hours_from_adm >= 0) %>%
  select(encounter_id, hours_from_adm, temperature) %>%
  mutate(hours_from_adm = round(hours_from_adm, digits = 0)) %>%
  group_by(encounter_id, hours_from_adm) %>%
  summarise(temperature = first(temperature)) %>% 
  rename(adm = hours_from_adm) %>%
  filter(!is.na(temperature)) 

table_icu<- table%>%
  inner_join(table_alg, by = "encounter_id")

table_temp_traj_cohort <- table_icu %>%
  # Pivot longer to create the 'group' column based on HSR, HFR, NT, HT
  pivot_longer(cols = c("HSR", "HFR", "NT", "HT"), names_to = "group", values_to = "value") %>%
  filter(value == 1) %>%
  select(-value) %>%
  
  # Step 2: Rename 'adm' to 'hour'
  rename(hour = adm) %>%
  
  # Group by 'group' and 'hour' to calculate avg_temperature, std, and n
  group_by(group, hour) %>%
  summarise(
    avg_temperature = mean(temperature, na.rm = TRUE),
    std = sd(temperature, na.rm = TRUE),
    n = n_distinct(encounter_id),
    .groups = 'drop'
  )%>%
  filter(hour != 73)

#Optional plot to visualize icu cohort temp traj 0-72 hours 
ggplot(table_temp_traj_cohort, aes(x = hour, y = avg_temperature, color = group, group = group)) +
  geom_line() +  # This adds the line connecting the points
  geom_smooth(se = FALSE, method = "loess", span = 0.2) +  # This adds the smooth trend line
  scale_x_continuous(breaks = seq(0, 72, by = 12), limits = c(0, 72)) +  # X-Axis from 0 to 72 hours
  labs(
    title = "Average Temperature Trend by Group",
    x = "Hour",
    y = "Average Temperature",
    color = "Group"
  ) +
  theme_minimal() +  # Minimal theme to keep the focus on the data
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),  # Adjust text angle and position
    plot.title = element_text(hjust = 0.5)  # Center the plot title
  )

write.csv(table_temp_traj_cohort, "C:/Users/manour/Documents/GitHub/CLIF-1.0/projects/temp_trajectory/table_temp_traj_cohort.csv", row.names = FALSE)

table2_alg_summary <- temp_algorithm %>%
  left_join(mergeddemographics) %>%
  filter(!is.na(age_at_admission)) %>%
  mutate(vent = ifelse(encounter_id %in% ventilator, 1, 0)) %>%
  mutate(icu = ifelse(encounter_id %in% icu_encounters, 1, 0)) %>%
  mutate(death = ifelse(disposition %in% c("Dead"), 1, 0)) %>%
  mutate(HSR = ifelse(model == 1, 1, 0)) %>%  # Renaming model1 to HSR
  mutate(HFR = ifelse(model == 2, 1, 0)) %>%  # Renaming model2 to HFR
  mutate(NT = ifelse(model == 3, 1, 0)) %>%   # Renaming model3 to NT
  mutate(HT = ifelse(model == 4, 1, 0)) %>%   # Renaming model4 to HT
  mutate(n = 1) %>%
  group_by(model) %>%
  summarise(N = sum(n), 
            Age = mean_r(age_at_admission),
            "Sex, male" = counts(sex == "Male"),
            Race = "",
            Black = counts(race == "Black or African-American"),
            White = counts(race == "White"),
            Other = counts(race != "Black or African-American" & race != "White"),
            ICU = counts(icu),
            Ventilator = counts(vent),
            "Mortality" = counts(death)
  )

characteristics_alg <- colnames(table2_alg_summary)
table2_alg_summary <- as.data.frame(t(table2_alg_summary))
summary(characteristics_alg)


# Initialize output vector for storing statistical results
# Compute and store p-values for statistical tests
output <- vector("double", length(characteristics_alg)) 
output[[1]]= NA
output[[2]]= NA
output[3] = summary(aov(age_at_admission~model, table_alg))[[1]][["Pr(>F)"]][1]
output[4] = round(chisq.test(table_alg$model, table_alg$sex)$p.value, digits=3)
output[5] = round(chisq.test(table_alg$model, table_alg$race)$p.value, digits=3)
output[6] = NA
output[7] = NA
output[8] = NA
output[9] =  round(chisq.test(table_alg$model, table_alg$vent)$p.value, digits=3)
output[10] =  round(chisq.test(table_alg$model, table_alg$death)$p.value, digits=3)

# Combine characteristics and output into table2_alg with meaningful labels
table2_alg = table2_alg_summary%>%
  mutate(Characteristics = characteristics_alg)%>%
  mutate("P-value" = signif(output, digits = 1))%>%
  select(Characteristics, everything())

# Format p-values and rename columns in table2_alg
table2_alg = table2_alg%>%
  mutate(`P-value` = ifelse(`P-value`<0.001,0,`P-value`))%>%
  mutate(`P-value` = as.character(`P-value`))%>%
  mutate(`P-value` = ifelse(`P-value`=="0", "<0.001", `P-value`))%>%
  mutate(`P-value` = ifelse(`P-value`=="1", "0.9", `P-value`))%>%
  mutate(`P-value` = replace_na(`P-value`, "-"))%>%
  rename("HSR"=V1)%>%
  rename("HFR"=V2)%>%
  rename("NT"=V3)%>%
  rename("HT"=V4)%>%
  filter(Characteristics!="model")

# Perform logistic regression for mechanical ventilation and mortality outcomes
df_alg <- as.data.frame(summary(glm(vent ~ HSR + NT + HT +  age_at_admission + sex + factor(race) + ethnicity, data = table_alg, family = "binomial"))$coefficients)%>%
  remove_rownames()%>%
  mutate(outcome = "Mechanical ventilation")

df_alg <- df_alg %>%
  rbind(as.data.frame(summary(glm(death ~ HSR + NT + HT +  age_at_admission + sex + factor(race) + ethnicity, data = table_alg, family = "binomial"))$coefficients)%>%
          remove_rownames()%>%
          mutate(outcome = "Mortality"))

df_alg <- df_alg %>%
  mutate(Features = rep(c("Intercept", "HSR", "NT", "HT", "Age", "Male sex", "Asian", "Black", "Pacific Islander", "Other", "White", "Non-Hispanic"), times = 2))

# Calculate confidence intervals and odds ratios, and format p-values in df_alg
df_alg <- df_alg %>%
  select(!`z value`)%>%
  mutate(ci = 1.96*`Std. Error`)%>%
  mutate(upper = Estimate + ci)%>%
  mutate(lower = Estimate - ci)%>%
  mutate("Odds ratio" = round(exp(Estimate), digits=2))%>%
  mutate(upper = round(exp(upper), digits=2))%>%
  mutate(lower = round(exp(lower), digits=2))%>%
  select(!Estimate)%>%
  rename("P-value" = `Pr(>|z|)`)%>%
  mutate(`P-value` = ifelse(`P-value`<0.001,0,`P-value`))%>%
  mutate(`P-value` = signif(`P-value`, digits=1))%>%
  mutate(`P-value` = as.character(`P-value`))%>%
  mutate(`P-value` = ifelse(`P-value`=="0", "<0.001", `P-value`))%>%
  mutate(`P-value` = ifelse(`P-value`=="1", "0.9", `P-value`))%>%
  mutate("Confidence Interval" = paste(round(lower, digits=2), "-" , round(upper, digits=2), sep = ""))%>%
  select(!ci)%>%
  select(!`Std. Error`)%>%
  select(Features, `Odds ratio`, "Confidence Interval", everything())%>%
  mutate(`Odds ratio` = as.numeric(`Odds ratio`))%>%
  mutate(upper = as.numeric(upper))%>%
  mutate(lower = as.numeric(lower))  %>%
  mutate(outcome = factor(outcome, levels = c("Mechanical ventilation",
                                              "Mortality")))%>%
  filter(Features=="HSR"|Features=="NT"|Features=="HT")

# Prepare data for plotting
graph_alg = df_alg%>%
  mutate(order = ifelse(Features=="HSR", 1, NA))%>%
  mutate(order = ifelse(Features=="NT", 3, order))%>%
  mutate(order = ifelse(Features=="HT", 4, order))%>%
  rbind(c("HFR", 1, NA, NA, "Mechanical ventilation", 1, 1, 2), fill = TRUE) %>%
  rbind(c("HFR", 1, NA, NA, "Mortality", 1, 1, 2), fill = TRUE) %>%
  mutate(order = as.factor(order))%>%
  mutate(`Odds ratio`= as.numeric(`Odds ratio`))%>%
  mutate(upper = as.numeric(upper))%>%
  mutate(lower = as.numeric(lower))

graph_alg <- df_alg %>%
  mutate(order = case_when(
    Features == "HSR" ~ 1,
    Features == "NT" ~ 3,
    Features == "HT" ~ 4,
    TRUE ~ NA_integer_ # Ensuring other features have NA assigned correctly
  )) %>%
  rbind(c("HFR", 1, NA, NA, "Mechanical ventilation", 1, 1, 2)) %>%
  rbind(c("HFR", 1, NA, NA, "Mortality", 1, 1, 2)) %>%
  mutate(order = factor(order, levels = c(1, 2, 3, 4))) %>%
  mutate(`Odds ratio` = as.numeric(`Odds ratio`),
         upper = as.numeric(upper),
         lower = as.numeric(lower))

# Plot
ggplot(graph_alg, aes(x = order, y = `Odds ratio`, color = order)) + 
  geom_point(position = position_dodge(width = 0.5), size = 3) + 
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0,
                position = position_dodge(width = 0.5)) +
  theme_classic() + xlab("") +
  scale_color_manual(values = c("#FF9900","#0000FF", "#336600", "#990000"),
                     name = "", 
                     labels = c("HSR", "HFR", "NT", "HT"),
                     guide = guide_legend()) +
  geom_hline(yintercept = 1.0) +
  coord_flip() +   
  facet_wrap(~ outcome)

# Save df_alg dataframe as CSV
write.csv(df_alg, file = "df_temptraj_72_post_icu.csv", row.names = FALSE)

# Save table2_alg dataframe as CSV
write.csv(table2_alg, file = "table2_temptraj_72_post_icu.csv", row.names = FALSE)