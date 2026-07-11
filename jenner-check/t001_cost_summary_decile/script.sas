/* Adapted from Code/SAS/Cost assignment/cost_summary.sas (Yanan-Hu/CSAI)
   Original reads csai.npdc_val_risk_cost from a LIBNAME pointing at a private
   linked-hospital-data folder (G:\Papers\...). That dataset is de-identified
   AIHW linkage data and cannot be shared, so this bundle substitutes a small
   mock cohort with the same columns (predicted_risk, bmi, mother_age, length
   of stay and cost fields) via inline datalines. The PROC RANK / PROC TABULATE
   / PROC SGPLOT logic below is otherwise unchanged from the source script. */

data npdc_val_risk_cost;
  input predicted_risk bmi mother_age
        mom_mean_LENGTH_OF_STAY baby_mean_LENGTH_OF_STAY total_mean_LENGTH_OF_STAY
        total_mom_birth_cost total_baby_birth_cost total_inp_birth_cost;
  datalines;
0.02 21.4 24 2.1 1.8 3.9 4200 3100  7300
0.05 23.8 27 2.3 2.0 4.3 4550 3300  7850
0.08 26.1 29 2.4 2.1 4.5 4800 3450  8250
0.11 27.9 31 2.6 2.2 4.8 5100 3600  8700
0.14 29.4 33 2.8 2.4 5.2 5600 3900  9500
0.18 30.7 35 3.1 2.6 5.7 6300 4200 10500
0.22 31.9 22 3.4 2.9 6.3 7100 4600 11700
0.27 33.2 38 3.8 3.2 7.0 8200 5100 13300
0.34 34.6 40 4.3 3.6 7.9 9600 5900 15500
0.41 36.1 42 5.1 4.1 9.2 11800 7000 18800
0.05 22.6 26 2.2 1.9 4.1 4350 3200  7550
0.16 28.8 30 2.9 2.5 5.4 5900 4000 9900
0.29 32.5 36 3.9 3.3 7.2 8500 5300 13800
0.09 25.2 28 2.4 2.1 4.5 4750 3400  8150
0.38 35.5 41 4.9 4.0 8.9 10900 6500 17400
;
run;

data npdc_val_risk_cost; set npdc_val_risk_cost;
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

proc print data=cost_summary noobs; run;

proc format;
value bmi2dec low-high=8.2;
run;

proc sgplot data=ranked_data noautolegend;
format bmi bmi2dec.;
vbar decile/response=bmi stat=mean limits=both fillattrs=(color=steelblue) outlineattrs=(thickness=0) datalabel=bmi;
xaxis label="Predicted risk decile group (1:Lowest risk; 10:Highest risk)";
yaxis label="Mean BMI";
run;

proc sgplot data=ranked_data noautolegend;
format total_mom_birth_cost Dollar8.0;
vbar decile/response=total_mom_birth_cost stat=mean limits=both fillattrs=(color=steelblue) outlineattrs=(thickness=0) datalabel=total_mom_birth_cost;
xaxis label="Predicted risk decile group (1:Lowest risk; 10:Highest risk)";
yaxis label="Mean maternal inpatient cost" valuesformat=Dollar8.0;
run;
