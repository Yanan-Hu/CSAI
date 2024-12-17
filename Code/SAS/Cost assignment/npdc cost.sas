/******************************************************************************************************************************
*Create date: 2 Nov 2024
*Last update date: 18 Nov 2024
*Author: Yanan Hu and Emily Callander
*Data source: IHACPA (public hospitals), PHDB (private hospitals, hospital type: private - other, national data, latest ARDRG version)
*Purpose: assigning cost for hospitals 2015/16 - 2019/20
*****************************************************************************************************************************/


libname matern "G:\Data in sas format";
libname cost "G:\Data in sas format\costs";


*import cost file;
data drgcost; set cost.drgcost_new;
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


*add remoteness, mother and baby's indigenous status and date of birth;
data npdc_main; set matern.npdc_main;
if RA_2011_CODE='10' then rurality=1; *major city;
else if RA_2011_CODE='11' then rurality=2; *inner regional;
else if RA_2011_CODE='12' then rurality=3; *outer regional;
else if RA_2011_CODE='13' then rurality=4; *remote;
else if RA_2011_CODE='14' then rurality=5; *very remote;
else rurality=9;

keep aborigin_mum_recode ABORIGIN_BUB_RECODE aihw_mom_ppn aihw_baby_ppn BDOB yr_dob_mum rurality;
run;


*import inp dataset;
data npdc_inp; set matern.npdc_inp;
rename ar_drg=drg;
run;


******************************************************
mom cost;


proc sql noprint;
create table merged_mum_inp as
select npdc_inp.*,npdc_main.*
from npdc_inp 
left join npdc_main
on npdc_inp.aihw_ppn = npdc_main.aihw_mom_ppn;
quit;


data mom_inp; set merged_mum_inp;
if aihw_ppn=aihw_mom_ppn then output;
run;


*sort both inp and cost file by drg to match;
proc sort data=drgcost; by drg; run;
proc sort data=mom_inp; by drg; run;


data mom_cost; merge mom_inp (in=a) drgcost (in=b);by drg;
if a then output; run;


data mom_cost; set mom_cost;
if drg='' then do; *use average total cost;
	cost_16=5199;
	cost_17=5171;
	cost_18=4885;
	cost_19=5027;
	cost_20=5335;

	ave_charge_16=3428;
	ave_charge_17=3433;
	ave_charge_18=3636;
	ave_charge_19=3692;
	ave_charge_20=3785;

	private_16=0;
	private_17=0;
	private_18=0;
	private_19=0;
	private_20=0;

end;

*identify obstetric-related admission;
obstetric=0;
ARRAY d_code(*)diagnosis_code1-diagnosis_code50;
	do i=1 to dim(d_code);
	d_code (i)=substr(d_code(i), 1, 1);

if d_code (i) in ('O') then do;
obstetric=1;
end;
end;


if obstetric ne 1 then do;
length diagnosis_short drg_short $1; 
diagnosis_short=diagnosis_codeP; 
drg_short=drg;
if diagnosis_short in ('O') or drg_short in ('O') 
then obstetric=1; 
end;

*identify private patients in private hospitals, limit to public;
if hospital_type=4 then private_hospital=1; else private_hospital=0;

private_episode=0;
if private_hospital=1 then do;
if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then private_episode=1;
end; 

*convert admission date into financial year date to match to DRG cost for each financial year;
if month(episode_start_date) in (7,8,9,10,11,12) then FFyear=year(episode_start_date)+1;
	else FFyear=year(episode_start_date);
if FFyear>2020 then delete;
run;



data mom_cost_public; set mom_cost (where=(private_episode=0));run;
data mom_cost_private; set mom_cost (where=(private_episode=1));run;


******************************************************
public hospital;

data mom_cost_public; set mom_cost_public;
if HOURS_IN_ICU=. then HOURS_IN_ICU=0;
run;


*assign a cost to the DRG, according to the FFyear;
data mom_cost_public; set mom_cost_public;
	if FFyear=2016 then DRGcost=cost_16;
	if FFyear=2017 then DRGcost=cost_17;
	if FFyear=2018 then DRGcost=cost_18;
	if FFyear=2019 then DRGcost=cost_19;
	if FFyear=2020 then DRGcost=cost_20; 
run;


data mom_cost_public; set mom_cost_public;

mother_age=year(episode_start_date)-yr_dob_mum;

*apply adjustments;
if FFyear=2016 then do;

	if mdc in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.15; 
	else if mdc in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.09; *specialised children's hospital;
	else if mdc not in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.22;
	else if mdc not in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.41;
	else if mdc not in ('19','20') and mother_age>17 and DAYS_IN_PSYCH_UNIT>0 then spa=0.34;
	else spa=0;

	if aborigin_mum_recode=1 then ind=0.04; else ind=0;

	if rurality=3 then a=0.08;
	else if rurality=4 then a=0.16;
	else if rurality=5 then a=0.22;
	else a=0;

	
	rt=0;
	dia=0;
	ARRAY code_16(*)procedure_code1-procedure_code50;
	do i=1 to dim(code_16);
	if substr(code_16(i), 1, 2)='15' or substr(code_16(i), 1, 5) in ('90764','90765','90766','90960','16003','16009','16012','16015','16018','37217') then do; 
	rt=0.26;
	end;

	if substr(code_16(i), 1, 5)='13100' then do; dia=0.25;
	end;

	end; 

	icu=0.0440*4971; *all in the specified icu list;

	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then pps=private_16; else pps=0;

	acc=0;
	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then do;
	if EPISODE_LENGTH_OF_STAY>1 then acc=0.0687*4971; *use overnight one, different for each state;
	else if EPISODE_LENGTH_OF_STAY=1 then acc=0.0499*4971; *use same day one, different for each state;
	end;

end;


if FFyear=2017 then do;

	if mdc in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.21; 
	else if mdc in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.10; *specialised children's hospital;
	else if mdc not in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.24;
	else if mdc not in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.45;
	else if mdc not in ('19','20') and mother_age>17 and DAYS_IN_PSYCH_UNIT>0 then spa=0.32;
	else spa=0;

	if aborigin_mum_recode=1 then ind=0.05; else ind=0;

	if rurality=3 then a=0.08;
	else if rurality=4 then a=0.18;
	else if rurality=5 then a=0.23;
	else a=0;

	rt=0;
	dia=0;
	ARRAY code_17(*)procedure_code1-procedure_code50;
	do i=1 to dim(code_17);
	if substr(code_17(i), 1, 2)='15' or substr(code_17(i), 1, 5) in ('90764','90765','90766','90960','16003','16009','16012','16015','16018','37217') then do; rt=0.26;
	end; 
	

	if substr(code_17(i), 1, 5)='13100' then do; dia=0.26; 
	end;
	 
	end;

	icu=0.0436*4883; *all in the specified icu list;

	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then pps=private_17; else pps=0;

	acc=0;
	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then do;
	if EPISODE_LENGTH_OF_STAY>1 then acc=0.07*4883; *use overnight one, different for each state;
	else if EPISODE_LENGTH_OF_STAY=1 then acc=0.0508*4883; *use same day one, different for each state;
	end;
	 
		

end;


if FFyear=2018 then do;

	if mdc in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.28; 
	else if mdc in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.10; *specialised children's hospital;
	else if mdc not in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.46;
	else if mdc not in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.44;
	else if mdc not in ('19','20') and mother_age>17 and DAYS_IN_PSYCH_UNIT>0 then spa=0.32;
	else spa=0;

	if aborigin_mum_recode=1 then ind=0.04; else ind=0;

	if rurality=3 then a=0.08;
	else if rurality=4 then a=0.20;
	else if rurality=5 then a=0.25;
	else a=0;

	rt=0;
	dia=0;
	ARRAY code_18(*)procedure_code1-procedure_code50;
	do i=1 to dim(code_18);
	if substr(code_18(i), 1, 2)='15' or substr(code_18(i), 1, 5) in ('90764','90765','90766','90960','16003','16009','16012','16015','16018','37217') then do; rt=0.27;
	end;
	 

	if substr(code_18(i), 1, 5)='13100' then do; dia=0.25; 
	end;
	 
	end;

	icu=0.0427*4910; *all in the specified icu list;

	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then pps=private_18; else pps=0;

	acc=0;
	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then do;
	if EPISODE_LENGTH_OF_STAY>1 then acc=0.0708*4910; *use overnight one, different for each state;
	else if EPISODE_LENGTH_OF_STAY=1 then acc=0.0514*4910; *use same day one, different for each state;
	end;
	 
	
end;

if FFyear=2019 then do; *note: no adjustment for Atreat, which is for remoteness of hospital, no data;

	if mdc in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.41; 
	else if mdc in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.15; *specialised children's hospital;
	else if mdc not in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.71;
	else if mdc not in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.58;
	else if mdc not in ('19','20') and mother_age>17 and DAYS_IN_PSYCH_UNIT>0 then spa=0.30;
	else spa=0;

	if aborigin_mum_recode=1 then ind=0.04; else ind=0;

	if rurality=3 then a=0.08;
	else if rurality=4 then a=0.25;
	else if rurality=5 then a=0.29;
	else a=0;

	rt=0;
	dia=0;
	ARRAY code_19(*)procedure_code1-procedure_code50;
	do i=1 to dim(code_19);
	if substr(code_19(i), 1, 2)='15' or substr(code_19(i), 1, 5) in ('90764','90765','90766','90960','16003','16009','16012','16015','16018','37217') then do; rt=0.32;
	end; 
	 
	if substr(code_19(i), 1, 5)='13100' then do; dia=0.27; 
	end;
	 
	end;

	icu=0.0439*5012; *all in the specified icu list;

	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then pps=private_19; else pps=0;

	acc=0;
	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then do;
	if EPISODE_LENGTH_OF_STAY>1 then acc=0.0711*5012; *use overnight one, different for each state;
	else if EPISODE_LENGTH_OF_STAY=1 then acc=0.0516*5012; *use same day one, different for each state;
	end;
	  
	
end;

if FFyear=2020 then do; *note: no adjustment for Atreat, which is for remoteness of hospital, no data;

	if mdc in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.49; 
	else if mdc in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.16; *specialised children's hospital;
	else if mdc not in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.89;
	else if mdc not in ('19','20') and mother_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.72;
	else if mdc not in ('19','20') and mother_age>17 and DAYS_IN_PSYCH_UNIT>0 then spa=0.32;
	else spa=0;


	if aborigin_mum_recode=1 then ind=0.04; else ind=0;

	if rurality=3 then a=0.08;
	else if rurality=4 then a=0.27;
	else if rurality=5 then a=0.29;
	else a=0;

	rt=0;
	dia=0;
	ARRAY code_20(*)procedure_code1-procedure_code50;
	do i=1 to dim(code_20);
	if substr(code_20(i), 1, 2)='15' or substr(code_20(i), 1, 5) in ('96256','90764','90765','90766','90960','16003','16009','16012','16015','16018','37217') then do; rt=0.36;
	end;

	if substr(code_20(i), 1, 5)='13100' then do; dia=0.27;
	end;
	 
	end;

	icu=0.0432*5134; *all in the specified icu list;

	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then pps=private_20; else pps=0;

	acc=0;
	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then do;
	if EPISODE_LENGTH_OF_STAY>1 then acc=0.0706*5134; *use overnight one, different for each state;
	else if EPISODE_LENGTH_OF_STAY=1 then acc=0.0512*5134; *use same day one, different for each state;
	end;
	 
end;

if DRGcost=. then DRGcost=0;
if DRGcost=0 then DRGcosta=0; 
else DRGcosta=DRGcost*(1+spa)*(1+ind+a+rt+dia)+icu*HOURS_IN_ICU - ((DRGcost+icu*HOURS_IN_ICU)*pps+EPISODE_LENGTH_OF_STAY*acc);

*adjust for inflation - 2023-24 dollars from: https://www.rba.gov.au/calculator/financialYearDecimal.html;

if FFyear=2016 then DRGcosta_inf=DRGcosta*1.26;
if FFyear=2017 then DRGcosta_inf=DRGcosta*1.24;
if FFyear=2018 then DRGcosta_inf=DRGcosta*1.22;
if FFyear=2019 then DRGcosta_inf=DRGcosta*1.20;
if FFyear=2020 then DRGcosta_inf=DRGcosta*1.18;

run;


data mom_cost_public_short; set mom_cost_public;
keep aihw_mom_ppn aihw_baby_ppn drg DRGcost DRGcosta DRGcosta_inf episode_start_date episode_end_date EPISODE_LENGTH_OF_STAY BDOB obstetric private_episode private_hospital;
run;


******************************************************
private hospital;


*assign a cost to the DRG, according to the FFyear 
and adjust for inflation - 2023-24 dollars from: https://www.rba.gov.au/calculator/financialYearDecimal.html;
data mom_cost_private; set mom_cost_private;
if FFyear=2016 then PHIcost=ave_charge_16;
if FFyear=2017 then PHIcost=ave_charge_17;
if FFyear=2018 then PHIcost=ave_charge_18;
if FFyear=2019 then PHIcost=ave_charge_19;
if FFyear=2020 then PHIcost=ave_charge_20;


if FFyear=2016 then PHIcost_inf=PHIcost*1.26;
if FFyear=2017 then PHIcost_inf=PHIcost*1.24;
if FFyear=2018 then PHIcost_inf=PHIcost*1.22;
if FFyear=2019 then PHIcost_inf=PHIcost*1.20;
if FFyear=2020 then PHIcost_inf=PHIcost*1.18;
run;


data mom_cost_private_short; set mom_cost_private;
keep aihw_mom_ppn aihw_baby_ppn drg PHIcost PHIcost_inf episode_start_date episode_end_date EPISODE_LENGTH_OF_STAY BDOB obstetric private_episode private_hospital;
run; 


proc sort data=mom_cost_private_short; by aihw_mom_ppn; run;
proc sort data=mom_cost_public_short; by aihw_mom_ppn; run;

data mom_cost; set mom_cost_private_short mom_cost_public_short; run;


*save cost data;
data cost.npdc_inp_mom_cost; set mom_cost;
run;


******************************************************
Baby cost;


proc sql noprint;
create table merged_baby_inp as
select npdc_inp.*,npdc_main.*
from npdc_inp 
left join npdc_main
on npdc_inp.aihw_ppn = npdc_main.aihw_baby_ppn;
quit;


data baby_inp; set merged_baby_inp;
if aihw_ppn=aihw_baby_ppn then output;
run;


*sort both inp and cost file by drg to match;
proc sort data=drgcost; by drg; run;
proc sort data=baby_inp; by drg; run;


data baby_cost; merge baby_inp (in=a) drgcost (in=b);by drg;
if a then output; run;


data baby_cost; set baby_cost;
if drg='' then do; *use average total cost;
	cost_16=5199;
	cost_17=5171;
	cost_18=4885;
	cost_19=5027;
	cost_20=5335;

	ave_charge_16=3428;
	ave_charge_17=3433;
	ave_charge_18=3636;
	ave_charge_19=3692;
	ave_charge_20=3785;

	private_16=0;
	private_17=0;
	private_18=0;
	private_19=0;
	private_20=0;

	paed_16=1; 
	paed_17=1;
	paed_18=1;
	paed_19=1;
	paed_20=1;

end;

*identify neonatal-related admission;
neonatal=0;
ARRAY d_b_code(*)diagnosis_code1-diagnosis_code50;
	do i=1 to dim(d_b_code);
	d_b_code (i)=substr(d_b_code(i), 1, 1);

if d_b_code (i) in ('P') then do;
neonatal=1;
end;
end;


if neonatal ne 1 then do;
length diagnosis_short drg_short $1; 
diagnosis_short=diagnosis_codeP; 
drg_short=drg;
if diagnosis_short in ('P') or drg_short in ('P') 
then neonatal=1; 
end;

*identify private patients in private hospitals, limit to public;
if hospital_type=4 then private_hospital=1; else private_hospital=0;

private_episode=0;
if private_hospital=1 then do;
if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then private_episode=1;
end; 

*convert admission date into financial year date to match to DRG cost for each financial year;
if month(episode_start_date) in (7,8,9,10,11,12) then FFyear=year(episode_start_date)+1;
	else FFyear=year(episode_start_date);
run;



data baby_cost_public; set baby_cost (where=(private_episode=0));run;
data baby_cost_private; set baby_cost (where=(private_episode=1));run;


******************************************************
public hospital;

data baby_cost_public; set baby_cost_public;
if HOURS_IN_ICU=. then HOURS_IN_ICU=0;
run;


*assign a cost to the DRG, according to the FFyear;
data baby_cost_public; set baby_cost_public;
	if FFyear=2016 then DRGcost=cost_16;
	if FFyear=2017 then DRGcost=cost_17;
	if FFyear=2018 then DRGcost=cost_18;
	if FFyear=2019 then DRGcost=cost_19;
	if FFyear=2020 then DRGcost=cost_20; 
run;


data baby_cost_public; set baby_cost_public;

baby_age=year(episode_start_date)-year(bdob);

*apply adjustments;
if FFyear=2016 then do;

	if area_identifier='X630' then paed=paed_16; else paed=1; *specialised children's hospital;
	if mdc in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.15; 
	else if mdc in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.09; *specialised children's hospital;
	else if mdc not in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.22;
	else if mdc not in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.41;
	else if mdc not in ('19','20') and baby_age>17 and DAYS_IN_PSYCH_UNIT>0 then spa=0.34;
	else spa=0;

	if aborigin_bub_recode=1 then ind=0.04; else ind=0;

	if rurality=3 then a=0.08;
	else if rurality=4 then a=0.16;
	else if rurality=5 then a=0.22;
	else a=0;

	
	rt=0;
	dia=0;
	ARRAY b_code_16(*)procedure_code1-procedure_code50;
	do i=1 to dim(b_code_16);
	if substr(b_code_16(i), 1, 2)='15' or substr(b_code_16(i), 1, 5) in ('90764','90765','90766','90960','16003','16009','16012','16015','16018','37217') then do; 
	rt=0.26;
	end;

	if substr(b_code_16(i), 1, 5)='13100' then do; dia=0.25;
	end;

	end; 

	icu=0.0440*4971; *all in the specified icu list;

	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then pps=private_16; else pps=0;

	acc=0;
	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then do;
	if EPISODE_LENGTH_OF_STAY>1 then acc=0.0687*4971; *use overnight one, different for each state;
	else if EPISODE_LENGTH_OF_STAY=1 then acc=0.0499*4971; *use same day one, different for each state;
	end;

end;


if FFyear=2017 then do;

	if area_identifier='X630' then paed=paed_17; else paed=1; *specialised children's hospital;
	if mdc in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.21; 
	else if mdc in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.10; *specialised children's hospital;
	else if mdc not in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.24;
	else if mdc not in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.45;
	else if mdc not in ('19','20') and baby_age>17 and DAYS_IN_PSYCH_UNIT>0 then spa=0.32;
	else spa=0;

	if aborigin_bub_recode=1 then ind=0.05; else ind=0;

	if rurality=3 then a=0.08;
	else if rurality=4 then a=0.18;
	else if rurality=5 then a=0.23;
	else a=0;

	rt=0;
	dia=0;
	ARRAY b_code_17(*)procedure_code1-procedure_code50;
	do i=1 to dim(b_code_17);
	if substr(b_code_17(i), 1, 2)='15' or substr(b_code_17(i), 1, 5) in ('90764','90765','90766','90960','16003','16009','16012','16015','16018','37217') then do; rt=0.26;
	end; 
	

	if substr(b_code_17(i), 1, 5)='13100' then do; dia=0.26; 
	end;
	 
	end;

	icu=0.0436*4883; *all in the specified icu list;

	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then pps=private_17; else pps=0;

	acc=0;
	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then do;
	if EPISODE_LENGTH_OF_STAY>1 then acc=0.07*4883; *use overnight one, different for each state;
	else if EPISODE_LENGTH_OF_STAY=1 then acc=0.0508*4883; *use same day one, different for each state;
	end;
	 
		

end;


if FFyear=2018 then do;

	if area_identifier='X630' then paed=paed_18; else paed=1; *specialised children's hospital;
	if mdc in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.28; 
	else if mdc in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.10; *specialised children's hospital;
	else if mdc not in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.46;
	else if mdc not in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.44;
	else if mdc not in ('19','20') and baby_age>17 and DAYS_IN_PSYCH_UNIT>0 then spa=0.32;
	else spa=0;

	if aborigin_bub_recode=1 then ind=0.04; else ind=0;

	if rurality=3 then a=0.08;
	else if rurality=4 then a=0.20;
	else if rurality=5 then a=0.25;
	else a=0;

	rt=0;
	dia=0;
	ARRAY b_code_18(*)procedure_code1-procedure_code50;
	do i=1 to dim(b_code_18);
	if substr(b_code_18(i), 1, 2)='15' or substr(b_code_18(i), 1, 5) in ('90764','90765','90766','90960','16003','16009','16012','16015','16018','37217') then do; rt=0.27;
	end;
	 

	if substr(b_code_18(i), 1, 5)='13100' then do; dia=0.25; 
	end;
	 
	end;

	icu=0.0427*4910; *all in the specified icu list;

	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then pps=private_18; else pps=0;

	acc=0;
	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then do;
	if EPISODE_LENGTH_OF_STAY>1 then acc=0.0708*4910; *use overnight one, different for each state;
	else if EPISODE_LENGTH_OF_STAY=1 then acc=0.0514*4910; *use same day one, different for each state;
	end;
	 
	
end;

if FFyear=2019 then do; *note: no adjustment for Atreat, which is for remoteness of hospital, no data;

	if area_identifier='X630' then paed=paed_19; else paed=1; *specialised children's hospital;
	if mdc in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.41; 
	else if mdc in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.15; *specialised children's hospital;
	else if mdc not in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.71;
	else if mdc not in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.58;
	else if mdc not in ('19','20') and baby_age>17 and DAYS_IN_PSYCH_UNIT>0 then spa=0.30;
	else spa=0;

	if aborigin_bub_recode=1 then ind=0.04; else ind=0;

	if rurality=3 then a=0.08;
	else if rurality=4 then a=0.25;
	else if rurality=5 then a=0.29;
	else a=0;

	rt=0;
	dia=0;
	ARRAY b_code_19(*)procedure_code1-procedure_code50;
	do i=1 to dim(b_code_19);
	if substr(b_code_19(i), 1, 2)='15' or substr(b_code_19(i), 1, 5) in ('90764','90765','90766','90960','16003','16009','16012','16015','16018','37217') then do; rt=0.32;
	end; 
	 
	if substr(b_code_19(i), 1, 5)='13100' then do; dia=0.27; 
	end;
	 
	end;

	icu=0.0439*5012; *all in the specified icu list;

	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then pps=private_19; else pps=0;

	acc=0;
	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then do;
	if EPISODE_LENGTH_OF_STAY>1 then acc=0.0711*5012; *use overnight one, different for each state;
	else if EPISODE_LENGTH_OF_STAY=1 then acc=0.0516*5012; *use same day one, different for each state;
	end;
	  
	
end;

if FFyear=2020 then do; *note: no adjustment for Atreat, which is for remoteness of hospital, no data;

	if area_identifier='X630' then paed=paed_20; else paed=1; *specialised children's hospital;
	if mdc in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.49; 
	else if mdc in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.16; *specialised children's hospital;
	else if mdc not in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier NE 'X630' then spa=0.89;
	else if mdc not in ('19','20') and baby_age<=17 and DAYS_IN_PSYCH_UNIT>0 and area_identifier='X630' then spa=0.72;
	else if mdc not in ('19','20') and baby_age>17 and DAYS_IN_PSYCH_UNIT>0 then spa=0.32;
	else spa=0;


	if aborigin_bub_recode=1 then ind=0.04; else ind=0;

	if rurality=3 then a=0.08;
	else if rurality=4 then a=0.27;
	else if rurality=5 then a=0.29;
	else a=0;

	rt=0;
	dia=0;
	ARRAY b_code_20(*)procedure_code1-procedure_code50;
	do i=1 to dim(b_code_20);
	if substr(b_code_20(i), 1, 2)='15' or substr(b_code_20(i), 1, 5) in ('96256','90764','90765','90766','90960','16003','16009','16012','16015','16018','37217') then do; rt=0.36;
	end;

	if substr(b_code_20(i), 1, 5)='13100' then do; dia=0.27;
	end;
	 
	end;

	icu=0.0432*5134; *all in the specified icu list;

	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then pps=private_20; else pps=0;

	acc=0;
	if substr(FINANCIAL_CLASS, 1, 1)='E' or FINANCIAL_CLASS in ('U3', 'U4') then do;
	if EPISODE_LENGTH_OF_STAY>1 then acc=0.0706*5134; *use overnight one, different for each state;
	else if EPISODE_LENGTH_OF_STAY=1 then acc=0.0512*5134; *use same day one, different for each state;
	end;
	 
end;

if DRGcost=. then DRGcost=0;
if DRGcost=0 then DRGcosta=0; 
else DRGcosta=DRGcost*paed*(1+spa)*(1+ind+a+rt+dia)+icu*HOURS_IN_ICU - ((DRGcost+icu*HOURS_IN_ICU)*pps+EPISODE_LENGTH_OF_STAY*acc);

*adjust for inflation - 2023-24 dollars from: https://www.rba.gov.au/calculator/financialYearDecimal.html;

if FFyear=2016 then DRGcosta_inf=DRGcosta*1.26;
if FFyear=2017 then DRGcosta_inf=DRGcosta*1.24;
if FFyear=2018 then DRGcosta_inf=DRGcosta*1.22;
if FFyear=2019 then DRGcosta_inf=DRGcosta*1.20;
if FFyear=2020 then DRGcosta_inf=DRGcosta*1.18;

run;



data baby_cost_public_short; set baby_cost_public;
keep aihw_mom_ppn aihw_baby_ppn drg DRGcost DRGcosta DRGcosta_inf episode_start_date episode_end_date EPISODE_LENGTH_OF_STAY BDOB neonatal private_episode private_hospital;
run;


******************************************************
private hospital;


*assign a cost to the DRG, according to the FFyear 
and adjust for inflation - 2023-24 dollars from: https://www.rba.gov.au/calculator/financialYearDecimal.html;
data baby_cost_private; set baby_cost_private;
if FFyear=2016 then PHIcost=ave_charge_16;
if FFyear=2017 then PHIcost=ave_charge_17;
if FFyear=2018 then PHIcost=ave_charge_18;
if FFyear=2019 then PHIcost=ave_charge_19;
if FFyear=2020 then PHIcost=ave_charge_20;


if FFyear=2016 then PHIcost_inf=PHIcost*1.26;
if FFyear=2017 then PHIcost_inf=PHIcost*1.24;
if FFyear=2018 then PHIcost_inf=PHIcost*1.22;
if FFyear=2019 then PHIcost_inf=PHIcost*1.20;
if FFyear=2020 then PHIcost_inf=PHIcost*1.18;
run;


data baby_cost_private_short; set baby_cost_private;
keep aihw_mom_ppn aihw_baby_ppn drg PHIcost PHIcost_inf episode_start_date episode_end_date EPISODE_LENGTH_OF_STAY BDOB neonatal private_episode private_hospital;
run; 


proc sort data=baby_cost_private_short; by aihw_baby_ppn; run;
proc sort data=baby_cost_public_short; by aihw_baby_ppn; run;

data baby_cost; set baby_cost_private_short baby_cost_public_short; run;


*save cost data;
data cost.npdc_inp_baby_cost; set baby_cost;
run;
