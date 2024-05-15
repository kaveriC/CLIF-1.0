################### Load libraries #############################################

library(data.table)
library(arrow)
library(tidyverse)

##################### User input ###############################################
# Set parameters
filetype <- "parquet"

# change to CLIF-1.0 root directory 
root_location <- '/Users/kavenchhikara/Desktop/CLIF-1.0'

# maximum age allowed, beyond this are replaced with NAs
max_age_at_adm = 119

# below filepaths should work if you are operating within the GitHub repo. 
labs_filepath <- paste0(root_location, "/rclif/clif_labs.", 
                        filetype)
labs_output_filepath <- paste0(root_location, "/rclif/clif_labs_clean_R.", 
                               filetype)
labs_outlier_thresholds_filepath <- paste0(root_location, 
                                           "/outlier_handlers/nejm_outlier_thresholds_labs.csv")

vitals_filepath <- paste0(root_location, "/rclif/clif_vitals.", 
                          filetype)
vitals_output_filepath <- paste0(root_location, "/rclif/clif_vitals_clean_R.", 
                                 filetype)
vitals_outlier_thresholds_filepath <- paste0(root_location, 
                                             "/outlier_handlers/nejm_outlier_thresholds_vitals.csv")

encounter_filepath <- paste0(root_location, 
                             "/rclif/clif_encounter_demographics_dispo.", 
                             filetype)
encounter_output_filepath <- paste0(root_location, "/rclif/clif_encounter_demographics_dispo._clean_R.", 
                                 filetype)


# Specify directory for result files
results_path <- paste0(root_location, "/outlier_handlers")

##################### Functions  ###############################################
# Define function to read data
read_data <- function(filepath, filetype) {
  if (filetype == 'csv') {
    return(fread(filepath))
  } else if (filetype == 'parquet') {
    # Read parquet file using appropriate library
    return(read_parquet(filepath))
  } else if (filetype == 'fst') {
    # Read fst file using appropriate library
    return(read_fst(filepath))
  } else {
    stop("Unsupported file type. Please provide either 'csv', 'parquet', or 'fst'.")
  }
}

# Define function to write data
write_data <- function(data, filepath, filetype) {
  if (filetype == 'csv') {
    fwrite(data, filepath)
  } else if (filetype == 'parquet') {
    # Write parquet file using appropriate library
    write_parquet(data, filepath, compression = "SNAPPY")
  } else if (filetype == 'fst') {
    # Write fst file using appropriate library
    write_fst(data, filepath)
  } else {
    stop("Unsupported file type. Please provide either 'csv', 'parquet', or 'fst'.")
  }
}

# Define function to replace outliers with NA values (long format)
replace_outliers_with_na_long <- function(df, df_outlier_thresholds,
                                          category_variable, numeric_variable) {
  # Merge the data frames on lab_category
  merged_data <- merge(df, df_outlier_thresholds, by = category_variable, all.x = TRUE)
  # Filter and replace outliers
  merged_data[[numeric_variable]] <- with(merged_data, ifelse(
    get(numeric_variable) < lower_limit | get(numeric_variable) > upper_limit,
    NA,
    get(numeric_variable)
  ))
  # Drop the outlier threshold columns
  merged_data <- merged_data[, !(names(merged_data) %in% c("lower_limit", "upper_limit"))]
  # Replace the original clif_labs with the updated values
  df <- merged_data
  return(df)
}

generate_summary_stats <- function(data, category_variable, numeric_variable) {
  summary_stats <- data %>%
    group_by({{ category_variable }}) %>%
    summarise(
      N = sum(!is.na({{ numeric_variable }})),
      Min = min({{ numeric_variable }}, na.rm = TRUE),
      Max = max({{ numeric_variable }}, na.rm = TRUE),
      Mean = mean({{ numeric_variable }}, na.rm = TRUE),
      Median = median({{ numeric_variable }}, na.rm = TRUE),
      First_Quartile = quantile({{ numeric_variable }}, 0.25, na.rm = TRUE),
      Third_Quartile = quantile({{ numeric_variable }}, 0.75, na.rm = TRUE)
    ) %>%
    ungroup() %>%
    arrange(-desc({{ category_variable }}))
  
  return(summary_stats)
}


#####################     Labs   ###############################################
# Read labs data
clif_labs <- read_data(labs_filepath, filetype)
labs_outlier_thresholds <- read_data(labs_outlier_thresholds_filepath, 'csv')
dir_path <- file.path(results_path, 'labs')
dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)

# if lab_value_numeric doesn't exist, create it
if (!"lab_value_numeric" %in% colnames(clif_labs)) {
  print("lab_value_numeric does not exist")
  clif_labs$lab_value_numeric <- as.numeric(parse_number(clif_labs$lab_value))
  print("lab_value_numeric created")
}

## replace outliers with NA
clif_labs_clean <- replace_outliers_with_na_long(clif_labs, 
                                                 labs_outlier_thresholds, 
                                                 'lab_category', 
                                                 'lab_value_numeric')

# Write clean labs file
write_data(clif_labs_clean, labs_output_filepath, filetype)

lab_summary_stats <- generate_summary_stats(clif_labs_clean,
                                            lab_category, 
                                            lab_value_numeric)
write_data(lab_summary_stats, paste0(results_path, 
                                     "/labs/clif_vitals_labs_stats_R.csv"), 
           'csv')

#####################   Vitals   ###############################################


# Read labs data
clif_vitals <- read_data(vitals_filepath, filetype)
vitals_outlier_thresholds <- read_data(vitals_outlier_thresholds_filepath, 
                                       'csv')
dir_path <- file.path(results_path, 'vitals')
dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)

## replace outliers with NA
clif_vitals_clean <- replace_outliers_with_na_long(clif_vitals, 
                                                   vitals_outlier_thresholds, 
                                                   'vital_category', 
                                                   'vital_value')

# Write clean labs file
write_data(clif_vitals_clean, vitals_output_filepath, filetype)

vital_summary_stats <- generate_summary_stats(clif_vitals_clean, 
                                              vital_category, 
                                              vital_value)
write_data(vital_summary_stats, paste0(results_path, 
                                       "/vitals/clif_vitals_summary_stats_R.csv"), 
           'csv')

################Encounter Demographics Dispo  ##################################

clif_encounter<- read_data(encounter_filepath, filetype)
dir_path <- file.path(results_path, 'encounter_demographic_dispo')
dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)

clif_encounter$age_at_admission <- ifelse(clif_encounter$age_at_admission > max_age_at_adm, 
                                          NA, 
                                          clif_encounter$age_at_admission)

write_data(clif_encounter, encounter_output_filepath, filetype)
