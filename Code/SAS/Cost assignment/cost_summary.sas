/******************************************************************************************************************************
*Create date: 2 Nov 2024
*Last update date: 18 Nov 2024
*Author: Yanan Hu
*Purpose: analyse cost by risk decile
*****************************************************************************************************************************/

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
