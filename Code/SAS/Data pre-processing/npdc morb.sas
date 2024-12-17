/******************************************************************************************************************************
*Create date: 2 Nov 2024
*Last update date: 18 Nov 2024
*Author: Yanan Hu and Emily Callander
*Purpose: Define composite maternal and neonatal morbidity:

Maternal:
- 3rd or 4th perineum damage
- haemorrhage
- ruptured uterous
- retained placenta

Neonatal:
- HIE
- trauma
- hypoxia
- other
- apgar score<7 at 5mins
- SGA

*****************************************************************************************************************************/


libname matern 'G:\Data in sas format';


data nsw_pdc; set matern.npdc_main;
if year=2020 then output;
run;


data nsw_pdc; set nsw_pdc;

if feed_bf='1' then bf=1; else bf=0;

if apgar5<7 then lowapgar=1;
else lowapgar=0;

if PERINEAL06 in ('4', '5') then perineum_damage=1;
else perineum_damage=0;


if PPHTF_RECODE ='1' then Matern_haemorrhage=1;
else Matern_haemorrhage=0;

run;


proc sort data=nsw_pdc; by gestage; run;

proc rank data=nsw_pdc out=nsw_pdc fraction ties=mean;
by gestage;
var bweight;
ranks baby_weight_rank;
run;

data nsw_pdc; set nsw_pdc;
if baby_weight_rank<0.10 then sga=1; else sga=0;
run;

data npdc_inp_short; set  matern.npdc_inp ;
length diagnosis_short $ 1;
diagnosis_short=diagnosis_codeP;
if diagnosis_short in ("P") then birth=1;
else birth=0;
if birth=0 then delete;

aihw_baby_ppn=aihw_ppn;

keep aihw_baby_ppn diagnosis_code1-diagnosis_code50;
run;

proc sort data=npdc_inp_short; by aihw_baby_ppn;
run; 


proc transpose data=npdc_inp_short out=npdc_inp_short_long;
by aihw_baby_ppn;
var diagnosis_code1-diagnosis_code50;
run;



data npdc_inp_short_long; set npdc_inp_short_long;

*HIE;
if col1 in ('P91.6','P91.60','P91.61','P91.62','P91.63') then HIE=1;
else if col2 in ('P91.6','P91.60','P91.61','P91.62','P91.63') then HIE=1;
else if col3 in ('P91.6','P91.60','P91.61','P91.62','P91.63') then HIE=1;
else if col4 in ('P91.6','P91.60','P91.61','P91.62','P91.63') then HIE=1;
else if col5 in ('P91.6','P91.60','P91.61','P91.62','P91.63') then HIE=1;
else if col6 in ('P91.6','P91.60','P91.61','P91.62','P91.63') then HIE=1;
else if col7 in ('P91.6','P91.60','P91.61','P91.62','P91.63') then HIE=1;
else if col8 in ('P91.6','P91.60','P91.61','P91.62','P91.63') then HIE=1;
else if col9 in ('P91.6','P91.60','P91.61','P91.62','P91.63') then HIE=1;
else if col10 in ('P91.6','P91.60','P91.61','P91.62','P91.63') then HIE=1;
else HIE=0;

*trauma;
if col1 in ('P14.0', 'P14.1','P14.2','P14.3', 'P14.8', 'P14.9', 'P13.4', 'P13.3') then trauma=1;
else if col2 in ('P14.0', 'P14.1','P14.2','P14.3', 'P14.8', 'P14.9', 'P13.4', 'P13.3') then trauma=1;
else if col3 in ('P14.0', 'P14.1','P14.2','P14.3', 'P14.8', 'P14.9', 'P13.4', 'P13.3') then trauma=1;
else if col4 in ('P14.0', 'P14.1','P14.2','P14.3', 'P14.8', 'P14.9', 'P13.4', 'P13.3') then trauma=1;
else if col5 in ('P14.0','P14.1','P14.2','P14.3', 'P14.8', 'P14.9', 'P13.4', 'P13.3') then trauma=1;
else if col6 in ('P14.0', 'P14.1','P14.2','P14.3', 'P14.8', 'P14.9', 'P13.4', 'P13.3') then trauma=1;
else if col7 in ('P14.0', 'P14.1','P14.2','P14.3', 'P14.8', 'P14.9', 'P13.4', 'P13.3') then trauma=1;
else if col8 in ('P14.0', 'P14.1','P14.2','P14.3', 'P14.8', 'P14.9', 'P13.4', 'P13.3') then trauma=1;
else if col9 in ('P14.0', 'P14.1','P14.2','P14.3', 'P14.8', 'P14.9', 'P13.4', 'P13.3') then trauma=1;
else if col10 in ('P14.0','P14.1','P14.2', 'P14.3', 'P14.8', 'P14.9', 'P13.4', 'P13.3') then trauma=1;
else trauma=0;

*hypoxia;
if col1 in ('P20.0', 'P20.1', 'P20.9') then hypoxia=1;
else if col2 in ('P20.0', 'P20.1', 'P20.9') then hypoxia=1;
else if col3 in ('P20.0', 'P20.1', 'P20.9') then hypoxia=1;
else if col4 in ('P20.0', 'P20.1', 'P20.9') then hypoxia=1;
else if col5 in ('P20.0', 'P20.1', 'P20.9') then hypoxia=1;
else if col6 in ('P20.0', 'P20.1', 'P20.9') then hypoxia=1;
else if col7 in ('P20.0', 'P20.1', 'P20.9') then hypoxia=1;
else if col8 in ('P20.0', 'P20.1', 'P20.9') then hypoxia=1;
else if col9 in ('P20.0', 'P20.1', 'P20.9') then hypoxia=1;
else if col10 in ('P20.0', 'P20.1', 'P20.9') then hypoxia=1;
else hypoxia=0;

*other;
if col1 in ('P24.0', 'P23.0','P23.1', 'P23.2','P23.3','P23.4','P23.5','P23.6','P23.8','P23.9','P22.0','P22.1','P22.8','P22.9') then other=1;
else if col2 in ('P24.0', 'P23.0','P23.1', 'P23.2','P23.3','P23.4','P23.5','P23.6','P23.8','P23.9','P22.0','P22.1','P22.8','P22.9') then other=1;
else if col3 in ('P24.0', 'P23.0','P23.1', 'P23.2','P23.3','P23.4','P23.5','P23.6','P23.8','P23.9','P22.0','P22.1','P22.8','P22.9') then other=1;
else if col4 in ('P24.0', 'P23.0','P23.1', 'P23.2','P23.3','P23.4','P23.5','P23.6','P23.8','P23.9','P22.0','P22.1','P22.8','P22.9') then other=1;
else if col5 in ('P24.0', 'P23.0','P23.1', 'P23.2','P23.3','P23.4','P23.5','P23.6','P23.8','P23.9','P22.0','P22.1','P22.8','P22.9') then other=1;
else if col6 in ('P24.0', 'P23.0','P23.1', 'P23.2','P23.3','P23.4','P23.5','P23.6','P23.8','P23.9','P22.0','P22.1','P22.8','P22.9') then other=1;
else if col7 in ('P24.0', 'P23.0','P23.1', 'P23.2','P23.3','P23.4','P23.5','P23.6','P23.8','P23.9','P22.0','P22.1','P22.8','P22.9') then other=1;
else if col8 in ('P24.0', 'P23.0','P23.1', 'P23.2','P23.3','P23.4','P23.5','P23.6','P23.8','P23.9','P22.0','P22.1','P22.8','P22.9') then other=1;
else if col9 in ('P24.0', 'P23.0','P23.1', 'P23.2','P23.3','P23.4','P23.5','P23.6','P23.8','P23.9','P22.0','P22.1','P22.8','P22.9') then other=1;
else if col10 in ('P24.0', 'P23.0','P23.1', 'P23.2','P23.3','P23.4','P23.5','P23.6','P23.8','P23.9','P22.0','P22.1','P22.8','P22.9') then other=1;
else other=0;

keep aihw_baby_ppn  HIE trauma hypoxia other;
run;


data HIE; set npdc_inp_short_long (where=(HIE=1));
run;
data trauma; set npdc_inp_short_long (where=(trauma=1));
run;
data hypoxia; set npdc_inp_short_long (where=(hypoxia=1));
run;
data other; set npdc_inp_short_long (where=(other=1));
run;


proc sort data=HIE nodupkey; by aihw_baby_ppn  ; run;
proc sort data=trauma nodupkey; by aihw_baby_ppn  ; run;
proc sort data=hypoxia nodupkey; by aihw_baby_ppn  ; run;
proc sort data=other nodupkey; by aihw_baby_ppn  ; run;
proc sort data=nsw_pdc ; by aihw_baby_ppn  ; run;

data nsw_pdc; merge nsw_pdc (in=a) HIE trauma hypoxia other; 
by aihw_baby_ppn ; 
if a then output; 
run;

data nsw_pdc; set nsw_pdc;
if HIE=. then HIE=0;
if trauma=. then trauma=0;
if hypoxia=. then hypoxia=0;
if other=. then other=0;

run;


data npdc_inp_short; set  matern.npdc_inp ;
length diagnosis_short $ 1;
diagnosis_short=diagnosis_codeP;
if diagnosis_short in ("O") then birth=1;
else birth=0;
if birth=0 then delete;

aihw_mom_ppn=aihw_ppn;
merge_birth_date=episode_start_date;
format merge_birth_date monyy7.;
keep aihw_mom_ppn merge_birth_date diagnosis_code1-diagnosis_code50;
run;

proc sort data=npdc_inp_short; by aihw_mom_ppn merge_birth_date;
run; 

proc transpose data=npdc_inp_short out=npdc_inp_short_long;
by aihw_mom_ppn merge_birth_date;
var diagnosis_code1-diagnosis_code50;
run;


data npdc_inp_short_long; set npdc_inp_short_long;
*PPH;
if col1 in ('O72.0','O72.1','O72.2', 'O72.3','O67.0','O67.8','O67.9') then Matern_haemorrhage2=1;
else if col2 in ('O72.0','O72.1','O72.2', 'O72.3','O67.0','O67.8','O67.9') then Matern_haemorrhage2=1;
else if col3 in ('O72.0','O72.1','O72.2', 'O72.3','O67.0','O67.8','O67.9') then Matern_haemorrhage2=1;
else if col4 in ('O72.0','O72.1','O72.2', 'O72.3','O67.0','O67.8','O67.9') then Matern_haemorrhage2=1;
else if col5 in ('O72.0','O72.1','O72.2', 'O72.3','O67.0','O67.8','O67.9') then Matern_haemorrhage2=1;
else if col6 in ('O72.0','O72.1','O72.2', 'O72.3','O67.0','O67.8','O67.9') then Matern_haemorrhage2=1;
else if col7 in ('O72.0','O72.1','O72.2', 'O72.3','O67.0','O67.8','O67.9') then Matern_haemorrhage2=1;
else if col8 in ('O72.0','O72.1','O72.2', 'O72.3','O67.0','O67.8','O67.9') then Matern_haemorrhage2=1;
else if col9 in ('O72.0','O72.1','O72.2', 'O72.3','O67.0','O67.8','O67.9') then Matern_haemorrhage2=1;
else if col10 in ('O72.0','O72.1','O72.2', 'O72.3','O67.0','O67.8','O67.9') then Matern_haemorrhage2=1;
else if col11 in ('O72.0','O72.1','O72.2', 'O72.3','O67.0','O67.8','O67.9') then Matern_haemorrhage2=1;
else if col12 in ('O72.0','O72.1','O72.2', 'O72.3','O67.0','O67.8','O67.9') then Matern_haemorrhage2=1;
else if col13 in ('O72.0','O72.1','O72.2', 'O72.3','O67.0','O67.8','O67.9') then Matern_haemorrhage2=1;
else if col14 in ('O72.0','O72.1','O72.2', 'O72.3','O67.0','O67.8','O67.9') then Matern_haemorrhage2=1;

else Matern_haemorrhage2=0;

*ruptured uterus;
if col1 in ('O71.0','O71.00','O71.01','O71.02','O71.1','O71.10', 'O71.11', 'O71.12') then ruptured_uterus=1;
else if col2 in ('O71.0','O71.00','O71.01','O71.02','O71.1','O71.10', 'O71.11', 'O71.12') then ruptured_uterus=1;
else if col3 in ('O71.0','O71.00','O71.01','O71.02','O71.1','O71.10', 'O71.11', 'O71.12') then ruptured_uterus=1;
else if col4 in ('O71.0','O71.00','O71.01','O71.02','O71.1','O71.10', 'O71.11', 'O71.12') then ruptured_uterus=1;
else if col5 in ('O71.0','O71.00','O71.01','O71.02','O71.1','O71.10', 'O71.11', 'O71.12') then ruptured_uterus=1;
else if col6 in ('O71.0','O71.00','O71.01','O71.02','O71.1','O71.10', 'O71.11', 'O71.12') then ruptured_uterus=1;
else if col7 in ('O71.0','O71.00','O71.01','O71.02','O71.1','O71.10', 'O71.11', 'O71.12') then ruptured_uterus=1;
else if col8 in ('O71.0','O71.00','O71.01','O71.02','O71.1','O71.10', 'O71.11', 'O71.12') then ruptured_uterus=1;
else if col9 in ('O71.0','O71.00','O71.01','O71.02','O71.1','O71.10', 'O71.11', 'O71.12') then ruptured_uterus=1;
else if col10 in ('O71.0','O71.00','O71.01','O71.02','O71.1','O71.10', 'O71.11', 'O71.12') then ruptured_uterus=1;
else if col11 in ('O71.0','O71.00','O71.01','O71.02','O71.1','O71.10', 'O71.11', 'O71.12') then ruptured_uterus=1;
else if col12 in ('O71.0','O71.00','O71.01','O71.02','O71.1','O71.10', 'O71.11', 'O71.12') then ruptured_uterus=1;
else if col13 in ('O71.0','O71.00','O71.01','O71.02','O71.1','O71.10', 'O71.11', 'O71.12') then ruptured_uterus=1;
else if col14 in ('O71.0','O71.00','O71.01','O71.02','O71.1','O71.10', 'O71.11', 'O71.12') then ruptured_uterus=1;

else ruptured_uterus=0;

*retained placenta;
if col1 in ('O73.0', 'O73.1') then retained_placenta=1;
else if col2 in ('O73.0', 'O73.1') then retained_placenta=1;
else if col3 in ('O73.0', 'O73.1') then retained_placenta=1;
else if col4 in ('O73.0', 'O73.1') then retained_placenta=1;
else if col5 in ('O73.0', 'O73.1') then retained_placenta=1;
else if col6 in ('O73.0', 'O73.1') then retained_placenta=1;
else if col7 in ('O73.0', 'O73.1') then retained_placenta=1;
else if col8 in ('O73.0', 'O73.1') then retained_placenta=1;
else if col9 in ('O73.0', 'O73.1') then retained_placenta=1;
else if col10 in ('O73.0', 'O73.1') then retained_placenta=1;
else if col11 in ('O73.0', 'O73.1') then retained_placenta=1;
else if col12 in ('O73.0', 'O73.1') then retained_placenta=1;
else if col13 in ('O73.0', 'O73.1') then retained_placenta=1;
else if col14 in ('O73.0', 'O73.1') then retained_placenta=1;


else retained_placenta=0;


keep aihw_mom_ppn merge_birth_date  Matern_haemorrhage2 ruptured_uterus retained_placenta;
run;

data Matern_haemorrhage; set npdc_inp_short_long (where=(Matern_haemorrhage2=1));
run;
data ruptured_uterus; set npdc_inp_short_long (where=(ruptured_uterus=1));
run;
data retained_placenta; set npdc_inp_short_long (where=(retained_placenta=1));
run;



proc sort data=Matern_haemorrhage nodupkey; by aihw_mom_ppn merge_birth_date  ; run;
proc sort data=ruptured_uterus nodupkey; by aihw_mom_ppn merge_birth_date  ; run;
proc sort data=retained_placenta nodupkey; by aihw_mom_ppn merge_birth_date  ; run;

data nsw_pdc_short; set nsw_pdc ;
merge_birth_date=baby_dob;
format merge_birth_date monyy7.;
keep aihw_baby_ppn aihw_mom_ppn merge_birth_date;
run;

proc sort data=nsw_pdc_short ; by aihw_mom_ppn merge_birth_date  ; run;

data nsw_pdc_short; merge nsw_pdc_short (in=a) Matern_haemorrhage ruptured_uterus retained_placenta; 
by  aihw_mom_ppn merge_birth_date ; 
if a then output; 
run;



proc sort data=nsw_pdc_short ; by aihw_baby_ppn  ; run;
proc sort data=nsw_pdc ; by aihw_baby_ppn  ; run;

data nsw_pdc; merge nsw_pdc nsw_pdc_short;
by aihw_baby_ppn;
run;

data nsw_pdc; set nsw_pdc;
if ruptured_uterus=. then ruptured_uterus=0;
if retained_placenta=. then retained_placenta=0;


if Matern_haemorrhage=0 then do;
if Matern_haemorrhage2=1 then Matern_haemorrhage=1;
end;

if Matern_haemorrhage=1 or ruptured_uterus=1 or retained_placenta=1 or perineum_damage=1 then mat_mor=1; else mat_mor=0;
if lowapgar=1 or HIE=1 or sga=1 or trauma=1 or hypoxia=1 or  other=1 then neo_mor=1; else neo_mor=0; *scn or nicu admission;
keep mat_mor  neo_mor  aihw_baby_ppn aihw_mom_ppn;
run;



libname csai "G:\Papers\Yanan Hu\PhD\Study#4\sas\clean data";

data csai.npdc_morb; set nsw_pdc;run;
