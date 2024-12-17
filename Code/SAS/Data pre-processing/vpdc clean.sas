************************************************************************************************************************************
* Purpose: Clean up three data sets to do prediction
* Author: Yanan Hu
* Date created: 11 Aug 2024
* Date last updated: 11 Aug 2024
* Note: do not delete missing value of candidate predictors, treat them as a group (9, 99, 999, etc);
************************************************************************************************************************************;


libname matern "G:\Data in sas format";


****VIC; 
*Note: Only include women without any medical conditions and obstetric complications;
data vpdc_main; set matern.vpdc_main; 
if MatMedCond01='' and ObstComplication01='' then output;
run;


data vpdc_main; set vpdc_main;
aihw_baby_ppn_char=put(e_linkedbabypersonid,14.);
aihw_mom_ppn_char=put(e_linkedmumpersonid,14.);
rename gravidity=gravidity_old;
rename aihw_baby_ppn_char=aihw_baby_ppn;
rename aihw_mom_ppn_char=aihw_mom_ppn;
run;


*only include IOL, non prior cs, singleton, cephalic pre, term, non-missing delivery mode, live births;
data vpdc_main; set vpdc_main;
if LabourTypeDescription="Induced" then output;
run;


data vpdc_main; set vpdc_main;
if NoOfPreviousCSections>0 or LastBirthCaesareanDescription=1 then delete;
if BirthPresentationDescription not in ('Vertex' 'Face' 'Brow') then delete;
if PluralityDescription not='Singleton' then delete;
if BirthMethodDescription in ('Not stated / inadequately described') then delete;
gest_weeks=int(GestationDays/7);
if gest_weeks<37 or gest_weeks>41 or gest_weeks=0 or GestationDays=. then delete;
if BirthStatusDescription='Stillbirth' then delete;
run;


*test eligibility criteria;
proc freq data=vpdc_main;
tables LabourTypeDescription NoOfPreviousCSections LastBirthCaesareanDescription BirthPresentationDescription BirthMethodDescription gest_weeks BirthStatusDescription; run;


*Define women's characteristicss;
data vpdc_main; set vpdc_main;
year=baby_birth_year;

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

if MumIndigenousGroup='Indigenous' then atsi=1; 
else if MumIndigenousGroup='Not Indigenous' then atsi=0;
else atsi=9;

if Smokingbefore20WeeksDescription in ('No smoking at all before 20 weeks o') then smoke_b20=0;
else if Smokingbefore20WeeksDescription not in ('Not stated / inadequately described') then smoke_b20=1;
else smoke_b20=9;

if SmokingAfter20WeeksDescription in ('No smoking') then smoke_a20=0;
else if SmokingAfter20WeeksDescription not in ('Not stated / inadequately described') then smoke_a20=1;
else smoke_a20=9;

if BirthMethodDescription in ('Planned Caesarean – labour' 'Planned Caesarean – no labour' 'Unplanned Caesarean – labour' 'Unplanned Caesarean – no labour') then cs=1; else cs=0;

if NoOfPreviousLiveBirths>1 or OutcomeLastPregnancDescription in ('Livebirth' 'Stillbirth' 'Neonatal death')then parity=1; else parity=0;

if AdmissionStatusDescription in ('3. Private in private hospital' '6. Public in private hospital') then private_hospital=1; 
else if AdmissionStatusDescription not in ('5. Unknown') then private_hospital=0; 
else private_hospital=9;

if RA_NAME_2016='Major Cities of Australia' then rurality=1; 
else if RA_NAME_2016='Inner Regional Australia' then rurality=2; 
else if RA_NAME_2016='Outer Regional Australia' then rurality=3; 
else if RA_NAME_2016='Remote Australia' then rurality=4; 
else if RA_NAME_2016='Very Remote Australia' then rurality=5;
else rurality=9;

if irsd_decile in (1,2) then seifa=1;
else if irsd_decile in (3,4) then seifa=2;
else if irsd_decile in (5,6) then seifa=3;
else if irsd_decile in (7,8) then seifa=4;
else if irsd_decile in (9,10) then seifa=5;
else seifa=9;

rename MumCountryOfBirth=cob;
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
drop cobsacc minor_group major_group;
run;


proc sort data=cobsacc_grouping; by cob; run;
proc sort data=vpdc_main; by cob; run;
data vpdc_main; merge vpdc_main (in=a) cobsacc_grouping; 
by cob;
if a then output; 
run;


data vpdc_main; set vpdc_main;
state='VIC';
gest_weeks_first_visit=GestationWksFirstAntenatalVisit;
num_ant_visit=NoOfAntenatalVisits;
pre_diab=0;
pre_hyper=0;
preeclampsia=0;
gest_hyper=0;
gest_diab=0;

if gravidity_old not=. then gravidity=gravidity_old-1;*gravidity include current pregnancy;
else gravidity=99;

if seifa=. then seifa=9;
if gest_weeks=. then gest_weeks=99;
if gest_weeks_first_visit=. then gest_weeks_first_visit=99;
if num_ant_visit=. then num_ant_visit=99;
if cob_region=. then cob_region=9;

if PreviousPregnanciesDescription='None' then graviditygp=1;
else if PreviousPregnanciesDescription='One' then graviditygp=2;
else if PreviousPregnanciesDescription='Two' then graviditygp=3;
else if PreviousPregnanciesDescription='Three' then graviditygp=4;
else if PreviousPregnanciesDescription in ('Four' 'Five or more') then graviditygp=5;
else graviditygp=9; *big discrepency between gravidity and PreviousPregnanciesDescription, consider Do not use gravidity;

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
data vpdc_main; set vpdc_main;
keep aihw_baby_ppn aihw_mom_ppn state year gravidity parity gest_weeks gest_weeks_first_visit num_ant_visit atsi smoke_b20 smoke_a20 pre_diab pre_hyper seifa preeclampsia
gest_hyper gest_diab cs rurality bmigp motheragegp bmi mother_age private_hospital cob_region graviditygp first_visitgp num_visitgp; run;


proc tabulate data=vpdc_main;
class parity gest_weeks atsi smoke_b20 smoke_a20 seifa cs rurality bmigp motheragegp private_hospital cob_region year graviditygp first_visitgp num_visitgp/missing;
tables all parity gest_weeks atsi smoke_b20 smoke_a20 seifa cs rurality bmigp motheragegp private_hospital cob_region graviditygp first_visitgp num_visitgp, year*(n colpctn);
run;


*save data (n=14,755);
libname phd "G:\Papers\Yanan Hu\PhD\clean data";
data phd.vpdc_main;set vpdc_main; run;
