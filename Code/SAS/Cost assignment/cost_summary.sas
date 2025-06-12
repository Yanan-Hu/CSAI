libname csai "G:\Papers\Yanan Hu\PhD\Study#4\sas\clean data";
libname cost "G:\Data in sas format\costs";


*import file;

data npdc_val_risk_cost; set csai.npdc_val_risk_cost;
bmi=round(bmi);
mother_age=round(mother_age);
run;


proc rank data=npdc_val_risk_cost out=ranked_data groups=10;
var predicted_risk;
ranks decile;
run;

data ranked_data; set ranked_data;
decile=decile+1;
keep decile mom_mean_LENGTH_OF_STAY baby_mean_LENGTH_OF_STAY total_mean_LENGTH_OF_STAY total_mom_birth_cost total_baby_birth_cost total_inp_birth_cost;
run;

proc tabulate data=ranked_data out=cost_summary;
class decile;
var  mom_mean_LENGTH_OF_STAY baby_mean_LENGTH_OF_STAY total_mean_LENGTH_OF_STAY total_mom_birth_cost total_baby_birth_cost total_inp_birth_cost;
tables  mom_mean_LENGTH_OF_STAY baby_mean_LENGTH_OF_STAY total_mean_LENGTH_OF_STAY total_mom_birth_cost total_baby_birth_cost total_inp_birth_cost, decile * (mean stderr);
run;

data cost_summary; set cost_summary;
drop 
_TYPE_  _PAGE_ _TABLE_;

run;



data csai.cost_summary; set cost_summary; run;




proc sgplot data=ranked_data noautolegend;
format bmi 8.2;
vbar decile/response=bmi stat=mean limits=both fillattrs=(color=steelblue) outlineattrs=(thickness=0) datalabel=bmi;
xaxis label="Predicted risk decile group (1:Lowest risk; 10:Highest risk)";
yaxis label="Mean BMI";
run;

proc sgplot data=ranked_data noautolegend;
format mother_age 8.2;
vbar decile/response=mother_age stat=mean limits=both fillattrs=(color=steelblue) outlineattrs=(thickness=0) datalabel=mother_age;
xaxis label="Predicted risk decile group (1:Lowest risk; 10:Highest risk)";
yaxis label="Mean maternal age";
run;

proc sgplot data=ranked_data noautolegend;
format total_mom_birth_cost Dollar8.0;
vbar decile/response=total_mom_birth_cost stat=mean limits=both fillattrs=(color=steelblue) outlineattrs=(thickness=0) datalabel=total_mom_birth_cost;
xaxis label="Predicted risk decile group (1:Lowest risk; 10:Highest risk)";
yaxis label="Mean maternal inpatient cost" valuesformat=Dollar8.0;
run;

proc sgplot data=ranked_data noautolegend;
format mom_mean_LENGTH_OF_STAY 8.2;
vbar decile/response=mom_mean_LENGTH_OF_STAY stat=mean limits=both fillattrs=(color=steelblue) outlineattrs=(thickness=0) datalabel=mom_mean_LENGTH_OF_STAY;
xaxis label="Predicted risk decile group (1:Lowest risk; 10:Highest risk)";
yaxis label="Mean maternal length of stay";
run;

proc sgplot data=ranked_data noautolegend;
format total_baby_birth_cost Dollar8.0;
vbar decile/response=total_baby_birth_cost stat=mean limits=both fillattrs=(color=steelblue) outlineattrs=(thickness=0) datalabel=total_baby_birth_cost;
xaxis label="Predicted risk decile group (1:Lowest risk; 10:Highest risk)";
yaxis label="Mean neonatal inpatient cost" valuesformat=Dollar8.0;
run;

proc sgplot data=ranked_data noautolegend;
format baby_mean_LENGTH_OF_STAY 8.2;
vbar decile/response=baby_mean_LENGTH_OF_STAY stat=mean limits=both fillattrs=(color=steelblue) outlineattrs=(thickness=0) datalabel=baby_mean_LENGTH_OF_STAY;
xaxis label="Predicted risk decile group (1:Lowest risk; 10:Highest risk)";
yaxis label="Mean neonatal length of stay";
run;

proc sgplot data=ranked_data noautolegend;
format total_inp_birth_cost Dollar8.0;
vbar decile/response=total_inp_birth_cost stat=mean limits=both fillattrs=(color=steelblue) outlineattrs=(thickness=0) datalabel=total_inp_birth_cost;
xaxis label="Predicted risk decile group (1:Lowest risk; 10:Highest risk)";
yaxis label="Mean total inpatient cost" valuesformat=Dollar8.0;
run;

proc sgplot data=ranked_data noautolegend;
format total_mean_LENGTH_OF_STAY 8.2;
vbar decile/response=total_mean_LENGTH_OF_STAY stat=mean limits=both fillattrs=(color=steelblue) outlineattrs=(thickness=0) datalabel=total_mean_LENGTH_OF_STAY;
xaxis label="Predicted risk decile group (1:Lowest risk; 10:Highest risk)";
yaxis label="Mean total length of stay";
run;


/*data pdc_dev_risk; set pdc_dev_risk;*/
/*aihw_mom_ppn=compress(strip(aihw_mom_ppn));*remove blank space at the front;*/
/*run;*/
/**/

/*PROC IMPORT OUT= drgcost */
/*  DATAFILE= "G:\Data in sas format\costs\drgcost.csv" */
/*  DBMS=CSV REPLACE;*/
/* GETNAMES=YES;*/
/* DATAROW=2; */
/*	 	 guessingrows=100;*/
/**/
/*RUN;*/

/*data csai.summary_data; set summary_data;*/
/*run;*/
/**/
/**/
/*PROC Export data= summary_data */
/*  outfile= "G:\Papers\Yanan Hu\PhD\Study#4\sas\clean data\summary_data.csv" */
/*  DBMS=CSV REPLACE;*/
/*RUN;*/


/*proc sgplot data=summary_data;*/
/*series x=decile y=total_inp_birth_cost_mean/lineattrs=(thickness=2 color=blue);*/
/*series x=decile y=total_mom_birth_cost_mean/lineattrs=(thickness=2 color=red);*/
/*series x=decile y=total_baby_birth_cost_mean/lineattrs=(thickness=2 color=green);*/
/*run;*/
/**/
/**/
/*proc sgplot data=summary_data;*/
/*series x=decile y=mother_age_mean/lineattrs=(thickness=2 color=black);*/
/*series x=decile y=bmi_mean/lineattrs=(thickness=2 color=yellow);*/
/*series x=decile y=total_mean_LENGTH_OF_STAY_mean/lineattrs=(thickness=2 color=orange);*/
/*run;*/


/*proc rank data=npdc_dev_cost_risk out=ranked_data groups=5;*/
/*var predicted_risk;*/
/*ranks quintile;*/
/*run;*/
/**/
/**/
/*proc tabulate data=ranked_data;*/
/*class quintile;*/
/*var mother_age bmi seifa rurality total_mean_LENGTH_OF_STAY total_inp_birth_cost total_mom_birth_cost pct_mom total_mom_birth_cost_ob pct_mom_ob total_baby_birth_cost pct_baby total_baby_birth_cost_neo pct_baby_neo;*/
/*tables mother_age bmi seifa rurality total_mean_LENGTH_OF_STAY total_inp_birth_cost total_mom_birth_cost pct_mom total_mom_birth_cost_ob pct_mom_ob total_baby_birth_cost pct_baby total_baby_birth_cost_neo pct_baby_neo, quintile *mean;*/
/*run;*/


/**/
/*proc sql noprint;*/
/*select count(*) into: total_count from npdc_dev_cost_risk;*/
/*quit;*/
/**/
/*proc sql noprint;*/
/*select sum(total_inp_birth_cost) into: total_cost from npdc_dev_cost_risk;*/
/*quit;*/
/**/
/*%let top_5_percent=%sysevalf(0.05*&total_count);*/
/*%let top_10_percent=%sysevalf(0.1*&total_count);*/
/*%let top_15_percent=%sysevalf(0.15*&total_count);*/
/*%let top_20_percent=%sysevalf(0.2*&total_count);*/
/*%let top_50_percent=%sysevalf(0.5*&total_count);*/
/*%let top_80_percent=%sysevalf(0.8*&total_count);*/
/**/
/*data top_5 next_5 top_10 next_5_2 top_15 top_20 top_50 bot_50 bot_20; set npdc_dev_cost_risk;*/
/*if _N_<=&top_5_percent then output top_5;*/
/*if &top_5_percent<_N_<=&top_10_percent then output next_5;*/
/*if _N_<=&top_10_percent then output top_10;*/
/*if &top_10_percent<_N_<=&top_15_percent then output next_5_2;*/
/*if _N_<=&top_15_percent then output top_15;*/
/*if _N_<=&top_20_percent then output top_20;*/
/*if _N_<=&top_50_percent then output top_50;*/
/*if &top_50_percent<_N_<=&total_count then output bot_50;*/
/*if &top_80_percent<_N_<=&total_count then output bot_20;*/
/*run;*/
/**/
/**/
/**/
/*proc sql;*/
/*create table cost_summary as*/
/*select 'Top 5%' as group,*/
/*mean(total_inp_birth_cost) as mean_cost,*/
/*sum(total_inp_birth_cost) as subtotal_cost,*/
/*calculated subtotal_cost/&total_cost*100 as pct_total_cost,*/
/*mean(total_mean_LENGTH_OF_STAY) as mean_los*/
/*from top_5*/
/*union all*/
/*select 'Next 5%' as group,*/
/*mean(total_inp_birth_cost) as mean_cost,*/
/*sum(total_inp_birth_cost) as subtotal_cost,*/
/*calculated subtotal_cost/&total_cost*100 as pct_total_cost,*/
/*mean(total_mean_LENGTH_OF_STAY) as mean_los*/
/*from next_5*/
/*union all*/
/*select 'Top 10%' as group,*/
/*mean(total_inp_birth_cost) as mean_cost,*/
/*sum(total_inp_birth_cost) as subtotal_cost,*/
/*calculated subtotal_cost/&total_cost*100 as pct_total_cost,*/
/*mean(total_mean_LENGTH_OF_STAY) as mean_los*/
/*from top_10*/
/*union all*/
/*select 'Next 5_2%' as group,*/
/*mean(total_inp_birth_cost) as mean_cost,*/
/*sum(total_inp_birth_cost) as subtotal_cost,*/
/*calculated subtotal_cost/&total_cost*100 as pct_total_cost,*/
/*mean(total_mean_LENGTH_OF_STAY) as mean_los*/
/*from next_5_2*/
/*union all*/
/*select 'Top 15%' as group,*/
/*mean(total_inp_birth_cost) as mean_cost,*/
/*sum(total_inp_birth_cost) as subtotal_cost,*/
/*calculated subtotal_cost/&total_cost*100 as pct_total_cost,*/
/*mean(total_mean_LENGTH_OF_STAY) as mean_los*/
/*from top_15*/
/*union all*/
/*select 'Top 20%' as group,*/
/*mean(total_inp_birth_cost) as mean_cost,*/
/*sum(total_inp_birth_cost) as subtotal_cost,*/
/*calculated subtotal_cost/&total_cost*100 as pct_total_cost,*/
/*mean(total_mean_LENGTH_OF_STAY) as mean_los*/
/*from top_20*/
/*union all*/
/*select 'Top 50%' as group,*/
/*mean(total_inp_birth_cost) as mean_cost,*/
/*sum(total_inp_birth_cost) as subtotal_cost,*/
/*calculated subtotal_cost/&total_cost*100 as pct_total_cost,*/
/*mean(total_mean_LENGTH_OF_STAY) as mean_los*/
/*from top_50*/
/*union all*/
/*select 'Bot 20%' as group,*/
/*mean(total_inp_birth_cost) as mean_cost,*/
/*sum(total_inp_birth_cost) as subtotal_cost,*/
/*calculated subtotal_cost/&total_cost*100 as pct_total_cost,*/
/*mean(total_mean_LENGTH_OF_STAY) as mean_los*/
/*from bot_20*/
/*union all*/
/*select 'Bot 50%' as group,*/
/*mean(total_inp_birth_cost) as mean_cost,*/
/*sum(total_inp_birth_cost) as subtotal_cost,*/
/*calculated subtotal_cost/&total_cost*100 as pct_total_cost,*/
/*mean(total_mean_LENGTH_OF_STAY) as mean_los*/
/*from bot_50;*/
/*quit;*/
/**/
/*proc print data=cost_summary; run;*/
/**/
/**/
/**/
/*data cumulative_data_mum; set npdc_dev_cost_risk;*/
/*retain cum_cost 0 cum_population 0;*/
/*cum_cost+total_mom_birth_cost;*/
/*cum_population+1;*/
/*population_ratio=cum_population/&total_count;*/
/*cost_ratio=cum_cost/&total_mum_cost;*/
/*run;*/
/**/
/**/
/**/
/*proc sql noprint;*/
/*select sum(baby_birth_DRGcost_neo) into: baby_birth_DRGcost_neo from npdc_dev_cost_risk;*/
/*quit;*/
/**/
/*data cumulative_data_baby; set npdc_dev_cost_risk;*/
/*retain cum_cost 0 cum_population 0;*/
/*cum_cost+baby_birth_DRGcost_neo;*/
/*cum_population+1;*/
/*population_ratio=cum_population/&total_count;*/
/*cost_ratio=cum_cost/&baby_birth_DRGcost_neo;*/
/*run;*/
/**/
/**/
/*proc sgplot data=cost_summary;*/
/*series x=group y=mean_cost/lineattrs=(thickness=2);*/
/*run;*/
/**/
/**/
/**/
/*proc sql noprint;*/
/*select sum(total_inp_birth_cost) into: total_cost from npdc_dev_cost_risk;*/
/*quit;*/
/**/
/*data cumulative_data; set npdc_dev_cost_risk;*/
/*retain cum_cost 0 cum_population 0;*/
/*cum_cost+total_inp_birth_cost;*/
/*cum_population+1;*/
/*population_ratio=cum_population/&total_count;*/
/*cost_ratio=cum_cost/&total_cost;*/
/*run;*/
/**/
/**/
/*proc sgplot data=cumulative_data;*/
/*series x=population_ratio y=cum_cost/lineattrs=(thickness=2);*/
/*run;*/
/**/




/*data npdc_dev_cost_risk; set npdc_dev_cost_risk;*/
/*obs_num=_N_; run;*/


/*proc sgplot data=npdc_dev_cost_risk;*/
/*series x=obs_num y=total_mom_birth_cost/lineattrs=(thickness=2);*/
/*run;*/




/**/
/*proc means data=top_5 n mean std;*/
/*var total_inp_birth_cost total_mom_birth_cost total_baby_birth_cost total_birth_DRGcost total_birth_PHIcost mom_birth_DRGcost_ob mom_birth_DRGcost_nob;*/
/*run;*/
/**/
/*proc means data=next_5 n mean std;*/
/*var total_inp_birth_cost total_mom_birth_cost total_baby_birth_cost total_birth_DRGcost total_birth_PHIcost mom_birth_DRGcost_ob mom_birth_DRGcost_nob;*/
/*run;*/
/**/
/*proc means data=next_5_2 n mean std;*/
/*var total_inp_birth_cost total_mom_birth_cost total_baby_birth_cost total_birth_DRGcost total_birth_PHIcost mom_birth_DRGcost_ob mom_birth_DRGcost_nob;*/
/*run;*/
/**/
/*proc means data=bot_85 n mean std;*/
/*var total_inp_birth_cost total_mom_birth_cost total_baby_birth_cost total_birth_DRGcost total_birth_PHIcost mom_birth_DRGcost_ob mom_birth_DRGcost_nob;*/
/*run;*/
/**/
/**/
/**/
/*proc means data=top_10 n mean std sum;*/
/*var total_inp_birth_cost total_mom_birth_cost total_baby_birth_cost total_birth_DRGcost total_birth_PHIcost mom_birth_DRGcost_ob mom_birth_DRGcost_nob;*/
/*run;*/
/**/
/*proc means data=top_15 n mean std sum;*/
/*var total_inp_birth_cost total_mom_birth_cost total_baby_birth_cost total_birth_DRGcost total_birth_PHIcost mom_birth_DRGcost_ob mom_birth_DRGcost_nob;*/
/*run;*/

/**/
/*PROC IMPORT OUT= pdc_dev_risk */
/*  DATAFILE= "G:\Papers\Yanan Hu\PhD\Study#4\sas\clean data\pdc_dev_risk.csv" */
/*  DBMS=CSV REPLACE;*/
/* GETNAMES=YES;*/
/* DATAROW=2; */
/*	 	 guessingrows=100000;*/
/**/
/*RUN;*/
/**/
/**/
/*PROC IMPORT OUT= npdc_val_risk */
/*  DATAFILE= "G:\Papers\Yanan Hu\PhD\Study#4\sas\clean data\npdc_val_risk.csv" */
/*  DBMS=CSV REPLACE;*/
/* GETNAMES=YES;*/
/* DATAROW=2; */
/*	 	 guessingrows=10000;*/
/**/
/*RUN;*/
/**/
/**/
/*PROC IMPORT OUT= vpdc_val_risk */
/*  DATAFILE= "G:\Papers\Yanan Hu\PhD\Study#4\sas\clean data\vpdc_val_risk.csv" */
/*  DBMS=CSV REPLACE;*/
/* GETNAMES=YES;*/
/* DATAROW=2; */
/*	 	 guessingrows=10000;*/
/**/
/*RUN;*/
/**/
/**change ppn from numeric to character var for merging;*/
/*data pdc_dev_risk;set pdc_dev_risk;*/
/*aihw_baby_ppn_char=put(aihw_baby_ppn,14.);*/
/*aihw_mom_ppn_char=put(aihw_mom_ppn,14.);*/
/*drop aihw_baby_ppn aihw_mom_ppn;*/
/*run;*/
/**/
/**/
/*data pdc_dev_risk; set pdc_dev_risk;*/
/*rename aihw_baby_ppn_char=aihw_baby_ppn;*/
/*rename aihw_mom_ppn_char=aihw_mom_ppn;*/
/*run;*/
/**/
/**/
/*data npdc_val_risk;set npdc_val_risk;*/
/*aihw_baby_ppn_char=put(aihw_baby_ppn,14.);*/
/*aihw_mom_ppn_char=put(aihw_mom_ppn,14.);*/
/*drop aihw_baby_ppn aihw_mom_ppn;*/
/*run;*/
/**/
/**/
/*data npdc_val_risk; set npdc_val_risk;*/
/*rename aihw_baby_ppn_char=aihw_baby_ppn;*/
/*rename aihw_mom_ppn_char=aihw_mom_ppn;*/
/*run;*/
/**/
/**/
/*data vpdc_val_risk;set vpdc_val_risk;*/
/*aihw_baby_ppn_char=put(aihw_baby_ppn,14.);*/
/*aihw_mom_ppn_char=put(aihw_mom_ppn,14.);*/
/*drop aihw_baby_ppn aihw_mom_ppn;*/
/*run;*/
/**/
/**/
/*data vpdc_val_risk; set vpdc_val_risk;*/
/*rename aihw_baby_ppn_char=aihw_baby_ppn;*/
/*rename aihw_mom_ppn_char=aihw_mom_ppn;*/
/*run;*/
/**/
/**/
/**/
/*data csai.pdc_dev_risk; set pdc_dev_risk;run;*/
/**/
/*data csai.npdc_val_risk; set npdc_val_risk;run;*/
/**/
/*data csai.vpdc_val_risk; set vpdc_val_risk;run;*/


/**/
/*proc means data=ranked_data;*/
/*class quintile;*/
/*var total_inp_birth_cost;*/
/*run;*/
/**/
/**/
/*proc means data=ranked_data;*/
/*class quintile;*/
/*var total_mean_LENGTH_OF_STAY;*/
/*run;*/
/**/
/**/
/*proc means data=ranked_data;*/
/*class quintile;*/
/*var total_mom_birth_cost;*/
/*run;*/
/**/
/**/
/*proc means data=ranked_data;*/
/*class quintile;*/
/*var total_baby_birth_cost;*/
/*run;*/

/*proc sql; select count(aihw_baby_ppn) as count*/
/*from ranked_data*/
/*where mom_birth_PHIcost=0 and mom_birth_DRGcost=0;*/
/*quit; *n=1144 (no matching record in npdc_inp);*/


/**/
/*data new; set ranked_data;*/
/*if mom_birth_PHIcost=0 and mom_birth_DRGcost=0;*/
/*keep aihw_mom_ppn aihw_baby_ppn year;*/
/*run;*/
/**/
/**/
/*data npdc_main; set matern.npdc_main;*/
/*keep aihw_mom_ppn aihw_baby_ppn bdob PLACEBTH;run;*/
/*run;*/
/**/
/**/
/*/*proc contents data=new; run;*/*/
/*/*proc contents data=npdc_main; run;*/*/
/**/
/*proc sort data=npdc_main; by aihw_baby_ppn; run;*/
/*proc sort data=new; by aihw_baby_ppn; run;*/
/**/
/*data test; merge new (in=a) npdc_main (in=b); by aihw_baby_ppn;*/
/*if a and b then output;*/
/*run;*/
/**/
/**/
/*proc freq data=test;*/
/*table PLACEBTH; run;*/
/**/
/**/
/**/
/**/
/*data npdc_inp; set matern.npdc_inp;*/
/*rename ar_drg=drg;*/
/*rename aihw_ppn=aihw_mom_ppn;*/
/*run;*/
/**/
/*data npdc_inp; set npdc_inp; */
/*year=year(episode_start_date);*/
/*keep aihw_mom_ppn year episode_start_date episode_end_date drg;run;*/
/**/
/**/
/*proc sort data=npdc_inp; by aihw_mom_ppn year; run;*/
/*proc sort data=test; by aihw_mom_ppn year; run;*/
/**/
/*data test2; merge test (in=a) npdc_inp (in=b); by aihw_mom_ppn year;*/
/*if a and b then output;*/
/*run;*/







/**/
/*proc sql;*/
/*create table group_total as */
/*select decile, mean (total_inp_birth_cost) as mean_cost,*/
/*sum(total_inp_birth_cost) as total_cost*/
/*from ranked_data*/
/*group by decile;*/
/*quit;*/



/*proc sql noprint;*/
/*select sum(total_cost) into: overall_total_cost*/
/*from group_total;*/
/*quit;*/
/**/
/**/
/**/
/*data cumu_cost; set group_total;*/
/*by decile;*/
/*retain cumulative_cost 0;*/
/*cumulative_cost+total_cost;*/
/*pct=total_cost/&overall_total_cost;*/
/*run;*/


/*proc print data=cumu_cost; run;*/
/**/
/**/


/*proc tabulate data=ranked_data out=summary_data;*/
/*class decile;*/
/*var mother_age bmi seifa rurality total_mean_LENGTH_OF_STAY total_inp_birth_cost total_mom_birth_cost pct_mom total_mom_birth_cost_ob pct_mom_ob total_baby_birth_cost pct_baby total_baby_birth_cost_neo pct_baby_neo;*/
/*tables mother_age bmi seifa rurality total_mean_LENGTH_OF_STAY total_inp_birth_cost total_mom_birth_cost pct_mom total_mom_birth_cost_ob pct_mom_ob total_baby_birth_cost pct_baby total_baby_birth_cost_neo pct_baby_neo, decile *mean;*/
/*run;*/


/*proc tabulate data=ranked_data out=summary_data;*/
/*class decile;*/
/*var mom_mean_LENGTH_OF_STAY total_mom_birth_cost;*/
/*tables mom_mean_LENGTH_OF_STAY total_mom_birth_cost, decile *mean;*/
/*run;*/
