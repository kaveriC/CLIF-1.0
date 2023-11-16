## Sample R-CLIF Tables

Relational CLIF has 19 tables that are organized into clinically relevant column categories - demographics, objective measures, respiratory support, orders and inputs-outputs. Below are sample templates for each table in R-CLIF

### Vitals

| encounter_id | recorded_time  | vital_name | vital_value | meas_site_name |
|-----------|----------|------------|-----------|-------|
| 1         | 2022-05-05 04:18:00       | respiratory_rate| 18        | not specified |
| 1         | 2022-05-05 04:18:00       | spO2          | 97        | not specified |
| 1         | 2022-05-05 04:18:00       | height          | 73        | not specified |
| 1         | 2022-05-05 04:18:00       | temp          | 98.1        | not specified |
| 1         | 2022-05-05 04:18:00       | heart_rate          | 73        | not specified |
| 1         | 2022-05-05 04:18:00       | weight          | 1756.8       | not specified |


* **encounter_id** is an ID variable for each patient encounter ( a given patient can have multiple encounters )
* **recorded_time** is the date and time when the vital is recorded
* **vital_name** includes a limited number of vitals, namely - temp(C), pulse, sbp, dbp, sp02, respiration, map, height (inches), weight (oz)
* **vital_value** is the recorded value of the vital identified by the CLIF consortium 
* **meas_site_name** is the site where vital is recorded. It has three categories - arterial, core, not specified.


### Labs

| encounter_id | lab_order_time | lab_result_time | lab_group | lab_name |lab_value  | reference_unit    | lab_type_name |
|-----------|----------|------------|-----------|-------|-------|--------------|----------|
| 2         | 2022-09-30 17:50:00 | 2022-09-30 18:53:00 | CBC  | basophil  |1 | % | standard;poc  | 
| 2         | 2022-09-30 17:50:00 | 2022-09-30 18:53:00 | CBC  | monocyte  |7 | % | standard;poc  | 
| 2         | 2022-09-30 17:50:00 | 2022-09-30 18:53:00 | CBC  | neutrophil  |47 | % | standard;poc  | 
| 2         | 2022-09-30 17:50:00 | 2022-09-30 18:53:00 | CBC  | lymphocyte  |44 | % | standard;poc  | 
| 2         | 2022-09-30 17:50:00 | 2022-09-30 18:53:00 | CBC  | eosinophils  |1 | % | standard;poc  | 
| 2         | 2022-09-30 17:50:00 | 2022-09-30 18:53:00 | LFT  | bilirubin_unconjugated  |0.9 | mg/dL | standard;poc  | 

* **lab_order_time** is the date and time when the lab is ordered
* **lab_order_time** is the date and time when the lab results are available 
* **lab_group** includes a limited number of labs that are categorized into five groups - ABG, BMP, CBC, Coags, LFT, Lactic Acid, Misc, VBG
* **lab_name** includes a limited number of labs identified by the CLIF consortium 
* **lab_value** is the recorded value corresponding to a lab_name
* **reference_unit** is the unit of measurement for that lab
* **lab_type_name** has three categories - arterial, venous and standard/proc

### Respiratory_support

| encounter_id | recorded_time | device_name | mode_name | mode_category |lpm  | fiO2    | peep |set_volume | pressure_support | set_resp_rate | 
|-----------|----------|------------|-----------|-------|-------|--------------|----------|------------|------|--------|
| 4         | 10/6/2022  10:20:00 | Vent | A/C Volume   | Volume  |NA | 0.4 |4        | 400          | NA    | 16    |  
| 4         | 10/6/2022  11:00:00 | Vent | A/C Volume   | Volume  |NA | 0.4 |4        | 400          | NA    | 16    | 
| 4         | 10/6/2022  15:00:00 | Vent | A/C Volume   | Volume  |NA | 0.4 |4        | 400          | NA    | 14   | 
| 4         | 10/7/2022  6:45:00 | Nasal Cannula | PS/CPAP   | Spontaneous  |4 | 0.4 |5       | NA         | NA    | 16    |  
| 4         | 10/7/2022  16:00:00 | Nasal Cannula | PS/CPAP   | Spontaneous  |2 | 0.4 |5       | NA          | 0    | NA    | 
| 4         | 10/9/2022  5:07:00 | Room Air | NA   | NA  |NA | NA | NA        | NA          | NA    | NA  | 

* **recorded_time** is the date and time when the device started
* **device_name** includes a limited number of devices identified by the CLIF consortium
* **mode_name** includes a limited number of modes identified by the CLIF consortium
* **mode_category** includes a limited number of mode categories identified by the CLIF consortium, namely - pressure, volume, spontenous
* **lpm** is liters per minute
* **fiO2** is fraction of inspired O2
* **peep** is positive-end-expiratory pressure
* **set_volume** is measured in mL
* **pressure_support** measured in cmH2O
* **set_resp_rate** measured in bpm
