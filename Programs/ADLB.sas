﻿/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: ADLB.SAS  
*
* Program Type: ADAM
*
* Purpose: To produce ADLB
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


/*COPY ALL THE VARIABLES FROM LB AND SUPPLB*/

DATA LB1;
   SET SDTM.LB;
RUN;
PROC SORT;BY USUBJID LBSEQ;RUN;


DATA SUPPLB;
   SET SDTM.SUPPLB;
   LBSEQ= INPUT (IDVARVAL,BEST.);
RUN;

PROC SORT;BY USUBJID LBSEQ;RUN;

PROC TRANSPOSE DATA=SUPPLB OUT=SUPPLB_TRANS;
   BY USUBJID LBSEQ;
   ID QNAM;
   VAR QVAL;
   IDLABEL QLABEL;
RUN;


DATA LB2;
   MERGE LB1 (IN=A) SUPPLB_TRANS (IN=B);
   BY USUBJID LBSEQ;
   IF A ;
RUN;

DATA LB3;
   LENGTH STUDYID $20.;
   MERGE LB2 (IN=A DROP=ARM ACTARM) ADAM.ADSL (IN=B);
   BY USUBJID;
   IF A AND B;
RUN;

DATA LB4;
   SET LB3;
   PARCAT1=LBCAT;

   /*   AVISIT    Set to LB.VISIT where LB.VISIT does not contain "Unscheduled Visit", and assign the visits (including unscheduled visits) with LB.LBBLFL="Y" to "Baseline".*/
   /**/
   /*   AVISITN   Set to LB.VISITNUM where LB.VISIT does not contain "Unscheduled Visit".*/

   IF INDEX (VISIT,"UNSCHEDULED")=0 THEN DO;
      AVISIT = VISIT;
      AVISITN =VISITNUM;
   END;

   IF LBBLFL EQ 'Y' THEN DO;
      AVISIT='Baseline';
      AVISITN=1;
   END;
   /*PARAM  "Concatenate LB.LBTEST and LB.LBSTRESU with "" "" if LBSTRESU is not missing;*/
   /*if LBSTRESU='' then LBTEST;"*/
   IF LBSTRESU NE '' THEN DO;
      PARAM=STRIP (LBTEST)||" ("|| STRIP (LBSTRESU)||")";
   END;

   IF LBSTRESU EQ '' THEN DO;
      PARAM=STRIP (LBTEST);
   END;


   PARAMCD=LBTESTCD;

   ANRLO=LBSTNRLO;
   ANRHI=LBSTNRHI;
   ANRIND=LBNRIND;

RUN;
PROC SORT;BY LBTESTCD;RUN;
PROC SORT DATA=LB1 OUT=PARAMCD (KEEP=LBTESTCD) NODUPKEY;
   BY LBTESTCD;
RUN;

DATA PARAMCD;
   SET PARAMCD;
   PARAMN=_N_;
RUN;

DATA LB5;
   MERGE LB4 (IN=A) PARAMCD (IN=B);
   BY LBTESTCD;
   IF A;
RUN;

DATA LB6;
   SET LB5;

   AVALC =LBSTRESC;
   AVAL = LBSTRESN;


   /*ADTM   "Set to Date/Time of Specimen Collection [LB.LBDTC] converted to numeric datetime."*/
   /*ADT    Set to date part of ADLB.ADTM*/
   /*ATM    Set to time part of ADLB.ADTM*/
   IF LBDTC NE '' THEN DO;
      ADT= INPUT( SUBSTR (LBDTC,1,10),YYMMDD10.);
      ADTM= INPUT (LBDTC,IS8601DT.);
      ATM= TIMEPART (ADTM);
      FORMAT ADT DATE9. ADTM DATETIME20. ATM TIME8.;

   END;

   /*ADY    "Set to date part of the non-imputed Date/Time of Specimen Collection [LB.LBDTC] converted to a numeric date minus */
   /*the date part of Datetime of First Exposure to Treatment [ADSL.TRTSDTM]. If the result is equal or greater than 0, */
   /*one day is added. Possible values are .., -2, -1, 1, 2, .. (no day zero is possible). */
   /*Else set to null, if the day, month and/or year of Date/Time of Specimen Collection [LB.LBDTC] or Datetime of First */
   /*Exposure to Treatment  [ADSL.TRTSDTM] is missing."*/
   NEW1= ADT;
   NEW2= TRTSDT;

   FORMAT NEW1 NEW2 DATE9.;

   IF NEW1 NE . AND NEW2 NE . THEN DO;

      IF NEW1 >= NEW2 THEN DO;
         ADY= (NEW1-NEW2)+1;
      END;


      IF NEW1 < NEW2 THEN DO;
         ADY= (NEW1-NEW2);
      END;
   END;


RUN;


/*BASELINE*/

/**/
/*BASE   "For baseline and post-baseline reocrds only:*/
/*set to the analysis value [ADLB.AVAL] identified as baseline (Baseline Record Flag [ADLB.ABLFL]  = 'Y') */
/*for each subject [ADLB.USUBJID] and parameter [ADLB.PARAMCD]."*/

/*BASEC  "For baseline and post-baseline reocrds only:*/
/*set to the analysis value [ADLB.AVALC] identified as baseline (Baseline Record Flag [ADLB.ABLFL]  = 'Y') */
/*for each subject [ADLB.USUBJID] and parameter [ADLB.PARAMCD] . "*/

/*BNRIND "For baseline and post-baseline reocrds only:*/
/*set to the analysis value [ADLB.ANRIND] identified as baseline (Baseline Record Flag [ADLB.ABLFL]  = 'Y') */
/*for each subject [ADLB.USUBJID] and parameter [ADLB.PARAMCD]. "*/

/*CHG    "Set to Analysis Value [ADLB.AVAL] minus Baseline Value [ADLB.BASE] Populate post-baseline records only"*/

/*PCHG   Set to ADLB.CHG/ADLB.BASE*100 for Post-baseline records. If BASE is not missing or BASE ne 0*/

DATA ADLB2;
   SET LB6;

   IF ADT NE . AND ADT <= TRTSDT AND (AVAL NE . OR AVALC NE '');
RUN;
PROC SORT;BY USUBJID PARAMN PARAM LBSEQ ADT ADTM;RUN;

DATA ADLB3;
   SET ADLB2;
   BY USUBJID PARAMN PARAM LBSEQ ADT ADTM;
   IF LAST.PARAMN;
   KEEP USUBJID PARAMN AVISITN;
RUN;
PROC SORT;BY USUBJID PARAMN AVISITN;RUN;


PROC SORT DATA=LB6;BY USUBJID PARAMN AVISITN;RUN;

/*ABLFL  Set to 'Y' for the last observation prior to Time 0 where AVAL/AVALC is non-missing, for each subject and parameter[ADLB.PARAMCD]. */

DATA LB7;
   MERGE LB6 (IN=A) ADLB3 (IN=B);
   BY USUBJID PARAMN AVISITN;
   IF A AND B THEN ABLFL="Y";
RUN;
PROC SORT DATA=LB7;BY USUBJID PARAMN AVISITN ADT ADTM;RUN;

DATA LB8;
   LENGTH BASEC BNRIND $100.;
   SET LB7;
   BY USUBJID PARAMN AVISITN ADT ADTM;

   RETAIN BASE BASEC BNRIND;

   IF FIRST.PARAMN THEN BASE=.;
   IF FIRST.PARAMN THEN BASEC=.;
   IF FIRST.PARAMN THEN  BNRIND=.;

   IF ABLFL EQ 'Y' THEN DO;
      BASE=AVAL;
      BASEC=AVALC;
      BNRIND=LBNRIND;

   END;

   ELSE DO;
      IF AVAL NE . AND BASE NE . THEN CHG=AVAL-BASE; 
      PCHG= ((AVAL-BASE)/BASE)*100;
   END;

   TRTP=TRT01P;
   TRTPN=TRT01PN;

   TRTA=TRT01A;
   TRTAN=TRT01AN;

   /*ANL01FL   Set to 'Y' if scheduled visits*/

   ANL01FL='Y';
   IF INDEX (VISIT,"UNSCHEDULED") >0 THEN DO;ANL01FL='';END;

RUN;

DATA TEST;
SET LB8;
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
ITTFL
PPROTFL
RANDFL
TRTP
TRTPN
TRTA
TRTAN
TRTSDTM
TRTSDT
TRTEDTM
TRTEDT
ADTM 
ADT 
ATM 
ADY 
PARCAT1 
PARAM 
PARAMN
PARAMCD 
AVAL
AVALC 
ABLFL 
BASE 
BASEC 
CHG 
PCHG 
ANRLO
ANRHI
ANRIND
BNRIND
VISITNUM 
VISIT 
AVISIT 
AVISITN 
ANL01FL
;
RUN;

DATA ADLB (LABEL="Laboratory Analysis Dataset");
   SET TEST;
RUN;
