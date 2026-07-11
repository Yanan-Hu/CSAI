/* Adapted from Code/SAS/Cost assignment/npdc cost.sas (Yanan-Hu/CSAI),
   the DRG cost-table import + missing-value imputation block, plus the
   obstetric-admission flagging logic further down the same script:

     "import cost file" / "if private_16=. then private_16=0;" etc.
     "identify obstetric-related admission" (ARRAY d_code / substr scan)

   The DRG/cost rows below are the real first data rows of the repo's own
   Code/SAS/Cost assignment/drgcost_new.csv (thousands separators stripped
   for plain-numeric datalines; values otherwise unchanged), inlined so the
   bundle is self-contained -- the shipped runner uploads script text only,
   not sibling data files (see jenner-check/README.md). A small mock
   inpatient cohort substitutes for the private matern/npdc_inp linkage
   data the original script joins against. The imputation defaults and the
   diagnosis-code array scan are otherwise unchanged from the source script. */

data drgcost;
  input drg $ cost_16 cost_17 cost_18 cost_19 cost_20
        ave_charge_16 ave_charge_17 ave_charge_18 ave_charge_19 ave_charge_20
        private_16 paed_16 private_17 paed_17 private_18 paed_18
        private_19 paed_19 private_20 paed_20;
  datalines;
801A 47003 50874 48714 51670 52477 24788.02 25322.82 27190.48 27317.91 28714.8 0.15 1.77 0.14 1.58 0.13 1.42 0.18 1.29 0.13 1.47
801B 20121 21425 21214 21077 22805 11826.11 12428.45 14594.08 14356.59 15420.61 0.18 1.31 0.17 0.85 0.18 0.92 0.15 1 0.21 0.95
801C 5480 8053 8276 8682 9752 4241.02 4092.92 5933.6 5867.12 6560.32 0.3 1.15 0.13 0.8 0.18 0.84 0.22 1 0.22 1
960Z 8792 16316 5905 3645 7347 1447.92 685.17 2935.11 3187.11 3824.94 . . . . . . . . . .
961Z 3363 6709 3207 1968 1621 2226.92 1380.47 9265.23 2697.25 3413.98 . . . . . . . . . .
A06A 223719 . . . . 122701.19 120643 . . . 0.1 1 0.09 1.19 0.12 1.16 . . . .
A07A 152812 . . . . . . . . . 0.07 1 0.06 2 0.06 1.98 . . . .
;
run;

data drgcost; set drgcost;
if drg='' then delete;
if private_16=. then private_16=0;
if private_17=. then private_17=0;
if private_18=. then private_18=0;
if private_19=. then private_19=0;
if private_20=. then private_20=0;

if paed_16=. then paed_16=1;
if paed_17=. then paed_17=1;
if paed_18=. then paed_18=1;
if paed_19=. then paed_19=1;
if paed_20=. then paed_20=1;

if cost_16=. then cost_16=0;
if cost_17=. then cost_17=0;
if cost_18=. then cost_18=0;
if cost_19=. then cost_19=0;
if cost_20=. then cost_20=0;

if ave_charge_16=. then ave_charge_16=0;
if ave_charge_17=. then ave_charge_17=0;
if ave_charge_18=. then ave_charge_18=0;
if ave_charge_19=. then ave_charge_19=0;
if ave_charge_20=. then ave_charge_20=0;
run;

proc print data=drgcost noobs;
var drg cost_16 cost_17 cost_18 cost_19 cost_20 private_16 paed_16;
run;

/* mock inpatient admission cohort standing in for matern.npdc_inp --
   diagnosis_code1-diagnosis_code3 mirrors the shape the source script
   scans (50 diagnosis-code columns; 3 is enough to exercise the array loop) */
data mom_inp;
  length drg $4 diagnosis_code1 diagnosis_code2 diagnosis_code3 diagnosis_codeP $6;
  input drg $ diagnosis_code1 $ diagnosis_code2 $ diagnosis_code3 $ diagnosis_codeP $;
  datalines;
801A O800  Z370  .     O800
801B O342  O809  .     O342
960Z P220  .     .     P220
A06A I269  O411  .     O411
A07A O140  O151  .     O140
;
run;

data mom_cost; merge mom_inp (in=a) drgcost (in=b); by drg;
if a then output; run;

*identify obstetric-related admission;
data mom_cost; set mom_cost;
obstetric=0;
ARRAY d_code(*) diagnosis_code1-diagnosis_code3;
	do i=1 to dim(d_code);
	d_code (i)=substr(d_code(i), 1, 1);

if d_code (i) in ('O') then do;
obstetric=1;
end;
end;
run;

proc freq data=mom_cost;
tables obstetric drg;
run;
