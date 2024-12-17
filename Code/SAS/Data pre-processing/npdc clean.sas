************************************************************************************************************************************
* Purpose: Clean up three data sets to do prediction
* Author: Yanan Hu
* Date created: 19 July 2024
* Date last updated: 11 Aug 2024
* Note: do not delete missing value of candidate predictors, treat them as a group (9, 99, 999, etc);
************************************************************************************************************************************;


libname matern "G:\Data in sas format";


****NSW;
data npdc_main; set matern.npdc_main; run;


*1565 duplicates, looks like different babies from the same mom, if keep the first record only (i.e., nodupkey), delete 796 duplicates;
*create a new ID by adding suffix;
proc sort data=npdc_main; by aihw_baby_ppn; run;
data npdc_main; set npdc_main; by aihw_baby_ppn;
if first.aihw_baby_ppn then suffix=0; else suffix+1;
if suffix>0 then aihw_baby_ppn=catx('_', aihw_baby_ppn, suffix);
run;


*Change character var to numeric var, note: has to create a new var;
data npdc_main; set npdc_main;
aborigin_mum_recode_num=input(aborigin_mum_recode,9.);
smoke1st_num=input(smoke1st,9.);
smoke2nd_num=input(smoke2nd,9.);
mdiab_num=input(mdiab,9.);
odiab_num=input(odiab,9.);
mdiab2016_num=input(mdiab2016,9.);
mhyper_num=input(mhyper,9.);
prevpreg_num=input(prevpreg,9.);
csbirth_num=input(csbirth,9.);
labons_num=input(labons,9.);
presen06_num=input(presen06,9.);
DELIV2011_CODE_num=input(DELIV2011_CODE,9.);
DELIV2011_num=input(DELIV2011,9.);
OHYP_NP_num=input(OHYP_NP,9.);
OHYP_P_num=input(OHYP_P,9.);
cobsacc_num=input(cobsacc,9.);
run;


data npdc_main; set npdc_main;
drop aborigin_mum_recode smoke1st smoke2nd mdiab odiab mdiab2016 mhyper prevpreg csbirth labons presen06 DELIV2011_CODE DELIV2011 OHYP_NP OHYP_P cobsacc;
run;


data npdc_main; set npdc_main;
rename aborigin_mum_recode_num=aborigin_mum_recode;
rename smoke1st_num=smoke1st;
rename smoke2nd_num=smoke2nd;
rename mdiab_num=mdiab;
rename odiab_num=odiab;
rename mdiab2016_num=mdiab2016;
rename mhyper_num=mhyper;
rename prevpreg_num=prevpreg;
rename csbirth_num=csbirth;
rename labons_num=labons;
rename presen06_num=presen06;
rename DELIV2011_CODE_num=DELIV2011_CODE;
rename DELIV2011_num=DELIV2011;
rename OHYP_NP_num=OHYP_NP;
rename OHYP_P_num=OHYP_P;
rename cobsacc_num=cobsacc;
run;


*only include IOL, non prior cs, singleton, cephalic pre, term, non-missing delivery mode, live births;
data npdc_main; set npdc_main;
if labons=2 or cswhy2016='13' then output; *add back failed iol;
run;


data npdc_main; set npdc_main;
if labons in (1, 9) then delete; *when adding back failed iol, some of them recorded as spontaneous onset of labour thus delete,9='not stated';
if csbirth=1 then delete; *previous birth was cs; *note cstotal (number of previous cs) was not requested;
if cswhy2016='15' then delete; *previous cs;
if presen06 not in ( 1, 3, 4) then delete;
if plural>1 then delete; *no missing data;
if DELIV2011_CODE=9 or DELIV2011=9 then delete; *no missing data, 9='not stated';
if gestage<37 or gestage>41 or gestage=. then delete;
if DTHTYPE_RECODE='2' then delete; *stillbirth;
if year=2015 then delete; *no BMI data;
run;


*test eligibility criteria;
proc freq data=npdc_main;
tables labons csbirth cswhy2016 presen06 plural DELIV2011_CODE gestage DTHTYPE_RECODE year; run;


*Define women's characteristicss;
data npdc_main; set npdc_main;
if MWeight=. or MWeight=0 then MWeight=999; 
if MHEIGHT=. or MHEIGHT=0 then MHEIGHT=999;
bmi=MWeight/((MHEIGHT/100)*(MHEIGHT/100));
if MWeight=999 or MHEIGHT=999 then bmi=99;
if yr_dob_mum=1900 or yr_dob_mum>=2014 then yr_dob_mum=9999; *unrealistic value;
mother_age=YEAR-yr_dob_mum;
if mother_age<0 then mother_age=99;

*Note: different vars were collected at different year (e.g., GDM: odiab (1994-2015) mdiab2016 (2016 onwards), most var are charater, mheight and mweight were collected since 2016;
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

if RA_2011_CODE='10' then rurality=1; *major city;
else if RA_2011_CODE='11' then rurality=2; *inner regional;
else if RA_2011_CODE='12' then rurality=3; *outer regional;
else if RA_2011_CODE='13' then rurality=4; *remote;
else if RA_2011_CODE='14' then rurality=5; *very remote;
else rurality=9;


if aborigin_mum_recode=2 then aborigin_mum_recode=0; *2 is 'No';
if DELIV2011_CODE=6 or DELIV2011=6 then cs=1;else cs=0;
if ODIAB=1 or MDIAB2016=3 then gest_diab=1; else gest_diab=0; *cannote differentiate 'no' with 'not stated/missing';
if MDIAB=1 or MDIAB2016 in (1 2 4) then pre_diab=1; else pre_diab=0; *cannote differentiate 'no' with 'not stated/missing';


if year NE 2016 then do;
if LHDHOSP_2010_CODE='XPRV' then private_hospital=1; 
else if LHDHOSP_2010_CODE not in ( '' 'YYYY' 'X999') then private_hospital=0;
else private_hospital=9;
end;
run;


 *private hospital 'LHDHOSP_2010_CODE' was missing for 2016, identify through major diagnosis code, ar_drg code and birth date; 
data npdc_main_2016; set npdc_main (where=(year=2016)); *n=27285;
format bdob ddmmyy10.;
keep aihw_mom_ppn aihw_baby_ppn bdob;
run;


data npdc_inp_birth_short; set matern.npdc_inp; *inp data starts from 2016;
aihw_mom_ppn=aihw_ppn;
format episode_start_date ddmmyy10.;
format episode_end_date ddmmyy10.;

if hospital_type=4 then private_hospital=1; else private_hospital=0;

ARRAY code(*)diagnosis_code1-diagnosis_code50;
	DO i=1 to dim(code);
	code (i)=substr(code(i), 1, 1);

if code (i) in ('O') then do;
birth=1;
end;
end;


if birth ne 1 then do;
length diagnosis_short ar_drg_short $1; 
diagnosis_short=diagnosis_codeP; 
ar_drg_short=ar_drg;
if diagnosis_short in ('O') 
or ar_drg in ('O') 
then birth=1; 
end;

if birth ne 1 then delete;

keep aihw_mom_ppn private_hospital episode_end_date episode_start_date;
run;
*note: Previous thoughts: cannote limit to admit_year=2016 since a few births might across year, for example, admit in Dec 2015 but gavie birth in Jan 2016,
but the inp starts from Jan 16, thus explain the non-matching record.


*cross join, consider mutilple births during a year;
proc sort data=npdc_inp_birth_short; by aihw_mom_ppn; run;
proc sort data=npdc_main_2016; by aihw_mom_ppn; run;
proc sql noprint;
create table test as
select*from npdc_main_2016 a 
join npdc_inp_birth_short b
on a.aihw_mom_ppn=b.aihw_mom_ppn;
quit;


data test2; set test;
if episode_start_date<=bdob<=episode_end_date then output;
drop episode_start_date episode_end_date bdob;
run;


proc sort data=test2 nodupkey; by aihw_baby_ppn; run;
proc sort data=npdc_main nodupkey; by aihw_baby_ppn; run;
data npdc_main; merge npdc_main test2;
by aihw_baby_ppn;
run;


*add SES quintiles from SLA;
data seifa_2011sla; set matern.seifa_2011sla;
if irsd_decile in (1,2) then seifa=1;
else if irsd_decile in (3,4) then seifa=2;
else if irsd_decile in (5,6) then seifa=3;
else if irsd_decile in (7,8) then seifa=4;
else if irsd_decile in (9,10) then seifa=5;
run;	


proc sort data=seifa_2011sla; by SLA_2011_CODE; run;
proc sort data=npdc_main; by SLA_2011_CODE; run;
data npdc_main; merge npdc_main (in=a) seifa_2011sla;
by SLA_2011_CODE;
if a then output;
run;


*grouping cob to regions;
data cobsacc_grouping; set matern.cobsacc_grouping;
if major_group='Australia (includes External Territories)' then cob_region=1;
else if major_group='OCEANIA AND ANTARCTICA' then cob_region=2;
else if major_group='Europe' then cob_region=3;
else if major_group='Africa' then cob_region=4;
else if major_group='Asia' then cob_region=5;
else if major_group='America' then cob_region=6;
else cob_region=9;
drop cob minor_group major_group;
run;


proc sort data=cobsacc_grouping; by cobsacc; run;
proc sort data=npdc_main; by cobsacc; run;
data npdc_main; merge npdc_main (in=a) cobsacc_grouping; 
by cobsacc;
if a then output; 
run;


*rename variables;
data npdc_main; set npdc_main;
state='NSW';
if prevpreg=0 then gravidity=0;
else gravidity=pregnum; *7 women record no previous pregancy but had number of previous pregnancy >1;

parity=prevpreg;
gest_weeks=gestage;
gest_weeks_first_visit=ancare2011;
num_ant_visit=ancarenum;
atsi=aborigin_mum_recode;
smoke_b20=smoke1st;
smoke_a20=smoke2nd;
pre_hyper=mhyper;
gest_hyper=OHYP_NP;
preeclampsia=OHYP_P; *did not request ehyper-eclampsia flag;


if private_hospital=. then private_hospital=9;
if seifa=. then seifa=9;
if gravidity=. then gravidity=99;
if parity=. then parity=9;
if gest_weeks=. then gest_weeks=99;
if gest_weeks_first_visit=. then gest_weeks_first_visit=99;
if num_ant_visit=. then num_ant_visit=99;
if num_ant_visit=90 then num_ant_visit=99;
if smoke_b20=. then smoke_b20=9;
if smoke_a20=. then smoke_a20=9;
if pre_hyper=. then pre_hyper=0; *cannote differentiate 'no' with 'not stated/missing';
if gest_hyper=. then gest_hyper=0; *cannote differentiate 'no' with 'not stated/missing';
if preeclampsia=. then preeclampsia=0; *cannote differentiate 'no' with 'not stated/missing';
if cob_region=. then cob_region=9;

if gravidity=0 then graviditygp=1;
else if gravidity=1 then graviditygp=2;
else if gravidity=2 then graviditygp=3;
else if gravidity=3 then graviditygp=4;
else if 4<=gravidity<99 then graviditygp=5;
else graviditygp=9;

if 0<gest_weeks_first_visit<14 then first_visitgp=1;
else if 14<=gest_weeks_first_visit=<19 then first_visitgp=2;
else if 19<gest_weeks_first_visit<90 then first_visitgp=3;
else first_visitgp=9;

if num_ant_visit=0 then num_visitgp=1;
else if 1<=num_ant_visit=<6 then num_visitgp=2;
else if 7<=num_ant_visit=<9 then num_visitgp=3;
else if 10<=num_ant_visit<99 then num_visitgp=4;
else num_visitgp=9;
run;


*limit to varaible for use;
data npdc_main; set npdc_main;
keep aihw_baby_ppn aihw_mom_ppn mheight mweight state year gravidity parity gest_weeks gest_weeks_first_visit num_ant_visit atsi smoke_b20 smoke_a20 pre_diab pre_hyper seifa preeclampsia
gest_hyper gest_diab cs rurality bmigp motheragegp bmi mother_age private_hospital cob_region graviditygp first_visitgp num_visitgp; run;


proc tabulate data=npdc_main;
class parity gest_weeks atsi smoke_b20 smoke_a20 pre_diab pre_hyper seifa preeclampsia
gest_hyper gest_diab cs rurality bmigp motheragegp private_hospital cob_region year graviditygp first_visitgp num_visitgp/missing;
tables all parity gest_weeks atsi seifa rurality smoke_b20 smoke_a20 pre_diab pre_hyper preeclampsia
gest_hyper gest_diab cs bmigp motheragegp private_hospital cob_region graviditygp first_visitgp num_visitgp, year*(n colpctn);
run;


*save data (n=127,673);
libname phd "G:\Papers\Yanan Hu\PhD\clean data";
data phd.npdc_main;set npdc_main; run;


libname data "G:\Papers\Yanan Hu\PhD\python\data";
data data.npdc_dev;set npdc_main (where=(year ne 2020)); run;
data data.npdc_val;set npdc_main (where=(year=2020)); run;
