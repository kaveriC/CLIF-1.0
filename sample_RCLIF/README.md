## Sample R-CLIF

Relational CLIF has 19 tables that are organized into clinically relevant column categories - demographics, objective measures, respiratory support, orders and inputs-outputs. Below are sample templates for each table in R-CLIF

### Vitals

| encounter | recorded_time  | vital_name | vital_value | meas_site_name |
|-----------|----------|------------|-----------|-------|
| 1         | 2022-05-05 04:18:00       | respiratory_rate| 18        | not specified |
| 1         | 2022-05-05 04:18:00       | spO2          | 97        | not specified |
| 1         | 2022-05-05 04:18:00       | height          | 73        | not specified |
| 1         | 2022-05-05 04:18:00       | temp          | 98.1        | not specified |
| 1         | 2022-05-05 04:18:00       | heart_rate          | 73        | not specified |
| 1         | 2022-05-05 04:18:00       | weight          | 1756.8       | not specified |


### Labs


### Respiratory_support

| encounter | recorded_time | device_name | mode_name | mode_category |lpm  | fiO2    | peep |set_volume | pressure_support | set_resp_rate | 
|-----------|----------|------------|-----------|-------|-------|--------------|----------|------------|------|--------|
| 1         | 10/6/2022  10:20:00 AM| Vent | A/C Volume   | Volume  |NA | 0.4 |4        | 400          | NA    | 16    |  
| 1         | 10/6/2022  11:00:00 AM       | Vent | A/C Volume   | Volume  |NA | 0.4 |4        | 400          | NA    | 16    | 
| 1         | 10/6/2022  3:00:00 PM      | Vent | A/C Volume   | Volume  |NA | 0.4 |4        | 400          | NA    | 14   | 
| 1         | 10/7/2022  6:45:00 AM| Nasal Cannula | PS/CPAP   | Spontaneous  |4 | 0.4 |5       | NA         | NA    | 16    |  
| 1         | 10/7/2022  4:00:00 PM | Nasal Cannula | PS/CPAP   | Spontaneous  |2 | 0.4 |5       | NA          | 0    | NA    | 
| 1         | 10/9/2022  5:07:00 AM | Room Air | NA   | NA  |NA | NA | NA        | NA          | NA    | NA  | 
