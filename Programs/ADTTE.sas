/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: ADTTE.SAS  
*
* Program Type: ADAM
*
* Purpose: To produce ADTTE
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

DATA ADSL;
   SET ADAM.ADSL;
RUN;

PROC SORT;BY USUBJID;RUN;

/*Fever Symptom*/
/*" when ADVS.PARAMCD='TEMP' and ADVS.ADY > =1*/
PROC SORT DATA=ADAM.ADVS OUT=ADVS (KEEP=USUBJID ADT ADY AVISITN AVISIT   PARAMCD TRTSDT AVAL);
   BY USUBJID AVISITN AVAL;
   WHERE PARAMCD='TEMP' and ADY GE 1;
RUN;

PROC SORT;BY USUBJID AVAL AVISITN;RUN;
/*GET MAXIMUM SEVERITY RECORD*/

DATA MAXSEV;
   SET ADVS;
   BY USUBJID AVAL AVISITN ;

   IF LAST.USUBJID;
RUN;


/*CNSR*/
/*"Set to 0 if subject has a record when ADVS.PARAMCD='TEMP' and ADVS.ADY > =1*/
/*else set to null"*/
/**/
/*AVAL*/
/*Set to ADVS.ADY if CNSR=0 */
/**/
/*EVNTDESC*/
/*"Set to 'Maximum Temperature ' if CNSR=0*/
/*Otherwise set to null"*/
/**/
/*ADT*/
/*Set to Analysis Date ADVS.ADT of the first occurrence of maximum severity Where ADVS.PARAMCD='TEMP'*/

DATA COMB;
   MERGE ADSL (IN=A) MAXSEV (IN=B);
   BY USUBJID;
   IF A ;

   IF B THEN DO;
      CNSR=0;
      AVAL=ADY;
      EVNTDESC='Maximum Temperature';
   END;

   IF A AND NOT B THEN DO;
      ADT=.;
      AVAL=.;
      CNSR=.;
      EVNTDESC='';
   END;
RUN;

/*PARAMCD*/
/*FEVERSYM*/
/**/
/*PARAM*/
/*Fever Symptom*/
/**/
/*PARAMN*/
/*1*/
/**/
/*PARCAT1*/
/*Time to Event*/
/**/
/*PARAMTYP*/
/*Set to 'DERIVED'*/
/**/
/*AVALU*/
/*Set to 'DAYS'*/
/**/
/*STARTDT*/
/*ADSL.TRTSDT*/
/**/
/*ADTF - no missing imputation done so set to missing*/
/**/
/*ANL01FL*/
/*Set to 'Y' */

DATA COMB1;
   SET COMB;
   length paramcd $8. param $200.;

   PARAMCD='FEVERSYM';
   PARAM='Fever Symptom';
   PARAMN=1;
   PARCAT1='Time to Event';
   PARAMTYP='DERIVED';
   AVALC='';
   AVALU='DAYS';
   STARTDT=TRTSDT;
   ADTF='';
   ANL01FL='Y';
RUN;

/*Elevated Respiratory Rate Symptom*/

/*when ADVS.PARAMCD='RESP' and ADVS.ADY > =1*/
PROC SORT DATA=ADAM.ADVS OUT=ADVS1 (KEEP=USUBJID ADT ADY AVISITN AVISIT PARAMCD TRTSDT AVAL);
   BY USUBJID AVISITN AVAL;
   WHERE PARAMCD='RESP' and ADY GE 1;
RUN;

PROC SORT;BY USUBJID AVAL AVISITN;RUN;

/*GET MAXIMUM SEVERITY RECORD*/

DATA MAXSEV1;
   SET ADVS1;
   BY USUBJID AVAL AVISITN ;

   IF LAST.USUBJID;
RUN;

DATA COMB;
   MERGE ADSL (IN=A) MAXSEV1 (IN=B);
   BY USUBJID;
   IF A ;

   IF B THEN DO;
      CNSR=0;
      AVAL=ADY;
      EVNTDESC='Maximum Respiratory Rate';
   END;

   IF A AND NOT B THEN DO;
      ADT=.;
      AVAL=.;
      CNSR=.;
      EVNTDESC='';
   END;
RUN;

DATA COMB2;
   SET COMB;
   length paramcd $8. param $200.;

   PARAMCD='ERESPSYM';
   PARAM='Elevated Respiratory Rate Symptom';
   PARAMN=2;
   PARCAT1='Time to Event';
   PARAMTYP='DERIVED';
   AVALC='';
   AVALU='DAYS';
   STARTDT=TRTSDT;
   ADTF='';
   ANL01FL='Y';
RUN;

data all;
   set comb1 comb2;
   STARTDTF='';
   CNSDTDSC='';
   format STARTDT date9.;
run;

proc sort;by usubjid paramn;run;

data final;
set all;
keep
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
ITTFL
PPROTFL
RANDFL
TRT01P
TRT01PN
TRT01A
TRT01AN
TRTSDT
TRTEDT
PARAM
PARAMN
PARAMCD
PARCAT1
PARAMTYP
AVAL
AVALU
STARTDT
STARTDTF
ADT
ADTF
ADY 
CNSR
EVNTDESC
CNSDTDSC
ANL01FL
;
run;

/*apply attributes per specs */
DATA ADTTE (LABEL="Time to Event Analysis Dataset");
   SET final;
RUN;
