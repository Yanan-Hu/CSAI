/* Adapted from Code/SAS/Data pre-processing/npdc clean.sas (Yanan-Hu/CSAI),
   the "Define women's characteristics" block:
     BMI computed from height/weight, missing-value sentinel handling
     (999/99/9999), and the motheragegp / bmigp categorical derivations,
     followed by the PROC TABULATE cross-tab further down the script.
   The original operates on the full npdc_main cohort (127,673 rows) loaded
   from a private LIBNAME; this bundle substitutes a small mock cohort with
   the same MWeight/MHEIGHT/yr_dob_mum/YEAR columns via inline datalines.
   The derivation logic itself -- including the deliberate sentinel-value
   convention (9/99/999/9999 rather than deleting missing data, per the
   script's own header note) -- is unchanged from the source script. */

data npdc_main;
  input MWeight MHEIGHT yr_dob_mum YEAR;
  datalines;
62  165 1990 2018
78  172 1985 2017
0   0   1990 2019
95  158 1978 2016
55  160 2001 2020
110 175 1988 2018
70  168 1993 2019
0   170 1995 2017
88  0   1982 2018
48  152 1979 2016
;
run;

data npdc_main; set npdc_main;
if MWeight=. or MWeight=0 then MWeight=999;
if MHEIGHT=. or MHEIGHT=0 then MHEIGHT=999;
bmi=MWeight/((MHEIGHT/100)*(MHEIGHT/100));
if MWeight=999 or MHEIGHT=999 then bmi=99;
if yr_dob_mum=1900 or yr_dob_mum>=2014 then yr_dob_mum=9999; *unrealistic value;
mother_age=YEAR-yr_dob_mum;
if mother_age<0 then mother_age=99;

if 0<mother_age<20 then motheragegp=1;
else if 20<=mother_age<35 then motheragegp=2;
else if 80>mother_age>=35 then motheragegp=3; *upper limit for excluding unrealistic value;
else motheragegp=9;

if MWeight=999 or MHEIGHT=999 then bmigp=9;
else if 0<bmi<18.5 then bmigp=1;
else if 18.5<=bmi<25 then bmigp=2;
else if 25<=bmi<30 then bmigp=3;
else if 100>bmi>=30 then bmigp=4; *upper limit for excluding unrealistic value;
else bmigp=9;
run;

proc tabulate data=npdc_main;
class motheragegp bmigp YEAR/missing;
tables motheragegp bmigp, YEAR*(n colpctn);
run;

proc print data=npdc_main noobs;
var MWeight MHEIGHT bmi mother_age motheragegp bmigp;
run;
