# |------------------------------------------------------------------------|
# | Project1: Hospital Quality of Care Scores Association                  |
# |           with Clinical Outcomes in MIDAS                              |
# | Project2: Income Association with Clinical Outcomes in MIDAs           |
# | Script: Make the data set for the analysis                             |
# | Authors: Georgia Barbayannis, I-ming Chiu, Noah Michel, Davit Sargsyan |   
# | Created: 04/21/2017                                                    |
# | Modified: 11/03/2017 (CORRECTED RACE DATA)                                                  |
# |------------------------------------------------------------------------|
# Header----
# Move up one directory
wd <- getwd()
setwd("..")
DATA_HOME <- paste(getwd(),
                   "data/dakota",
                   sep = "/")
# Reset working directory
setwd(wd)
getwd()

require(data.table)
require(ggplot2)

# Load MIDAS----
# The dataset was created using 
# '.../midas/source/export_midas_from_csv_to_rdata.R' script
load("midas15_race_corrected.RData")
midas15

# Remove unused variables----
midas15[, PROC1 := NULL]
midas15[, PROC2 := NULL]
midas15[, PROC3 := NULL]
midas15[, PROC4 := NULL]
midas15[, PROC5 := NULL]
midas15[, PROC6 := NULL]
midas15[, PROC7 := NULL]
midas15[, PROC8 := NULL]
gc()

# Number of patients
length(unique(midas15$Patient_ID))
# 4,679,372

# Admission dates
summary(midas15$ADMDAT)
# From 1985-03-20 to 2015-12-31
# Keep only records from 01/01/1995 (admission dates)
midas15 <- subset(midas15, ADMDAT >= "1995-01-01")

# Remove records with discarge date before admission
midas15[which(midas15$ADMDAT > midas15$DSCHDAT), ]
# None

range(midas15$ADMDAT)
# "1995-01-01" "2015-12-31"
range(midas15$DSCHDAT)
# "1995-01-01" "2016-02-09"

range(midas15$AGE)
# 18 to 124
hist(midas15$AGE, 100)

# NEW (07/22/2017): keep inpatient records only
midas15 <- droplevels(subset(midas15,
                             PAT_TYPE %in% c("Inpatinet Before 2008", "Inpatient")))

# Sort----
setkey(midas15,
       Patient_ID,
       ADMDAT)
summary(midas15)
gc()

#**********************************************************
# Separate diagnostic codes (DX1:DX9)
dx <- midas15[, .(Patient_ID, DX1, DX2, DX3, DX4, DX5, DX6, DX7, DX8, DX9)]
cnames <- names(dx)

dx.1.3 <- copy(dx)
dx.1.3[, cnames[-1] := lapply(dx.1.3[, cnames[-1], with = FALSE],
                              substr,
                              start = 1,
                              stop = 3)]
gc()

save(midas15, dx, dx.1.3,  
     file = "midas15_dakota_11032017.RData", 
     compress = FALSE)

#**********************************************************
# PART II----
load("midas15_dakota_11032017.RData")
# CHECKPOINT: is total bill different for men and women?
# Restrict total bill to $10^2 - $10^6 interval
hist(log10(midas15$TOTBIL), 100)

# Vascular Disease: Miocardial Infarction----
# 410 Acute myocardial infarction
## 410.0 Acute myocardial infarction of anterolateral wall
### 410.00 Acute myocardial infarction of anterolateral wall, episode of care unspecified
### 410.01 Acute myocardial infarction of anterolateral wall, initial episode of care
### 410.02 Acute myocardial infarction of anterolateral wall, subsequent episode of care
## 410.1 Acute myocardial infarction of other anterior wall
### 410.10 Acute myocardial infarction of other anterior wall, episode of care unspecified
### 410.11 Acute myocardial infarction of other anterior wall, initial episode of care
### 410.12 Acute myocardial infarction of other anterior wall, subsequent episode of care
## 410.2 Acute myocardial infarction of inferolateral wall
### 410.20 Acute myocardial infarction of inferolateral wall, episode of care unspecified
### 410.21 Acute myocardial infarction of inferolateral wall, initial episode of care
### 410.22 Acute myocardial infarction of inferolateral wall, subsequent episode of care
## 410.3 Acute myocardial infarction of inferoposterior wall
### 410.30 Acute myocardial infarction of inferoposterior wall, episode of care unspecified
### 410.31 Acute myocardial infarction of inferoposterior wall, initial episode of care
### 410.32 Acute myocardial infarction of inferoposterior wall, subsequent episode of care
## 410.4 Acute myocardial infarction of other inferior wall
### 410.40 Acute myocardial infarction of other inferior wall, episode of care unspecified convert
### 410.41 Acute myocardial infarction of other inferior wall, initial episode of care
### 410.42 Acute myocardial infarction of other inferior wall, subsequent episode of care
## 410.5 Acute myocardial infarction of other lateral wall
### 410.50 Acute myocardial infarction of other lateral wall, episode of care unspecified
### 410.51 Acute myocardial infarction of other lateral wall, initial episode of care
### 410.52 Acute myocardial infarction of other lateral wall, subsequent episode of care
## 410.6 True posterior wall infarction
### 410.60 True posterior wall infarction, episode of care unspecified
### 410.61 True posterior wall infarction, initial episode of care
### 410.62 True posterior wall infarction, subsequent episode of care
## 410.7 Subendocardial infarction
### 410.70 Subendocardial infarction, episode of care unspecified
### 410.71 Subendocardial infarction, initial episode of care
### 410.72 Subendocardial infarction, subsequent episode of care
## 410.8 Acute myocardial infarction of other specified sites
### 410.80 Acute myocardial infarction of other specified sites, episode of care unspecified
### 410.81 Acute myocardial infarction of other specified sites, initial episode of care
### 410.82 Acute myocardial infarction of other specified sites, subsequent episode of care
## 410.9 Acute myocardial infarction of unspecified site
### 410.90 Acute myocardial infarction of unspecified site, episode of care unspecified
### 410.91 Acute myocardial infarction of unspecified site, initial episode of care
### 410.92 Acute myocardial infarction of unspecified site, subsequent episode of care

# AMI as reason for admission (DX1)
midas15[, ami.dx1 := (dx.1.3$DX1 == "410")]
# AMI as reason for admission (DX1-9)
midas15[, ami := (rowSums(dx.1.3 == "410") > 0)]
addmargins(table(ami = midas15$ami,
                 ami.dx1 = midas15$ami.dx1))

# Keep patients who were admitted for AMI from 01/01/2000 onward
id.keep <- unique(midas15$Patient_ID[midas15$ami.dx1 &
                                       midas15$ADMDAT >= "2000-01-01"])
dt1 <- subset(midas15, 
              Patient_ID %in% id.keep)
setkey(dt1)
length(unique(dt1$Patient_ID))
# 1,645,160 records for 237,496 patients

# Same for DXs and PROCs
dx <- subset(dx, 
             Patient_ID %in% id.keep)
dx.1.3 <- subset(dx.1.3, 
                Patient_ID %in% id.keep)
rm(midas15)
gc()

# # Vascular Disease: Myocardial infarction of anterolateral wall: 410.0x----
# dt1[, ami.antlat := factor(as.numeric(rowSums(dx.1.4 == "4100") > 0))]
# addmargins(table(dt1$ami.antlat))
# 
# # Vascular Disease: Myocardial infarction of other anterior wall: 410.1x
# dt1[, ami.ant := factor(as.numeric(rowSums(dx.1.4 == "4101") > 0))]
# addmargins(table(dt1$ami.ant))
#
# # Vascular Disease: Myocardial infarction of inferolateral, inferoposterior, 
# # inferior or true posterior walls: 410.2x, 410.3x, 410.4x and 410.6x
# dt1[, ami.inf := factor(as.numeric(rowSums(data.table(rowSums(dx.1.4 == "4102", na.rm = TRUE),
#                                                       rowSums(dx.1.4 == "4103", na.rm = TRUE),
#                                                       rowSums(dx.1.4 == "4104", na.rm = TRUE),
#                                                       rowSums(dx.1.4 == "4106", na.rm = TRUE))) > 0))]
# addmargins(table(dt1$ami.inf))
# 
# # Vascular Disease: Myocardial infarction of other lateral wall: 410.5x
# dt1[, ami.lat := factor(as.numeric(rowSums(dx.1.4 == "4105") > 0))]
# addmargins(table(dt1$ami.lat))
# 
# # Vascular Disease: Myocardial infarction of subendocardial wall: 410.5x
# # NOTE: BEST (JK)
# dt1[, ami.subec := factor(as.numeric(rowSums(dx.1.4 == "4107") > 0))]
# addmargins(table(dt1$ami.subec))
# 
# # Vascular Disease: Myocardial infarction of unspecified sites: 410.8x and 410.9x
# dt1[, ami.other := factor(as.numeric(rowSums(data.table(rowSums(dx.1.4 == "4108", na.rm = TRUE),
#                                                         rowSums(dx.1.4 == "4109", na.rm = TRUE))) > 0))]
# addmargins(table(dt1$ami.other))

########################################
# Risk factors----
# See "C:\Users\ds752\Documents\svn_local\trunk\Cardiovascular\MCHADS\source\final\MIDAS ICD-9 Code Counts.pptx" for details
# 1. Unused CHF codes----
# 428 Heart failure
## 428.1 Left heart failure
## 428.2 Systolic heart failure
## 428.3 Diastolic heart failure
## 428.4 Combined systolic and diastolic heart failure
## 428.9 Heart failure, unspecified

# 1a. Acute CFH----
## 428.0 Congestive heart failure, unspecified
### 428.20 Systolic heart failure, unspecified
### 428.21 Acute systolic heart failure
### 428.23 Acute on chronic systolic heart failure
### 428.30 Diastolic heart failure, unspecified
### 428.31 Acute diastolic heart failure
### 428.33 Acute on chronic diastolic heart failure
### 428.40 Combined systolic and diastolic heart failure, unspecified
### 428.41 Acute combined systolic and diastolic heart failure
### 428.43 Acute on chronic combined systolic and diastolic heart failure
dt1[, chf.acute := (rowSums(data.table(rowSums(dx == "4280", na.rm = TRUE),
                                       rowSums(dx == "42820", na.rm = TRUE),
                                       rowSums(dx == "42821", na.rm = TRUE),
                                       rowSums(dx == "42823", na.rm = TRUE),
                                       rowSums(dx == "42830", na.rm = TRUE),
                                       rowSums(dx == "42831", na.rm = TRUE),
                                       rowSums(dx == "42833", na.rm = TRUE),
                                       rowSums(dx == "42840", na.rm = TRUE),
                                       rowSums(dx == "42841", na.rm = TRUE),
                                       rowSums(dx == "42843", na.rm = TRUE))) > 0)]
table(dt1$chf.acute)
gc()

# 1b. Acute CFH in DX1----
dt1[, chf.acute.dx1 := (dx$DX1 %in% c("4280",
                                      "42820",
                                      "42821",
                                      "42823",
                                      "42830",
                                      "42831",
                                      "42833",
                                      "42840",
                                      "42841",
                                      "42843"))]
table(chf.acute = dt1$chf.acute,
      chf.acute.dx1 = dt1$chf.acute.dx1)
gc()

# 1c. Chronic CFH----
### 428.22 Chronic systolic heart failure
### 428.32 Chronic diastolic heart failure
### 428.42 Chronic combined systolic and diastolic heart failure
dt1[, chf.chron := (rowSums(data.table(rowSums(dx == "42822", na.rm = TRUE),
                                       rowSums(dx == "42832", na.rm = TRUE),
                                       rowSums(dx == "42842", na.rm = TRUE))) > 0)]
table(dt1$chf.chron)
gc()

# 2. Hypertension----
dt1[, hyp.401 := (rowSums(data.table(rowSums(dx == "4010", na.rm = TRUE),
                                     rowSums(dx == "4011", na.rm = TRUE),
                                     rowSums(dx == "4019", na.rm = TRUE))) > 0)]
table(dt1$hyp.401)

dt1[, hyp.402 := (rowSums(data.table(rowSums(dx == "40200", na.rm = TRUE),
                                     rowSums(dx == "40201", na.rm = TRUE),
                                     rowSums(dx == "40290", na.rm = TRUE),
                                     rowSums(dx == "40291", na.rm = TRUE))) > 0)]
table(dt1$hyp.402)

dt1[, hyp.403 := (rowSums(data.table(rowSums(dx == "40300", na.rm = TRUE),
                                     rowSums(dx == "40301", na.rm = TRUE),
                                     rowSums(dx == "40310", na.rm = TRUE),
                                     rowSums(dx == "40311", na.rm = TRUE),
                                     rowSums(dx == "40390", na.rm = TRUE),
                                     rowSums(dx == "40391", na.rm = TRUE))) > 0)]
table(dt1$hyp.403)

dt1[, hyp.404 := (rowSums(data.table(rowSums(dx == "40400", na.rm = TRUE),
                                     rowSums(dx == "40401", na.rm = TRUE),
                                     rowSums(dx == "40402", na.rm = TRUE),
                                     rowSums(dx == "40403", na.rm = TRUE),
                                     rowSums(dx == "40410", na.rm = TRUE),
                                     rowSums(dx == "40411", na.rm = TRUE),
                                     rowSums(dx == "40412", na.rm = TRUE),
                                     rowSums(dx == "40413", na.rm = TRUE),
                                     rowSums(dx == "40490", na.rm = TRUE),
                                     rowSums(dx == "40491", na.rm = TRUE),
                                     rowSums(dx == "40492", na.rm = TRUE),
                                     rowSums(dx == "40493", na.rm = TRUE))) > 0)]
table(dt1$hyp.404)

dt1[, hyp.405 := (rowSums(data.table(rowSums(dx == "40501", na.rm = TRUE),
                                     rowSums(dx == "40509", na.rm = TRUE),
                                     rowSums(dx == "40511", na.rm = TRUE),
                                     rowSums(dx == "40519", na.rm = TRUE),
                                     rowSums(dx == "40591", na.rm = TRUE),
                                     rowSums(dx == "40599", na.rm = TRUE))) > 0)]
table(dt1$hyp.405)

dt1[, hyp := (rowSums(dt1[, c("hyp.401",
                              "hyp.402",
                              "hyp.403",
                              "hyp.404",
                              "hyp.405"), with = FALSE] == 1) > 0)]
table(dt1$hyp)
gc()

# 3. Diabetes----
dt1[, diab := (rowSums(dx.1.3 == "250", na.rm = TRUE) > 0)]
table(dt1$diab)
gc()

# 4. Chronic liver disease and cirrhosis----
# 571 Chronic liver disease and cirrhosis
## 571.0 Alcoholic fatty liver
## 571.1 Acute alcoholic hepatitis
## 571.2 Alcoholic cirrhosis of liver
## 571.3 Alcoholic liver damage, unspecified
## 571.4 Chronic hepatitis
### 571.40 Chronic hepatitis, unspecified
### 571.41 Chronic persistent hepatitis
### 571.42 Autoimmune hepatitis
### 571.49 Other chronic hepatitis
### 571.5 Cirrhosis of liver without mention of alcohol
### 571.6 Biliary cirrhosis
### 571.8 Other chronic nonalcoholic liver disease
### 571.9 Unspecified chronic liver disease without mention of alcohol
dt1[, cld := (rowSums(dx.1.3 == "571", na.rm = TRUE) > 0)]
table(dt1$cld)
gc()

# # 5. Acute kidney failure----
# # 584 Acute kidney failure
# ## 584.5 Acute kidney failure with lesion of tubular necrosis
# ## 584.6 Acute kidney failure with lesion of renal cortical necrosis
# ## 584.7 Acute kidney failure with lesion of renal medullary [papillary] necrosis
# ## 584.8 Acute kidney failure with other specified pathological lesion in kidney
# ## 584.9 Acute kidney failure, unspecified
# dt1[, akf := (rowSums(dx.1.3 == "584", na.rm = TRUE) > 0)]
# table(dt1$akf)

# 5a. Chronic kidney disease----
# 585 Chronic kidney disease (ckd)
## 585.1 Chronic kidney disease, Stage I
## 585.2 Chronic kidney disease, Stage II (mild)
## 585.3 Chronic kidney disease, Stage III (moderate)
## 585.4 Chronic kidney disease, Stage IV (severe)
## 585.5 Chronic kidney disease, Stage V
## 585.6 End stage renal disease
## 585.9 Chronic kidney disease, unspecified
dt1[, ckd := (rowSums(dx.1.3 == "585", na.rm = TRUE) > 0)]
table(dt1$ckd)
gc()

# 6. COPD----
# 490 Bronchitis, not specified as acute or chronic
# 491 Chronic bronchitis
# 492 Emphysema
# 493 Asthma
# 494 Bronchiectasis
# 495 Extrinsic allergic alveolitis
# 496 Chronic airway obstruction, not elsewhere classified
dt1[, copd := (rowSums(data.table(rowSums(dx.1.3 == "490", na.rm = TRUE),
                                  rowSums(dx.1.3 == "491", na.rm = TRUE),
                                  rowSums(dx.1.3 == "492", na.rm = TRUE),
                                  rowSums(dx.1.3 == "493", na.rm = TRUE),
                                  rowSums(dx.1.3 == "494", na.rm = TRUE),
                                  rowSums(dx.1.3 == "495", na.rm = TRUE),
                                  rowSums(dx.1.3 == "496", na.rm = TRUE))) > 0)]
table(dt1$copd)
gc()

# 7. Disorders of lipoid metabolism disorder----
# 272 Disorders of lipoid metabolism
## 272.0 Pure hypercholesterolemia
## 272.1 Pure hyperglyceridemia
## 272.2 Mixed hyperlipidemia
## 272.3 Hyperchylomicronemia
## 272.4 Other and unspecified hyperlipidemia
## 272.5 Lipoprotein deficiencies (REMOVED, 07/21/2017, JBK)
## 272.6 Lipodystrophy (REMOVED, 07/21/2017, JBK)
## 272.7 Lipidoses (REMOVED, 07/21/2017, JBK)
## 272.8 Other disorders of lipoid metabolism
## 272.9 Unspecified disorder of lipoid metabolism
dt1[, lipid := (rowSums(data.table(rowSums(dx == "2720", na.rm = TRUE),
                                   rowSums(dx == "2721", na.rm = TRUE),
                                   rowSums(dx == "2722", na.rm = TRUE),
                                   rowSums(dx == "2723", na.rm = TRUE),
                                   rowSums(dx == "2724", na.rm = TRUE),
                                   rowSums(dx == "2728", na.rm = TRUE),
                                   rowSums(dx == "2729", na.rm = TRUE))) > 0)]
table(dt1$lipid)
gc()

# Clean memory
dt1
summary(dt1)
rm(dx,
   dx.1.3)
gc()

#**********************************************************
# First MI discharge (DX1) between 01/01/2000 and 12/31/2015
setkey(dt1, DSCHDAT, Patient_ID)

dt1[, first := min(DSCHDAT[ami.dx1 &
                             DSCHDAT >= "2000-01-01"],
                   na.rm = TRUE), 
    by = Patient_ID]

# Admissions prior to first MI (5 years look-back)
dt1[, prior := ((DSCHDAT < first) & 
                  (difftime(DSCHDAT, 
                            first,
                            units = "days") < 5*365.25))]

# First AF admissions
dt1[, current := (DSCHDAT == first)]

# Summary
sum(dt1$prior)
sum(dt1$current)
dt1 <- droplevels(dt1)
summary(dt1)
save(dt1, file = "dt1_11032017.RData", compress = FALSE)

#**********************************************************
# PART III----
load("dt1_11032017.RData")

# Outcomes and histories (prior to 1st PCI)----
system.time(
  hh <- dt1[, list(ADMDAT,
                   DSCHDAT,
                   patbdte,
                   NEWDTD,
                   CAUSE,
                   HOSP,
                   DIV,
                   ZIP,
                   SEX,
                   PRIME,
                   TOTBIL,
                   RACE,
                   HISPAN,
                   AGE,
                   dschyear = as.numeric(substr(DSCHDAT, 1, 4)),
                   first,
                   prior,
                   current,
                   ami.dx1,
                   ami,
                   post.ami.dx1 = sum(ami.dx1 & 
                                    !(prior | current) &
                                    (difftime(ADMDAT,
                                              first,
                                              units = "days") > 0) &
                                    (is.na(NEWDTD) | (difftime(NEWDTD,
                                                               ADMDAT,
                                                               units = "days")) > 0)) > 0,
                   post.ami.dx1.dat = min(ADMDAT[ami.dx1 & 
                                               !(prior | current) &
                                               (difftime(ADMDAT,
                                                         first,
                                                         units = "days") > 0) &
                                               (is.na(NEWDTD) | (difftime(NEWDTD,
                                                                          ADMDAT,
                                                                          units = "days")) > 0)],
                                      na.rm = TRUE),
                   hami = (sum(ami & prior) > 0),
                   hchf.acute = (sum(chf.acute & prior) > 0),
                   chf.acute.current = (sum(chf.acute & current) > 0),
                   hchf.chron = (sum(chf.chron & (prior | current)) > 0), 
                   hhyp = (sum(hyp & (prior | current)) > 0), 
                   hdiab = (sum(diab & (prior | current)) > 0), 
                   hcld = (sum(cld & (prior | current)) > 0),
                   hckd = (sum(ckd & (prior | current)) > 0),
                   hcopd = (sum(copd & (prior | current)) > 0),
                   hlipid = (sum(lipid & (prior | current)) > 0)), 
            by = Patient_ID]
)
summary(hh)
gc()

# Separate first MI admission
# Remove all cases with no MI records
case <- unique(subset(hh, current & ami.dx1))

# CHECKPOINT: did we find all readmission dates?
sum(is.finite(case$post.ami.dat))
sum(case$post.ami)

# If the are are more than 1 records of 1st MI admissions per person,
nrow(case) - length(unique(case$Patient_ID))
# Remove 567 patient with duplicate records
case <- case[!(Patient_ID %in% Patient_ID[duplicated(Patient_ID)]), ]
summary(case)

# Remove patients that died at 1st MI discharge
case <- droplevels(subset(case, (is.na(NEWDTD) | NEWDTD != first)))

# Remove anyone with history of MI
case <- droplevels(subset(case, !hami))
case[, hami := NULL]

# MI discharges
t1 <- table(case$dschyear,
            case$ami.dx1)
t1 <- data.table(Year = as.numeric(rownames(t1)),
                 Count = t1[, 1])

t1

# Plot number of AMI admissions over time
p1 <- ggplot(data = t1,
             aes(x = Year,
                 y = Count)) +
  geom_line(size = 0.5,
            color = "blue") +
  geom_point(size = 2,
             shape = 21,
             fill = "blue") +
  scale_x_continuous(breaks = unique(t1$Year),
                     labels = unique(t1$Year)) +
  ggtitle("Number of Discharges After 1st AMI Over Time") +
  theme(axis.text.x = element_text(angle = 45,
                                   hjust = 1),
        plot.title = element_text(hjust = 0.5))
print(p1)

png(filename = "tmp/ami_adm_over_time.png",
     height = 4,
     width = 5,
     units = 'in',
     res = 300)
print(p1)
graphics.off()

# Save cases----
save(case, 
     file = "case_11032017.RData",
     compress = FALSE)
write.csv(case,
          "case_11032017.csv",
          row.names = FALSE)