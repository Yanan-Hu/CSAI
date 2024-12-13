/******************************************************************************************************************************
*Create date: 2 Nov 2024
*Last update date: 18 Nov 2024
*Author: Yanan Hu
*Purpose: assess cost implication of risk group by the XGBoost model
*****************************************************************************************************************************/

libname cost "G:\Data in sas format\costs";
libname csai "G:\Papers\Yanan Hu\PhD\Study#4\sas\clean data";


* import costs;
data mom_cost; set cost.npdc_inp_mom_cost;
run;

data baby_cost; set cost.npdc_inp_baby_cost;
run;


******************************************************
csai study; 

*limit to intrapartum admission (from giving birth to discharge);
data mom_cost; set mom_cost;
if episode_start_date<=BDOB<=episode_end_date then output;
run;


*transpose;
proc sql;
create table mom_cost_sum as
select aihw_mom_ppn, aihw_baby_ppn,
sum(case when obstetric=1 then DRGcost else 0 end) as mom_birth_DRGcost_ob,
sum(case when obstetric ne 1 then DRGcost else 0 end) as mom_birth_DRGcost_nob,

sum(case when obstetric=1 then PHIcost else 0 end) as mom_birth_PHIcost_ob,
sum(case when obstetric ne 1 then PHIcost else 0 end) as mom_birth_PHIcost_nob,

mean(EPISODE_LENGTH_OF_STAY) as mom_mean_LENGTH_OF_STAY

from mom_cost
group by aihw_baby_ppn;
quit;

proc sort data=mom_cost_sum nodupkey; by aihw_baby_ppn; run;

*limit to frmo birth to 30 days after birth;
data baby_cost; set baby_cost;
if BDOB<=episode_start_date<=intnx('month',BDOB,1,'same') then output;
run;

*transpose;
proc sql;
create table baby_cost_sum as
select aihw_mom_ppn, aihw_baby_ppn,
sum(case when neonatal=1 then DRGcost else 0 end) as baby_birth_DRGcost_neo,
sum(case when neonatal ne 1 then DRGcost else 0 end) as baby_birth_DRGcost_nneo,

sum(case when neonatal=1 then PHIcost else 0 end) as baby_birth_PHIcost_neo,
sum(case when neonatal ne 1 then PHIcost else 0 end) as baby_birth_PHIcost_nneo,

mean(EPISODE_LENGTH_OF_STAY) as baby_mean_LENGTH_OF_STAY

from baby_cost
group by aihw_baby_ppn;
quit;


proc sort data=baby_cost_sum nodupkey; by aihw_baby_ppn; run;


*limit to mom in csai npdc_dev dataset;
data pdc_dev_risk; set csai.pdc_dev_risk; run;

data npdc_dev_risk; set pdc_dev_risk;
if state='NSW' then output; run;

proc sort data=npdc_dev_risk; by aihw_baby_ppn; run;
proc sort data=mom_cost_sum; by aihw_baby_ppn; run;
data npdc_dev_risk_cost_mom; merge npdc_dev_risk (in=a) mom_cost_sum (in=b); by aihw_baby_ppn;
if a then output; run;


*limit to baby in csai npdc dataset;
proc sort data=npdc_dev_risk; by aihw_baby_ppn; run;
proc sort data=baby_cost_sum; by aihw_baby_ppn; run;
data npdc_dev_risk_cost_baby; merge npdc_dev_risk (in=a) baby_cost_sum (in=b); by aihw_baby_ppn;
if a then output; run;


*merge mom and baby cost file;
proc sql noprint;
create table npdc_dev_risk_cost as
select*from npdc_dev_risk_cost_mom a 
join npdc_dev_risk_cost_baby b
on a.aihw_baby_ppn = b.aihw_baby_ppn;
quit;


data npdc_dev_risk_cost; set npdc_dev_risk_cost;
if mom_birth_DRGcost_ob=. then mom_birth_DRGcost_ob=0;
if mom_birth_DRGcost_nob=. then mom_birth_DRGcost_nob=0;
mom_birth_DRGcost=mom_birth_DRGcost_ob+mom_birth_DRGcost_nob;

if mom_birth_PHIcost_ob=. then mom_birth_PHIcost_ob=0;
if mom_birth_PHIcost_nob=. then mom_birth_PHIcost_nob=0;
mom_birth_PHIcost=mom_birth_PHIcost_ob+mom_birth_PHIcost_nob;

if mom_mean_LENGTH_OF_STAY=. then mom_mean_LENGTH_OF_STAY=0;

if baby_birth_DRGcost_neo=. then baby_birth_DRGcost_neo=0;
if baby_birth_DRGcost_nneo=. then baby_birth_DRGcost_nneo=0;
baby_birth_DRGcost=baby_birth_DRGcost_neo+baby_birth_DRGcost_nneo;

if baby_birth_PHIcost_neo=. then baby_birth_PHIcost_neo=0;
if baby_birth_PHIcost_nneo=. then baby_birth_PHIcost_nneo=0;
baby_birth_PHIcost=baby_birth_PHIcost_neo+baby_birth_PHIcost_nneo;

if baby_mean_LENGTH_OF_STAY=. then baby_mean_LENGTH_OF_STAY=0;

mom_birth_DRGcost_ob=round(mom_birth_DRGcost_ob);
mom_birth_DRGcost_nob=round(mom_birth_DRGcost_nob);
mom_birth_PHIcost_ob=round(mom_birth_PHIcost_ob);
mom_birth_PHIcost_nob=round(mom_birth_PHIcost_nob);
mom_mean_LENGTH_OF_STAY=round(mom_mean_LENGTH_OF_STAY);

baby_birth_DRGcost_neo=round(baby_birth_DRGcost_neo);
baby_birth_DRGcost_nneo=round(baby_birth_DRGcost_nneo);
baby_birth_PHIcost_neo=round(baby_birth_PHIcost_neo);
baby_birth_PHIcost_nneo=round(baby_birth_PHIcost_nneo);
baby_mean_LENGTH_OF_STAY=round(baby_mean_LENGTH_OF_STAY);

total_birth_DRGcost=round(mom_birth_DRGcost+baby_birth_DRGcost);
total_birth_PHIcost=round(mom_birth_PHIcost+baby_birth_PHIcost);
total_inp_birth_cost=round(total_birth_DRGcost+total_birth_PHIcost);

total_mom_birth_cost=round(mom_birth_DRGcost+mom_birth_PHIcost);
total_baby_birth_cost=round(baby_birth_DRGcost+baby_birth_PHIcost);

total_mom_birth_cost_ob=mom_birth_DRGcost_ob+mom_birth_PHIcost_ob;
total_baby_birth_cost_neo=baby_birth_DRGcost_neo+baby_birth_PHIcost_neo;

total_mean_LENGTH_OF_STAY=round(mom_mean_LENGTH_OF_STAY+baby_mean_LENGTH_OF_STAY);

total_mom_birth_cost_ob=mom_birth_DRGcost_ob+mom_birth_PHIcost_ob;
total_baby_birth_cost_neo=baby_birth_DRGcost_neo+baby_birth_PHIcost_neo;

if total_mom_birth_cost ne 0 then pct_mom_ob=total_mom_birth_cost_ob/total_mom_birth_cost; else pct_mom_ob=0;
if total_baby_birth_cost ne 0 then pct_baby_neo=total_baby_birth_cost_neo/total_baby_birth_cost; else pct_baby_neo=0;
if total_inp_birth_cost ne 0 then pct_mom=total_mom_birth_cost/total_inp_birth_cost; else pct_mom=0;
if total_inp_birth_cost ne 0 then pct_baby=total_baby_birth_cost/total_inp_birth_cost; else pct_baby=0;
run;


*save data with cost;
data csai.npdc_dev_risk_cost; set npdc_dev_risk_cost;
run;


*limit to mom in csai npdc_val dataset;
data npdc_val_risk; set csai.npdc_val_risk; run;
proc sort data=npdc_val_risk; by aihw_baby_ppn; run;
proc sort data=mom_cost_sum; by aihw_baby_ppn; run;
data npdc_val_risk_cost_mom; merge npdc_val_risk (in=a) mom_cost_sum (in=b); by aihw_baby_ppn;
if a then output; run;


*limit to baby in csai npdc dataset;
proc sort data=npdc_val_risk; by aihw_baby_ppn; run;
proc sort data=baby_cost_sum; by aihw_baby_ppn; run;
data npdc_val_risk_cost_baby; merge npdc_val_risk (in=a) baby_cost_sum (in=b); by aihw_baby_ppn;
if a then output; run;


*merge mom and baby cost file;
proc sql noprint;
create table npdc_val_risk_cost as
select*from npdc_val_risk_cost_mom a 
join npdc_val_risk_cost_baby b
on a.aihw_baby_ppn = b.aihw_baby_ppn;
quit;

data npdc_val_risk_cost; set npdc_val_risk_cost;
if mom_birth_DRGcost_ob=. then mom_birth_DRGcost_ob=0;
if mom_birth_DRGcost_nob=. then mom_birth_DRGcost_nob=0;
mom_birth_DRGcost=mom_birth_DRGcost_ob+mom_birth_DRGcost_nob;

if mom_birth_PHIcost_ob=. then mom_birth_PHIcost_ob=0;
if mom_birth_PHIcost_nob=. then mom_birth_PHIcost_nob=0;
mom_birth_PHIcost=mom_birth_PHIcost_ob+mom_birth_PHIcost_nob;

if mom_mean_LENGTH_OF_STAY=. then mom_mean_LENGTH_OF_STAY=0;

if baby_birth_DRGcost_neo=. then baby_birth_DRGcost_neo=0;
if baby_birth_DRGcost_nneo=. then baby_birth_DRGcost_nneo=0;
baby_birth_DRGcost=baby_birth_DRGcost_neo+baby_birth_DRGcost_nneo;

if baby_birth_PHIcost_neo=. then baby_birth_PHIcost_neo=0;
if baby_birth_PHIcost_nneo=. then baby_birth_PHIcost_nneo=0;
baby_birth_PHIcost=baby_birth_PHIcost_neo+baby_birth_PHIcost_nneo;

if baby_mean_LENGTH_OF_STAY=. then baby_mean_LENGTH_OF_STAY=0;

mom_birth_DRGcost_ob=round(mom_birth_DRGcost_ob);
mom_birth_DRGcost_nob=round(mom_birth_DRGcost_nob);
mom_birth_PHIcost_ob=round(mom_birth_PHIcost_ob);
mom_birth_PHIcost_nob=round(mom_birth_PHIcost_nob);
mom_mean_LENGTH_OF_STAY=round(mom_mean_LENGTH_OF_STAY);

baby_birth_DRGcost_neo=round(baby_birth_DRGcost_neo);
baby_birth_DRGcost_nneo=round(baby_birth_DRGcost_nneo);
baby_birth_PHIcost_neo=round(baby_birth_PHIcost_neo);
baby_birth_PHIcost_nneo=round(baby_birth_PHIcost_nneo);
baby_mean_LENGTH_OF_STAY=round(baby_mean_LENGTH_OF_STAY);

total_birth_DRGcost=round(mom_birth_DRGcost+baby_birth_DRGcost);
total_birth_PHIcost=round(mom_birth_PHIcost+baby_birth_PHIcost);
total_inp_birth_cost=round(total_birth_DRGcost+total_birth_PHIcost);

total_mom_birth_cost=round(mom_birth_DRGcost+mom_birth_PHIcost);
total_baby_birth_cost=round(baby_birth_DRGcost+baby_birth_PHIcost);

total_mom_birth_cost_ob=mom_birth_DRGcost_ob+mom_birth_PHIcost_ob;
total_baby_birth_cost_neo=baby_birth_DRGcost_neo+baby_birth_PHIcost_neo;

total_mean_LENGTH_OF_STAY=round(mom_mean_LENGTH_OF_STAY+baby_mean_LENGTH_OF_STAY);

total_mom_birth_cost_ob=mom_birth_DRGcost_ob+mom_birth_PHIcost_ob;
total_baby_birth_cost_neo=baby_birth_DRGcost_neo+baby_birth_PHIcost_neo;

if total_mom_birth_cost ne 0 then pct_mom_ob=total_mom_birth_cost_ob/total_mom_birth_cost; else pct_mom_ob=0;
if total_baby_birth_cost ne 0 then pct_baby_neo=total_baby_birth_cost_neo/total_baby_birth_cost; else pct_baby_neo=0;
if total_inp_birth_cost ne 0 then pct_mom=total_mom_birth_cost/total_inp_birth_cost; else pct_mom=0;
if total_inp_birth_cost ne 0 then pct_baby=total_baby_birth_cost/total_inp_birth_cost; else pct_baby=0;
run;


*save data with cost;
data csai.npdc_val_risk_cost; set npdc_val_risk_cost;
run;
