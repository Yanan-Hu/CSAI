/******************************************************************************************************************************
*Create date: 2 Nov 2024
*Last update date: 18 Nov 2024
*Author: Yanan Hu and Emily Callander
*Data source: IHACPA (public hospitals), PHDB (private hospitals, hospital type: private - other, national data, latest ARDRG version)
*Purpose: creat new drg cost file by treating missing data for hospitals 2015/16 - 2019/20
*****************************************************************************************************************************/

libname matern "G:\Data in sas format";
libname cost "G:\Data in sas format\costs";



*import cost file;
data drgcost; set cost.drgcost;
run;


*add mean costs for drg end with Z (Version before 6.0X);
proc sql;
create table mean_cost as
select distinct substr(drg, 1, 3)||'Z' as drg, 

mean(cost_16) as fill_cost_16,
mean(cost_17) as fill_cost_17,
mean(cost_18) as fill_cost_18,
mean(cost_19) as fill_cost_19,
mean(cost_20) as fill_cost_20,

mean(ave_charge_16) as fill_ave_charge_16,
mean(ave_charge_17) as fill_ave_charge_17,
mean(ave_charge_18) as fill_ave_charge_18,
mean(ave_charge_19) as fill_ave_charge_19,
mean(ave_charge_20) as fill_ave_charge_20,

mean(private_16) as fill_private_16,
mean(private_17) as fill_private_17,
mean(private_18) as fill_private_18,
mean(private_19) as fill_private_19,
mean(private_20) as fill_private_20,

mean(paed_16) as fill_paed_16,
mean(paed_17) as fill_paed_17,
mean(paed_18) as fill_paed_18,
mean(paed_19) as fill_paed_19,
mean(paed_20) as fill_paed_20
 
from drgcost
where substr(drg, 4, 1) ne 'Z'
group by substr(drg, 1, 3);
quit;



*look for drg in inpatient file but not in drgcost by ffyear;
data npdc_inp; set matern.npdc_inp;
rename ar_drg=drg;
if month(episode_start_date) in (7,8,9,10,11,12) then FFyear=year(episode_start_date)+1;
	else FFyear=year(episode_start_date);
run;


*find mismatch drg and assign costs by ffyear;
*2016;
data inp_16; set npdc_inp; 
if drg='' then delete;
if FFyear=2016 then output;
keep drg;run;


data drg_16; set drgcost;
if  cost_16 ne . then output;
keep drg cost_16;
run;


proc sort data=drg_16 nodupkey; by drg; run;
proc sort data=inp_16 nodupkey; by drg; run;


data missing_16; merge inp_16 (in=a) drg_16 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_cost_16; set mean_cost;
keep drg fill_cost_16;
run;


proc sort data=missing_16; by drg; run;
proc sort data=mean_cost_16; by drg; run;


data fill_16; merge missing_16 (in=a) mean_cost_16; by drg;
if a then output; run;


data fill_16; set  fill_16;
if cost_16=. then cost_16=fill_cost_16;
drop fill_cost_16;
run;


data drg_16_full; set drg_16 fill_16; run;

proc sort data=drg_16_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_16 as
select *,(select cost_16 from drg_16_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_cost_16
from drg_16_full as a;
quit;


data fill_16; set fill_16;
if  cost_16=.   then cost_16=fill_cost_16;
drop fill_cost_16;
run;



*find mismatch drg and assign costs by ffyear;
data drg_phi_16; set drgcost;
if  ave_charge_16 ne . then output;
keep drg ave_charge_16;
run;



proc sort data=drg_phi_16 nodupkey; by drg; run;
proc sort data=inp_16 nodupkey; by drg; run;


data missing_phi_16; merge inp_16 (in=a) drg_phi_16 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_ave_charge_16; set mean_cost;
keep drg fill_ave_charge_16;
run;


proc sort data=missing_phi_16; by drg; run;
proc sort data=mean_ave_charge_16; by drg; run;


data fill_phi_16; merge missing_phi_16 (in=a) mean_ave_charge_16; by drg;
if a then output; run;


data fill_phi_16; set  fill_phi_16;
if ave_charge_16=. then ave_charge_16=fill_ave_charge_16;
drop fill_ave_charge_16;
run;


data drg_phi_16_full; set drg_phi_16 fill_phi_16; run;

proc sort data=drg_phi_16_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_phi_16 as
select *,(select ave_charge_16 from drg_phi_16_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_ave_charge_16
from drg_phi_16_full as a;
quit;


data fill_phi_16; set fill_phi_16;
if  ave_charge_16=.   then ave_charge_16=fill_ave_charge_16;
drop fill_ave_charge_16;
run;



data pri_16; set drgcost;
if  private_16 ne . then output;
keep drg private_16;
run;


proc sort data=pri_16 nodupkey; by drg; run;
proc sort data=inp_16 nodupkey; by drg; run;


data missing_pri_16; merge inp_16 (in=a) pri_16 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_private_16; set mean_cost;
keep drg fill_private_16;
run;


proc sort data=missing_pri_16; by drg; run;
proc sort data=mean_private_16; by drg; run;


data fill_pri_16; merge missing_pri_16 (in=a) mean_private_16; by drg;
if a then output; run;


data fill_pri_16; set  fill_pri_16;
if private_16=. then private_16=fill_private_16;
drop fill_private_16;
run;


data pri_16_full; set pri_16 fill_pri_16; run;

proc sort data=pri_16_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_pri_16 as
select *,(select private_16 from pri_16_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_private_16
from pri_16_full as a;
quit;


data fill_pri_16; set fill_pri_16;
if  private_16=.   then private_16=fill_private_16;
drop fill_private_16;
run;




data pa_16; set drgcost;
if  paed_16 ne . then output;
keep drg paed_16;
run;


proc sort data=pa_16 nodupkey; by drg; run;
proc sort data=inp_16 nodupkey; by drg; run;


data missing_pa_16; merge inp_16 (in=a) pa_16 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_paed_16; set mean_cost;
keep drg fill_paed_16;
run;


proc sort data=missing_pa_16; by drg; run;
proc sort data=mean_paed_16; by drg; run;


data fill_pa_16; merge missing_pa_16 (in=a) mean_paed_16; by drg;
if a then output; run;


data fill_pa_16; set  fill_pa_16;
if paed_16=. then paed_16=fill_paed_16;
drop fill_paed_16;
run;


data pa_16_full; set pa_16 fill_pa_16; run;

proc sort data=pa_16_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_pa_16 as
select *,(select paed_16 from pa_16_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_paed_16
from pa_16_full as a;
quit;


data fill_pa_16; set fill_pa_16;
if  paed_16=.   then paed_16=fill_paed_16;
drop fill_paed_16;
run;


*2017;
data inp_17; set npdc_inp; 
if drg='' then delete;
if FFyear=2017 then output;
keep drg;run;


data drg_17; set drgcost;
if  cost_17 ne . then output;
keep drg cost_17;
run;


proc sort data=drg_17 nodupkey; by drg; run;
proc sort data=inp_17 nodupkey; by drg; run;


data missing_17; merge inp_17 (in=a) drg_17 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_cost_17; set mean_cost;
keep drg fill_cost_17;
run;


proc sort data=missing_17; by drg; run;
proc sort data=mean_cost_17; by drg; run;


data fill_17; merge missing_17 (in=a) mean_cost_17; by drg;
if a then output; run;


data fill_17; set  fill_17;
if cost_17=. then cost_17=fill_cost_17;
drop fill_cost_17;
run;


data drg_17_full; set drg_17 fill_17; run;

proc sort data=drg_17_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_17 as
select *,(select cost_17 from drg_17_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_cost_17
from drg_17_full as a;
quit;


data fill_17; set fill_17;
if  cost_17=.   then cost_17=fill_cost_17;
drop fill_cost_17;
run;



*find mismatch drg and assign costs by ffyear;
data drg_phi_17; set drgcost;
if  ave_charge_17 ne . then output;
keep drg ave_charge_17;
run;



proc sort data=drg_phi_17 nodupkey; by drg; run;
proc sort data=inp_17 nodupkey; by drg; run;


data missing_phi_17; merge inp_17 (in=a) drg_phi_17 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_ave_charge_17; set mean_cost;
keep drg fill_ave_charge_17;
run;


proc sort data=missing_phi_17; by drg; run;
proc sort data=mean_ave_charge_17; by drg; run;


data fill_phi_17; merge missing_phi_17 (in=a) mean_ave_charge_17; by drg;
if a then output; run;


data fill_phi_17; set  fill_phi_17;
if ave_charge_17=. then ave_charge_17=fill_ave_charge_17;
drop fill_ave_charge_17;
run;


data drg_phi_17_full; set drg_phi_17 fill_phi_17; run;

proc sort data=drg_phi_17_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_phi_17 as
select *,(select ave_charge_17 from drg_phi_17_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_ave_charge_17
from drg_phi_17_full as a;
quit;


data fill_phi_17; set fill_phi_17;
if  ave_charge_17=.   then ave_charge_17=fill_ave_charge_17;
drop fill_ave_charge_17;
run;



data pri_17; set drgcost;
if  private_17 ne . then output;
keep drg private_17;
run;


proc sort data=pri_17 nodupkey; by drg; run;
proc sort data=inp_17 nodupkey; by drg; run;


data missing_pri_17; merge inp_17 (in=a) pri_17 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_private_17; set mean_cost;
keep drg fill_private_17;
run;


proc sort data=missing_pri_17; by drg; run;
proc sort data=mean_private_17; by drg; run;


data fill_pri_17; merge missing_pri_17 (in=a) mean_private_17; by drg;
if a then output; run;


data fill_pri_17; set  fill_pri_17;
if private_17=. then private_17=fill_private_17;
drop fill_private_17;
run;


data pri_17_full; set pri_17 fill_pri_17; run;

proc sort data=pri_17_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_pri_17 as
select *,(select private_17 from pri_17_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_private_17
from pri_17_full as a;
quit;


data fill_pri_17; set fill_pri_17;
if  private_17=.   then private_17=fill_private_17;
drop fill_private_17;
run;




data pa_17; set drgcost;
if  paed_17 ne . then output;
keep drg paed_17;
run;


proc sort data=pa_17 nodupkey; by drg; run;
proc sort data=inp_17 nodupkey; by drg; run;


data missing_pa_17; merge inp_17 (in=a) pa_17 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_paed_17; set mean_cost;
keep drg fill_paed_17;
run;


proc sort data=missing_pa_17; by drg; run;
proc sort data=mean_paed_17; by drg; run;


data fill_pa_17; merge missing_pa_17 (in=a) mean_paed_17; by drg;
if a then output; run;


data fill_pa_17; set  fill_pa_17;
if paed_17=. then paed_17=fill_paed_17;
drop fill_paed_17;
run;


data pa_17_full; set pa_17 fill_pa_17; run;

proc sort data=pa_17_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_pa_17 as
select *,(select paed_17 from pa_17_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_paed_17
from pa_17_full as a;
quit;


data fill_pa_17; set fill_pa_17;
if  paed_17=.   then paed_17=fill_paed_17;
drop fill_paed_17;
run;


*2018;
data inp_18; set npdc_inp; 
if drg='' then delete;
if FFyear=2018 then output;
keep drg;run;


data drg_18; set drgcost;
if  cost_18 ne . then output;
keep drg cost_18;
run;


proc sort data=drg_18 nodupkey; by drg; run;
proc sort data=inp_18 nodupkey; by drg; run;


data missing_18; merge inp_18 (in=a) drg_18 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_cost_18; set mean_cost;
keep drg fill_cost_18;
run;


proc sort data=missing_18; by drg; run;
proc sort data=mean_cost_18; by drg; run;


data fill_18; merge missing_18 (in=a) mean_cost_18; by drg;
if a then output; run;


data fill_18; set  fill_18;
if cost_18=. then cost_18=fill_cost_18;
drop fill_cost_18;
run;


data drg_18_full; set drg_18 fill_18; run;

proc sort data=drg_18_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_18 as
select *,(select cost_18 from drg_18_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_cost_18
from drg_18_full as a;
quit;


data fill_18; set fill_18;
if  cost_18=.   then cost_18=fill_cost_18;
drop fill_cost_18;
run;



*find mismatch drg and assign costs by ffyear;
data drg_phi_18; set drgcost;
if  ave_charge_18 ne . then output;
keep drg ave_charge_18;
run;



proc sort data=drg_phi_18 nodupkey; by drg; run;
proc sort data=inp_18 nodupkey; by drg; run;


data missing_phi_18; merge inp_18 (in=a) drg_phi_18 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_ave_charge_18; set mean_cost;
keep drg fill_ave_charge_18;
run;


proc sort data=missing_phi_18; by drg; run;
proc sort data=mean_ave_charge_18; by drg; run;


data fill_phi_18; merge missing_phi_18 (in=a) mean_ave_charge_18; by drg;
if a then output; run;


data fill_phi_18; set  fill_phi_18;
if ave_charge_18=. then ave_charge_18=fill_ave_charge_18;
drop fill_ave_charge_18;
run;


data drg_phi_18_full; set drg_phi_18 fill_phi_18; run;

proc sort data=drg_phi_18_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_phi_18 as
select *,(select ave_charge_18 from drg_phi_18_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_ave_charge_18
from drg_phi_18_full as a;
quit;


data fill_phi_18; set fill_phi_18;
if  ave_charge_18=.   then ave_charge_18=fill_ave_charge_18;
drop fill_ave_charge_18;
run;



data pri_18; set drgcost;
if  private_18 ne . then output;
keep drg private_18;
run;


proc sort data=pri_18 nodupkey; by drg; run;
proc sort data=inp_18 nodupkey; by drg; run;


data missing_pri_18; merge inp_18 (in=a) pri_18 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_private_18; set mean_cost;
keep drg fill_private_18;
run;


proc sort data=missing_pri_18; by drg; run;
proc sort data=mean_private_18; by drg; run;


data fill_pri_18; merge missing_pri_18 (in=a) mean_private_18; by drg;
if a then output; run;


data fill_pri_18; set  fill_pri_18;
if private_18=. then private_18=fill_private_18;
drop fill_private_18;
run;


data pri_18_full; set pri_18 fill_pri_18; run;

proc sort data=pri_18_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_pri_18 as
select *,(select private_18 from pri_18_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_private_18
from pri_18_full as a;
quit;


data fill_pri_18; set fill_pri_18;
if  private_18=.   then private_18=fill_private_18;
drop fill_private_18;
run;




data pa_18; set drgcost;
if  paed_18 ne . then output;
keep drg paed_18;
run;


proc sort data=pa_18 nodupkey; by drg; run;
proc sort data=inp_18 nodupkey; by drg; run;


data missing_pa_18; merge inp_18 (in=a) pa_18 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_paed_18; set mean_cost;
keep drg fill_paed_18;
run;


proc sort data=missing_pa_18; by drg; run;
proc sort data=mean_paed_18; by drg; run;


data fill_pa_18; merge missing_pa_18 (in=a) mean_paed_18; by drg;
if a then output; run;


data fill_pa_18; set  fill_pa_18;
if paed_18=. then paed_18=fill_paed_18;
drop fill_paed_18;
run;


data pa_18_full; set pa_18 fill_pa_18; run;

proc sort data=pa_18_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_pa_18 as
select *,(select paed_18 from pa_18_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_paed_18
from pa_18_full as a;
quit;


data fill_pa_18; set fill_pa_18;
if  paed_18=.   then paed_18=fill_paed_18;
drop fill_paed_18;
run;


*2019;
data inp_19; set npdc_inp; 
if drg='' then delete;
if FFyear=2019 then output;
keep drg;run;


data drg_19; set drgcost;
if  cost_19 ne . then output;
keep drg cost_19;
run;


proc sort data=drg_19 nodupkey; by drg; run;
proc sort data=inp_19 nodupkey; by drg; run;


data missing_19; merge inp_19 (in=a) drg_19 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_cost_19; set mean_cost;
keep drg fill_cost_19;
run;


proc sort data=missing_19; by drg; run;
proc sort data=mean_cost_19; by drg; run;


data fill_19; merge missing_19 (in=a) mean_cost_19; by drg;
if a then output; run;


data fill_19; set  fill_19;
if cost_19=. then cost_19=fill_cost_19;
drop fill_cost_19;
run;


data drg_19_full; set drg_19 fill_19; run;

proc sort data=drg_19_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_19 as
select *,(select cost_19 from drg_19_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_cost_19
from drg_19_full as a;
quit;


data fill_19; set fill_19;
if  cost_19=.   then cost_19=fill_cost_19;
drop fill_cost_19;
run;



*find mismatch drg and assign costs by ffyear;
data drg_phi_19; set drgcost;
if  ave_charge_19 ne . then output;
keep drg ave_charge_19;
run;



proc sort data=drg_phi_19 nodupkey; by drg; run;
proc sort data=inp_19 nodupkey; by drg; run;


data missing_phi_19; merge inp_19 (in=a) drg_phi_19 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_ave_charge_19; set mean_cost;
keep drg fill_ave_charge_19;
run;


proc sort data=missing_phi_19; by drg; run;
proc sort data=mean_ave_charge_19; by drg; run;


data fill_phi_19; merge missing_phi_19 (in=a) mean_ave_charge_19; by drg;
if a then output; run;


data fill_phi_19; set  fill_phi_19;
if ave_charge_19=. then ave_charge_19=fill_ave_charge_19;
drop fill_ave_charge_19;
run;


data drg_phi_19_full; set drg_phi_19 fill_phi_19; run;

proc sort data=drg_phi_19_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_phi_19 as
select *,(select ave_charge_19 from drg_phi_19_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_ave_charge_19
from drg_phi_19_full as a;
quit;


data fill_phi_19; set fill_phi_19;
if  ave_charge_19=.   then ave_charge_19=fill_ave_charge_19;
drop fill_ave_charge_19;
run;



data pri_19; set drgcost;
if  private_19 ne . then output;
keep drg private_19;
run;


proc sort data=pri_19 nodupkey; by drg; run;
proc sort data=inp_19 nodupkey; by drg; run;


data missing_pri_19; merge inp_19 (in=a) pri_19 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_private_19; set mean_cost;
keep drg fill_private_19;
run;


proc sort data=missing_pri_19; by drg; run;
proc sort data=mean_private_19; by drg; run;


data fill_pri_19; merge missing_pri_19 (in=a) mean_private_19; by drg;
if a then output; run;


data fill_pri_19; set  fill_pri_19;
if private_19=. then private_19=fill_private_19;
drop fill_private_19;
run;


data pri_19_full; set pri_19 fill_pri_19; run;

proc sort data=pri_19_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_pri_19 as
select *,(select private_19 from pri_19_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_private_19
from pri_19_full as a;
quit;


data fill_pri_19; set fill_pri_19;
if  private_19=.   then private_19=fill_private_19;
drop fill_private_19;
run;




data pa_19; set drgcost;
if  paed_19 ne . then output;
keep drg paed_19;
run;


proc sort data=pa_19 nodupkey; by drg; run;
proc sort data=inp_19 nodupkey; by drg; run;


data missing_pa_19; merge inp_19 (in=a) pa_19 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_paed_19; set mean_cost;
keep drg fill_paed_19;
run;


proc sort data=missing_pa_19; by drg; run;
proc sort data=mean_paed_19; by drg; run;


data fill_pa_19; merge missing_pa_19 (in=a) mean_paed_19; by drg;
if a then output; run;


data fill_pa_19; set  fill_pa_19;
if paed_19=. then paed_19=fill_paed_19;
drop fill_paed_19;
run;


data pa_19_full; set pa_19 fill_pa_19; run;

proc sort data=pa_19_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_pa_19 as
select *,(select paed_19 from pa_19_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_paed_19
from pa_19_full as a;
quit;


data fill_pa_19; set fill_pa_19;
if  paed_19=.   then paed_19=fill_paed_19;
drop fill_paed_19;
run;


*2020;
data inp_20; set npdc_inp; 
if drg='' then delete;
if FFyear=2020 then output;
keep drg;run;


data drg_20; set drgcost;
if  cost_20 ne . then output;
keep drg cost_20;
run;


proc sort data=drg_20 nodupkey; by drg; run;
proc sort data=inp_20 nodupkey; by drg; run;


data missing_20; merge inp_20 (in=a) drg_20 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_cost_20; set mean_cost;
keep drg fill_cost_20;
run;


proc sort data=missing_20; by drg; run;
proc sort data=mean_cost_20; by drg; run;


data fill_20; merge missing_20 (in=a) mean_cost_20; by drg;
if a then output; run;


data fill_20; set  fill_20;
if cost_20=. then cost_20=fill_cost_20;
drop fill_cost_20;
run;


data drg_20_full; set drg_20 fill_20; run;

proc sort data=drg_20_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_20 as
select *,(select cost_20 from drg_20_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_cost_20
from drg_20_full as a;
quit;


data fill_20; set fill_20;
if  cost_20=.   then cost_20=fill_cost_20;
drop fill_cost_20;
run;



*find mismatch drg and assign costs by ffyear;
data drg_phi_20; set drgcost;
if  ave_charge_20 ne . then output;
keep drg ave_charge_20;
run;



proc sort data=drg_phi_20 nodupkey; by drg; run;
proc sort data=inp_20 nodupkey; by drg; run;


data missing_phi_20; merge inp_20 (in=a) drg_phi_20 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_ave_charge_20; set mean_cost;
keep drg fill_ave_charge_20;
run;


proc sort data=missing_phi_20; by drg; run;
proc sort data=mean_ave_charge_20; by drg; run;


data fill_phi_20; merge missing_phi_20 (in=a) mean_ave_charge_20; by drg;
if a then output; run;


data fill_phi_20; set  fill_phi_20;
if ave_charge_20=. then ave_charge_20=fill_ave_charge_20;
drop fill_ave_charge_20;
run;


data drg_phi_20_full; set drg_phi_20 fill_phi_20; run;

proc sort data=drg_phi_20_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_phi_20 as
select *,(select ave_charge_20 from drg_phi_20_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_ave_charge_20
from drg_phi_20_full as a;
quit;


data fill_phi_20; set fill_phi_20;
if  ave_charge_20=.   then ave_charge_20=fill_ave_charge_20;
drop fill_ave_charge_20;
run;



data pri_20; set drgcost;
if  private_20 ne . then output;
keep drg private_20;
run;


proc sort data=pri_20 nodupkey; by drg; run;
proc sort data=inp_20 nodupkey; by drg; run;


data missing_pri_20; merge inp_20 (in=a) pri_20 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_private_20; set mean_cost;
keep drg fill_private_20;
run;


proc sort data=missing_pri_20; by drg; run;
proc sort data=mean_private_20; by drg; run;


data fill_pri_20; merge missing_pri_20 (in=a) mean_private_20; by drg;
if a then output; run;


data fill_pri_20; set  fill_pri_20;
if private_20=. then private_20=fill_private_20;
drop fill_private_20;
run;


data pri_20_full; set pri_20 fill_pri_20; run;

proc sort data=pri_20_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_pri_20 as
select *,(select private_20 from pri_20_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_private_20
from pri_20_full as a;
quit;


data fill_pri_20; set fill_pri_20;
if  private_20=.   then private_20=fill_private_20;
drop fill_private_20;
run;




data pa_20; set drgcost;
if  paed_20 ne . then output;
keep drg paed_20;
run;


proc sort data=pa_20 nodupkey; by drg; run;
proc sort data=inp_20 nodupkey; by drg; run;


data missing_pa_20; merge inp_20 (in=a) pa_20 (in=b);by drg;
if a and not b then output; run;


*assign mean cost to missing Z;
data mean_paed_20; set mean_cost;
keep drg fill_paed_20;
run;


proc sort data=missing_pa_20; by drg; run;
proc sort data=mean_paed_20; by drg; run;


data fill_pa_20; merge missing_pa_20 (in=a) mean_paed_20; by drg;
if a then output; run;


data fill_pa_20; set  fill_pa_20;
if paed_20=. then paed_20=fill_paed_20;
drop fill_paed_20;
run;


data pa_20_full; set pa_20 fill_pa_20; run;

proc sort data=pa_20_full; by drg; run;


*assign Z cost to A or B or C;
proc sql;
create table fill_pa_20 as
select *,(select paed_20 from pa_20_full as b 
where substr(a.drg, 1, 3)=substr(b.drg, 1, 3)
and substr(b.drg, 4, 1)= 'Z') as fill_paed_20
from pa_20_full as a;
quit;


data fill_pa_20; set fill_pa_20;
if  paed_20=.   then paed_20=fill_paed_20;
drop fill_paed_20;
run;



* merge all;
data drgcost_new; merge 
fill_16 fill_phi_16 fill_pri_16 fill_pa_16
fill_17 fill_phi_17 fill_pri_17 fill_pa_17
fill_18 fill_phi_18 fill_pri_18 fill_pa_18
fill_19 fill_phi_19 fill_pri_19 fill_pa_19
fill_20 fill_phi_20 fill_pri_20 fill_pa_20;
by drg; 
run; 


data cost.drgcost_new; set drgcost_new;run;



