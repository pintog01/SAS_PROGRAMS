libname syndrom 'G:\Infect Prevention\IS01_groups\My Documents\IPC Surveillance Data\Respiratory Syndromic Surveillance';**testing;
libname shad odbc DSN= 'EPSi_Shadow' schema = dbo; * SQL server;  /*EPSi shadow database, windows authentication*/
libname pdadev oracle user='pda_read' password=pdaread path='findwdev' schema=SCPM;  **Patient Day Array Development;
libname pda oracle user='pda_user' password=pdauser path='findwprd' schema=SCPM;  **Patient Day Array Production NEW;
libname epsi 'G:\Infect Prevention\SSI_dbase\SASProgramsAndDataSets\EPSI Data';
libname surgery 'G:\Infect Prevention\SSI_dbase\SurgeryLog';
libname micro 'G:\Infect Prevention\IS01_groups\My Documents\Micro.downloads.shared_drive\FINALDATASETS';
libname ags "G:\Infect Prevention\SSI_dbase\SASProgramsAndDataSets";
libname Iso   "G:\Infect Prevention\Isolation_dbase";
libname cvc 'G:\Infect Prevention\IS01_groups\My Documents\IPC Surveillance Data\CLABS-CAUTI-VAPS DOWNLOADS\CLABSI 2013 Download Files';
libname Foley 'G:\Infect Prevention\IS01_groups\My Documents\IPC Surveillance Data\CLABS-CAUTI-VAPS DOWNLOADS\CAUTI 2013 Download Files';
libname vent 'G:\Infect Prevention\IS01_groups\My Documents\IPC Surveillance Data\CLABS-CAUTI-VAPS DOWNLOADS\VAP 2013 Download Files';
libname vent1 'G:\Infect Prevention\IS01_groups\My Documents\Device_downloads\Vent2014';
libname daily "G:\Infect Prevention\IS01_groups\My Documents\IPC Surveillance Data\Daily Reviews";
libname whonet "G:\Infect Prevention\WHONet\Ouput";   
libname edw oracle user='scorecard_read' password=sread path='findwprd' schema=SCPM;  **EDW;
libname tsia oracle user='tsi_read' password=tsi123 path='tsiarch' schema=TSIADM;  /*TSI archive*/
LIBNAME SSI ACCESS PATH='G:\Infect Prevention\Data Management\Databases\SSI_Review_DB.accdb.mdb'; 
Libname CAUTI ACCESS PATH='G:\Infect Prevention\Data Management\Databases\CAUTI_Reviews.accdb.mdb'; 
Libname CLABSI ACCESS PATH='G:\Infect Prevention\Data Management\Databases\CLABSI_Reviews.accdb'; 
libname OtptSurv 'G:\Infect Prevention\SSI_dbase\SASProgramsAndDataSets\Data Requests\Outpatient_Surveillance';
libname dash 'G:\Infect Prevention\IS01_groups\My Documents\IPC Surveillance Data\DASHBOARD\DASHBOARD INTERNAL REPORT for IPC';
libname dllfinal 'G:\Infect Prevention\IS01_groups\My Documents\IPC Surveillance Data\Daily Reviews\Cases_ForPractitioners\Finalized CAUTI-CLABS 2013 to present\Sent to External';
libname pdaexpor oracle user='pda_read' password=pdaread path='findwprd' schema='edwstg'; /*PROD NHSN EXPORT*/
Libname Dazo ACCESS PATH="G:\Infect Prevention\Data Management\Databases\dazo_db.accdb";
Libname aca1 'G:\Infect Prevention\Data Management\Databases\Database_Codes\Datasets'; 
options mcompilenote=all symbolgen mprint ; *mstored sasmstore = dbdrafts;
Libname denom 'G:\Infect Prevention\Data Management\Denominators'; 

********INPUT TIME PERIOD OF INTEREST BEFORE RUNNING CODE*********;
%let currentepsi = nov_2015;
%let currqtrstart = '01apr2015'd;
%let currqtrend =  '30jun2015'd;
%let prevqtrstart = '01jan2015'd;
%let currentquarter = '2015-02';
%let excel = Q22015_IPC_Infections_RunDate%sysfunc(date(),MMDDYYD.).xls;

PROC FORMAT;
      VALUE compliancepct 0-.84= Red other = black;
      VALUE obsnumber 0-25 = Orange other = black;
    
RUN;
*** PROC TEMPLATE TO SPECIFY COLORS AND FONT AND SIZES;
ods path(prepend) work.template(update);
proc template;
 define style mystyle;
 notes "My Simple Style";
 class body /
 backgroundcolor = white
 color = black
 fontfamily = "Arial"
 ;
 class systemtitle /
 fontfamily = "Arial"
 fontsize = 10pt
 fontweight = bold
 ;
 class table /
 backgroundcolor = #f0f0f0
 bordercolor = black
 borderstyle = solid
 borderwidth = 1pt
 cellpadding = 2pt
 cellspacing = 1pt
 frame = void
 rules = groups
 ;
 class header, footer /
 backgroundcolor = CXFFFFFF
 fontfamily = "Arial"
 fontweight = bold
 ;
 class data /
 fontfamily = "Arial"
 ;
 end;
run;

ods listing;
ods tagsets.ExcelXP style=mystyle
startpage=no file="G:\Infect Prevention\Data Management\IPC_Quarterly_Reports\&excel" ;



********device days (FOLEY AND CVC)*******************;


data cvcdays;
length unit $30.;
set denom.denom_CVC;
where date >= &currqtrstart and date <= &currqtrend;
mon_yr=date;
format mon_yr yymmd7.;
if Unit in ("TH 6 MAIN PACU", "TH 6 MAIN PERI","TH CARDIAC ELE","TH CH EMERG DE","TH EMERGENCY D", "TH 10 DAYSG PA")then
Unit="TH Unclassified";
if Unit in ("HJD C1 ASC PER","HJD C2 MAIN OR","HJD C2 MAIN PE")then
Unit="HJD Unclassified";
length mon_yr1 $15.;
mon_yr1=put(mon_yr, yymmd7.);
run;

/*Counting days by unit and the time period total*/
proc freq data = cvcdays; 
tables unit*mon_yr1/out=cvcdays1 noprint;
run;


proc freq data=cvcdays;
tables Unit*year /nocol norow nopercent noprint out=cvcdaystotyear;
run;

/*Changing variable name for appending*/
data cvcdaystotyear1;
set cvcdaystotyear;
mon_yr1=Compress("Total"||"-"||Year);
run;
proc append data=cvcdaystotyear1 base = cvcdays1 force;run;

/*Infection data from NHSN*/
data infections;
length unit $30.;
set edw.nhsn_event;
where event_type = 'BSI' and del_ind = 'N';
if location =	"8 E"	then Unit=	"TH 8 EAST"	;
if location =	"9 E"	then Unit=	"TH 9 EAST"	;
if location =	"15 E - CCC"	then Unit=	"TH 15 ECCC"	;
if location =	"14 E"	then Unit=	"TH 14 EAST"	;
if location =	"17 E"	then Unit=	"TH 17 EAST"	;
if location =	"15 W - CCC"	then Unit=	"TH 15 WCCC"	;
if location =	"16 E"	then Unit=	"TH 16 EAST"	;
if location =	"HCC 11"	then Unit=	"TH HCC 11"	;
if location =	"TPU"	then Unit=	"TH 14 TPU"	;
if location =	"13E"	then Unit=	"TH 13 EAST"	;
if location =	"17 W"	then Unit=	"TH 17 WEST"	;
if location =	"8 W"	then Unit=	"TH 8 WEST"	;
if location =	"CARD REHAB"	then Unit=	"TH HCC 9"	;
if location =	"14W"	then Unit=	"TH 14 WEST"	;
if location =	"PICU"	then Unit=	"TH 9 PICU"	;
if location =	"15 CCVCU"	then Unit=	"TH 15 CCVCU"	;
if location =	"12 WEST"	then Unit=	"TH 12 WEST"	;
if location =	"11E"	then Unit=	"TH 11 EAST"	;
if location =	"16 EAST"	then Unit=	"TH 16 BMT"	;
if location =	"12 E"	then Unit=	"TH 12 EAST"	;
if location =	"NSICU"	then Unit=	"TH 12 NSICU"	;
if location =	"HCC 13"	then Unit=	"TH HCC 13"	;
if location =	"16 W"	then Unit=	"TH 16 WEST"	;
if location =	"HCC 12"	then Unit=	"TH HCC 12"	;
if location =	"NICU"	then Unit=	"TH 9 NICU"	;
if location =	"HCC 10"	then Unit=	"TH HCC 10"	;
if location =	"17 W SDU"	then Unit=	"TH 17 WEST-SDU"	;
if location =	"17 E SDU"	then Unit=	"TH 17 EAST-SDU"	;
if location =	"11 SDU"	then Unit=	"HJD 11 SDU"	;
if location =	"12TH FLOOR"	then Unit=	"HJD 12 FLOOR"	;
if location =	"9 S"	then Unit=	"HJD 9 SOUTH"	;
if location =	"11 S"	then Unit=	"HJD 11 FLOOR"	;
if location =	"9 N"	then Unit=	"HJD 9 NORTH"	;
if location =	"8 S"	then Unit=	"HJD 8 SOUTH"	;
if location =	"8 N"	then Unit=	"HJD 8 NORTH"	;
if location =	"11 SCU"	then Unit=	"HJD 11 SCU"	;
if location =	"CV PACU"	then Unit=	"TH 6 CVSCU"	;
mon_yr = datepart(event_date);
format mon_yr yymmd7.;
year=year(mon_yr);
run;

data infectionsA;
set infections;
where (mon_yr >= &currqtrstart and mon_yr <= &currqtrend);
run;

proc freq data = infectionsA; 
tables unit*mon_yr/out=infections1 noprint;
run;

data infections2;
length mon_yr1 $15.;
set infections1;
mon_yr1=put(mon_yr, yymmd7.);
infection=count;
drop count;
run;
proc freq data=infectionsa;
tables Unit*year /nocol norow nopercent noprint out=infectionstotyear;
run;
data infectionstotyear1;
set infectionstotyear;
mon_yr1=compress("Total"||"-"||Year);
infection=count;
drop count;
run;


proc append data=infectionstotyear1 base = infections2 force;run;

/*Merge infections with CVC denominator by unit and mon yr*/
proc sql;
create table infection_clabsi as select *
from cvcdays1 as a
left join infections2 as b
on a.unit=b.unit and a.mon_yr1=b.Mon_yr1;
quit;
/*proc freq data=infection_clabsi;table mon_yr;where eventid ne ' '  ;run;*/

/*Calculate rates*/
data infection_clabsi1;
set infection_clabsi;
if infection=. then infection=0;
if count=. then count=0;
rate = (infection/count)*1000;
if Rate = . then rate=0.0;
format rate 4.1;
Facility=scan(unit,1);
if index(unit,"SDU")ne 0 then Facility=scan(unit,1)||"-"||"SDU";
if unit in ("TH 15 WCCC", "TH 15 ECCC", "TH 15 CCVCU", "TH 9 NICU", "TH 9 PICU", "TH 12 NSICU",
"TH 14 TPU", "TH 6 CVSCU") then Facility= "TH-ICU"; 
run;

/*Exporting*/
ods listing;
ods tagsets.ExcelXP 
 options(sheet_name='1.CLABSI Rates') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');

proc report data=infection_clabsi1 nowd box; 
 column Unit facility Mon_yr1,(infection count rate) shaderow;
 define Unit /"Unit" id group order=internal width=15; 
 define Facility /"Facility" id group order=internal width=7; 
 define Mon_yr1 /across order=formatted 'Month-Year';
 define Count / "Days" width=3 display;
 define Infection / "Cases" width=3 display;
 define Rate / 'Rate' display ;
 define shaderow / noprint;
 title1 'CLABSI' ;
run ;

***********CLABSI LINELIST***************;

/*Infections from NHSN for line list*/
data clabsilist;
length unit $30.;
set edw.nhsn_event;
where event_type = 'BSI' and del_ind = 'N';
if location =	"8 E"	then Unit=	"TH 8 EAST"	;
if location =	"9 E"	then Unit=	"TH 9 EAST"	;
if location =	"15 E - CCC"	then Unit=	"TH 15 ECCC"	;
if location =	"14 E"	then Unit=	"TH 14 EAST"	;
if location =	"17 E"	then Unit=	"TH 17 EAST"	;
if location =	"15 W - CCC"	then Unit=	"TH 15 WCCC"	;
if location =	"16 E"	then Unit=	"TH 16 EAST"	;
if location =	"HCC 11"	then Unit=	"TH HCC 11"	;
if location =	"TPU"	then Unit=	"TH 14 TPU"	;
if location =	"13E"	then Unit=	"TH 13 EAST"	;
if location =	"17 W"	then Unit=	"TH 17 WEST"	;
if location =	"8 W"	then Unit=	"TH 8 WEST"	;
if location =	"CARD REHAB"	then Unit=	"TH HCC 9"	;
if location =	"14W"	then Unit=	"TH 14 WEST"	;
if location =	"PICU"	then Unit=	"TH 9 PICU"	;
if location =	"15 CCVCU"	then Unit=	"TH 15 CCVCU"	;
if location =	"12 WEST"	then Unit=	"TH 12 WEST"	;
if location =	"11E"	then Unit=	"TH 11 EAST"	;
if location =	"16 EAST"	then Unit=	"TH 16 BMT"	;
if location =	"12 E"	then Unit=	"TH 12 EAST"	;
if location =	"NSICU"	then Unit=	"TH 12 NSICU"	;
if location =	"HCC 13"	then Unit=	"TH HCC 13"	;
if location =	"16 W"	then Unit=	"TH 16 WEST"	;
if location =	"HCC 12"	then Unit=	"TH HCC 12"	;
if location =	"NICU"	then Unit=	"TH 9 NICU"	;
if location =	"HCC 10"	then Unit=	"TH HCC 10"	;
if location =	"17 W SDU"	then Unit=	"TH 17 WEST-SDU"	;
if location =	"17 E SDU"	then Unit=	"TH 17 EAST-SDU"	;
if location =	"11 SDU"	then Unit=	"HJD 11 SDU"	;
if location =	"12TH FLOOR"	then Unit=	"HJD 12 FLOOR"	;
if location =	"9 S"	then Unit=	"HJD 9 SOUTH"	;
if location =	"11 S"	then Unit=	"HJD 11 FLOOR"	;
if location =	"9 N"	then Unit=	"HJD 9 NORTH"	;
if location =	"8 S"	then Unit=	"HJD 8 SOUTH"	;
if location =	"8 N"	then Unit=	"HJD 8 NORTH"	;
if location =	"11 SCU"	then Unit=	"HJD 11 SCU"	;
if location =	"CV PACU"	then Unit=	"TH 6 CVSCU"	;
/*mon_yr=input(eventdate,date9.);*/
/*format mon_yr yymmd7.;*/
event_date=datepart(event_date);
format event_date date9.;
if event_date >=&currqtrstart and event_date <= &currqtrend;
eventid = input(event_id, $15.);
patid=mrn;
run;

**** pulling all the cases from the CLABSI_Review DB;

proc sort data=Clabsi.cvc_Lines  out=clabsilines; by visitidcodead infectionstatusline ip_lda_id;run;
proc sort data=Clabsi.clabsi_micro  out=clabsimicro; by visitidcodead infectionstatusmicro performeddtm orgname;run;
proc sql;
create table infectionsaca as select *
from clabsiLines as a
full join clabsimicro as b
on a.VisitIDCodeAd=b.VisitIDCodeAd and a.infectionstatusline=b.infectionstatusmicro;
quit;
proc sort data=infectionsaca ;by descending anon_key event_date ;run;

****** cases by specified quarter;
data inf_confirm;
set infectionsaca;
where infectionstatusmicro in ("Infect_1", "Infect_2") and ((datepart(performeddtm)>= &currqtrstart 
and datepart(performeddtm)<=&currqtrend) or (datepart(event_date)>= &currqtrstart 
and datepart(performeddtm)<=&currqtrend));
run;
proc sort data=inf_confirm nodupkey; by patient_mrn admission_date infectionstatusmicro performeddtm event_date orgname accnumber;run;
proc sort data = inf_confirm; by accnumber;run;
proc transpose data = inf_confirm out = inf_confirm1 prefix=neworg; by accnumber; var org;run;
proc sql;
create table inf_confirm2 as select *
from inf_confirm as a
left join inf_confirm1 as b
on a.accnumber=b.accnumber;
quit;

proc sort data = inf_confirm2 nodupkey; by accnumber;run;

**********Merging with NHSN export dataset by eventid to get all demographic information and line information;

proc sql;
create table linelist as
select *
from inf_confirm2 as a
full join clabsilist as b
on a.event_id=b.eventid;
quit;

***Create alert if there are cases in CLABSI database but are not in NHSN***;
**Send email that explains the issues***;

proc sort data=linelist nodupkey;by event_id mrn event_date;run;

***** keeping only needed variables;

Proc format;
value orgf 1	=	'Acinetobacter spp.'
	2	=	'Actinomyces spp.'
	3	=	'Aeromonas spp.'
	4	=	'Aspergillus fumigatus'
	5	=	'Aspergillus niger'
	6	=	'Aspergillus spp.'
	7	=	'Aspergillus terreus'
	8	=	'B. anthracis'
	9	=	'Bacteroides spp.'
	10	=	'Blastomyces '
	11	=	'Burkholderia spp.'
	12	=	'C. albicans'
	13	=	'C. glabrata'
	14	=	'C. krusei'
	15	=	'C. lusitaniae'
	16	=	'C. parapsilosis'
	17	=	'Campylobacter spp.'
	18	=	'Citrobacter spp.'
	19	=	'Clostridium spp.'
	20	=	'Coagulase negative staph spp.'
	21	=	'Coccidioides spp.'
	22	=	'Corynebacterium spp.'
	23	=	'Cryptococcus spp.'
	24	=	'E. cassiflavus'
	25	=	'E. coli'
	26	=	'E. faecalis'
	27	=	'E. faecium'
	28	=	'E. gallinarum'
	29	=	'Enterobacter spp.'
	30	=	'Erysipelothrix spp.'
	31	=	'Fusobacterium spp.'
	32	=	'Group B strep'
	33	=	'HACEK'
	34	=	'Haemophilus spp.'
	35	=	'Histoplasma spp.'
	36	=	'Klebsiella oxytoca'
	37	=	'Klebsiella pneumoniae'
	38	=	'Klebsiella spp.'
	39	=	'Lactobacillus spp.'
	40	=	'Legionella pneumophila'
	41	=	'Leuconostoc spp.'
	42	=	'Listeria spp.'
	43	=	'M. tubercolosis'
	44	=	'MAI'
	45	=	'Malassezia spp.'
	46	=	'Morganella spp.'
	47	=	'Mucor spp.'
	48	=	'Neisseria spp.'
	49	=	'Nocardia spp.'
	50	=	'Other Bacillus spp.'
	51	=	'Other bacteria'
	52	=	'Other Candida spp.'
	53	=	'Other Enterococcus spp.'
	54	=	'Other GNR'
	55	=	'Other GPC'
	56	=	'Other Klebsiella spp.'
	57	=	'Other mold'
	58	=	'Other mycobacterium'
	59	=	'Other Pseudomonas spp.'
	60	=	'Other strep spp.'
	61	=	'Other yeast'
	62	=	'P. aeruginosa'
	63	=	'P. boydii'
	64	=	'Prevotella spp.'
	65	=	'Prevotella spp.'
	66	=	'Proteus spp.'
	67	=	'Providencia spp.'
	68	=	'RGM'
	69	=	'Rhizopus spp.'
	70	=	'S. aureus'
	71	=	'Salmonella spp.'
	72	=	'Scedosporium spp.'
	73	=	'Serratia spp.'
	74	=	'Shigella spp.'
	75	=	'spirochete'
	76	=	'Sporothrix spp.'
	77	=	'Stenotrophomonas maltophilia'
	78	=	'Strep bovis group'
	79	=	'Strep pneumo'
	80	=	'Strep spp.'
	81	=	'Trichophyton spp.'
	82	=	'Vibrio spp.'
	83	=	'Viridans Strep spp.'
	84	=	'Yersinia spp.'
	85	=	'Other GPR'
	86	=	'Enterococcus spp.'
	87	=	'Other GNC'
	88	=	'Adenovirus'	
	89	=	'Coronavirus HKU1'	
	90	=	'Coronavirus NL63'	
	91	=	'Human Metapneumovirus'	
	92	=	'Rhinovirus/Enterovirus'	
	93	=	'Influenza A H3'	
	94	=	'Influenza A H1'	
	95	=	'Influenza A H1 2009'	
	96	=	'Influenza B'	
	97	=	'Parainfluenza Virus 1'	
	98	=	'Parainfluenza Virus 2'	
	99	=	'Parainfluenza Virus 3'	
	100	=	'Parainfluenza Virus 4'	
	101	=	'Respiratory Syncitial Virus'	
	102	=	'Influenza A'	
	103	=	'Influenza B'	
	104	=	'Chlamydia'	
	105	=	'Neisseria Gonorrhoeae'	;
run;
data finallineslist (rename=(ACCOUNT_NUMBER=CSN icisOrderID=CultureID Performeddtm=Culture_Date));
retain FULLNAME MRN sex DOB ADMISSION_DATE DISCHARGE_DATE HAR ACCOUNT_NUMBER icisOrderID OrgName1 
Orgname2 Orgname3 PerformDate Event_Date Insertion_date
Removal_date Event_location Facility DEVICE_DESCRIPTION device_comments;
label 
FULLNAME = "Patient Name"
sex= "Sex"
ADMISSION_DATE = "Admission Date"
DISCHARGE_DATE = "Discharge Date"
;
set linelist;
OrgName1 = neworg1;
Orgname2 = neworg2;
Orgname3 = neworg3;
format OrgName1 Orgname2 Orgname3 orgf.;
keep ADMISSION_DATE
DOB
DISCHARGE_DATE
Event_Date
FULLNAME
MBI
MBI_Category
icisOrderID
HAR
PerformedDtm
Removal_date
Event_location
SEX
OrgName1 
Orgname2 
Orgname3 
MRN
Insertion_date
DEVICE_DESCRIPTION
Facility ACCOUNT_NUMBER 
device_comments;
Facility=scan(unit,1);
if index(Event_location,"SDU")ne 0 then Facility=scan(Event_location,1)||"-"||"SDU";
if Event_location in ("TH 15 WCCC", "TH 15 ECCC", "TH 15 CCVCU", "TH 9 NICU", "TH 9 PICU", "TH 12 NSICU",
"TH 14 TPU", "TH 6 CVSCU") then Facility= "TH-ICU"; 
run;

ods listing;
ods tagsets.ExcelXP 
 options(sheet_name='2.CLABSI Line List') ;
    ods tagsets.ExcelXP options(sheet_interval = 'none');

Proc print data=finallineslist noobs label width=MIN; var _ALL_; run;




****************CAUTI rates;
****getting denominator days from denom libname for specified time period;

data cautidays;
length unit $30.;
set denom.denom_foley;
where date >= &currqtrstart and date <= &currqtrend;
mon_yr=date;
format mon_yr yymmd7.;
if Unit in ("TH 6 MAIN PACU", "TH 6 MAIN PERI","TH CARDIAC ELE","TH CH EMERG DE","TH EMERGENCY D", "TH 10 DAYSG PA")then
Unit="TH Unclassified";
if Unit in ("HJD C1 ASC PER","HJD C2 MAIN OR","HJD C2 MAIN PE")then
Unit="HJD Unclassified";
run;


**** counting days by unit and month ***;

proc freq data = cautidays; 
tables unit*mon_yr/out=cautidays1 noprint;
run;

*****changing variable name and type for appending later;

data cautidays2;
length mon_yr1 $15.;
set cautidays1;
mon_yr1=put(mon_yr, yymmd7.);
run;

*****counting days by unit and year (summing out the quarter);
proc freq data=cautidays;
tables Unit*year /nocol norow nopercent noprint out=cautidaystotyear;
run;

*****changing variable name and type for appending later;
data cautidaystotyear1;
set cautidaystotyear;
mon_yr1=compress("Total"||"-"||Year);
run;

******* appending monthly days with quater/year total;
proc append data=cautidaystotyear1 base = cautidays2 force;run;

***** getting cases from NHSN;

data infectionscauti;
length unit $30.;
set edw.nhsn_event;
where event_type = 'UTI' and del_ind = 'N';
if location =	"8 E"	then Unit=	"TH 8 EAST"	;
if location =	"9 E"	then Unit=	"TH 9 EAST"	;
if location =	"15 E - CCC"	then Unit=	"TH 15 ECCC"	;
if location =	"14 E"	then Unit=	"TH 14 EAST"	;
if location =	"17 E"	then Unit=	"TH 17 EAST"	;
if location =	"15 W - CCC"	then Unit=	"TH 15 WCCC"	;
if location =	"16 E"	then Unit=	"TH 16 EAST"	;
if location =	"HCC 11"	then Unit=	"TH HCC 11"	;
if location =	"TPU"	then Unit=	"TH 14 TPU"	;
if location =	"13E"	then Unit=	"TH 13 EAST"	;
if location =	"17 W"	then Unit=	"TH 17 WEST"	;
if location =	"8 W"	then Unit=	"TH 8 WEST"	;
if location =	"CARD REHAB"	then Unit=	"TH HCC 9"	;
if location =	"14W"	then Unit=	"TH 14 WEST"	;
if location =	"PICU"	then Unit=	"TH 9 PICU"	;
if location =	"15 CCVCU"	then Unit=	"TH 15 CCVCU"	;
if location =	"12 WEST"	then Unit=	"TH 12 WEST"	;
if location =	"11E"	then Unit=	"TH 11 EAST"	;
if location =	"16 EAST"	then Unit=	"TH 16 BMT"	;
if location =	"12 E"	then Unit=	"TH 12 EAST"	;
if location =	"NSICU"	then Unit=	"TH 12 NSICU"	;
if location =	"HCC 13"	then Unit=	"TH HCC 13"	;
if location =	"16 W"	then Unit=	"TH 16 WEST"	;
if location =	"HCC 12"	then Unit=	"TH HCC 12"	;
if location =	"NICU"	then Unit=	"TH 9 NICU"	;
if location =	"HCC 10"	then Unit=	"TH HCC 10"	;
if location =	"17 W SDU"	then Unit=	"TH 17 WEST-SDU"	;
if location =	"11 SDU"	then Unit=	"HJD 11 SDU"	;
if location =	"12TH FLOOR"	then Unit=	"HJD 12 FLOOR"	;
if location =	"9 S"	then Unit=	"HJD 9 SOUTH"	;
if location =	"11 S"	then Unit=	"HJD 11 FLOOR"	;
if location =	"10TH FLOOR"	then Unit=	"HJD 10 FLOOR"	;
if location =	"9 N"	then Unit=	"HJD 9 NORTH"	;
if location =	"8 S"	then Unit=	"HJD 8 SOUTH"	;
if location =	"8 N"	then Unit=	"HJD 8 NORTH"	;
if location =	"11 SCU"	then Unit=	"HJD 11 SCU"	;
if location =	"CV PACU"	then Unit=	"TH 6 CVSCU"	;
mon_yr=datepart(event_date);
format mon_yr yymmd7.;
year=year(mon_yr);
run;
data infectionscautiA;
set infectionscauti;
where mon_yr >= &currqtrstart and mon_yr <= &currqtrend;
run;

******counting infections by unit and month;

proc freq data = infectionscautiA;
tables unit*mon_yr/out=infectionscauti1 noprint;
run;
****changing variables name/type for appending later;
data infectionscauti2;
length mon_yr1 $15.;
set infectionscauti1;
mon_yr1=put(mon_yr, yymmd7.);
infection=count;
run;
***** counting infection total for the quarter;
proc freq data=infectionscautiA;
tables Unit*year /nocol norow nopercent noprint out=infectionscautitotyear;
run;
****changing variables name/type for appending later;
data infectionscautitotyear1;
set infectionscautitotyear;
mon_yr1=compress("Total"||"-"||Year);
infection=count;
run;
**** appending month count and total quarter count;

proc append data=infectionscautitotyear1 base = infectionscauti2 force;run;

**** joining denominator and numerator by unit and month;

proc sql;
create table infection_cauti as select *
from cautidays2 as a
left join infectionscauti2 as b
on a.unit=b.unit and a.mon_yr1=b.MOn_yr1;
quit;

***** Calculating rates;

data infection_cauti1;
set infection_cauti;
if infection=. then infection=0;
if count=. then count=0;
rate = (infection/count)*1000;
if Rate = . then rate=0.0;
format rate 4.1;
Facility=scan(unit,1);
if index(unit,"SDU")ne 0 then Facility=scan(unit,1)||"-"||"SDU";
if unit in ("TH 15 WCCC", "TH 15 ECCC", "TH 15 CCVCU", "TH 9 NICU", "TH 9 PICU", "TH 12 NSICU",
"TH 14 TPU", "TH 6 CVSCU") then Facility= "TH-ICU"; 
run;

ods listing;
ods tagsets.ExcelXP 
 options(sheet_name='3.CAUTI Rates') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');

proc report data=infection_cauti1 nowd box; 
 column Unit facility Mon_yr1,(infection count rate) shaderow;
 define Unit /"Unit" id group order=internal width=7; 
 define Facility /"Facility" id group order=internal width=15; 
 define Mon_yr1 /across order=formatted 'Month-Year';
 define Count / "Days" width=3 display;
 define Infection / "Cases" width=3 display;
 define Rate / 'Rate' display ;
 define shaderow / noprint;
 title1 'CAUTI' ;
run ;

*******************CAUTI LINELIST************;


data CAutilist;
length unit $30.;
set edw.nhsn_event;
where event_type = 'UTI' and del_ind = "N";
if location =	"8 E"	then Unit=	"TH 8 EAST"	;
if location =	"9 E"	then Unit=	"TH 9 EAST"	;
if location =	"15 E - CCC"	then Unit=	"TH 15 ECCC"	;
if location =	"14 E"	then Unit=	"TH 14 EAST"	;
if location =	"17 E"	then Unit=	"TH 17 EAST"	;
if location =	"15 W - CCC"	then Unit=	"TH 15 WCCC"	;
if location =	"16 E"	then Unit=	"TH 16 EAST"	;
if location =	"HCC 11"	then Unit=	"TH HCC 11"	;
if location =	"TPU"	then Unit=	"TH 14 TPU"	;
if location =	"13E"	then Unit=	"TH 13 EAST"	;
if location =	"17 W"	then Unit=	"TH 17 WEST"	;
if location =	"8 W"	then Unit=	"TH 8 WEST"	;
if location =	"CARD REHAB"	then Unit=	"TH HCC 9"	;
if location =	"14W"	then Unit=	"TH 14 WEST"	;
if location =	"PICU"	then Unit=	"TH 9 PICU"	;
if location =	"15 CCVCU"	then Unit=	"TH 15 CCVCU"	;
if location =	"12 WEST"	then Unit=	"TH 12 WEST"	;
if location =	"11E"	then Unit=	"TH 11 EAST"	;
if location =	"16 EAST"	then Unit=	"TH 16 BMT"	;
if location =	"12 E"	then Unit=	"TH 12 EAST"	;
if location =	"NSICU"	then Unit=	"TH 12 NSICU"	;
if location =	"HCC 13"	then Unit=	"TH HCC 13"	;
if location =	"16 W"	then Unit=	"TH 16 WEST"	;
if location =	"HCC 12"	then Unit=	"TH HCC 12"	;
if location =	"NICU"	then Unit=	"TH 9 NICU"	;
if location =	"HCC 10"	then Unit=	"TH HCC 10"	;
if location =	"17 W SDU"	then Unit=	"TH 17 WEST-SDU"	;
if location =	"11 SDU"	then Unit=	"HJD 11 SDU"	;
if location =	"12TH FLOOR"	then Unit=	"HJD 12 FLOOR"	;
if location =	"9 S"	then Unit=	"HJD 9 SOUTH"	;
if location =	"11 S"	then Unit=	"HJD 11 FLOOR"	;
if location =	"9 N"	then Unit=	"HJD 9 NORTH"	;
if location =	"8 S"	then Unit=	"HJD 8 SOUTH"	;
if location =	"8 N"	then Unit=	"HJD 8 NORTH"	;
if location =	"11 SCU"	then Unit=	"HJD 11 SCU"	;
if location =	"CV PACU"	then Unit=	"TH 6 CVSCU"	;
if location =	"10TH FLOOR"	then Unit=	"HJD 10 FLOOR"	;
/*mon_yr=input(eventdate,date9.);*/
/*format mon_yr yymmd7.;*/
event_date=datepart(event_date);
format event_date date9.;
eventid=compress(put(event_id,$15.));
run;

data currentcauti;
set cautilist;
where event_date >=&currqtrstart and event_date <= &currqtrend;
run;


data cauti_lines;
set cauti.foley_list;
where infectionstatusline in ('Infect_1','Infect_2');
run;
data cauti_micro;
set cauti.pos_urine;
where event_date >=&currqtrstart and event_date <= &currqtrend and (infectionstatusmicro in ('Infect_1','Infect_2') and 
IPCP_decision = 1);
if mrn1 = ' ' then delete;
eventid=compress(put(event_id,$15.));
run;
proc sort data = cauti_micro; by accnumber1;run;
proc transpose data = cauti_micro out = cauti_micro1 prefix=neworg; by accnumber1; var org;run;
proc sql;
create table cauti_micro2 as select *
from cauti_micro as a
left join cauti_micro1 as b
on a.accnumber1=b.accnumber1;
quit;

proc sort data = cauti_micro2 nodupkey; by accnumber1;run;

proc sql;
create table cauti_merge as select *
from cauti_micro2 aS A
left join cauti_lines as b
on a.visitidcodead=b.visitidcodead and a.infectionstatusmicro=b.infectionstatusline;
quit;

proc sql;
create table cauti_nhsn as select *
from currentcauti as a
full join cauti_merge as b
on a.eventid=b.event_id;
quit;


data cauti_nhsn1;
set cauti_nhsn;
drop csn ;
run;





*********************CAUTI ONLY FOR Q1 2015!!!! no merge for previous quarter because of no micro id to merge;
********* using excel spreadsheet for now. change to cauti db after its ready;



/*


PROC IMPORT OUT= WORK.CAUTIcases 
            DATAFILE= "G:\Infect Prevention\IS01_groups\My Documents\IPC
 Surveillance Data\Daily Reviews\Cases_ForPractitioners\MASTER DailyLine
List_CAUTI_Jul2015.xls" 
            DBMS=EXCEL REPLACE;
     RANGE="Sheet1$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

PROC IMPORT OUT= WORK.CAUTIcases1 
            DATAFILE= "G:\Infect Prevention\IS01_groups\My Documents\IPC
 Surveillance Data\Daily Reviews\Cases_ForPractitioners\MASTER DailyLine
List_CAUTI_aug2015.xls" 
            DBMS=EXCEL REPLACE;
     RANGE="Sheet1$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;
PROC IMPORT OUT= WORK.CAUTIcases2 
            DATAFILE= "G:\Infect Prevention\IS01_groups\My Documents\IPC
 Surveillance Data\Daily Reviews\Cases_ForPractitioners\MASTER DailyLine
List_CAUTI_sep2015.xls" 
            DBMS=EXCEL REPLACE;
     RANGE="Sheet1$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;
proc append data=CAUTIcases1 base=CAUTIcases force;run;
proc append data=CAUTIcases2 base=CAUTIcases force;run;
data cauticases1;
set cauticases;
where upcase(cauti_yn) in ("Y","YES");
drop sex dob;
run;
proc sql;
create table cauticasesnhsn as select *
from currentcauti as a
full join cauticases1 as b
on a.event_id = b.eventid;
quit;
data micro;
set micro.microdballyears;
where performdate >=&currqtrstart and performdate <= &currqtrend;
accnumber1=scan(accnumber,1,"_");
run;

proc sql;
create table dob as select *
from cauticases1 as a
left join pda.scpm_patient (keep=patient_mrn sex dob) as b
on a.mrn=b.patient_mrn
left join micro (keep=mrn accnumber1 orgnhsn org)as c
on a.accnumber=c.accnumber1;
quit;*/

Proc format;
value orgf 1	=	'Acinetobacter spp.'
	2	=	'Actinomyces spp.'
	3	=	'Aeromonas spp.'
	4	=	'Aspergillus fumigatus'
	5	=	'Aspergillus niger'
	6	=	'Aspergillus spp.'
	7	=	'Aspergillus terreus'
	8	=	'B. anthracis'
	9	=	'Bacteroides spp.'
	10	=	'Blastomyces '
	11	=	'Burkholderia spp.'
	12	=	'C. albicans'
	13	=	'C. glabrata'
	14	=	'C. krusei'
	15	=	'C. lusitaniae'
	16	=	'C. parapsilosis'
	17	=	'Campylobacter spp.'
	18	=	'Citrobacter spp.'
	19	=	'Clostridium spp.'
	20	=	'Coagulase negative staph spp.'
	21	=	'Coccidioides spp.'
	22	=	'Corynebacterium spp.'
	23	=	'Cryptococcus spp.'
	24	=	'E. cassiflavus'
	25	=	'E. coli'
	26	=	'E. faecalis'
	27	=	'E. faecium'
	28	=	'E. gallinarum'
	29	=	'Enterobacter spp.'
	30	=	'Erysipelothrix spp.'
	31	=	'Fusobacterium spp.'
	32	=	'Group B strep'
	33	=	'HACEK'
	34	=	'Haemophilus spp.'
	35	=	'Histoplasma spp.'
	36	=	'Klebsiella oxytoca'
	37	=	'Klebsiella pneumoniae'
	38	=	'Klebsiella spp.'
	39	=	'Lactobacillus spp.'
	40	=	'Legionella pneumophila'
	41	=	'Leuconostoc spp.'
	42	=	'Listeria spp.'
	43	=	'M. tubercolosis'
	44	=	'MAI'
	45	=	'Malassezia spp.'
	46	=	'Morganella spp.'
	47	=	'Mucor spp.'
	48	=	'Neisseria spp.'
	49	=	'Nocardia spp.'
	50	=	'Other Bacillus spp.'
	51	=	'Other bacteria'
	52	=	'Other Candida spp.'
	53	=	'Other Enterococcus spp.'
	54	=	'Other GNR'
	55	=	'Other GPC'
	56	=	'Other Klebsiella spp.'
	57	=	'Other mold'
	58	=	'Other mycobacterium'
	59	=	'Other Pseudomonas spp.'
	60	=	'Other strep spp.'
	61	=	'Other yeast'
	62	=	'P. aeruginosa'
	63	=	'P. boydii'
	64	=	'Prevotella spp.'
	65	=	'Prevotella spp.'
	66	=	'Proteus spp.'
	67	=	'Providencia spp.'
	68	=	'RGM'
	69	=	'Rhizopus spp.'
	70	=	'S. aureus'
	71	=	'Salmonella spp.'
	72	=	'Scedosporium spp.'
	73	=	'Serratia spp.'
	74	=	'Shigella spp.'
	75	=	'spirochete'
	76	=	'Sporothrix spp.'
	77	=	'Stenotrophomonas maltophilia'
	78	=	'Strep bovis group'
	79	=	'Strep pneumo'
	80	=	'Strep spp.'
	81	=	'Trichophyton spp.'
	82	=	'Vibrio spp.'
	83	=	'Viridans Strep spp.'
	84	=	'Yersinia spp.'
	85	=	'Other GPR'
	86	=	'Enterococcus spp.'
	87	=	'Other GNC'
	88	=	'Adenovirus'	
	89	=	'Coronavirus HKU1'	
	90	=	'Coronavirus NL63'	
	91	=	'Human Metapneumovirus'	
	92	=	'Rhinovirus/Enterovirus'	
	93	=	'Influenza A H3'	
	94	=	'Influenza A H1'	
	95	=	'Influenza A H1 2009'	
	96	=	'Influenza B'	
	97	=	'Parainfluenza Virus 1'	
	98	=	'Parainfluenza Virus 2'	
	99	=	'Parainfluenza Virus 3'	
	100	=	'Parainfluenza Virus 4'	
	101	=	'Respiratory Syncitial Virus'	
	102	=	'Influenza A'	
	103	=	'Influenza B'	
	104	=	'Chlamydia'	
	105	=	'Neisseria Gonorrhoeae'	;
run;
data finallineslistcauti;
retain FULLNAME MRN sex DOB ADMISSION_DATE Discharge_date HAR CSN icisOrderID Org1
Org2 Culture_Date EventDate Insertion_date
Removal_date Unit Facility DEVICE_DESCRIPTION;
label
FULLNAME = "Patient Name"
sex= "Sex"
ADMISSION_DATE = "Admission Date"
discharge_date = "Discharge Date"
Orgname="Organism";
set cauti_nhsn1;
FullName=Ptname;
Culture_Date=performeddtm;
Unit=event_location;
EventDate=(Event_Date) ;
org1=neworg1;
org2=neworg2;
CSN=ACCOUNT_NUMBER;
discharge_date=(discharge_date2) ;
keep Culture_Date csn
ADMISSION_DATE
DOB
Discharge_date
EventDate
FULLNAME
icisOrderID
HAR
Removal_date
Unit
SEX
Org1
Org2
MRN
Insertion_date
DEVICE_DESCRIPTION
Facility ;
Facility=scan(unit,1);
if index(unit,"SDU")ne 0 then Facility=scan(unit,1)||"-"||"SDU";
if unit in ("TH 15 WCCC", "TH 15 ECCC", "TH 15 CCVCU", "TH 9 NICU", "TH 9 PICU", "TH 12 NSICU",
"TH 14 TPU", "TH 6 CVSCU") then Facility= "TH-ICU"; 
format culture_date datetime20.;
format eventdate discharge_date date9.;
format org1 org2 orgf.;
run;


ods listing;
ods tagsets.ExcelXP 
 options(sheet_name='4.CAUTI Line List') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');

Proc print data=finallineslistcauti noobs label width=minimum ;var _ALL_;run;

************************************CDIFF RATES;
*****getting patient days;


Data Stay;
set denom.denom_ptday;
where date >= &currqtrstart and date <= &currqtrend;
if unit in ("HJD C1 ASC PAC","HJD C1 ASC PER","HJD C2 MAIN OR","HJD C2 MAIN PE","HJD IMMEDIATE","TH 10 DAYSG PE",
"TH 10 DAYSG PA","TH 2 RAD IR","TH 6 MAIN PERI","TH 6 MAIN PACU","TH CARDIAC CAT","TH CARDIAC ELE","TH CC RAD ONC",
"TH CC RAD ONC","TH CC RAD PET","TH CH EMERG DE","TH GAMMA KNIFE","TH HCC 2 PACU","TH HCC13 NIC") then delete;
mon_yr=compress(Month||"-"||year);
run;


*******counting pt days by unit and month;

proc freq data=stay;
tables Unit*mon_yr /nocol norow nopercent noprint out=ptdaysfinaltot;
run;

data ptdaysfinaltot1;
set ptdaysfinaltot;
mon_yr1=put(mon_yr,$15.);
run;

*******counting pt days by quarter total;

proc freq data=stay;
tables Unit*year /nocol norow nopercent noprint out=ptdaysfinaltotyear;
run;

****new variable for appending;
data ptdaysfinaltotyear1;
set ptdaysfinaltotyear;
mon_yr1=compress("Total"||"-"||Year);
run;

*****appending total and month numbers;
proc append data=ptdaysfinaltotyear1 base = ptdaysfinaltot1 force;run;

***** making separate pt days datasets for recurrent and incident cases (to calculate rates separately later;
data ptdaysfinaltot2;
set ptdaysfinaltot1;
cdiassay="Recurrent";
run;
data ptdaysfinaltot3;
set ptdaysfinaltot1;
cdiassay="Incident";
run;
proc append data=ptdaysfinaltot3 base = ptdaysfinaltot2 force;run;

******* getting cases from NHSN;
proc sql;
create table labid as select *
from edw.nhsn_event as a
left join edw.nhsn_labid_event as b
on a.event_id=b.event_id;
quit;

*************only hospital onset;

data infectionscdiff;
length unit $30.;
set labid;
where cdiff = 'Y' and onset = "HO"  and del_ind ='N';
if location =	"8 E"	then Unit=	"TH 8 EAST"	;
else if location =	"17 E SDU"	then Unit=	"TH 17 EAST-SDU"	;
else if location =	"9 E"	then Unit=	"TH 9 EAST"	;
else if location =	"15 E - CCC"	then Unit=	"TH 15 ECCC"	;
else if location =	"14 E"	then Unit=	"TH 14 EAST"	;
else if location =	"17 E"	then Unit=	"TH 17 EAST"	;
else if location in	("15 W", "15 W - CCC")	then Unit=	"TH 15 WCCC"	;
else if location =	"16 E"	then Unit=	"TH 16 EAST"	;
else if location =	"HCC 11"	then Unit=	"TH HCC 11"	;
else if location =	"TPU"	then Unit=	"TH 14 TPU"	;
else if location =	"13E"	then Unit=	"TH 13 EAST"	;
else if location =	"17 W"	then Unit=	"TH 17 WEST"	;
else if location =	"8 W"	then Unit=	"TH 8 WEST"	;
else if location in	("HCC 9","CARD REHAB")	then Unit=	"TH HCC 9"	;
else if location = "14W"	then Unit=	"TH 14 WEST"	;
else if location =	"PICU"	then Unit=	"TH 9 PICU"	;
else if location =	"15 CCVCU"	then Unit=	"TH 15 CCVCU"	;
else if location =	"12 WEST"	then Unit=	"TH 12 WEST"	;
else if location =	"11E"	then Unit=	"TH 11 EAST"	;
else if location =	"16 EAST"	then Unit=	"TH 16 BMT"	;
else if location =	"12 E"	then Unit=	"TH 12 EAST"	;
else if location =	"NSICU"	then Unit=	"TH 12 NSICU"	;
else if location =	"HCC 13"	then Unit=	"TH HCC 13"	;
else if location =	"16 W"	then Unit=	"TH 16 WEST"	;
else if location =	"HCC 12"	then Unit=	"TH HCC 12"	;
else if location =	"NICU"	then Unit=	"TH 9 NICU"	;
else if location =	"HCC 10"	then Unit=	"TH HCC 10"	;
else if location =	"17 W SDU"	then Unit=	"TH 17 WEST-SDU"	;
else if location =	"11 SDU"	then Unit=	"HJD 11 SDU"	;
else if location in	("12 N", "12 S", "12TH FLOOR")	then Unit=	"HJD 12 FLOOR"	;
else if location =	"9 S"	then Unit=	"HJD 9 SOUTH"	;
else if location =	"11 S"	then Unit=	"HJD 11 FLOOR"	;
else if location =	"9 N"	then Unit=	"HJD 9 NORTH"	;
else if location =	"8 S"	then Unit=	"HJD 8 SOUTH"	;
else if location =	"8 N"	then Unit=	"HJD 8 NORTH"	;
else if location in	("11SCU","11 SCU")	then Unit=	"HJD 11 SCU"	;
else if location =	"CV PACU"	then Unit=	"TH 6 CVSCU"	;
else if Location  = "13 WEST" then Unit = "TH 13 OB";
else if location = "14 W SDU" then unit = "TH 14 WEST-SDU";
else if location = "17 E SDU" then untit = "TH 17 EAST-SDU";
else if location = "SICU" then untit = "TH 15 ECCC";
else if location =	"17 E SDU"	then Unit=	"TH 17 EAST-SDU"	;
mon_yr=datepart(event_date);
format mon_yr mmyyd7.;
year=year(mon_yr);
if cdi_assay = " " then delete;
if  mon_yr >= &currqtrstart and mon_yr <= &currqtrend then output;
run;
/*proc freq data = infectionscdiff;table location;where unit = ' ';run;*/
******counting cdiff cases by unit, month and if incident or recurrent (cdiassay);
proc freq data = infectionscdiff noprint; 
tables unit*mon_yr*cdi_assay/out=infectionscdiff1 ;
*where  mon_yr >= &currqtrstart and mon_yr <= &currqtrend;
run;

**** I am assuming if cdiassay is empty it is an incident case (these are only HO cases to begin with;

data infectionscdiff2;
length mon_yr1 $15.;
set infectionscdiff1;
mon_yr1=compress(put(mon_yr, mmyyd7.));
infection=count;
drop count;
run;
******counting cdiff cases by unit, quarter(year total) and if incident or recurrent (cdiassay);

proc freq data=infectionscdiff;
tables Unit*year*cdi_assay /nocol norow nopercent noprint out=infectionscdifftotyear;
where  mon_yr >= &currqtrstart and mon_yr <= &currqtrend;
run;
data infectionscdifftotyear1;
set infectionscdifftotyear;
mon_yr1=compress("Total"||"-"||Year);
infection=count;
drop count;
run;

*** appending both monthly data and quarter total together;
proc append data=infectionscdifftotyear1 base = infectionscdiff2 force;run;
******* merging ptdays and infections on unit month and if incident or recurrent;
proc sql;
create table infection_cdiff as select *
from ptdaysfinaltot2 as a
full join infectionscdiff2 as b
on a.unit=b.unit and a.mon_yr1=b.mon_yr1 and a.cdiassay=b.cdi_assay;
quit;

******** calculating rates;

data infection_cdiff1;
set infection_cdiff;
if infection=. then infection=0;
if count=. then count=0;
rate = (infection/count)*1000;
if Rate = . then rate=0.0;
format rate 4.1;
Facility=scan(unit,1);
if index(unit,"SDU")ne 0 then Facility=scan(unit,1)||"-"||"SDU";
if unit in ("TH 15 WCCC", "TH 15 ECCC", "TH 15 CCVCU", "TH 9 NICU", "TH 9 PICU", "TH 12 NSICU",
"TH 14 TPU", "TH 6 CVSCU") then Facility= "TH-ICU"; 
if mon_yr1=' '  then mon_yr1="Total";
run;

ods listing;
ods tagsets.ExcelXP 
 options(sheet_name='5.CDIFF Rates') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');

proc report data=infection_cdiff1 nowd box;
 column Unit cdiassay facility Mon_yr1,(infection count rate) shaderow;
 define Unit /"Unit" id group order=internal width=7; 
 define cdiassay /" " id group order=internal width=7; 
 define Facility /"Facility" id group order=internal width=15; 
 define Mon_yr1 /across order=formatted 'Month-Year';
 define Count / "Days" width=3 display;
 define Infection / "Cases" width=3 display;
 define Rate / 'Rate' display ;
 define shaderow / noprint;
 title1 'CDIFF' ;
run ;


*************************CDIFF LINELIST*************************************************;
*****pulling cdiff cases from NHSN;

proc sql;
create table labid as select *
from edw.nhsn_event as a
left join edw.nhsn_labid_event as b
on a.event_id=b.event_id;
quit;


data infectionscdiff;
length unit $30.;
set labid;
where cdiff = 'Y' and onset = "HO" and del_ind = 'N' ;
if location =	"16 EAST"	then Unit=	"TH 16 BMT"	;
if location =	"8 E"	then Unit=	"TH 8 EAST"	;
if location =	"9 E"	then Unit=	"TH 9 EAST"	;
if location =	"15 E - CCC"	then Unit=	"TH 15 ECCC"	;
if location =	"14 E"	then Unit=	"TH 14 EAST"	;
if location =	"17 E"	then Unit=	"TH 17 EAST"	;
if location =	"15 W - CCC"	then Unit=	"TH 15 WCCC"	;
if location =	"16 E"	then Unit=	"TH 16 EAST"	;
if location =	"HCC 11"	then Unit=	"TH HCC 11"	;
if location =	"TPU"	then Unit=	"TH 14 TPU"	;
if location =	"13E"	then Unit=	"TH 13 EAST"	;
if location =	"17 W"	then Unit=	"TH 17 WEST"	;
if location =	"8 W"	then Unit=	"TH 8 WEST"	;
if location =	"CARD REHAB"	then Unit=	"TH HCC 9"	;
if location =	"14W"	then Unit=	"TH 14 WEST"	;
if location =	"PICU"	then Unit=	"TH 9 PICU"	;
if location =	"15 CCVCU"	then Unit=	"TH 15 CCVCU"	;
if location =	"12 WEST"	then Unit=	"TH 12 WEST"	;
if location =	"11E"	then Unit=	"TH 11 EAST"	;
if location =	"16 EAST"	then Unit=	"TH 16 BMT"	;
if location =	"12 E"	then Unit=	"TH 12 EAST"	;
if location =	"NSICU"	then Unit=	"TH 12 NSICU"	;
if location =	"HCC 13"	then Unit=	"TH HCC 13"	;
if location =	"16 W"	then Unit=	"TH 16 WEST"	;
if location =	"HCC 12"	then Unit=	"TH HCC 12"	;
if location =	"NICU"	then Unit=	"TH 9 NICU"	;
if location =	"HCC 10"	then Unit=	"TH HCC 10"	;
if location =	"17 W SDU"	then Unit=	"TH 17 WEST-SDU"	;
if location =	"11 SDU"	then Unit=	"HJD 11 SDU"	;
if location =	"12TH FLOOR"	then Unit=	"HJD 12 FLOOR"	;
if location =	"9 S"	then Unit=	"HJD 9 SOUTH"	;
if location =	"11 S"	then Unit=	"HJD 11 FLOOR"	;
if location =	"9 N"	then Unit=	"HJD 9 NORTH"	;
if location =	"8 S"	then Unit=	"HJD 8 SOUTH"	;
if location =	"8 N"	then Unit=	"HJD 8 NORTH"	;
if location =	"11 SCU"	then Unit=	"HJD 11 SCU"	;
if location =	"CV PACU"	then Unit=	"TH 6 CVSCU"	;
else if location =	"9 E"	then Unit=	"TH 9 EAST"	;
else if location =	"15 E - CCC"	then Unit=	"TH 15 ECCC"	;
else if location =	"14 E"	then Unit=	"TH 14 EAST"	;
else if location =	"17 E"	then Unit=	"TH 17 EAST"	;
else if location in	("15 W", "15 W - CCC")	then Unit=	"TH 15 WCCC"	;
else if location =	"16 E"	then Unit=	"TH 16 EAST"	;
else if location =	"HCC 11"	then Unit=	"TH HCC 11"	;
else if location =	"TPU"	then Unit=	"TH 14 TPU"	;
else if location =	"13E"	then Unit=	"TH 13 EAST"	;
else if location =	"17 W"	then Unit=	"TH 17 WEST"	;
else if location =	"8 W"	then Unit=	"TH 8 WEST"	;
else if location in	("HCC 9","CARD REHAB")	then Unit=	"TH HCC 9"	;
else if location = "14W"	then Unit=	"TH 14 WEST"	;
else if location =	"PICU"	then Unit=	"TH 9 PICU"	;
else if location =	"15 CCVCU"	then Unit=	"TH 15 CCVCU"	;
else if location =	"12 WEST"	then Unit=	"TH 12 WEST"	;
else if location =	"11E"	then Unit=	"TH 11 EAST"	;
else if location =	"16 EAST"	then Unit=	"TH 16 BMT"	;
else if location =	"12 E"	then Unit=	"TH 12 EAST"	;
else if location =	"NSICU"	then Unit=	"TH 12 NSICU"	;
else if location =	"HCC 13"	then Unit=	"TH HCC 13"	;
else if location =	"16 W"	then Unit=	"TH 16 WEST"	;
else if location =	"HCC 12"	then Unit=	"TH HCC 12"	;
else if location =	"NICU"	then Unit=	"TH 9 NICU"	;
else if location =	"HCC 10"	then Unit=	"TH HCC 10"	;
else if location =	"17 W SDU"	then Unit=	"TH 17 WEST-SDU"	;
else if location =	"17 E SDU"	then Unit=	"TH 17 EAST-SDU"	;
else if location =	"11 SDU"	then Unit=	"HJD 11 SDU"	;
else if location in	("12 N", "12 S", "12TH FLOOR")	then Unit=	"HJD 12 FLOOR"	;
else if location =	"9 S"	then Unit=	"HJD 9 SOUTH"	;
else if location =	"11 S"	then Unit=	"HJD 11 FLOOR"	;
else if location =	"9 N"	then Unit=	"HJD 9 NORTH"	;
else if location =	"8 S"	then Unit=	"HJD 8 SOUTH"	;
else if location =	"8 N"	then Unit=	"HJD 8 NORTH"	;
else if location in	("11SCU","11 SCU")	then Unit=	"HJD 11 SCU"	;
else if location =	"CV PACU"	then Unit=	"TH 6 CVSCU"	;
else if Location  = "13 WEST" then Unit = "TH 13 OB";
else if location = "14 W SDU" then unit = "TH 14 WEST-SDU";
else if location = "17 E SDU" then untit = "TH 17 EAST-SDU";
else if location = "SICU" then untit = "TH 15 ECCC";
mon_yr=datepart(event_date);
format mon_yr date9.;
mrn2=compress(put(input(mrn,8.),z7.));
mrn1=prxchange('s/^0+//o ',1,MRN);
run;

data INFECTIONSCDIFFlist;
set INFECTIONSCDIFF;
where mon_yr >= &currqtrstart and mon_yr <= &currqtrend;
run;

data micro;
set micro.microdballyears;
where performdate >=&currqtrstart and performdate <= &currqtrend and org = 19;
run;

*******merging cdiff and micro to get patient demogrphics and other info using mrn and performdate;
data patient;
set pda.scpm_patient ;
mrn1=prxchange('s/^0+//o ',1,patient_MRN);
keep mrn1 sex dob;
run;
proc sql;
create table cdiffmerge as select * 
from INFECTIONSCDIFFlist as a
left join micro as b
on a.mrn1=b.mrn1 and a.mon_yr=b.performdate
left join patient as c
on a.mrn1=c.mrn1;
quit;
******* fixing variables for export;

data INFECTIONSCDIFFlist1;
retain Ptname mrn sex dob HAR CSN admitdtm dischargedtm orderid unit Culture_Date cdi_assay location_admit_date last_discharge_date;
set cdiffmerge;
format culture_date datetime22.;
Culture_Date=performeddtm;
keep unit location_admit_date last_discharge_date cdi_assay ptname mrn orderid admitdtm dischargedtm Culture_Date HAR CSN;
run;

ods listing;
ods tagsets.ExcelXP 
 options(sheet_name='6.CDIFF Line List') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');

Proc print data=INFECTIONSCDIFFlist1 noobs label width=minimum ;var _ALL_;run;

*********Vent days/rates***************************;

***********************VENT DATA*************CUSP****************************;

Data Stay;
length unit $30.;
set pda.Scpm_patient_stay;
Date = datepart(EFFECTIVE_DATE);
time = timepart(EFFECTIVE_DATE);
/*if date >= &currqtrstart. and date <= &currqtrend;*/
/*if time ne 86340 then delete;*/
/*if IS_DISCHARGE_DAY = '1' then delete;*/
Month1 = month (Date);
Month = put (month1, Z2.0);
Year  = year (Date);
format date date9.;
Month_year = compress (month||"_"||year);
Year_month = compress (year||"_"||month);
If DEPARTMENT_NAME = "TH 17 WEST" and ROOM_NAME in ("TH1717", "TH1718") then Unit = "TH 17 WEST-SDU";
else if DEPARTMENT_NAME = "TH 17 EAST" and ROOM_NAME in ("TH1736", "TH1737") then Unit = "TH 17 EAST-SDU";
else if DEPARTMENT_NAME = "TH 14 WEST" and ROOM_NAME in ("TH1413", "TH1414") then Unit = "TH 14 WEST-SDU";
else if DEPARTMENT_NAME = "TH 14 EAST" and ROOM_NAME in ("TH1436", "TH1437") then Unit = "TH 14 EAST-SDU";
else if DEPARTMENT_NAME = "TH 12 WEST" and ROOM_NAME in ("TH1207", "TH1208", "TH1209","TH1210", "TH1211", "TH1212",
"TH1213", "TH1214","TH1215","TH1216") then Unit = "TH 12 NSICU";
else Unit = DEPARTMENT_NAME;
/*if unit in ("HJD C1 ASC PAC","HJD C1 ASC PER","HJD C2 MAIN OR","HJD C2 MAIN PE","HJD IMMEDIATE","TH 10 DAYSG PE",*/
/*"TH 10 DAYSG PA","TH 2 RAD IR","TH 6 MAIN PERI","TH 6 MAIN PACU","TH CARDIAC CAT","TH CARDIAC ELE","TH CC RAD ONC",*/
/*"TH CC RAD ONC","TH CC RAD PET","TH CH EMERG DE","TH GAMMA KNIFE","TH HCC 2 PACU","TH HCC13 NIC") then delete;*/
run;


proc sql;							
create table vent_listtemp as							
select *							
from pda.Scpm_patient_device (drop=  device_desc) as a							
left join pda.Scpm_patient (keep= PATIENT_MRN FULLNAME PATIENT_KEY SEX DOB RACE_1 ETHINIC_GROUP )as b  							
on a.PATIENT_KEY=b.PATIENT_KEY 		
left join stay as d  							
on a.PATIENT_KEY=d.PATIENT_KEY and datepart(a.EFFECTIVE_DATE)=datepart(d.EFFECTIVE_DATE)	
left join pda.Scpm_patient_device_grouper as e  							
on a.FLO_MEAS_ID=e.FLO_MEAS_ID	
left join pda.scpm_patient_vital_signs (keep = MIN_FIO2 MAX_FIO2 MIN_PEEP MAX_PEEP MIN_TEMPERATURE MAX_TEMPERATURE RECORD_DATE PATIENT_KEY ) as f
on a.PATIENT_KEY = f.PATIENT_KEY and datepart(f.RECORD_DATE) = datepart (a.EFFECTIVE_DATE) 
left join pda.scpm_patient_lab_results (keep = min_wbc max_wbc effective_date_key patient_key) as g
on a.PATIENT_KEY = g.PATIENT_KEY and g.EFFECTIVE_DATE_KEY = a.EFFECTIVE_DATE_KEY 
/*left join pda.scpm_patient_measure_vent (keep = ) as g*/
/*on */

where a.DEVICE_GROUP in ("Airway", "Endotracheal tube", "Tracheostomy tube");
quit;

data vent_list;
set vent_listtemp;
if prxmatch ('m/mask/io', device_comments)> 0 and prxmatch ('m/endotracheal|ETT |trach-to-vent/io', device_comments) = 0 then delete;
run;

Data vent_lines;
set vent_list;
date = datepart (effective_date);
format date date9.;
admit_date2 = datepart (ADMISSION_DATE) ;
format admit_date2 yymmdd10.;
Admitdatechar =put(admit_date2,yymmddn8.);
MRN1=prxchange('s/^0+//o ',1,PATIENT_MRN);
VisitIDCodeAD = (MRN1||Admitdatechar);
VisitIDCodeAD = compress (VisitIDCodeAD, " ");
*where DEVICE_GROUP in("Airway", "Endotracheal tube", "Tracheostomy tube");
run;


/*proc freq data=CVC_report; tables DEVICE_desc;run;*/
proc sort data=vent_lines;by IP_LDA_ID date;run;

data vent_lines1;
set vent_lines;
by IP_LDA_ID date;
if first.IP_LDA_ID then First_day=date;
if last.IP_LDA_ID  then Last_day=date;
format first_day last_day date9.;
if first_day=. and last_day=. then delete;
lag_first=lag(first_day);
format lag_first date9.;
if first_day=. then first_day=lag_first;
if last_day=. then delete;
drop lag_first;
run;

/*Avg length of ventilation*/
/* All patient days during the a patient stay is applied to the month in which the discharge occurred. Patients admitted and discharged on the same day before midnight have a length of stay of 1. */
data length;
set vent_lines1;
where unit in ('TH 15 ECCC');
vent_length = last_day - first_day + 1;
if vent_length = 0 then vent_length = 1;
avg_yrmonth = put (last_day, yymm5.);
avg_yrqtr = put (last_day, yyq6.);
avg_year = year (last_day);
if avg_year in (2014, 2015);
/*if time ne 86340 then delete;*/
/*if IS_DISCHARGE_DAY = '1' then delete;*/
run;
proc summary data =length sum;
class avg_yrmonth avg_yrqtr;
freq vent_length;
output out = length2;
run;
data length2a;
set length2;
where _type_ in (1, 2);
rename _freq_ = ventday_sum;
run;
proc freq data =length noprint;
table avg_yrmonth/out = length_m;
run;
proc freq data =length noprint;
table avg_yrqtr/out = length_qt;
run;

data length_qt2;
set length_qt;
rename count = qtr_episodes;run;
proc sql; create table final_average as
select *
from length2a as a
left join length_m as b
on a.avg_yrmonth=b.avg_yrmonth
left join length_qt2 as c
on a.avg_yrqtr=c.avg_yrqtr;
quit;

data final_average_final;
set final_average;
drop percent _type_;
avg_vent_lengtha = ventday_sum/count;
avg_vent_lengthb = ventday_sum/qtr_episodes;
if avg_vent_lengtha = . then avg_vent_lengtha = avg_vent_lengthb;
if count = . then count = qtr_episodes;
drop qtr_episodes avg_vent_lengthb;
avg_vent_length = round (avg_vent_lengtha);
rename count = episodes_sum_removal;
attrib _all_ label=' '; 
keep avg_yrmonth avg_yrqtr avg_vent_length count;
/*if avg_yrmonth in ('');*/
/*if avg_yrqtr in ('');*/
run;

proc sort data = final_average_final; by avg_yrmonth; run;

data check;
set vent_lines1;
where month(last_day) = 7 and year(last_day)=2011;
vent_length = last_day - first_day + 1;
run;

/*************************/

proc sql;
create table vent_linesFinal as
select *
from vent_lines as a
left join vent_lines1 (keep = ip_lda_id first_day last_day) as b 
on a.IP_LDA_ID=b.IP_LDA_ID;
quit;

proc sort data = vent_linesfinal out= vent_linesfinal nodupkey; by patient_key effective_date; run;

data vents;
set vent_linesFinal;
date2 = put (date, yymmddn8.);
vaekey = compress (mrn1||unit||date2);
First_daychar = put (first_day, yymmddn8.);
VentEpisode = compress(MRN1||"_"||First_daychar);
/*Month1 = month (Date);*/
/*Month = put (month1, Z2.0);*/
/*Year  = year (Date);*/
/*format date date9.;*/
/*Month_year = compress (month||"_"||year);*/
/*Year_month = compress (year||"_"||month);*/
run;





Data Deaths (Keep = Death VisitIDCodeAD Discharge_disp_desc);
set edw.scpm_encounter;
where Discharge_disp_desc in ("Expired", "Expired in Medical Facility", "DECEASED / EXPIRED");
Death = 1;
AdmitDate = datepart (ADMIT_DATE);
Admitdatechar =put(Admitdate,yymmddn8.);
MRN1=prxchange('s/^0+//o',1,MRN);
VisitIDCodeAD = (MRN1||Admitdatechar);
VisitIDCodeAD  = compress(VisitIDCodeAD, "  - ");
run;

Proc sort data = Vents; by VisitIDCodeAd; run;
Proc sort data = Deaths; by VisitIDCodeAd; run;

Data DeathVent;
merge Vents ( in = a) Deaths ( in = b);
by VisitIDcodeAd; 
if a;
/*Month1 = put (month, Z2.0);*/
/*Year_Month = compress (year||"_"||month1);*/
run;

Data DeathVentPatients;
set DeathVent;
run;


Proc sort data = DeathVentPatients nodupkey; by MRN1 Unit Year_Month ; run;

Proc freq data =  DeathVentPatients noprint;
table Unit*Year_Month / out = PtsOnVentPerUnit;
run;

Data ptsOnVentPerUnit1 (rename = (COUNT = PtsOnVent));
set PtsOnVentPerUnit;
attrib _all_ label=' ';
drop PERCENT;
run;


Data VentEpisodes;
set DeathVent;
run;
Proc sort data = VentEpisodes nodupkey; by VentEpisode Unit Year_Month; run;

Proc freq data =  VentEpisodes noprint;
table Unit*Year_Month / out = VentEpisodesPerUnit;
run;

Data VentEpisodesPerUnit1 (rename = (COUNT = VentEpisodesPerUnit));
set VentEpisodesPerUnit;
attrib _all_ label=' ';
drop PERCENT;
run;

Proc freq data = DeathVent noprint;
table Unit*Year_Month / out = ags.VentsPerUnit;
run;

Data VentsPerUnit1 (rename = (COUNT = VentDays));
set ags.VentsPerUnit;
attrib _all_ label=' ';
drop PERCENT;
run;


Data Stay;
set pda.Scpm_patient_stay;
Date = datepart(EFFECTIVE_DATE);
time = timepart(EFFECTIVE_DATE);
if date >= &currqtrstart. and date <= &currqtrend;
if time ne 86340 then delete;
if IS_DISCHARGE_DAY = '1' then delete;
Month1 = month (Date);
Month = put (month1, Z2.0);
Year  = year (Date);
format date date9.;
Month_year = compress (month||"_"||year);
Year_month = compress (year||"_"||month);
If DEPARTMENT_NAME = "TH 17 WEST" and ROOM_NAME in ("TH1717", "TH1718") then Unit = "TH 17 WEST-SDU";
else if DEPARTMENT_NAME = "TH 17 EAST" and ROOM_NAME in ("TH1736", "TH1737") then Unit = "TH 17 EAST-SDU";
else if DEPARTMENT_NAME = "TH 14 WEST" and ROOM_NAME in ("TH1413", "TH1414") then Unit = "TH 14 WEST-SDU";
else if DEPARTMENT_NAME = "TH 14 EAST" and ROOM_NAME in ("TH1436", "TH1437") then Unit = "TH 14 EAST-SDU";
else if DEPARTMENT_NAME = "TH 12 WEST" and ROOM_NAME in ("TH1207", "TH1208", "TH1209","TH1210", "TH1211", "TH1212",
"TH1213", "TH1214","TH1215","TH1216") then Unit = "TH 12 NSICU";
else Unit = DEPARTMENT_NAME;
/*if unit in ("HJD C1 ASC PAC","HJD C1 ASC PER","HJD C2 MAIN OR","HJD C2 MAIN PE","HJD IMMEDIATE","TH 10 DAYSG PE",*/
/*"TH 10 DAYSG PA","TH 2 RAD IR","TH 6 MAIN PERI","TH 6 MAIN PACU","TH CARDIAC CAT","TH CARDIAC ELE","TH CC RAD ONC",*/
/*"TH CC RAD ONC","TH CC RAD PET","TH CH EMERG DE","TH GAMMA KNIFE","TH HCC 2 PACU","TH HCC13 NIC") then delete;*/
run;

proc freq data = stay noprint; tables unit; run;
Proc freq data = Stay noprint;
table Unit*Year_Month / out = HospitalDays;
run;

Data HospitalDays1 (rename = ( COUNT = HospitalDays));
set HospitalDays;
attrib _all_ label=' ';
drop PERCENT;
run;

Proc sort data = DeathVent; by MRN1 Unit Year_Month; run;

Data DeathVentPatientsDeaths;
set DeathVent;
where Death = 1;
by MRN1 Unit Year_Month ;
if last.MRN1 and Last.Unit and Last.Year_Month  ;
run;

*Proc sort data = DeathVentPatientsDeaths nodupkey; *by MRN1 Location Year_Month  ; *run; 

Proc freq data = DeathVentPatientsDeaths noprint;
table Unit*Year_Month / out = DeathsPerUnit;
run;

Data DeathsPerUnit1 (Rename = (COUNT = Deaths));
set DeathsperUnit;
attrib _all_ label=' ';
drop PERCENT;
run;


/*NHSN cases*/

data vae1;
length unit $30.;
set edw.nhsn_event;
where event_type in ('VAE') and del_ind = "N";
if specific_event = 'VAC' then VAC = 1;
if specific_event = 'IVAC' then IVAC = 1;
if specific_event = 'PVAP' then PVAP = 1;
mrn2 = input(mrn, 7.);
MRN1=prxchange('s/^0+//o',1,MRN);
if location =	"8 E"	then Unit=	"TH 8 EAST"	;
if location =	"9 E"	then Unit=	"TH 9 EAST"	;
if location =	"15 E - CCC"	then Unit=	"TH 15 ECCC"	;
if location =	"14 E"	then Unit=	"TH 14 EAST"	;
if location =	"17 E"	then Unit=	"TH 17 EAST"	;
if location =	"15 W - CCC"	then Unit=	"TH 15 WCCC"	;
if location =	"16 E"	then Unit=	"TH 16 EAST"	;
if location =	"HCC 11"	then Unit=	"TH HCC 11"	;
if location =	"TPU"	then Unit=	"TH 14 TPU"	;
if location =	"13E"	then Unit=	"TH 13 EAST"	;
if location =	"17 W"	then Unit=	"TH 17 WEST"	;
if location =	"8 W"	then Unit=	"TH 8 WEST"	;
if location =	"CARD REHAB"	then Unit=	"TH HCC 9"	;
if location =	"14W"	then Unit=	"TH 14 WEST"	;
if location =	"PICU"	then Unit=	"TH 9 PICU"	;
if location =	"15 CCVCU"	then Unit=	"TH 15 CCVCU"	;
if location =	"12 WEST"	then Unit=	"TH 12 WEST"	;
if location =	"11E"	then Unit=	"TH 11 EAST"	;
if location =	"16 EAST"	then Unit=	"TH 16 BMT"	;
if location =	"12 E"	then Unit=	"TH 12 EAST"	;
if location =	"NSICU"	then Unit=	"TH 12 NSICU"	;
if location =	"HCC 13"	then Unit=	"TH HCC 13"	;
if location =	"16 W"	then Unit=	"TH 16 WEST"	;
if location =	"HCC 12"	then Unit=	"TH HCC 12"	;
if location =	"NICU"	then Unit=	"TH 9 NICU"	;
if location =	"HCC 10"	then Unit=	"TH HCC 10"	;
if location =	"17 W SDU"	then Unit=	"TH 17 WEST-SDU"	;
if location =	"11 SDU"	then Unit=	"HJD 11 SDU"	;
if location =	"12TH FLOOR"	then Unit=	"HJD 12 FLOOR"	;
if location =	"9 S"	then Unit=	"HJD 9 SOUTH"	;
if location =	"11 S"	then Unit=	"HJD 11 FLOOR"	;
if location =	"9 N"	then Unit=	"HJD 9 NORTH"	;
if location =	"8 S"	then Unit=	"HJD 8 SOUTH"	;
if location =	"8 N"	then Unit=	"HJD 8 NORTH"	;
if location =	"11 SCU"	then Unit=	"HJD 11 SCU"	;
if location =	"CV PACU"	then Unit=	"TH 6 CVSCU"	;
eventdate2 = datepart (event_date);
if eventdate2 >= &currqtrstart and eventdate2 <= &currqtrend;
format eventdate2 mmddyy9.;
eventdatechar = put (eventdate2, yymmddn8.);
vaekey = compress (mrn1||unit||eventdatechar);
month = month(eventdate2);
year = year (eventdate2);
Month1 = put (month, Z2.0);
Year_Month = compress (year||"_"||month1);
/*keep mrn1 unit vac ivac pvap eventdate2 vaekey yearmonth;*/
run;



Data VACe;
set VAE1;
Where VAC = 1;
run;
Data IVACe;
set VAE1;
where IVAC = 1;
run;
Data PVAPe;
set VAE1;
where PVAP =1;
run;


Proc freq data = Vace noprint;
table Unit*Year_Month / out = VAC;
run;
Proc freq data = ivace noprint;
table Unit*Year_Month / out = IVAC;
run;
Proc freq data = pvape noprint;
table Unit*Year_Month / out = PVAP;
run;




Data VAC1 (Rename = (COUNT = VAC));
set VAC;
attrib _all_ label=' ';
drop PERCENT;
run;

Data IVAC1 (Rename = (COUNT = IVAC));
set IVAC;
attrib _all_ label=' ';
drop PERCENT;
run;

Data PVAP1 (Rename = (COUNT = PVAP));
set PVAP;
attrib _all_ label=' ';
drop PERCENT;
run;


**;

Proc sort data = ptsOnVentPerUnit1; by Unit Year_Month ; run;
Proc sort data = VentEpisodesPerUnit1; by Unit Year_Month ; run;
Proc sort data = VentsPerUnit1; by Unit Year_Month ; run;
Proc sort data = HospitalDays1; by Unit Year_Month ; run;
Proc sort data = DeathsPerUnit1; by Unit Year_Month ; run;
Proc sort data = VAC1; by Unit Year_Month ; run;
Proc sort data = IVAC1; by Unit Year_Month ; run;
Proc sort data = PVAP1; by Unit Year_Month ; run;


/*proc freq data = cusp; tables location;run;*/
Data VAEreport;
merge ptsOnVentPerUnit1 VentEpisodesPerUnit1 VentsPerUnit1 HospitalDays1 DeathsPerUnit1 VAC1 IVAC1 PVAP1;
by Unit Year_Month ;
if Unit in ('HJD C1 ASC PAC') then Unit = 'HJD C1 ASC PACU';
if Unit in ('HJD C1 ASC PER') then Unit = 'HJD C1 ASC PERI-OP';
if Unit in ('HJD C2 MAIN OR') then Unit = 'HJD C2 MAIN OR PACU';
if Unit in ('HJD C2 MAIN PE') then Unit = 'HJD C2 MAIN PERI-OP';
if Unit in ('TH 10 DAYSG PA') then Unit = 'TH 10 DAYSG PACU';
if Unit in ('TH 10 DAYSG PE') then Unit = 'TH 10 DAYSG PERI-OP';
if Unit in ('TH 6 MAIN PERI') then Unit = 'TH 6 MAIN PERI-OP';
if Unit in ('TH CARDIAC CAT') then Unit = 'TH CARDIAC CATH';
if Unit in ('TH CARDIAC ELE') then Unit = 'TH CARDIAC ELEPHYS';
if Unit in ('TH EMERGENCY D') then Unit = 'TH EMERGENCY DEPT';
if Unit in ('TH HCC 2 PERI-') then Unit = 'TH HCC 2 PERI-OP';
if Unit in ('TH CH EMERG DE') then Unit = 'TH CH EMERG DEPT';
if Unit in ('X_TH 16 OBSERV') then Unit = 'X_TH 16 OBSERVATION';
if unit = ' ' then delete;
if deaths = . then Deaths = 0;
if VAC = . then VAC = 0;
if IVAC = . then IVAC = 0;
if PtsonVent = . then PtsonVent = 0;
if VentEpisodesPerUnit = . then VentEpisodesPerUnit = 0;
if Ventdays = . then Ventdays = 0;
if HospitalDays = . then HospitalDays = 0;
if PVAP = . then PVAP = 0;
run;


/*Vents per month*/
Proc freq data = DeathVent noprint;
table Unit*Year_Month / nocol norow nopercent noprint out = VentsPerUnit;
run;


Data VentsPerUnit1 (rename = (COUNT = VentDays));
set VentsPerUnit;
attrib _all_ label=' ';
drop PERCENT;
run;

Proc freq data = DeathVent noprint;
table Unit*Year/nocol norow nopercent noprint out = VentsPerUnitYear;
run;
data VentsPerUnitYear1 (rename = (COUNT = VentDays));
set VentsPerUnitYear;
year_month=compress("Total"||"-"||Year);
attrib _all_ label=' ';
drop PERCENT year;
run;

proc append data=VentsPerUnitYear1 base = VentsPerUnit1 force;run;

/*Numerator*/
Proc freq data = Vace noprint;
table Unit*Year_Month /nocol norow nopercent noprint out = VAC;
run;
data VAC1 (rename = (COUNT = Infection));
length VAE_type $10. unit $60.;
set VAC;
VAE_Type = 'VAC';
attrib _all_ label=' ';
drop PERCENT;
run;
Proc freq data = ivace noprint;
table Unit*Year_Month /nocol norow nopercent noprint out = IVAC;
run;
data IVAC1 (rename = (COUNT = Infection));
length VAE_type $10. unit $60.;
set IVAC;
VAE_Type = 'IVAC';
attrib _all_ label=' ';
drop PERCENT;
run;
Proc freq data = pvape noprint;
table Unit*Year_Month /nocol norow nopercent noprint out = PVAP;
run;
data PVAP1 (rename = (COUNT = Infection));
length VAE_type $10. unit $60.;
set PVAP;
VAE_Type = 'PVAP';
attrib _all_ label=' ';
drop PERCENT;
run;

Proc freq data = Vace noprint;
table Unit*Year /nocol norow nopercent noprint out = VACyear;
run;
data VACyear1 (rename = (COUNT = Infection));
length VAE_type $10. unit $60.;
set VACyear;
VAE_Type = 'VAC';
attrib _all_ label=' ';
drop PERCENT year;
year_month=compress("Total"||"-"||Year);
run;
Proc freq data = ivace noprint;
table Unit*Year /nocol norow nopercent noprint out = IVACyear;
run;
data IVACyear1 (rename = (COUNT = Infection));
length VAE_type $10. unit $60.;
set IVACyear;
VAE_Type = 'IVAC';
attrib _all_ label=' ';
drop PERCENT year;
year_month=compress("Total"||"-"||Year);
run;
Proc freq data = pvape noprint;
table Unit*Year /nocol norow nopercent noprint out = PVAPyear;
run;
data PVAPyear1 (rename = (COUNT = Infection));
length VAE_type $10. unit $60.;
set PVAPyear;
VAE_Type = 'PVAP';
attrib _all_ label=' ';
drop PERCENT year;
year_month=compress("Total"||"-"||Year);
run;


proc append data = IVAC1 base = Vac1 force; run;
proc append data = PVAP1 base = Vac1 force; run;
proc append data = VACyear1 base = Vac1 force; run;
proc append data = IVACyear1 base = Vac1 force; run;
proc append data = PVAPyear1 base = Vac1 force; run;

proc sql;
create table vaemerge as 
select *
from ventsperunit1 as a
left join vac1 as b on
a.unit = b.unit and a.year_month = b.year_month;
quit;

data vaemerge2;
length unit $25.;
set vaemerge;
if infection = . then infection = 0;
rate = (infection/ventdays)*1000;
if Rate = . then rate=0.0;
format rate 4.1;
Facility=scan(unit,1);
if index(unit,"SDU")ne 0 then Facility=scan(unit,1)||"-"||"SDU";
if unit in ("TH 15 WCCC", "TH 15 ECCC", "TH 15 CCVCU", "TH 9 NICU", "TH 9 PICU", "TH 12 NSICU",
"TH 14 TPU", "TH 6 CVSCU") then Facility= "TH-ICU"; 
if year_month=' '  then year_month="Total";
if unit = 'TH EMERGENCY D' then unit = 'TH EMERGENCY DEPT';
If infection = . then infection = 0;
If ventdays = . then ventdays = 0;
If rate = . then rate = 0;
run;

ods listing;
ods tagsets.ExcelXP 
 options(sheet_name='7.VAE Rates') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');

proc report data=vaemerge2 nowd box;
 column Unit VAE_type facility year_month,(infection ventdays rate) shaderow;
 define Unit /"Unit" id group order=internal width=7; 
 define VAE_type /" " id group order=internal width=7; 
 define Facility /"Facility" id group order=internal width=15; 
 define year_month /across order=formatted 'Month-Year';
 define Ventdays / "Days" width=3 display;
 define Infection / "Cases" width=3 display;
 define Rate / 'Rate' display ;
 define shaderow / noprint;
 title1 'VAE' ;
run ;


/*
PROC EXPORT DATA= WORK.CUSP 
            OUTFILE= "G:\Infect Prevention\Data Management\IPC_Quarterly
_Reports\&excel" 
            DBMS=EXCEL REPLACE;
     SHEET="8.VAE_Raw_Data-CUSP"; 
RUN;
*/
ods listing;
ods tagsets.ExcelXP 
 options(sheet_name='8.VAE Raw Data - CUSP') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');

Proc print data=vaereport noobs label width=minimum ;var _ALL_;run;


**************************************************Hand Hygiene/dazo/ISOLATION***********************************;


PROC IMPORT OUT= WORK.HH 
            DATATABLE= "HandHygiene" 
            DBMS=ACCESS REPLACE;
     DATABASE="G:\Infect Prevention\Data Management\Databases\HandHygiene_Database.accdb"; 
     SCANMEMO=YES;
     USEDATE=NO;
     SCANTIME=YES;
RUN;
PROC EXPORT DATA= WORK.Hh 
            OUTFILE= "G:\Infect Prevention\Data Management\App\HH.csv" 
            DBMS=CSV LABEL REPLACE;
     PUTNAMES=YES;
RUN;


****** CROSSWALK FOR UNITS/FACILITY AND ADDING DATE VARIABLES******;
data hh1;
length location1 $30.;
set hh;
location=compress(location);
if Location ="Hemo" then Location1="TH 18 HEMO";
if Location ="12E" then Location1="TH 12 EAST";
if Location ="12e" then Location1="TH 12 EAST";
if Location ="12W" then Location1="TH 12 WEST";
if Location ="12w" then Location1="TH 12 WEST";
if Location ="13E" then Location1="TH 13 EAST";
if Location ="13W" then Location1="TH 13 WEST";
if Location ="14E" then Location1="TH 14 EAST";
if Location ="14W" then Location1="TH 14 WEST";
if Location ="15CCVCU" then Location1="TH 15 CCVCU";
if Location ="15E" then Location1="TH 15 EAST";
if Location ="15ECCC" then Location1="TH 15 EAST";
if Location ="15W" then Location1="TH 15 WEST";
if Location ="16E" then Location1="TH 16 EAST";
if Location ="16W" then Location1="TH 16 WEST";
if Location ="17E" then Location1="TH 17 EAST";
if Location ="17W" then Location1="TH 17 WEST";
if Location ="6PACU" then Location1="TH 6 PACU";
if Location ="6RR/CU" then Location1="TH 6 PACU";
if Location ="8W" then Location1="TH 8 WEST";
if Location ="9E" then Location1="TH 9 EAST";
if Location ="9W" then Location1="TH 9 PICU";
if Location ="9W/NICU" then Location1="TH 9 NICU";
if Location ="9W/PICU" then Location1="TH 9 PICU";
if Location ="ER" then Location1="TH EMERGENCY";
if Location ="HCC10" then Location1="TH 10 HCC";
if Location ="HCC11" then Location1="TH 11 HCC";
if Location ="HCC12" then Location1="TH 12 HCC";
if Location ="HCC13" then Location1="TH 13 HCC";
if Location ="HCC14" then Location1="TH 14 HCC";
if Location ="HCC8" then Location1="TH 8 HCC";
if Location ="HCC9" then Location1="TH 9 HCC";
if Location ="HJD10" then Location1="HJD 10 FLOOR";
if Location ="HJD11" then Location1="HJD 11 FLOOR";
if Location ="HJD11/SCU/SDU" then Location1="HJD 11 SCU/SDU";
if Location ="HJD12" then Location1="HJD 12 FLOOR";
if Location ="HJD12N" then Location1="HJD 12 FLOOR";
if Location ="HJD12S" then Location1="HJD 12 FLOOR";
if Location ="HJD8" then Location1="HJD 8 FLOOR";
if Location ="HJD8N" then Location1="HJD 8 NORTH";
if Location ="HJD8S" then Location1="HJD 8 SOUTH";
if Location ="HJD9" then Location1="HJD 9 FLOOR";
if Location ="HJD9N" then Location1="HJD 9 NORTH";
if Location ="HJD9S" then Location1="HJD 9 SOUTH";
if Location ="TH15E" then Location1="TH 15 EAST";
if Location ="TH15ECC" then Location1="TH 15 EAST";
if Location ="TH16" then Location1="TH 16 EAST";
if Location ="TH9W" then Location1="TH 9 PICU";
if Location ="TH15E" then Location1="TH 15 EAST";
if Location ="15CCC" then Location1="TH 15 EAST";
if Location ="8N" then Location1="HJD 8 NORTH";
if Location ="9WNICU" then Location1="TH 9 NICU";
if Location ="16" then Location1="TH 16 EAST";
if Location ="15WCCC" then Location1="TH 15 WEST";
if Location in ("HJD11S","HJD11/SCU/SDU") then Location1="HJD 11 SCU/SDU";
if Location in ("10W","HJD10") then Location1="HJD 10 FLOOR";
*if location in('HJD10','HJD11','HJD11/SCU/SDU','HJD12','HJD8N','HJD8S','HJD9N','HJD9S') then Facility="HJD";
*else if Location in('12E','12W','13E','13W','14E','14W','16E','16W','17E','17W','9E','ER','HCC11','HCC12','HCC13','HCC14',
'HCC9') then Facility="TH";
*else Facility="TH";
*if location in('HJD10','HJD11','HJD11/SCU/SDU','HJD12','HJD8N','HJD8S','HJD9N','HJD9S') then ICU="Non-ICU";
*else if Location in('12E','12W','13E','13W','14E','14W','16E','16W','17E','17W','9E','ER','HCC11','HCC12','HCC13','HCC14',
'HCC9') then ICU="Non-ICU";
*else  ICU="ICU";
Facility=" "||compress(scan(Location1,1))||" TOTAL";
Nyumc="NYUMC TOTAL";
Month=compress(month);
if month='Jan' then Month1=01;
else if Month='Feb' then Month1=02;
else if Month='Mar' then Month1=03;
else if Month='March' then Month1=03;
else if Month='Apr' then Month1=04;
else if Month='April' then Month1=04;
else if Month='May' then Month1=05;
else if Month='Jun' then Month1=06;
else if Month='June' then Month1=06;
else if Month='Jul' then Month1=07;
else if Month='July' then Month1=07;
else if Month='Aug' then Month1=08;
else if Month='Sep' then Month1=09;
else if Month='Oct' then Month1=10;
else if Month='Nov' then Month1=11;
else if Month='Dec' then Month1=12;
month2= put( month1, z2.);
Mon_yr1=cat( '01',Month2,year);
mon_yr=input(mon_yr1,ddmmyy9.);
format mon_yr yymmd7.;
if Location1 = " " then delete;
if location1 in ("TH 10 HCC","TH 8 HCC") then delete;
quarter_year= put(mon_yr,yyq6.);
run;
data hh1;set hh1;where mon_yr >= &currqtrstart and mon_yr <= &currqtrend ;run;
/*proc freq data=hh1;table Location1;run;*/
*** PROC SUMMARY FOR EACH INDIVIDUAL UNIT/VARIABLE TYPE IS UNIQUE FOR EACH COMBINATIONS (UNITxMONTH UNITxYEAR UNITxTOTAL ETC)*;
proc sort data=hh1; by mon_yr location1 facility ;run;
Proc summary data=HH1;
class mon_yr Location1 year compliance;
output out=hhsummary;
run;
*** PROC SUMMARY FOR ALL NYUMC*;
proc sort data=hh1; by mon_yr nyumc year compliance  ;run;
Proc summary data=HH1;
class mon_yr nyumc year compliance;
output out=hhsummarynyumc;
run;
*** PROC SUMMARY FOR EACH FACILITY*;
proc sort data=hh1; by mon_yr facility year compliance  ;run;
Proc summary data=HH1;
class mon_yr facility year compliance;
output out=hhsummaryfac;
run;

*CHANGING VARIABLES SO FACILITY,NYUMC APPEND TO SAME DATASET;
data hhsummarynyumc;
set hhsummarynyumc;
Location1=nyumc;
run;
data hhsummaryfac;
set hhsummaryfac;
Location1=facility;
run;
***APPENDING TO CREATE SEPARATE REPORT FOR TOTALS;
proc append data=hhsummarynyumc base=hhsummaryfac force;run;


**** WHERE COMPLIANCE IS MISSING = NUMBER OBS (N) FOR THAT MONTH/YEAR;
data hhsummary1;
set hhsummary;
if compliance = . then compliance=3;
run;
data hhsummaryfac1;
set hhsummaryfac;
if compliance = . then compliance=3;
run;

***tRANSPOSING TO GET N,COMPLIANCE AND NON COMPLIANCE IN COMLUMNS TO CALCULATE PERCENT;
proc sort data=hhsummary1 nodup; by location1 mon_yr year compliance  ;run;
proc transpose data=hhsummary1 out=hhtrans; by location1 mon_yr year ;var _FREQ_;id compliance;run;

***CALCULATING PERCENT AND DELETING ROWS NOT USED (IE TOTAL FOR ALL YEARS COMBINED);
data hhfinal;
length monyr $15.;
set hhtrans;
where location1 ne " ";
percent=_1/_3;
if _1 = . and _3 ne . then percent= 0;
if _3 = . then percent = .;
format percent percent.2;
monyr=put(mon_yr,yymmd7.);
year1=compress(put(year,$15.))||"-Total";
if mon_yr = . then monyr=year1;
if mon_yr= . and year=. then delete;
*drop year year1;
run;
proc sort data=hhfinal nodupkey;by location1 monyr;run;

****DOING THE SAME FOR THE FACILITY TOTALS DATASET****;
proc sort data=hhsummaryfac1 nodup; by location1 mon_yr year compliance  ;run;
proc transpose data=hhsummaryfac1 out=hhtransfac; by location1 mon_yr year;var _FREQ_;id compliance;run;
data hhfinalfac;
length monyr $15.;
set hhtransfac;
percent=_1/_3;
if _1 = . and _3 ne . then percent= 0;
if _3 = . then percent = .;
format percent percent.2;
monyr=put(mon_yr,yymmd7.);
year1=compress(put(year,$15.))||"-Total";
if mon_yr = . then monyr=year1;
if mon_yr= . and year=. then delete;
*drop year year1;
run;
proc sort data=hhfinalfac nodupkey;by location1 monyr;run;

***FORMATS FOR <85% = RED USING PercentBMIgt30f, CAN ALWAYS BE RENAMED***;

ods tagsets.ExcelXP 
 options(sheet_name='9.Hand Hygiene') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');


proc report data=hhfinal nowd box;  
 column Location1  Monyr,( percent _3) shaderow;
 define Location1 /"Location" id group order=internal width=15; 
 define Monyr /across order=internal 'Month-Year';
 define _3 / "N" width=5 display;
 define percent / '%' style  (column) = [Foreground = compliancepct. ] ;
 define shaderow / noprint;
compute Shaderow;
cnt+1;
if mod(cnt,2) eq 1 then shadeit+1;
else  call
define(_row_,'style','style={background=graydd}');
endcomp;
 title1 'Hand Hygiene Compliance' ;
run ;
proc report data=hhfinalfac nowd box;
 column Location1  Monyr,( percent _3) shaderow;
 define Location1 /"Location" group order=internal width=15; 
 define Monyr /across order=formatted 'Month-Year';
 define _3 / "N" width=5 display;
 define percent / '%' style  (column) = [Foreground = compliancepct.] ;
 define shaderow / noprint;
compute Shaderow;
cnt+1;
if mod(cnt,2) eq 1 then shadeit+1;
else  call
define(_row_,'style','style={background=graydd}');
endcomp;
run ;



/*proc freq data=dazo1;table unit;where location1=' ';run;*/
data dazo;
set dazo.'dazo master table'n;
compliance1=upcase(Check_Status);
if compliance1="PASS" then compliance =1;
else if compliance1="FAIL" then compliance=2;
year=year(datepart(Date_Stamped));
qrt=Year||"-"||"0"||scan((substr(quarter,2)),1);
drop quarter;
run;
data dazo1;
length location1 $30.;
set dazo;
where compliance in (1,2) ;
location=compress(location);
quarter=compress(qrt);
if Unit ="12E" then Location1="TH 12 EAST";
if Unit ="12W" then Location1="TH 12 WEST";
if Unit ="12w" then Location1="TH 12 WEST";
if Unit ="13E" then Location1="TH 13 EAST";
if Unit ="13W" then Location1="TH 13 WEST";
if Unit ="14E" then Location1="TH 14 EAST";
if Unit ="14W" then Location1="TH 14 WEST";
if Unit ="15CCVCU" then Location1="TH 15 CCVCU";
if Unit ="15 CCVCU" then Location1="TH 15 CCVCU";
if Unit ="15E" then Location1="TH 15 EAST";
if Unit ="15ECCC" then Location1="TH 15 EAST";
if Unit ="15E/CCVCU" then Location1="TH 15 EAST";
if Unit ="15W" then Location1="TH 15 WEST";
if Unit ="16E" then Location1="TH 16 EAST";
if Unit ="16W" then Location1="TH 16 WEST";
if Unit ="17E" then Location1="TH 17 EAST";
if Unit ="17W" then Location1="TH 17 WEST";
if Unit ="6PACU" then Location1="TH 6 PACU";
if Unit ="6 PACU" then Location1="TH 6 PACU";
if Unit ="6RR/CU" then Location1="TH 6 PACU";
if Unit ="8W" then Location1="TH 8 WEST";
if Unit ="9E" then Location1="TH 9 EAST";
if Unit ="9W" then Location1="TH 9 PICU";
if Unit ="9W/NICU" then Location1="TH 9 NICU";
if Unit ="9W/PICU" then Location1="TH 9 PICU";
if Unit ="ER" then Location1="TH EMERGENCY";
if Unit ="HCC10" then Location1="TH 10 HCC";
if Unit ="HCC11" then Location1="TH 11 HCC";
if Unit ="HCC12" then Location1="TH 12 HCC";
if Unit ="HCC13" then Location1="TH 13 HCC";
if Unit ="HCC14" then Location1="TH 14 HCC";
if Unit ="HCC8" then Location1="TH 8 HCC";
if Unit ="HCC9" then Location1="TH 9 HCC";
if Unit ="HCC 10" then Location1="TH 10 HCC";
if Unit ="HCC 11" then Location1="TH 11 HCC";
if Unit ="HCC 12" then Location1="TH 12 HCC";
if Unit ="HCC 13" then Location1="TH 13 HCC";
if Unit ="HCC 14" then Location1="TH 14 HCC";
if Unit ="HCC 8" then Location1="TH 8 HCC";
if Unit ="HCC 9" then Location1="TH 9 HCC";
if Unit ="HJD10" then Location1="HJD 10 FLOOR";
if Unit ="HJD11" then Location1="HJD 11 FLOOR";
if Unit ="HJD 10" then Location1="HJD 10 FLOOR";
if Unit ="HJD 11" then Location1="HJD 11 FLOOR";
if Unit ="HJD11/SCU/SDU" then Location1="HJD 11 SCU/SDU";
if Unit ="HJD 11/SCU/SDU" then Location1="HJD 11 SCU/SDU";
if Unit ="HJD12" then Location1="HJD 12 FLOOR";
if Unit ="HJD12N" then Location1="HJD 12 FLOOR";
if Unit ="HJD12S" then Location1="HJD 12 FLOOR";
if Unit ="HJD8" then Location1="HJD 8 FLOOR";
if Unit ="HJD8N" then Location1="HJD 8 NORTH";
if Unit ="HJD8S" then Location1="HJD 8 SOUTH";
if Unit ="HJD9" then Location1="HJD 9 FLOOR";
if Unit ="HJD9N" then Location1="HJD 9 NORTH";
if Unit ="HJD9S" then Location1="HJD 9 SOUTH";
if Unit ="HJD 12" then Location1="HJD 12 FLOOR";
if Unit ="HJD12N" then Location1="HJD 12 FLOOR";
if Unit ="HJD12S" then Location1="HJD 12 FLOOR";
if Unit ="HJD 8" then Location1="HJD 8 FLOOR";
if Unit ="HJD 8N" then Location1="HJD 8 NORTH";
if Unit ="HJD 8S" then Location1="HJD 8 SOUTH";
if Unit ="HJD 9" then Location1="HJD 9 FLOOR";
if Unit ="HJD 9N" then Location1="HJD 9 NORTH";
if Unit ="HJD 9S" then Location1="HJD 9 SOUTH";
if Unit ="TH15E" then Location1="TH 15 EAST";
if Unit ="TH15ECC" then Location1="TH 15 EAST";
if Unit ="TH16" then Location1="TH 16 EAST";
if Unit ="TH9W" then Location1="TH 9 PICU";
if Unit ="16N" then delete;
*if location in('HJD10','HJD11','HJD11/SCU/SDU','HJD12','HJD8N','HJD8S','HJD9N','HJD9S') then Facility="HJD";
*else if Location in('12E','12W','13E','13W','14E','14W','16E','16W','17E','17W','9E','ER','HCC11','HCC12','HCC13','HCC14',
'HCC9') then Facility="TH";
*else Facility="TH";
*if location in('HJD10','HJD11','HJD11/SCU/SDU','HJD12','HJD8N','HJD8S','HJD9N','HJD9S') then ICU="Non-ICU";
*else if Location in('12E','12W','13E','13W','14E','14W','16E','16W','17E','17W','9E','ER','HCC11','HCC12','HCC13','HCC14',
'HCC9') then ICU="Non-ICU";
*else  ICU="ICU";
Facility=" "||compress(scan(Location1,1))||" TOTAL";
Nyumc="NYUMC TOTAL";
/*Month=compress(month);
if month='Jan' then Month1=01;
else if Month='Feb' then Month1=02;
else if Month='Mar' then Month1=03;
else if Month='Apr' then Month1=04;
else if Month='May' then Month1=05;
else if Month='Jun' then Month1=06;
else if Month='Jul' then Month1=07;
else if Month='Aug' then Month1=08;
else if Month='Sep' then Month1=09;
else if Month='Oct' then Month1=10;
else if Month='Nov' then Month1=11;
else if Month='Dec' then Month1=12;
month2= put( month1, z2.);
Mon_yr1=cat( '01',Month2,year);
mon_yr=input(mon_yr1,ddmmyy9.);
format mon_yr yymmd7.;*/
if Location1 = " " then delete;

run;
data dazo1;set dazo1;where  quarter= &currentquarter;run;
proc sort data=dazo1; by quarter location1 facility ;run;
Proc summary data=dazo1;
class quarter Location1 year compliance;
output out=dazosummary;
run;
*** PROC SUMMARY FOR ALL NYUMC*;
proc sort data=dazo1; by quarter nyumc year compliance  ;run;
Proc summary data=dazo1;
class quarter nyumc year compliance;
output out=dazosummarynyumc;
run;
*** PROC SUMMARY FOR EACH FACILITY*;
proc sort data=dazo1; by quarter facility year compliance  ;run;
Proc summary data=Dazo1;
class quarter facility year compliance;
output out=Dazosummaryfac;
run;

*CHANGING VARIABLES SO FACILITY,NYUMC APPEND TO SAME DATASET;
data Dazosummarynyumc;
set Dazosummarynyumc;
Location1=nyumc;
run;
data Dazosummaryfac;
set Dazosummaryfac;
Location1=facility;
run;
***APPENDING TO CREATE SEPARATE REPORT FOR TOTALS;
proc append data=Dazosummarynyumc base=Dazosummaryfac force;run;


**** WHERE COMPLIANCE IS MISSING = NUMBER OBS (N) FOR THAT MONTH/YEAR;
data Dazosummary1;
set Dazosummary;
if compliance = . then compliance=3;
run;
data Dazosummaryfac1;
set Dazosummaryfac;
if compliance = . then compliance=3;
run;

***tRANSPOSING TO GET N,COMPLIANCE AND NON COMPLIANCE IN COMLUMNS TO CALCULATE PERCENT;
proc sort data=Dazosummary1 nodup; by location1 quarter year compliance  ;run;
proc transpose data=Dazosummary1 out=Dazotrans; by location1 quarter year ;var _FREQ_;id compliance;run;

***CALCULATING PERCENT AND DELETING ROWS NOT USED (IE TOTAL FOR ALL YEARS COMBINED);
data Dazofinal;
*length monyr $15.;
set dazotrans;
where location1 ne " ";
percent=_1/_3;
if _1 = . and _3 ne . then percent= 0;
if _3 = . then percent = .;
format percent percent.2;
monyr=quarter;
year1=compress(put(year,$15.))||"-Total";
*if quarter = ' ' then monyr=year1;
*if quarter= ' ' and year = . then delete;
if Monyr = ' ' then delete;
*drop year year1;
run;
proc sort data=Dazofinal nodupkey;by location1 monyr;run;

****DOING THE SAME FOR THE FACILITY TOTALS DATASET****;
proc sort data=Dazosummaryfac1 nodup; by location1 quarter year compliance  ;run;
proc transpose data=Dazosummaryfac1 out=Dazotransfac; by location1 quarter year;var _FREQ_;id compliance;run;
data Dazofinalfac;
length monyr $15.;
set Dazotransfac;
percent=_1/_3;
if _1 = . and _3 ne . then percent= 0;
if _3 = . then percent = .;
format percent percent.2;
monyr=quarter;
year1=compress(put(year,$15.))||"-Total";
*if quarter = ' ' then monyr=year1;
*if quarter= ' ' and year=. then delete;
if Monyr = ' ' then delete;
*drop year year1;
run;
proc sort data=Dazofinalfac nodupkey;by location1 monyr;run;


ods tagsets.ExcelXP options(sheet_name='10.DAZO-Environmental Compliance') ;
 ods tagsets.ExcelXP options(sheet_interval = 'none');

proc report data=dazofinal nowd box; 
 column Location1  Monyr,( percent _3) shaderow;
 define Location1 /"Location" id group order=internal width=15; 
 define Monyr /across order=formatted 'Quarter-Year' width=15;
 define _3 / "N" width=5 display;
 define percent / '%' style  (column) = [Foreground = compliancepct. ] ;
 define shaderow / noprint;
compute Shaderow;
cnt+1;
if mod(cnt,2) eq 1 then shadeit+1;
else  call
define(_row_,'style','style={background=graydd}');
endcomp;
 title1 'Dazo Compliance' ;
run ;
proc report data=dazofinalfac nowd box;
 column Location1  Monyr,( percent _3) shaderow;
 define Location1 /"Location" group order=internal width=40; 
 define Monyr /across order=formatted 'Quarter-Year';
 define _3 / "N" width=5 display;
 define percent / '%' style  (column) = [Foreground = compliancepct. ] ;
 define shaderow / noprint;
compute Shaderow;
cnt+1;
if mod(cnt,2) eq 1 then shadeit+1;
else  call
define(_row_,'style','style={background=graydd}');
endcomp;
 title1 'Dazo Compliance' ;
run ;



*******CONTACT ISOLATION;


data hh2;
set hh1;
where Isolation_Compliance in (1,2);
run;
proc sort data=hh2; by mon_yr location1 facility ;run;
Proc summary data=HH2;
class mon_yr Location1 year Isolation_Compliance;
output out=contactsummary;
run;
*** PROC SUMMARY FOR ALL NYUMC*;
proc sort data=hh2; by mon_yr nyumc year Isolation_Compliance  ;run;
Proc summary data=HH2;
class mon_yr nyumc year Isolation_Compliance;
output out=contactsummarynyumc;
run;
*** PROC SUMMARY FOR EACH FACILITY*;
proc sort data=hh2; by mon_yr facility year Isolation_Compliance  ;run;
Proc summary data=HH2;
class mon_yr facility year Isolation_Compliance;
output out=contactsummaryfac;
run;

*CHANGING VARIABLES SO FACILITY,NYUMC APPEND TO SAME DATASET;
data contactsummarynyumc;
set contactsummarynyumc;
Location1=nyumc;
run;
data contactsummaryfac;
set contactsummaryfac;
Location1=facility;
run;
***APPENDING TO CREATE SEPARATE REPORT FOR TOTALS;
proc append data=contactsummarynyumc base=contactsummaryfac force;run;


**** WHERE COMPLIANCE IS MISSING = NUMBER OBS (N) FOR THAT MONTH/YEAR;
data contactsummary1;
set contactsummary;
if isolation_compliance = . then isolation_compliance=3;
run;
data contactsummaryfac1;
set contactsummaryfac;
if isolation_compliance = . then isolation_compliance=3;
run;

***tRANSPOSING TO GET N,COMPLIANCE AND NON COMPLIANCE IN COMLUMNS TO CALCULATE PERCENT;
proc sort data=contactsummary1 nodup; by location1 mon_yr year isolation_compliance  ;run;
proc transpose data=contactsummary1 out=contacttrans; by location1 mon_yr year ;var _FREQ_;id isolation_compliance;run;

***CALCULATING PERCENT AND DELETING ROWS NOT USED (IE TOTAL FOR ALL YEARS COMBINED);
data contactfinal;
length monyr $15.;
set contacttrans;
where location1 ne " ";
percent=_1/_3;
if _1 = . and _3 ne . then percent= 0;
if _3 = . then percent = .;
format percent percent.2;
monyr=put(mon_yr,yymmd7.);
year1=compress(put(year,$15.))||"-Total";
if mon_yr = . then monyr=year1;
if mon_yr= . and year=. then delete;
*drop year year1;
run;
proc sort data=contactfinal nodupkey;by location1 monyr;run;

****DOING THE SAME FOR THE FACILITY TOTALS DATASET****;
proc sort data=contactsummaryfac1 nodup; by location1 mon_yr year isolation_compliance  ;run;
proc transpose data=contactsummaryfac1 out=contacttransfac; by location1 mon_yr year;var _FREQ_;id isolation_compliance;run;
data contactfinalfac;
length monyr $15.;
set contacttransfac;
percent=_1/_3;
if _1 = . and _3 ne . then percent= 0;
if _3 = . then percent = .;
format percent percent.2;
monyr=put(mon_yr,yymmd7.);
year1=compress(put(year,$15.))||"-Total";
if mon_yr = . then monyr=year1;
if mon_yr= . and year=. then delete;
*drop year year1;
run;
proc sort data=contactfinalfac nodupkey;by location1 monyr;run;

/**/
/*ods listing;*/
/*ods tagsets.ExcelXP */
/*style=mystyle startpage=no file="G:\Infect Prevention\Data Management\IPC_Quarterly_Reports\GP&excel";*/
  ods tagsets.ExcelXP options(sheet_name='11.Isolation Precaution') ;
    ods tagsets.ExcelXP options(sheet_interval = 'none');

proc report data=contactfinal nowd box; where monyr ne " ";
*PUT COLUMNS IN ORDER TO APPEAR IF IN PARENTHESIS IT WILL GO A SUBCOLUMN BELOW PREVIOUS VARIABLE;
column Location1  Monyr,( percent _3) shaderow; 
 define Location1 /"Location" id group  order=internal width=15; *ID(REPEATS UNITS FOR EVERY PAGE IN REPORT)
 GROUP MEANS HOW YOU WAN TO GROUP THE DATA (ie BY UNITS IN THIS CASE)/PUT VARIABLE LABEL TO DISPLAY IN REPORT IN " "/
 ORDER = SORTING WITHIN PROC REPORT; 
 define Monyr /across order = formatted 'Month-Year' ; *ACROSS SAME AS COLUMNS;
 define _3 / "N" width=5 display;
 define percent / '%' style  (column) = [Foreground = compliancepct.] ; *ADDING CONDITIONAL FORMATING
 FROM FORMAT CODE BEFORE;
 define shaderow / noprint; *SHADEROW FOR ALTERNATING GREY ROWS;
compute Shaderow;
cnt+1;
if mod(cnt,2) eq 1 then shadeit+1;
else  call
define(_row_,'style','style={background=graydd}');
endcomp;
 title1 'Isolation Precaution' ;
run ;


proc report data=contactfinalfac nowd box;
 column Location1  Monyr,( percent _3) shaderow;
 define Location1 /"Location" id group order=internal width=15; 
 define Monyr /across order=formatted 'Month-Year';
 define _3 / "N" width=5 display;
 define percent / '%' style  (column) = [Foreground = compliancepct. ] ;
 define shaderow / noprint;
compute Shaderow;
cnt+1;
if mod(cnt,2) eq 1 then shadeit+1;
else  call
define(_row_,'style','style={background=graydd}');
endcomp;
 title1 'Isolation Precaution' ;
run ;


*************************SSI*******************;

Data Infections;
set ssi.Patient_DOSF;
If SSI_YN in ("Other", "N", "No", "N/A", "N/a", " ", "P") then delete;
Admitdate = datepart (Proc_Admit_date);
MRNDOSKey = compress(Patient_DOS_Key, " ,_");
Admitdatechar =put(Admitdate,yymmddn8.);
VisitIDCodeAD = (MRN||Admitdatechar);
VisitIDCodeAD = compress (VisitIDCodeAD, " ");
If SSI_Type =  "Sup Primary (SIP)" then SSIInfect = 1;
else If SSI_Type = "SIP" then SSIInfect = 1;
else If SSI_Type = "sip" then SSIInfect = 1;
else If SSI_Type = "Sup Secondary (SIS)" then SSIInfect = 2;
else If SSI_Type = "SIS" then SSIInfect = 2;
else if SSI_Type = "Deep Primary (DIP)" then SSIInfect = 3;
else if SSI_Type = "DIP" then SSIInfect = 3;
else if SSI_Type = "Organ Space (O/S)" then SSIInfect = 3;
else if SSI_Type = "Organ/Space" then SSIInfect = 3;
else if SSI_Type = "ORGAN/SPACE" then SSIInfect = 3;
else if SSI_Type = "Organ Space (O/S)" then SSIInfect = 3;
else if SSI_Type = "Organ/PJI" then SSIInfect = 3;
else if SSI_Type = "Organ" then SSIInfect = 3;
else if SSI_Type = "ORGAN/SPACE" then SSIInfect = 3;
else if SSI_Type = "OS" then SSIInfect = 3;
else if SSI_Type = "O/S" then SSIInfect = 3;
else if SSI_Type = "IAB" then SSIInfect = 3;
else if SSI_Type = "JNT" then SSIInfect = 3;
else if SSI_Type = "Deep Secondary (DIS)" then SSIInfect = 4;
else if SSI_Type = "DIS" then SSIInfect = 4;
else if SSI_Type = "MED" then SSIInfect = 3;
else if SSI_Type = " " then SSIInfect = 9;
else if SSI_Type = "Other (indicate in notes)" then SSIInfect = 9;
else SSIInfect = 9;
If SSIinfect in (3,4) then Deep = 1;
if SSIInfect in (1,2) then Superficial = 1;
If Deep = . then Deep1 = 0;
else Deep1 =1;
If Superficial = . then Super1 = 0;
else Super1 = 1;
If Deep = 1 or Superficial = 1 then Infect1 = 1;
else Infect1 = 0;
MRN1= compress (MRN);
MRN2 = put (MRN1, 8.);
drop mrn ;
if A_PDS_RF_RO in ("pds", "PDS", "Post-Discharge", "Post Discharge Surveillance", "P") then PDS = 1;
run;




********************Melinda! Can you help with creating a macro for this dataset?*****;

***Merge the infections to the procedure dataset to get extra information about patient*****;


Proc sort data = ags.procedures_&currentepsi ; by MRNDOSKEY; run;
*Proc sort data = ags.mergeddss_censusFinalBiandHK; *by MRNDOSKEY; *run;
Proc sort data= Infections nodupkey; by MRNDOSKEY SSIInfect; run;


Data NumAnalyze;
length Locationfix $36.;
merge Infections (in = a) ags.procedures_&currentepsi (in = b) ;
by MRNDOSKEY;
if b;
Performdate = datepart (Culture_date);
if Age <18 then agef = 0;
else if Age >= 18 then agef = 1;
else agef = age;
if LOCATIONf in (1, 9, 13) then LocationFix = "Cervical";
else if Locationf in (6) then Locationfix = "Cervical/dorsal/dorsolumbar";
else if Locationf = 5 then LocationFix = "Dorsal/dorsolumbar";
else if Locationf in (7,8) then LocationFix = "Lumbar/lumbrosacral";
else if Locationf = 12 then LocationFix = "Dorsal/dorsolumbar/Lumbar/lumbrosacral";
else if Locationf = 20 then LocationFix = "Cervical/dorsal/dorsolumbar/Lumbar/lumbrosacral";
else locationfix = " ";
if service in ("Neurosurg Spinal", "Neurosurgery", "Neurosurgery NYU", "Neurosurgery-Spine", "Surgery, Neuro", "Neurosur") then Dept2 = 'Neurosurgery';
else if Dept in ("Orthopaedic", "Orthopaedic Surgery" ) then Dept2 = 'Orthopaedic Surgery';
else if service in ("Surgery, Orthopedics", "Ortho Peds HJD", "Ortho SP/Scoliosis", "Orthopaed Surg Spine", "Orthopaedic A" , "Orthopaedic C" , "Orthopaedic Surgery, General",
"Orthopaedic Surgery, Pediatric", "Orthopedics NYU", "General Surgery HJD", "Orthopae") then Dept2 = 'Orthopaedic Surgery';
else if Hospital = "H" and (FUSN = 1 or RFUSN = 1 or LAM = 1) then Dept2 = 'Orthopaedic Surgery';
else if Department = 'Neurology' and (FUSN = 1 or RFUSN = 1 or LAM = 1)  then Dept2 = 'Neurosurgery';
else if Hospital = "T" and (FUSN = 1 or RFUSN = 1 or LAM = 1)  then Dept2 = 'Neurosurgery';
else dept2 = dept;
If NUM_LEVELf in (1) then NumLevel = 0;
else if NUM_LEVELf in (6, 5) then NumLevel = 1;
else if NUM_LEVELf in (12, 7) then NumLevel = 2;
else if NUM_LEVELf = . then NumLevel = .;
If dept2 = 'Neurosurgery' then NeuroDept = 1;
else if dept2 = 'Orthopaedic Surgery' or dept2 = "Orthopaedic" then NeuroDept = 0;
else NeuroDept = .;
Year1 = put (year, 4.);
run;

****Pull the "pending" infections from the new SSI DB****;

Data Pending_infections;
set ssi.Patient_DOSF;
where SSI_YN = "P";
Admitdate = datepart (Proc_Admit_date);
MRNDOSKey = compress(Patient_DOS_Key, " ,_");
Admitdatechar =put(Admitdate,yymmddn8.);
VisitIDCodeAD = (MRN||Admitdatechar);
VisitIDCodeAD = compress (VisitIDCodeAD, " ");
If SSI_Type =  "Sup Primary (SIP)" then SSIInfect = 1;
else If SSI_Type = "SIP" then SSIInfect = 1;
else If SSI_Type = "sip" then SSIInfect = 1;
else If SSI_Type = "Sup Secondary (SIS)" then SSIInfect = 2;
else If SSI_Type = "SIS" then SSIInfect = 2;
else if SSI_Type = "Deep Primary (DIP)" then SSIInfect = 3;
else if SSI_Type = "DIP" then SSIInfect = 3;
else if SSI_Type = "Organ Space (O/S)" then SSIInfect = 3;
else if SSI_Type = "Organ/Space" then SSIInfect = 3;
else if SSI_Type = "ORGAN/SPACE" then SSIInfect = 3;
else if SSI_Type = "Organ Space (O/S)" then SSIInfect = 3;
else if SSI_Type = "Organ/PJI" then SSIInfect = 3;
else if SSI_Type = "Organ" then SSIInfect = 3;
else if SSI_Type = "ORGAN/SPACE" then SSIInfect = 3;
else if SSI_Type = "OS" then SSIInfect = 3;
else if SSI_Type = "O/S" then SSIInfect = 3;
else if SSI_Type = "IAB" then SSIInfect = 3;
else if SSI_Type = "JNT" then SSIInfect = 3;
else if SSI_Type = "Deep Secondary (DIS)" then SSIInfect = 4;
else if SSI_Type = "DIS" then SSIInfect = 4;
else if SSI_Type = "MED" then SSIInfect = 3;
else if SSI_Type = " " then SSIInfect = 9;
else if SSI_Type = "Other (indicate in notes)" then SSIInfect = 9;
else SSIInfect = 9;
If SSIinfect in (3,4) then Deep = 1;
if SSIInfect in (1,2) then Superficial = 1;
If Deep = . then Deep1 = 0;
else Deep1 =1;
If Superficial = . then Super1 = 0;
else Super1 = 1;
If Deep = 1 or Superficial = 1 then Infect1 = 1;
else Infect1 = 0;
MRN1= compress (MRN);
MRN2 = put (MRN1, 8.);
drop mrn ;
if A_PDS_RF_RO in ("pds", "PDS", "Post-Discharge", "Post Discharge Surveillance", "P") then PDS = 1;
run;

****Get extra info by merging to procedure database*****;

Proc sort data = Pending_infections; by MRNDOSKEY; run;

Data Pending_infectionsProc;
merge Pending_infections (in = a) ags.procedures_&currentepsi (in = b);
by MRNDOSKEY;
if a;
run;



Data Numanalyze1 (keep = NHSN_EventID TimePeriod CSN HAR Deep1 Infect1 Super1 VisitIDCodeAD ICIS_OrderID date_of_service2 Proc_Discharge_date admit_date2 dob2 date_of_service2  Infect1 deep1 super1 FUSN RFUSN CRAN CBGB CBGC HPRO KPRO LAM VSHN COLO HYST PVBY OTH CV_VALVE SPRO EPRO APRO WPRO ARTHSCPY LVAD 
VisitDOSKey discharge_date2 DOB MRN VisitIDCode PatientNameCensus csn Culture_date MRNDOSKEY)   ;
set Numanalyze;
where date_of_service2 >= &currqtrstart and  date_of_service2 < &currqtrend and infect1 = 1;
run;



***Final line list for current quarter****;

Data SSI_LineList (keep = NHSN_EventID TimePeriod CSN HAR Deep1 Infect1 Super1 VisitIDCodeAD ICIS_OrderID date_of_service2 Discharge_date admit_date2 
 date_of_service2  Infect1 deep1 super1 FUSN RFUSN CRAN CBGB CBGC HPRO KPRO LAM VSHN COLO HYST PVBY OTH CV_VALVE SPRO EPRO APRO WPRO ARTHSCPY LVAD 
VisitDOSKey discharge_date2 DOB MRN VisitIDCode PatientNameCensus csn  MRNDOSKEY Date_of_Event dept department division surgeon_name 
patient_type dictation_code physician_NPI date_of_service ADT_Patient_Type)   ;
label
NHSN_EventID = "NHSN_EventID"
TimePeriod = "Time Period"
Date_of_Event = "Date_of_Event"
date_of_service2 = 'Procedure Date'
Discharge_date = 'Discharge Date'
admit_date2 = 'Admission Date'
dob = 'Date of Birth'
PatientNameCensus = 'Patient Name'
dept = 'Department_1'
department = 'Department_2'
division = 'Division'
surgeon_name = 'Surgeon name' 
CSN = "CSN"
HAR = "HAR";

set Numanalyze;
where date_of_service2 >= &currqtrstart and  date_of_service2 < &currqtrend and infect1 = 1;
run;




***Final line list for current and previous quarter potential cases****;


Data SSI_LineList_Potential (keep = NHSN_EventID TimePeriod CSN HAR Deep1 Infect1 Super1 VisitIDCodeAD ICIS_OrderID date_of_service2 Discharge_date admit_date2 
 date_of_service2  Infect1 deep1 super1 FUSN RFUSN CRAN CBGB CBGC HPRO KPRO LAM VSHN COLO HYST PVBY OTH CV_VALVE SPRO EPRO APRO WPRO ARTHSCPY LVAD 
VisitDOSKey discharge_date2 DOB MRN VisitIDCode PatientNameCensus csn  MRNDOSKEY Date_of_Event dept department division surgeon_name
patient_type dictation_code physician_NPI date_of_service ADT_Patient_Type)    ;
label
NHSN_EventID = "NHSN_EventID"
TimePeriod = "Time Period"
Date_of_Event = "Date_of_Event"
date_of_service2 = 'Procedure Date'
Discharge_date = 'Discharge Date'
admit_date2 = 'Admission Date'
dob = 'Date of Birth'
PatientNameCensus = 'Patient Name'
dept = 'Department_1'
department = 'Department_2'
division = 'Division'
surgeon_name = 'Surgeon name' 
CSN = "CSN"
HAR = "HAR";
set Pending_infectionsProc;
where date_of_service2 >= &prevqtrstart and date_of_service2 < &currqtrend ;
run;

********************************************************EXPORT SSI DATA*******************************************************************;
******************************************************************************************************************************************;
/*PROC EXPORT DATA= WORK.SSI_LINELIST 
            OUTFILE= "G:\Infect Prevention\Data Management\IPC_Quarterly
_Reports\&excel" 
            DBMS=EXCEL REPLACE;
     SHEET="13.SSI_LineList"; 
RUN;


PROC EXPORT DATA= WORK.SSI_LineList_Potential 
            OUTFILE= "G:\Infect Prevention\Data Management\IPC_Quarterly
_Reports\&excel" 
            DBMS=EXCEL REPLACE;
     SHEET="14.SSI_LineList_Potential"; 
RUN;
*/

ods listing;
ods tagsets.ExcelXP  options(sheet_name='13.SSI_LineList') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');

Proc print data=SSI_LINELIST  noobs label width=minimum ;var _ALL_;run;

ods listing;
ods tagsets.ExcelXP  options(sheet_name='14.SSI_LineList_Potential') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');

Proc print data=SSI_LineList_Potential   noobs label width=minimum ;var _ALL_;run;




*************************************************************************************************************;
*************************************************************************************************************************************;
*********************************Date of Last Infection***********************************************************************************;

************************************************************************************************************************************;
*************************************************************************************************************************************;


proc sql;
create table infections as
select *
from edw.nhsn_event as a
left join edw.nhsn_bsi_event as b
on a.event_id = b.event_id
left join edw.nhsn_event_criteria as c
on a.event_id = c.event_id
left join edw.nhsn_labid_event as d
on a.event_id = d.event_id;
quit;

/*proc freq data = infections; tables eventtype;run;*/

data infections2;
set infections;
where del_ind = "N";
if EVENT_TYPE in ('LABID', 'BSI', 'UTI');
eventtype2 = event_type;
*if onset ne 'HO' or MSSA = 'Y' or VRE = 'Y' or CEPHRKLEB = 'Y' or ACINE = 'Y' then delete;
if event_type = 'LABID' and CRE_E_COLI = 'Y' then eventtype2 = 'CREECOLI';
if event_type = 'LABID' and CRE_KLEB = 'Y' then eventtype2 = 'CREKLEB';
if event_type = 'LABID' and CDIFF = 'Y' then eventtype2 = 'CDIF';
if event_type = 'LABID' and MRSA = 'Y' then eventtype2 = 'MRSA';
key = compress (event_type||location);
eventdate2= datepart (event_date);
if eventdate2 <= &currqtrend;
format eventdate2 mmddyy10.;
run;


data infections3;
set infections2;
if location in ('1 NORTH') then location = 'RIRM 1 NORTH';
if location in ('1 SOUTH') then location = 'RIRM 1 SOUTH';
if location in ('10TH FLOOR') then location = 'HJD 10TH FLOOR';
if location in ('11 S') then location = 'HJD 11 SOUTH';
if location in ('11 SCU') then location = 'HJD 11 SCU';
if location in ('11 SDU') then location = 'HJD 11 SDU';
if location in ('11 E', '11E') then location = 'TH 11 EAST';
if location in ('12 E') then location = 'TH 12 EAST';
if location in ('12 N') then location = 'HJD 12 NORTH';
if location in ('12 S') then location = 'HJD 12 SOUTH';
if location in ('12 WEST') then location = 'TH 12 WEST';
if location in ('12TH FLOOR') then location = 'HJD 12TH FLOOR';
if location in ('13E') then location = 'TH 13 EAST';
if location in ('14 E') then location = 'TH 14 EAST';
if location in ('14W') then location = 'TH 14 WEST';
if location in ('15 CCVCU') then location = 'TH 15 CCVCU';
if location in ('15 E - CCC', 'SICU') then location = 'TH 15 ECCC';
if location in ('15 W', '15 W - CCC', 'MICU') then location = 'TH 15 WCCC';
if location in ('16 E', '16 EAST') then location = 'TH 16 EAST';
if location in ('16 W') then location = 'TH 16 WEST';
if location in ('17 E') then location = 'TH 17 EAST';
if location in ('17 E SDU') then location = 'TH 17 EAST SDU';
if location in ('17 W') then location = 'TH 17 WEST';
if location in ('17 W SDU') then location = 'TH 17 WEST SDU';
if location in ('4 W') then location = 'RIRM 4 WEST';
if location in ('5 S') then location = 'RIRM 5 SOUTH';
if location in ('8 E') then location = 'TH 8 EAST';
if location in ('8 N') then location = 'HJD 8 NORTH';
if location in ('8 S') then location = 'HJD 8 SOUTH';
if location in ('8 W') then location = 'TH 8 WEST';
if location in ('9 E') then location = 'TH 9 EAST';
if location in ('9 N') then location = 'HJD 9 NORTH';
if location in ('9 S') then location = 'HJD 9 SOUTH';
if location in ('CARD REHAB', 'HCC 9') then location = 'TH HCC 9';
if location in ('COBBLE HIL') then location = 'TH CH EMERG DEPT';
if location in ('CV PACU') then location = 'TH 6 CVSCU';
if location in ('HCC 10') then location = 'TH HCC 10';
if location in ('HCC 11') then location = 'TH HCC 11';
if location in ('HCC 12') then location = 'TH HCC 12';
if location in ('HCC 13') then location = 'TH HCC 13';
if location in ('NICU') then location = 'TH 9 NICU';
if location in ('NSICU') then location = 'TH 12 WEST NSICU';
if location in ('PERELMAN') then location = 'TH EMERGENCY DEPT';
if location in ('PICU') then location = 'TH 9 PICU';
if location in ('TPU') then location = 'TH 14 TPU';
if location in ('5 SOUTH') then location = 'RIRM 5 SOUTH';
if location in ('4 WEST') then location = 'RIRM 4 WEST';
key = compress(event_type||location);
if location in ('CCU', 'CVCU', 'RIRM 1 NORTH', 'RIRM 1 SOUTH', 'RIRM 4 WEST', 'RIRM 5 SOUTH') then delete;
keep key eventdate2 eventtype2 location;
run;

proc sort data = infections3; by key descending eventdate2; run;
/*proc freq data = infections3; table event_location; run;*/

data infections4;
set infections3;
by key descending eventdate2;
if first.key then flag = 1; else flag = 0;
if flag = 0 then delete;
run;

proc sort data = infections4; by eventtype2; run;
ods listing;
ods tagsets.ExcelXP 
 options(sheet_name='15.Date since last infection') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');

proc report data=infections4 nowd box;where eventtype2 ne "LABID";
column  location (eventdate2),eventtype2 shaderow;
define location /  group style(column) = [cellwidth=2in];
define eventtype2 /  order = internal across ' ' style(column) = [cellwidth=1in];
define eventdate2 / ' ' style(column) = [cellwidth=1.5in] display;
define shaderow / noprint;
title "Date since Last Infection - Updated %sysfunc(date(),MMDDYYD.)";
run;

***sheet for sir;
data SIR;
input SIR $50.;
datalines;
Add Table from NHSN
;
run;

ods listing;
ods tagsets.ExcelXP 
 options(sheet_name='16.SIR-CAUTI,CLABSI') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');
	proc print data=SIR noobs;run;

******************LEAN6********************************;

data cvclean;
length lean lean1 leantype leantype1 $30.;
set denom.denom_cvc;
where date >= &currqtrstart and date <= &currqtrend;
mon_yr=date;
format mon_yr yymmd7.;
year=year(mon_yr);
devicedate=date;
format devicedate date9.;
if unit in ("TH 15 ECCC",
"TH 15 CCVCU",
"TH 15 WCCC" ,
"TH 6 CVSCU" ,
"TH 9 NICU"  ,
"TH 9 PICU" ,
"TH 14 TPU",
"TH 12 NSICU") then delete;
if cvc_type1 in (1) then leantype=" PICC";
else if cvc_type1 in (7,9,11) then leantype=" Tunneled/Implanted";
else if cvc_type1 in (3,5) then leantype=" Percutaneous/Intro";
else if cvc_type1 in (13,15,17,19,21) then leantype="Other/CVC";
if cvc_type2 in (1) then leantype1=" PICC";
else if cvc_type2 in (7,9,11) then leantype1=" Tunneled/Implanted";
else if cvc_type2 in (3,5) then leantype1=" Percutaneous/Intro";
else if cvc_type2 in (13,15,17,19,21) then leantype1="Other/CVC";
if FACILITY = ('TISCH') then Lean="non-ICU (TH)";
else if FACILITY = ('HJD') then Lean="non-ICU (South)";
if unit in ("TH 16 EAST","TH 16 BMT") then Lean1="non-ICU (Heme-Onc North)";
key1=mrn1||DeviceDate;
run;

proc freq data=cvclean;tables lean*leanType/out=test noprint;run;
proc freq data=cvclean;tables lean*leantype1/out=test1 noprint;run;
data test2;
set test1;
number=count;
drop count;
run;
/*proc sort data= test ; by lean cvc_type1;run;*/
/*proc transpose data=test out=tran;by lean;var count;ID cvc_type1;run;*/
/*proc sort data= test2; by lean cvc_type1;run;*/
/*proc transpose data=test2 out=tran2;by lean;var count;ID cvc_type1;run;*/
proc sql;
create table merge as select *
from test as a
full join test2 as b
on a.lean=b.lean and a.leantype=b.leantype1;
quit;

data lean6;
set merge;
days=count+number;
if days=. then days=count;
if leatype= " " then leantype=leantype1;
run;
proc freq data=cvclean;tables lean/out=total noprint;run;
data total1;
set total;
leantype="Total";
days=count;
run;
******************;
proc freq data=cvclean;tables lean1*leanType/out=testH noprint;run;
proc freq data=cvclean;tables lean1*leantype1/out=test1H noprint;run;
data test2H;
set test1H;
number=count;
drop count;
run;
/*proc sort data= test ; by lean cvc_type1;run;*/
/*proc transpose data=test out=tran;by lean;var count;ID cvc_type1;run;*/
/*proc sort data= test2; by lean cvc_type1;run;*/
/*proc transpose data=test2 out=tran2;by lean;var count;ID cvc_type1;run;*/
proc sql;
create table mergeH as select *
from test2H as a
left join testH as b
on a.lean1=b.lean1 and a.leantype1=b.leantype;
quit;

data lean6H;
length lean $30.;
set mergeH;
days=count+number;
if days=. then days=count;
lean=lean1;
if leatype= " " then leantype=leantype1;
run;
proc freq data=cvclean;tables lean1/out=totalH noprint;run;
data total1H;
length lean $30.;
set totalH;
leantype="Total";
days=count;
lean=lean1;
run;

data lean6A;
set lean6 total1 lean6H total1H;
if lean = ' ' then delete;
run;

data clabsilist;
length unit $30.;
set edw.nhsn_event;
where event_type = 'BSI' and del_ind ='N';
if location =	"8 E"	then Unit=	"TH 8 EAST"	;
if location =	"9 E"	then Unit=	"TH 9 EAST"	;
if location =	"15 E - CCC"	then Unit=	"TH 15 ECCC"	;
if location =	"14 E"	then Unit=	"TH 14 EAST"	;
if location =	"17 E"	then Unit=	"TH 17 EAST"	;
if location =	"15 W - CCC"	then Unit=	"TH 15 WCCC"	;
if location =	"16 E"	then Unit=	"TH 16 EAST"	;
if location =	"HCC 11"	then Unit=	"TH HCC 11"	;
if location =	"TPU"	then Unit=	"TH 14 TPU"	;
if location =	"13E"	then Unit=	"TH 13 EAST"	;
if location =	"17 W"	then Unit=	"TH 17 WEST"	;
if location =	"8 W"	then Unit=	"TH 8 WEST"	;
if location =	"CARD REHAB"	then Unit=	"TH HCC 9"	;
if location =	"14W"	then Unit=	"TH 14 WEST"	;
if location =	"PICU"	then Unit=	"TH 9 PICU"	;
if location =	"15 CCVCU"	then Unit=	"TH 15 CCVCU"	;
if location =	"12 WEST"	then Unit=	"TH 12 WEST"	;
if location =	"11E"	then Unit=	"TH 11 EAST"	;
if location =	"16 EAST"	then Unit=	"TH 16 BMT"	;
if location =	"12 E"	then Unit=	"TH 12 EAST"	;
if location =	"NSICU"	then Unit=	"TH 12 NSICU"	;
if location =	"HCC 13"	then Unit=	"TH HCC 13"	;
if location =	"16 W"	then Unit=	"TH 16 WEST"	;
if location =	"HCC 12"	then Unit=	"TH HCC 12"	;
if location =	"NICU"	then Unit=	"TH 9 NICU"	;
if location =	"HCC 10"	then Unit=	"TH HCC 10"	;
if location =	"17 W SDU"	then Unit=	"TH 17 WEST-SDU"	;
if location =	"11 SDU"	then Unit=	"HJD 11 SDU"	;
if location =	"12TH FLOOR"	then Unit=	"HJD 12 FLOOR"	;
if location =	"9 S"	then Unit=	"HJD 9 SOUTH"	;
if location =	"11 S"	then Unit=	"HJD 11 FLOOR"	;
if location =	"9 N"	then Unit=	"HJD 9 NORTH"	;
if location =	"8 S"	then Unit=	"HJD 8 SOUTH"	;
if location =	"8 N"	then Unit=	"HJD 8 NORTH"	;
if location =	"11 SCU"	then Unit=	"HJD 11 SCU"	;
if location =	"CV PACU"	then Unit=	"TH 6 CVSCU"	;
if unit in ("TH 15 ECCC",
"TH 15 CCVCU",
"TH 15 WCCC" ,
"TH 6 CVSCU" ,
"TH 9 NICU"  ,
"TH 9 PICU" ,
"TH 14 TPU",
"TH 12 NSICU") then delete;
facility= scan(unit,1);
if FACILITY = ('TH') then Lean="non-ICU (TH)";
else if FACILITY = ('HJD') then Lean="non-ICU (South)";
if unit in ("TH 16 EAST","TH 16 BMT") then Lean1="non-ICU (Heme-Onc North)";
/*mon_yr=input(eventdate,date9.);*/
/*format mon_yr yymmd7.;*/
event_date=datepart(event_date);
format event_date date9.;
if event_date >=&currqtrstart and event_date <= &currqtrend;
eventid= compress(put(event_id, $15.));
run;

proc sort data=Clabsi.cvc_Lines  out=clabsilines; by visitidcodead infectionstatusline;run;
proc sort data=Clabsi.clabsi_micro out=clabsimicro; by visitidcodead infectionstatusmicro;run;
Data InfectionsAccess;
Merge clabsiLines(in=a) clabsimicro (in=b);
by VisitIDCodeAd;
run;
proc sort data=aca1.infections ;by aca_key1 aca_key2;run;
proc sort data=aca1.infections ;by descending anon_key event_date ;run;
data inf_confirm;
set infectionsaccess;
where infectionstatusmicro in ("Infect_1", "Infect_2");
*keep event_id mbi device_description device_comments insertion_date removal_date sex dob event_date reviewed_date event_location fullname Patient_Mrn reviewed_by admission_Date  infectionstatusmicro performeddtm orgname;

run;
proc sort data=inf_confirm nodupkey; by patient_mrn admission_date infectionstatusmicro performeddtm event_id;run;

proc sql;
create table linelist as
select *
from clabsilist as a
left join inf_confirm as b
on a.eventid=b.event_id;
quit;
proc sort data=linelist nodupkey; by patient_mrn admission_date infectionstatusmicro performeddtm event_id;run;

data devicetype;
length type $30.;
set linelist;
where infectionstatusline ne "No";
if prxmatch('m/PICC /io',device_description) >0 then type=" PICC";
else if prxmatch('m/Tunneled |implanted /io',device_description) >0 then type=" Tunneled/Implanted";
else if prxmatch('m/Pecutaneous |Intro /io',device_description) >0 then type=" Percutaneous/Intro";
else type="Other/CVC";
if eventid = ' ' then delete;
keep type unit facility lean lean1;
run;

proc freq data= devicetype;table lean*type/out=type noprint ;run;

proc freq data= devicetype;table lean1*type/out=type1 noprint ;run;
proc freq data= devicetype;table lean1/out=type3 noprint ;run;
proc freq data= devicetype;table lean/out=type4 noprint ;run;
data type;
set type;
infection=count;
run;
data type1;
length lean2 $30.;
set type1;
if lean1 = ' ' then delete;
infection1=count;
lean2 = lean1;
drop lean1;
run;

data type3;
length lean2 $30.;
set type3;
if lean1 = ' ' then delete;
infection1=count;
lean2 = lean1;
type="Total";
drop lean1;
run;
data type4;
set type4;
infection=count;
type="Total";
run;
proc append data=type3 base = type1 force;run;
proc append data=type4 base = type force;run;
proc sql;
create table finallean6 as
select *
from lean6A as a
full join type as b
on a.lean=b.lean and a.leantype=b.type;
quit;


proc sql;
create table finallean6A as
select *
from finallean6 as a
left join type1 as b
on a.lean1=b.lean2 and a.leantype=b.type;
quit;

data finallean6AB;
set finallean6A;
if days=. then days=number;
if infection=. then infection=infection1;
if infection=. then infection=0;
rate = infection/days*1000;
format rate 3.1;
if days = . then days=0;
if rate=. then rate=0.0;
if lean1=' ' then lean1=lean;
run;



ods listing;
ods tagsets.ExcelXP 
 options(sheet_name='17.Lean6') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');

proc report data=finallean6AB nowd box; 
 column lean1 leantype,(infection days rate) shaderow;
 define lean1 /" " id group order=internal width=15; 
 define leantype /across order=internal ' ';
 define days / "Days" width=3 display;
 define Infection / "Cases" width=3 display;
 define Rate / 'Rate' display ;
 define shaderow / noprint;
run ;




*************************************************************************************************************************;
*************************************************************************************************************************;
**Spine Fusion Rates Adults - Primary for AMP ***************************************************************************;


Proc Summary Data = Numanalyze;
where (FUSN = 1 or RFUSN = 1 or lam = 1) and agef = 1 ;
Class TimePeriod ;
Var Deep1 Super1 Infect1 ;
Output out = Sum_Infections_Spine
(rename = _freq_ = Procedures)
sum (Deep1) = sumDeep1
sum (Super1) = sumSuper1
sum (Infect1) = sumInfect1;
run;

Data Spine_Summary (drop=  _TYPE_ year);
set Sum_Infections_Spine;
where TimePeriod ^= " "  ;
RateDeep = (SumDeep1/Procedures)*100;
RateDeep = round (RateDeep ,.1);
RateSuper = (SumSuper1/Procedures)*100;
RateSuper = round (RateSuper ,.1);
RateInfect = (SumInfect1/Procedures)*100;
RateInfect = round (RateInfect ,.1);
Years = put (Year, 4.);
*format agef ageff. Revisionf Revisionff.;
run;


ods listing;
ods tagsets.ExcelXP 
 options(sheet_name='18.AMP - Spine fusion') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');

Proc Report data = Spine_Summary headline headskip nowd 
STYLE (HEADER) = [Foreground = Black Font_weight = Bold Font_size = 8pt];
COLUMN TimePeriod Procedures sumDeep1 sumSuper1 SumInfect1 RateDeep RateSuper RateInfect Shaderow;
define TimePeriod / 'TimePeriod' ;
Define SumDeep1 /'Deep/Infections';
Define SumSuper1 /'Super/Infections';
Define SumInfect1 /'Overall/Infections';
Define RateDeep /'Rate of/Deep Infections';
Define RateSuper /'Rate of/Super Infections';
Define RateInfect /'Rate of/Overall Infections';
Title 'FUSN Rates, Adults - Primary';
define shaderow / noprint;
compute Shaderow;
cnt+1;
if mod(cnt,2) eq 1 then shadeit+1;
else  call
define(_row_,'style','style={background=graydd}');
 endcomp;
run;

*******************************************************;
*******DISCHARGE DISPOSITION************************************************;
proc sql;
	create table transfers as 
			select distinct  /*'distinct' eliminates duplicate encounters*/
			e.MedicalRecordNumber as MRN   
			,e.PatientAccount as Encounter
			,e.CustomPatientType as Patient_Type
			,e.dob 							
			,e.AdmissionDate as admitdate			
			,e.DischargeDate as dischargedate		
			,e.LastName
			,e.FirstName 
			,e.LOS
			,e.DischargeDisposition as discharge_disposition
			,e.sex
			,e.race
			,ext.userfield14 as CSN
			,ext.userfield13 as HAR
			,ext.UserField45 as department
			,ext.UserField46 as division 
			,ext.UserField36 as HIC_Medicare_Number 
			,d.description as dischargedisposition_desc
			
			from shad.V_PAT_ENCOUNTER as e         
			left join shad.T_ENCOUNTER_CPT as cpt on e.PatientAccount=cpt.PatientAccount 				
			left join shad.V_ENCOUNTER_EXT as ext on e.PatientAccount = ext.PatientAccount
			left join shad.T_IP_Encounter as ip on e.PatientAccount = ip.PatientAccount
			left join shad.T_discharge_disposition as d on e.dischargedisposition = d.dischargedisposition
		where (e.TotalCharges > 0) 
		and (datepart(e.dischargedate) >= &currqtrstart and datepart(e.dischargedate) <= &currqtrend)
		and e.dischargedisposition not in ('01', '1', '06', '20', , '312', '40', '41', '42', '50', , '51', '6',
'EX', 'HH', 'HM', 'HO', 'HT', 'IV', 'XH',  '41', 'SF', 'SL', 'XH', 'XM', 'XU'); /*these cover discharged to home, died, or discharge to home health service/hospice.*/
		quit;

data transfers2;
set transfers;
where patient_type in ('TI', 'HI');
discharge_dt = datepart (dischargedate);
format discharge_dt mmddyy10.;
discharge = put (discharge_dt, yymmddn8.);
mrn2 = input (mrn, 7.);
mrn3 = put (mrn2, 7.);
mrnisokey = compress (mrn3||discharge);
Lastn = scan (Lastname, 1, ', ');
Firstn1 = scan (Lastname, 2, ', ');
length Firstn $1.;
Firstn = substr(FirstN1, 1, 1);
misskey = compress (Lastn||FirstN||discharge);
discharge_mon = month (discharge_dt);
if discharge_mon in (1, 2, 3) then discharge_qtr = 1;
if discharge_mon in (4, 5, 6) then discharge_qtr = 2;
if discharge_mon in (7, 8, 9) then discharge_qtr = 3;
if discharge_mon in (10, 11, 12) then discharge_qtr = 4;
run;

/*proc freq data = transfers2; tables Patient_Type*discharge_mon Patient_Type*discharge_qtr / nocol norow nopercent; run;*/
data iso1 (keep = mrn1 mrnisokey misskey patient department isolation_status date);
set iso.Iso_dec2012topresent;
where isolation_dt >= &currqtrstart and isolation_dt <= &currqtrend;
Lastn = scan (Pat_name, 1, ', ');
Firstn = scan (Pat_name, 2, ', ');
Firstinitial = substr(firstn, 1, 1);
mrn2 = input (mrn, 7.);
mrn1 = put (mrn2, 7.);
isodate = put (isolation_Dt, yymmddn8.);
mrnisokey = compress (mrn1||isodate);
misskey = compress (upcase(lastn)||upcase(Firstinitial)||isodate);
rename pat_name = patient unit = department isolation_dt = date isolation_description = isolation_status;
run;

/*proc freq data = iso.Iso_dec2012topresent; tables isolation_dt; run;*/

proc sql;
create table isodischarge as
select *
from iso1 as a
inner join transfers2 (keep = mrn patient_type dob admitdate discharge_dt lastname los discharge_disposition 
sex dischargedisposition_desc mrnisokey discharge_mon discharge_qtr mrn3) as b
on a.mrn1= b.mrn3
where (b.discharge_dt - 1) <= a.date <= b.discharge_dt;
quit;


data iso3;
set isodischarge;
rename date = isolation_date;
drop patient;
if discharge_mon in (1, 2, 3) then discharge_qtr = 1;
else if discharge_mon in (4, 5, 6) then discharge_qtr = 2;
else if discharge_mon in (7, 8, 9) then discharge_qtr = 3;
else if discharge_mon in (10, 11, 12) then discharge_qtr = 4;
drop mrn3 mrnisokey misskey mrn1 patient_type los discharge_disposition;
run;

proc sort data = iso3 nodupkey out = iso4; by _all_; run;


ods listing;
ods tagsets.ExcelXP 
 options(sheet_name='19.AMP - Discharge Disposition') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');

Proc print data=iso4 noobs label width=minimum ;var _ALL_;run;



*******************************************************;
*******NICU MRSA SCREENING************************************************;

proc sql;							
create table Patient_History as							
select *							
from pda.Scpm_patient_transfer as a							
left join pda.Scpm_patient (keep= PATIENT_MRN FULLNAME PATIENT_KEY sex dob)as b  							
on a.PATIENT_KEY=b.PATIENT_KEY
where a.patient_class = "Inpatient" and datepart (a.admission_date) >= &currqtrstart 
and datepart (a.admission_date) <= &currqtrend and a.department_name = ('TH 9 NICU')
and datepart(a.admission_date) = datepart(a.transfer_date);
quit;

Data Patient_History1;
set Patient_History;
admitdate = datepart (ADMISSION_DATE) ;
transferdate = datepart (transfer_DATE) ;
format admitdate yymmdd10.;
admitmonth = month (admitdate);
if admitmonth in (1, 2, 3) then admitqtr = 1;
else if admitmonth in (4, 5, 6) then admitqtr = 2;
else if admitmonth in (7, 8, 9) then admitqtr = 3;
else if admitmonth in (10, 11, 12) then admitqtr = 4;
Admitdatechar =put(admitdate,yymmddn8.);
MRN1=prxchange('s/^0+//o ',1,PATIENT_MRN);
VisitIDCodeAD = (MRN1||Admitdatechar);
VisitIDCodeAD = compress (VisitIDCodeAD, " ");
mrn = input (patient_mrn, 7.);
mrn1 = put (mrn, 7.);
drop mrn patient_mrn;
run;

proc sort data = patient_history1 nodupkey out = patient_history_dedup; by mrn1 admitdate transferdate; run;

* Don't really need this in code below...

OrderName in  ("MRSA SCREEN BY PCR", "MRSA Screen by PCR", "MRSA/MSSA by PCR", "MRSA/MSSA Screen by Culture", "MRSA/MSSA SCREEN BY CULTURE", 
"MRSA Screen by Culture", "Nose Culture w/Gram Stain", "MRSA/MSSA SCREEN BY PCR", "MRSA SCREEN", "MRSA SCREEN BY CULTURE", "MRSA/MSSA SCREEN", "MRSA/MSSA SCREEN BY CULTURE", 
"MRSA/MSSA SCREEN BY PCR", "NOSE CULTURE W GRAM STAIN", "NOSE CULTURE WITH GRAM STAIN", "MRSA SCREEN") and;

data allstaph;
set micro.microdballyears;
where   MRSATestResult1 in (2,3)
and performdate >= &currqtrstart and performdate <= &currqtrend and orderlocation = 'TH 9 NICU';
csn2 = put (csn, 9.);
run;

proc sql;
create table MRSAcensus as
select *
from allstaph (keep = orderlocation service ptname mrn ordername organism resultvalue
orderid admitdate dischargedate performdate qtr year mrsatestresult1 ptclass csn2) as a
left join patient_history_dedup (keep = account_number sex dob) as b on a.csn2 = b.account_number;
quit;

proc sort data = mrsacensus out = mrsacensus2 nodupkey; by account_number orderid; run;

data nicumrsa_export;
retain mrn ptname sex dob admitdate service performdate orderlocation ordername resultvalue qtr year account_number;
set mrsacensus2;
drop csn2  ptclass mrsatestresult1 orderid organism dischargedate;
run;


ods listing;
ods tagsets.ExcelXP 
 options(sheet_name='20.AMP - NICU MRSA') ;

    ods tagsets.ExcelXP options(sheet_interval = 'none');

Proc print data=nicumrsa_export noobs label width=minimum ;var _ALL_;run;



ods tagsets.ExcelXP close;;
ods listing close;

libname	syndrom	clear;
libname	shad	clear;
libname	pdadev	clear;
libname	pda	clear;
libname	epsi	clear;
libname	surgery	clear;
libname	micro	clear;
libname	ags	clear;
libname	Iso	clear;
libname	cvc	clear;
libname	Foley	clear;
libname	vent	clear;
libname	vent1	clear;
libname	daily	clear;
libname	whonet	clear;
libname	edw	clear;
libname	tsia	clear;
LIBNAME	SSI	clear;
Libname	CAUTI	clear;
Libname	CLABSI	clear;
libname	OtptSurv	clear;
libname	dash	clear;
libname	dllfinal	clear;
libname	pdaexpor	clear;
Libname	DAZO	clear;
Libname	aca1	clear;

