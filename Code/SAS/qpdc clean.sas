************************************************************************************************************************************
* Purpose: Clean up three data sets to do prediction
* Author: Yanan Hu
* Date created: 19 July 2024
* Date last updated: 11 Aug 2024
* Note: do not delete missing value of candidate predictors, treat them as a group (9, 99, 999, etc);
************************************************************************************************************************************;


libname matern "G:\Data in sas format";


****QLD;
data qpdc_mum_main; set matern.qpdc_mum_main;
aihw_mom_ppn=person_id;
mum_ev_id=ev_id;
drop person_id ev_id;
length minor_group $47;
if cntry_birth_broad='Southern and Eastern Europe' then minor_group='South Eastern Europe';
else if cntry_birth_broad='Oceania and Antarctica' then minor_group='Antarctica';
else if cntry_birth_broad='United Kingdom, Channel Islands & Isle of' then minor_group='United Kingdom, Channel Islands and Isle of Man';
else minor_group=cntry_birth_broad;
run;


data qpdc_baby_main; set matern.qpdc_baby_main;
aihw_mom_ppn=mum_person_id;
aihw_baby_ppn=person_id;
baby_ev_id=ev_id;
drop person_id mum_person_id ev_id;
run;
*note, has 1 dupicated aihw_baby_ppn, but not aihw_baby_ppn baby_ev_id;

proc sort data=qpdc_mum_main; by aihw_mom_ppn mum_ev_id; run;
proc sort data=qpdc_baby_main; by aihw_mom_ppn mum_ev_id; run;
data qpdc_main; merge qpdc_mum_main qpdc_baby_main (in=a);
by aihw_mom_ppn mum_ev_id; 
if a then output;
run;

proc sort data=qpdc_main; by aihw_mom_ppn mum_ev_id; run;
data qpdc_main; set qpdc_main; by aihw_mom_ppn mum_ev_id;
if first.mum_ev_id then birth_ep=1; else birth_ep+1;
run;


*only include IOL, non prior cs, singleton, cephalic pre, term, non-missing delivery mode, live births;
data qpdc_main; set qpdc_main;
if labour_onset='Induced' or caesar in ('O610' 'O611' 'O618' 'O619') then output; *add back failed iol;
run;

data qpdc_main; set qpdc_main;
if labour_onset in ('Spontaneous' '') then delete; *when adding back failed iol, some of them recorded as spontaneous onset of labour thus delete;
if nr_prev_caesar>0 then delete; *note: last birth method file did not request, thus only use nr_prev_caesar;
if pres not in ('Vertex' 'Cephalic' 'Face' 'Brow' 'Other Cephalic') then delete;
if plur not='Singleton' then delete;
if deliv_code in ('Not Stated / Unknown' '') then delete;
if gest_weeks<37 or gest_weeks>41 or gest_weeks=. then delete;
if born_alive='Still Birt' then delete;
run;


*test eligibility criteria;
proc freq data=qpdc_main;
tables labour_onset nr_prev_caesar pres plur deliv_code gest_weeks born_alive; run;


*Define women's characteristicss;
data qpdc_main; set qpdc_main;
year=year(baby_dob);
mother_age=year-mother_yob;
if mother_age=. then mother_age=99;
if mother_age>80 then mother_age=99;

if 0<mother_age<20 then motheragegp=1; 
else if 20<=mother_age<35 then motheragegp=2;
else if 80>mother_age>=35 then motheragegp=3; *upper limit for excluding unrealistic value;
else motheragegp=9;

*weight and height are not requesuted;
if bmi=. then bmi=99;
if 0<bmi<18.5 then bmigp=1;
else if 18.5<=bmi<25 then bmigp=2;
else if 25<=bmi<30 then bmigp=3;
else if 100>bmi>=30 then bmigp=4; *upper limit for excluding unrealistic value;
else bmigp=9;


if indig_status='Ye' then atsi=1;
else if indig_status='No' then atsi=0;
else atsi=9;

if deliv_code in ('Classical Caesarean Section' 'Lower Segment Caesarean Section') then cs=1; else cs=0;
if last_birth_method_status='Yes' or birth_ep>1 then parity=1; else parity=0;
if prev_preg in ('No' 'Not') and total_prev_preg=. then total_prev_preg=0; *this situation means total_prev_preg was not collected due to not reported 'Yes' for prev_preg;

if smoke_status_b20='Yes' then smoke_b20=1;
else if smoke_status_b20 in ('No') then smoke_b20=0;
else smoke_b20=9;

if smoke_status_a20='Yes' then smoke_a20=1;
else if smoke_status_a20 in ('No') then smoke_a20=0;
else smoke_a20=9;
run;


*****************************************************************************************************************************;
*add SES quintiles from postcode;
data irsd_2016; set matern.irsd_2016;
if irsd_decile in (1,2) then seifa=1;
else if irsd_decile in (3,4) then seifa=2;
else if irsd_decile in (5,6) then seifa=3;
else if irsd_decile in (7,8) then seifa=4;
else if irsd_decile in (9,10) then seifa=5;
else seifa=9;
run;	


proc sort data=irsd_2016; by post_code; run;
proc sort data=qpdc_main; by post_code; run;
data qpdc_main; merge qpdc_main (in=a) irsd_2016;
by post_code;
if a then output;
run;


data ra_code_2016; set matern.ra_code_2016;
if RA_NAME_2016='Major Cities of Australia' then rurality=1; 
else if RA_NAME_2016='Inner Regional Australia' then rurality=2; 
else if RA_NAME_2016='Outer Regional Australia' then rurality=3; 
else if RA_NAME_2016='Remote Australia' then rurality=4; 
else if RA_NAME_2016='Very Remote Australia' then rurality=5;
else rurality=9; 
post_code=POSTCODE_2017;
drop POSTCODE_2017;
run;	


proc sort data=ra_code_2016; by post_code; run;
proc sort data=qpdc_main; by post_code; run;
data qpdc_main; merge qpdc_main (in=a) ra_code_2016;
by post_code;
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
drop cobsacc cob major_group;
run;


proc sort data=cobsacc_grouping nodupkey; by minor_group; run;
proc sort data=qpdc_main; by minor_group; run;
data qpdc_main; merge qpdc_main (in=a) cobsacc_grouping; 
by minor_group;
if a then output; 
run;


*GDM, GH, preeclampsia;
data qpdc_mum_preg_comp; set matern.qpdc_mum_preg_comp; *preg_comp: all start with O;
length preg_cmplc_short $ 4;
preg_cmplc_short=preg_cmplc;
if preg_cmplc_short='O244' then gest_diab=1; else gest_diab=0;
length preg_cmplc_short2 $ 3;
preg_cmplc_short2=preg_cmplc;
if preg_cmplc_short2='O13' then gest_hyper=1; else gest_hyper=0;
if preg_cmplc_short2 in ('O11' 'O14' 'O15') then preeclampsia=1; else preeclampsia=0;
aihw_mom_ppn=person_id;
mum_ev_id=ev_id;
keep aihw_mom_ppn mum_ev_id gest_diab gest_hyper preeclampsia;
run;


*pre-existing diabetes and chronic hypertension;
data qpdc_mum_medic_cond; set matern.qpdc_mum_medic_cond;
length medic_cond_short $ 3;
medic_cond_short=medic_cond;
if medic_cond_short in ('E10' 'E11' 'E12' 'E13' 'E14' 'O24') then pre_diab=1; else pre_diab=0;
if medic_cond_short in ('I10' 'I11' 'I12' 'I13' 'I14' 'I15' 'O10' 'O11') then pre_hyper=1; else pre_hyper=0;
aihw_mom_ppn=person_id;
mum_ev_id=ev_id;
keep aihw_mom_ppn mum_ev_id pre_diab pre_hyper;
run;


data gest_diab; set qpdc_mum_preg_comp (where=(gest_diab=1)); run;
data gest_hyper; set qpdc_mum_preg_comp (where=(gest_hyper=1)); run;
data preeclampsia; set qpdc_mum_preg_comp (where=(preeclampsia=1)); run;
data pre_diab; set qpdc_mum_medic_cond (where=(pre_diab=1)); run;
data pre_hyper; set qpdc_mum_medic_cond (where=(pre_hyper=1)); run;

proc sort data=qpdc_main; by aihw_mom_ppn mum_ev_id; run;
proc sort data=gest_diab nodupkey; by aihw_mom_ppn mum_ev_id; run;
proc sort data=gest_hyper nodupkey; by aihw_mom_ppn mum_ev_id; run;
proc sort data=preeclampsia nodupkey; by aihw_mom_ppn mum_ev_id; run;
proc sort data=pre_diab nodupkey; by aihw_mom_ppn mum_ev_id; run;
proc sort data=pre_hyper nodupkey; by aihw_mom_ppn mum_ev_id; run;

data qpdc_main; merge qpdc_main (in=a) gest_diab gest_hyper preeclampsia pre_diab pre_hyper; 
by aihw_mom_ppn mum_ev_id; 
if a then output; 
run;


*private hospital;
*identifying facility of actual on mother QHAPDC and matching to mmyyyy of birth on PDC;
data qhapdc_mum_main; set matern.qhapdc_mum_main (where=(drg in ('O01A' 'O01B' 'O02A' 'O02B' 'O03A' 'O03B' 'O04A' 'O04B' 'O05Z' 
'O60Z' 'O61Z' 'O63Z' 'O64Z' 'O66Z')));
if FCLTY_NAME='' then private_hospital=9;
else if FCLTY_NAME='Private facility' then private_hospital=1; 
else private_hospital=0;

aihw_mom_ppn=person_id;
merge_birth_date=start_date;
merge_birth_date2=end_date;

format merge_birth_date monyy7.;
format merge_birth_date2 monyy7.;
keep aihw_mom_ppn merge_birth_date merge_birth_date2 private_hospital;
run;


data pdc_baby_birth; set qpdc_main;
merge_birth_date=baby_dob;
merge_birth_date2=baby_dob;
format merge_birth_date monyy7.;
format merge_birth_date2 monyy7.;
keep aihw_baby_ppn aihw_mom_ppn mum_ev_id merge_birth_date merge_birth_date2;
run;


proc sort data=qhapdc_mum_main; by aihw_mom_ppn merge_birth_date; run;
proc sort data=pdc_baby_birth; by aihw_mom_ppn merge_birth_date; run;
data birth_details; merge qhapdc_mum_main pdc_baby_birth (in=a); by aihw_mom_ppn merge_birth_date; if a then output; run;
proc sort data=birth_details nodupkey; by aihw_baby_ppn; run;
data birth_details2; set birth_details (where=(private_hospital=.));run;
data birth_details2; set birth_details2;
drop private_hospital;
run;

proc sort data=qhapdc_mum_main; by aihw_mom_ppn merge_birth_date2; run;
proc sort data=birth_details2; by aihw_mom_ppn merge_birth_date2; run;
data birth_details3; merge qhapdc_mum_main birth_details2 (in=a); by aihw_mom_ppn merge_birth_date2; if a then output; run;

data birth_details4; set birth_details (where=(private_hospital ne .));run;
proc sort data=birth_details4; by aihw_baby_ppn; run;
proc sort data=birth_details3; by aihw_baby_ppn; run;
data birth_details5; merge birth_details4 birth_details3; by aihw_baby_ppn; run;


proc sort data=qpdc_main; by aihw_baby_ppn; run;
proc sort data=birth_details5; by aihw_baby_ppn; run;
data qpdc_main; merge qpdc_main birth_details5; by aihw_baby_ppn; run;


data qpdc_main; set qpdc_main;
state='QLD';
gravidity=total_prev_preg;
gest_weeks_first_visit=gestation_first_visit;
num_ant_visit=total_antenatal_visits;

if gest_diab=. then gest_diab=0;
if gest_hyper=. then gest_hyper=0;
if preeclampsia=. then preeclampsia=0;
if pre_diab=. then pre_diab=0;
if pre_hyper=. then pre_hyper=0; 
if private_hospital=. then private_hospital=9; 
if seifa=. then seifa=9;
if rurality=. then rurality=9;
if gravidity=. then gravidity=99;
if gest_weeks=. then gest_weeks=99;
if gest_weeks_first_visit=. then gest_weeks_first_visit=99;
if num_ant_visit=. then num_ant_visit=99;
if num_ant_visit=999 then num_ant_visit=99;
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
data qpdc_main; set qpdc_main;
keep aihw_baby_ppn aihw_mom_ppn state year gravidity parity gest_weeks gest_weeks_first_visit num_ant_visit atsi smoke_b20 smoke_a20 pre_diab pre_hyper seifa preeclampsia
gest_hyper gest_diab cs rurality bmigp motheragegp bmi mother_age private_hospital cob_region graviditygp first_visitgp num_visitgp; run;


proc tabulate data=qpdc_main;
class parity gest_weeks atsi smoke_b20 smoke_a20 pre_diab pre_hyper seifa preeclampsia
gest_hyper gest_diab cs rurality bmigp motheragegp private_hospital cob_region year graviditygp first_visitgp num_visitgp/missing;
tables all parity gest_weeks atsi seifa rurality smoke_b20 smoke_a20 pre_diab pre_hyper preeclampsia
gest_hyper gest_diab cs bmigp motheragegp private_hospital cob_region graviditygp first_visitgp num_visitgp, year*(n colpctn);
run;


*change ppn from numeric to character var for merging;
data qpdc_main;set qpdc_main;
aihw_baby_ppn_char=put(aihw_baby_ppn,14.);
aihw_mom_ppn_char=put(aihw_mom_ppn,14.);
drop aihw_baby_ppn aihw_mom_ppn;
run;


data qpdc_main; set qpdc_main;
rename aihw_baby_ppn_char=aihw_baby_ppn;
rename aihw_mom_ppn_char=aihw_mom_ppn;
run;


*save data (n=67,554);
libname phd "G:\Papers\Yanan Hu\PhD\clean data";
data phd.qpdc_main;set qpdc_main; run;



