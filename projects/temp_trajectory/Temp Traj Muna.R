setwd("C:/Users/manour/Desktop/CLIF")
library(readr)
library(dplyr)
library(tidyverse)
install.packages("radiant.data")
library(radiant.data)
install.packages("remotes")
library(flipTime)

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

#Identify patients who went to the ICU (outcome1) 
#ADT TABLE
setwd("C:/Users/manour/Desktop/CLIF/Location")
location<- read_csv("locationCLIF.csv")%>%
  filter(location_name=="ICU")%>%
  select(encounter_id)%>%distinct()%>%deframe()

#Identify patients who are on the ventilator (outcome2)
setwd("C:/Users/manour/Desktop/CLIF/Demographics")
encounter <- read_csv("encounterpatientid.csv")

#Respiratory Table
setwd("C:/Users/manour/Desktop/CLIF/Respiratory")
ventilator <- read_csv("ventCLIF.csv")

ventilator <- left_join(ventilator, encounter, by = "patient_id")%>%
  filter(device_name =="Vent")%>%
  select(encounter_id)%>%distinct()%>%deframe()

setwd("C:/Users/manour/Desktop/CLIF/Demographics")
#Patient_demographics and disposition Table
demogs = read_csv("mergeddemographics.csv")

setwd("C:/Users/manour/Desktop/CLIF/Vitals")
#Vitals Table
vitals = read_csv("finalvitalsCLIF.csv")

summary(vitals)
str(vitals$recorded_dttm)
unique(vitals$recorded_dttm)

temperature_cohort = vitals %>%
  filter(vital_name == "temp_c") %>%
  rename(temperature = vital_value) %>%
  mutate(temperature = ifelse(temperature < 32 | temperature > 44, NA, temperature)) %>%
  filter(!is.na(temperature)) %>%
  mutate(temperature = scale(temperature) / sd(temperature),
         temp_time = as.POSIXct(recorded_dttm, format = "%m/%d/%Y %H:%M:%S" )) %>%
  group_by(encounter_id) %>%
  mutate(first_temp = min(temp_time)) %>%
  mutate(hours_from_adm = as.numeric(temp_time - first_temp) / 3600) %>%
  filter(hours_from_adm < 73 & hours_from_adm >= 0) %>%
  select(encounter_id, hours_from_adm, temperature) %>%
  mutate(hours_from_adm = round(hours_from_adm, digits = 0)) %>%
  group_by(encounter_id, hours_from_adm) %>%
  summarise(temperature = first(temperature)) %>%
  rename(adm = hours_from_adm) %>%
  filter(!is.na(temperature)) %>%
  ungroup() %>%
  mutate(traj1 = -0.89548 - 0.00298 * adm + 0.00010 * (adm^2),
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
  ) %>%
  select(encounter_id, model)

unique <- temperature_cohort%>%
  distinct(temperature_cohort$encounter_id)

table <- temperature_cohort %>%
  left_join(demogs) %>%
  filter(!is.na(age_at_admission)) %>%
  mutate(vent = ifelse(encounter_id %in% ventilator, 1, 0)) %>%
  mutate(icu = ifelse(encounter_id %in% location, 1, 0)) %>%
  mutate(death = ifelse(disposition %in% c("Dead", "Hospice"), 1, 0)) %>%
  mutate(HSR = ifelse(model == 1, 1, 0)) %>%  # Renaming model1 to HSR
  mutate(HFR = ifelse(model == 2, 1, 0)) %>%  # Renaming model2 to HFR
  mutate(NT = ifelse(model == 3, 1, 0)) %>%   # Renaming model3 to NT
  mutate(HT = ifelse(model == 4, 1, 0))       # Renaming model4 to HT

table2_summary <- temperature_cohort %>%
  left_join(demogs) %>%
  filter(!is.na(age_at_admission)) %>%
  mutate(vent = ifelse(encounter_id %in% ventilator, 1, 0)) %>%
  mutate(icu = ifelse(encounter_id %in% location, 1, 0)) %>%
  mutate(death = ifelse(disposition %in% c("Dead", "Hospice"), 1, 0)) %>%
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

characteristics <- colnames(table2_summary)
table2_summary <- as.data.frame(t(table2_summary))
summary(characteristics)

output <- vector("double", length(characteristics)) 
output[[1]]= NA
output[[2]]= NA
output[3] = summary(aov(age_at_admission~model, table))[[1]][["Pr(>F)"]][1]
output[4] = round(chisq.test(table$model, table$sex)$p.value, digits=3)
output[5] = round(chisq.test(table$model, table$race)$p.value, digits=3)
output[6] = NA
output[7] = NA
output[8] = NA
output[9] =  round(chisq.test(table$model, table$icu)$p.value, digits=3)
output[10] =  round(chisq.test(table$model, table$vent)$p.value, digits=3)
output[11] =  round(chisq.test(table$model, table$death)$p.value, digits=3)

table2 = table2_summary%>%
  mutate(Characteristics = characteristics)%>%
  mutate("P-value" = signif(output, digits = 1))%>%
  select(Characteristics, everything())

table2 = table2%>%
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

df <- as.data.frame(summary(glm(icu ~ HSR + NT + HT +  age_at_admission + sex + factor(race) + ethnicity, data = table, family = "binomial"))$coefficients)%>%
  remove_rownames()%>%
  mutate(outcome = "ICU")

df <- df %>%
  rbind(as.data.frame(summary(glm(vent ~ HSR + NT + HT +  age_at_admission + sex + factor(race) + ethnicity, data = table, family = "binomial"))$coefficients)%>%
          remove_rownames()%>%
          mutate(outcome = "Mechanical ventilation"))

df <- df %>%
  rbind(as.data.frame(summary(glm(death ~ HSR + NT + HT +  age_at_admission + sex + factor(race) + ethnicity, data = table, family = "binomial"))$coefficients)%>%
          remove_rownames()%>%
          mutate(outcome = "Mortality"))

df <- df %>%
  mutate(Features = rep(c("Intercept", "HSR", "NT", "HT", "Age", "Male sex", "Asian", "Black", "Pacific Islander", "Other", "White", "Non-Hispanic"), times = 3))

df <- df %>%
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
  mutate(outcome = factor(outcome, levels = c("ICU",
                                              "Mechanical ventilation",
                                              "Mortality")))%>%
  filter(Features=="HSR"|Features=="NT"|Features=="HT")

graph = df%>%
  mutate(order = ifelse(Features=="HSR", 1, NA))%>%
  mutate(order = ifelse(Features=="NT", 3, order))%>%
  mutate(order = ifelse(Features=="HT", 4, order))%>%
  rbind(c("HFR", 1, NA, NA, "ICU", 1, 1, 2), fill = TRUE) %>%
  rbind(c("HFR", 1, NA, NA, "Mechanical ventilation", 1, 1, 2), fill = TRUE) %>%
  rbind(c("HFR", 1, NA, NA, "Mortality", 1, 1, 2), fill = TRUE) %>%
  mutate(order = as.factor(order))%>%
  mutate(`Odds ratio`= as.numeric(`Odds ratio`))%>%
  mutate(upper = as.numeric(upper))%>%
  mutate(lower = as.numeric(lower))

graph <- df %>%
  mutate(order = ifelse(Features == "HSR", 1, NA),
         order = ifelse(Features == "NT", 3, order),
         order = ifelse(Features == "HT", 4, order)) %>%
  rbind(c("HFR", 1, NA, NA, "ICU", 1, 1, 2)) %>%
  rbind(c("HFR", 1, NA, NA, "Mechanical ventilation", 1, 1, 2)) %>%
  rbind(c("HFR", 1, NA, NA, "Mortality", 1, 1, 2)) %>%
  mutate(order = factor(order, levels = c(1, 2, 3, 4))) %>%
  mutate(`Odds ratio` = as.numeric(`Odds ratio`)) %>%
  mutate(upper = as.numeric(upper)) %>%
  mutate(lower = as.numeric(lower))

ggplot(graph, aes(x = order, y = `Odds ratio`, color = order)) + 
  geom_point(position = position_dodge(width = 2), size = 3) + 
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0,
                position = position_dodge(width = 2)) + 
  theme_classic() + xlab("") +
  theme(axis.text = element_text(size = 12),
        axis.title.x = element_text(size = 12, vjust = -1), 
        axis.title.y = element_blank(),
        axis.text.y = element_blank(),
        axis.line.y = element_blank(),
        legend.position = "none") + 
  scale_color_manual(values = c("#FF9900","#0000FF", "#336600", "#990000"), # add blue 
                     name = "", 
                     labels = c("HSR","HFR","NT","HT"), # order 1 2 3 4 
                     guide = guide_legend()) +
  geom_hline(yintercept = 1.0) +
  theme(strip.text = element_text(size = 13),
        axis.ticks = element_blank(),
        plot.title = element_text(size = 11, face = "italic", hjust = 0.4),
        legend.position = "bottom") +
  coord_flip() +   
  guides(color = guide_legend(nrow = 2, size = 10)) + 
  facet_wrap(~ outcome)

# Save df dataframe as CSV
write.csv(df, file = "df_temptraj.csv", row.names = FALSE)

# Save table2 dataframe as CSV
write.csv(table2, file = "table2_temptraj.csv", row.names = FALSE)


#What does temperature look like in our vitals dataset?
library(readr)
vitals<- read_csv("C:/Users/manour/Desktop/CLIF/Vitals/finalvitalsCLIF.csv")

#48 HOURS POST HOSPITALIZATION 
vitalstemp <- vitals %>%
  filter(vital_name == "temp_c") %>%
  left_join(temperature_cohort, by = "encounter_id") %>%
  mutate(model = ifelse(is.na(model), NA, as.factor(model))) %>%
  mutate(trajectory = case_when(
    model == 1 ~ "HSR",
    model == 2 ~ "HFR",
    model == 3 ~ "NT",
    model == 4 ~ "HT",
    TRUE ~ NA_character_  # Handling other cases
  )) %>%
  mutate(model = ifelse(is.na(vital_value), NA, model),
         trajectory = ifelse(is.na(vital_value), NA, trajectory))


vitalstempplot <- vitalstemp %>%
  mutate(recorded_dttm = as.POSIXct(recorded_dttm)) %>% 
  group_by(encounter_id) %>% 
  mutate(first_recorded_dttm = min(recorded_dttm), 
         hours_since_start = as.numeric(difftime(recorded_dttm, first_recorded_dttm, units = "hours"))) %>% 
  ungroup() %>%
  filter(hours_since_start <= 48) %>%
  group_by(encounter_id, trajectory, hours_since_start) %>%
  summarise(avg_temp_c = mean(vital_value, na.rm = TRUE), .groups = 'drop') %>%
  group_by(trajectory, hours_since_start) %>%
  summarise(avg_temp_c = mean(avg_temp_c, na.rm = TRUE), .groups = 'drop')%>%
  filter(!is.na(trajectory))

predictions_list <- vitalstempplot %>%
  group_by(trajectory) %>%
  do({
    model <- lm(avg_temp_c ~ poly(hours_since_start, 2, raw=TRUE), data=.)
    data.frame(hours_since_start = seq(min(.$hours_since_start), max(.$hours_since_start), length = 100),
               avg_temp_c = predict(model, newdata = data.frame(hours_since_start = seq(min(.$hours_since_start), max(.$hours_since_start), length = 100))),
               trajectory = unique(.$trajectory))
  }) %>%
  ungroup()

ggplot(predictions_list, aes(x = hours_since_start, y = avg_temp_c, color = trajectory)) +
  geom_line(size=1) +
  labs(title = "Average Temperature (°C) over 48 Hours by Trajectory",
       x = "Time from Presentation (h)",
       y = "Average Temperature (°C)",
       color = "Trajectory") +
  theme_minimal() +
  coord_cartesian(ylim = c(36, 37.6)) +
  scale_y_continuous(breaks = seq(36, 38, by = 0.3))



ggplot(vitalstempplot, aes(x = hours_since_start, y = avg_temp_c, color = trajectory)) +
  geom_point() +
  geom_line(data = predictions_list, aes(x = hours_since_start, y = avg_temp_c, group = trajectory), size = 1) +
  labs(title = "Average Temperature (°C) over 48 Hours by Trajectory",
       x = "Time from Presentation (h)",
       y = "Average Temperature (°C)",
       color = "Trajectory") +
  theme_minimal() +
  coord_cartesian(ylim = c(36, 37.6)) +
  scale_y_continuous(breaks = seq(36, 38, by = 0.3))



#72 HOURS POST HOSPITALIZATION
vitalstemp <- vitals %>%
  filter(vital_name == "temp_c") %>%
  left_join(temperature_cohort, by = "encounter_id") %>%
  mutate(model = ifelse(is.na(model), NA, as.factor(model))) %>%
  mutate(trajectory = case_when(
    model == 1 ~ "HSR",
    model == 2 ~ "HFR",
    model == 3 ~ "NT",
    model == 4 ~ "HT",
    TRUE ~ NA_character_  # Handling other cases
  )) %>%
  mutate(model = ifelse(is.na(vital_value), NA, model),
         trajectory = ifelse(is.na(vital_value), NA, trajectory))


vitalstempplot <- vitalstemp %>%
  mutate(recorded_dttm = as.POSIXct(recorded_dttm)) %>% 
  group_by(encounter_id) %>% 
  mutate(first_recorded_dttm = min(recorded_dttm), 
         hours_since_start = as.numeric(difftime(recorded_dttm, first_recorded_dttm, units = "hours"))) %>% 
  ungroup() %>%
  filter(hours_since_start <= 72) %>%
  group_by(encounter_id, trajectory, hours_since_start) %>%
  summarise(avg_temp_c = mean(vital_value, na.rm = TRUE), .groups = 'drop') %>%
  group_by(trajectory, hours_since_start) %>%
  summarise(avg_temp_c = mean(avg_temp_c, na.rm = TRUE), .groups = 'drop')%>%
  filter(!is.na(trajectory))

predictions_list <- vitalstempplot %>%
  group_by(trajectory) %>%
  do({
    model <- lm(avg_temp_c ~ poly(hours_since_start, 2, raw=TRUE), data=.)
    data.frame(hours_since_start = seq(min(.$hours_since_start), max(.$hours_since_start), length = 100),
               avg_temp_c = predict(model, newdata = data.frame(hours_since_start = seq(min(.$hours_since_start), max(.$hours_since_start), length = 100))),
               trajectory = unique(.$trajectory))
  }) %>%
  ungroup()

ggplot(predictions_list, aes(x = hours_since_start, y = avg_temp_c, color = trajectory)) +
  geom_line(size=1) +
  labs(title = "Average Temperature (°C) over 72 Hours by Trajectory",
       x = "Time from Presentation (h)",
       y = "Average Temperature (°C)",
       color = "Trajectory") +
  theme_minimal() +
  coord_cartesian(ylim = c(36, 37.6)) +
  scale_y_continuous(breaks = seq(36, 38, by = 0.3))



ggplot(vitalstempplot, aes(x = hours_since_start, y = avg_temp_c, color = trajectory)) +
  geom_point() +
  geom_line(data = predictions_list, aes(x = hours_since_start, y = avg_temp_c, group = trajectory), size = 1) +
  labs(title = "Average Temperature (°C) over 72 Hours by Trajectory",
       x = "Time from Presentation (h)",
       y = "Average Temperature (°C)",
       color = "Trajectory") +
  theme_minimal() +
  coord_cartesian(ylim = c(36, 37.6)) +
  scale_y_continuous(breaks = seq(36, 38, by = 0.3))

