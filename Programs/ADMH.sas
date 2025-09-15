/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: ADMH.SAS  
*
* Program Type: ADAM
*
* Purpose: To produce ADMH
* Usage Notes: 
*
* SAS  Version: 9.4
* Operating System: Windows 2003 R2 Standard Edition.                   
*
* Author: 
* Date Created: 
* Modification History:
*******************************************************************/          
libname SDTM "C:\C1\ST\Jul2022\CL\SDTM";
libname ADAM "C:\C1\ST\Jul2022\CL\ADAM datasets";

PROC DATASETS LIB=WORK KILL;
RUN;
QUIT;

OPTION VALIDVARNAME=UPCASE;


/*COPY ALL THE VARIABLES FROM DM AND SUPPDM*/

DATA MH1;
   SET SDTM.MH;
RUN;

/*to bring required columns from suppmh*/
DATA SUPPMH;
   SET SDTM.SUPPMH;
   MHSEQ= INPUT (IDVARVAL,BEST.);
RUN;

PROC SORT;BY USUBJID MHSEQ;RUN;

PROC TRANSPOSE DATA=SUPPMH OUT=SUPPMH_TRANS;
   BY USUBJID MHSEQ;
   ID QNAM;
   VAR QVAL;
   IDLABEL QLABEL;
RUN;


DATA MH2;
   MERGE MH1 (IN=A) SUPPMH_TRANS (IN=B);
   BY USUBJID MHSEQ;
   IF A ;
RUN;

/*bring required variables from adsl*/
DATA MH3;
   LENGTH MHPRIOR $10.;
   MERGE MH2 (IN=A DROP=ARM ACTARM) ADAM.ADSL (IN=B);
   BY USUBJID;
   IF A AND B;
   /*MHPRIOR*/
   /*"Set to ""Past"" ADMH.MHENRF equals to 'BEFORE'.*/
   /*Set to ""Current""  when ADMH.MHENRF equals to 'ONGOING' "*/

   IF MHENRF='BEFORE' THEN MHPRIOR='Past';
   IF MHENRF='ONGOING' THEN MHPRIOR='Current';

RUN;


DATA MH4;
SET MH3;
KEEP
STUDYID
USUBJID
SUBJID
SITEID
AGE
AGEU
SEX
RACE
ETHNIC
COUNTRY
SAFFL
TRT01P
TRT01PN
TRT01A
TRT01AN
TRTSDT
TRTEDT
MHSEQ
MHCAT
MHREL
MHPRIOR
MHTERM
MHDECOD
MHBODSYS
MHSTDTC
MHSTDY
MHENDTC
MHENDY
MHENRF
MHONGO
;
RUN;



proc sql noprint;
create table admh as
select
STUDYID  label="Study Identifier"         ,
USUBJID  label="Unique Subject Identifier"         ,
SUBJID   label="Subject Identifier for the Study"        ,
SITEID   label="Study Site Identifier"       ,
AGE   label="Age"       ,
AGEU  label="Age Units"       ,
SEX   label="Sex"       ,
RACE  label="Race"         ,
ETHNIC   label="Ethnicity"       ,
COUNTRY  label="Country"         ,
SAFFL label="Safety Population Flag"         ,
TRT01P   label="Planned Treatment for Period 01"         ,
TRT01PN  label="Planned Treatment for Period 01 (N)"        ,
TRT01A   label="Actual Treatment for Period 01"       ,
TRT01AN  label="Actual Treatment for Period 01 (N)"         ,
TRTSDT   label="Date of First Exposure to Treatment" length=   8  ,
TRTEDT   label="Date of Last Exposure to Treatment" length= 8  ,
MHSEQ label="Sequence Number" length=  8  ,
MHCAT label="Category for Medical History"         ,
MHREL label="Is the condition related to COVID-19?" length= 200   ,
MHPRIOR  label="Past/Current Event" length=  10 ,
MHTERM   label="Reported Term for the Medical History"         ,
MHDECOD  label="Dictionary-Derived Term   "     ,
MHBODSYS label="Body System or Organ Class"        ,
MHSTDTC  label="Start Date/Time of Medical History Event "     ,
MHSTDY   label="Study Day of Start of Observation"       ,
MHENDTC  label="End Date/Time of Medical History Event"        ,
MHENDY   label="Study Day of End of Observation"         ,
MHENRF   label="End Relative to Reference Period"        ,
MHONGO   label="Ongoing?"
from MH4;
quit;
run;  

DATA ADMH (LABEL="Medical History Analysis Dataset");
   SET admh;
RUN;



