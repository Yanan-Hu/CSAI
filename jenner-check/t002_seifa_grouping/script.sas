/* Adapted from Code/SAS/Data pre-processing/npdc clean.sas (Yanan-Hu/CSAI),
   the SEIFA (socio-economic disadvantage) grouping + merge block:
     "add SES quintiles from SLA"
   The original reads matern.seifa_2011sla from a private LIBNAME and merges
   it into the full npdc_main cohort (127,673 rows) keyed on SLA_2011_CODE.
   That cohort is de-identified linked hospital data and cannot be shared, so
   this bundle substitutes a small mock cohort. The SLA_2011_CODE/IRSD_decile
   rows below are the first 15 real data rows of the repo's own
   Code/SAS/Data pre-processing/SEIFA_2011SLA.csv, inlined via datalines so
   the bundle is self-contained (the shipped runner uploads script text only
   -- see jenner-check/README.md -- so no sibling data file is read). The
   IRSD-decile-to-SEIFA-quintile recode and the merge/sort logic are
   unchanged from the source script. */

data seifa_2011sla;
  input SLA_2011_CODE IRSD_decile;
  if irsd_decile in (1,2) then seifa=1;
  else if irsd_decile in (3,4) then seifa=2;
  else if irsd_decile in (5,6) then seifa=3;
  else if irsd_decile in (7,8) then seifa=4;
  else if irsd_decile in (9,10) then seifa=5;
  datalines;
105051100 4
105054800 9
105055200 7
105057201 4
105057204 8
105057205 6
105057206 7
105106550 8
105108050 9
105108500 10
105154150 6
105154450 7
105156650 5
105157151 9
105157152 9
;
run;

/* mock cohort standing in for npdc_main (private linked hospital data) --
   reuses SLA codes actually present in the SEIFA rows above (drawn from
   the repo's own SEIFA_2011SLA.csv) */
data npdc_main;
  input aihw_baby_ppn SLA_2011_CODE;
  datalines;
1001 105051100
1002 105054800
1003 105055200
1004 105057201
1005 105057204
1006 105057205
1007 105057206
1008 105106550
1009 105108050
1010 105108500
1011 105154150
1012 105154450
1013 105156650
1014 105157151
1015 105157152
;
run;

proc sort data=seifa_2011sla; by SLA_2011_CODE; run;
proc sort data=npdc_main; by SLA_2011_CODE; run;
data npdc_main; merge npdc_main (in=a) seifa_2011sla;
by SLA_2011_CODE;
if a then output;
run;

proc freq data=npdc_main;
tables seifa;
run;

proc print data=npdc_main noobs;
var aihw_baby_ppn SLA_2011_CODE IRSD_decile seifa;
run;
