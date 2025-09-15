/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: DM.SAS  
*
* Program Type: SDTM
*
* Purpose: To produce DM
* Usage Notes: 
*
* SAS  Version: 9.4
* Operating System: Windows 2003 R2 Standard Edition.                   
*
* Author: 
* Date Created: 
* Modification History:
*******************************************************************/          
libname SDTM "C:\C1\ST\Jul2022\CL\SDTM_US";
options nofmterr;
libname raw "C:\C1\ST\Jul2022\CL\RAW";

PROC DATASETS LIB=WORK KILL;
RUN;
QUIT;

/*STUDYID  AAA-2022*/
/*DOMAIN   Set to 'DM'*/
/*USUBJID  Set to Concatenation of STUDYID and DM.SUBNUM.*/
/*SUBJID   Set to DM.SUBJID or extract from SUBNUM*/
/*BRTHDTC   Set to DM.BRTHDAT in IS0 8601 Format*/
/*AGE Set to DM.AGE*/


data dm1;
   /*if variable name in raw data set and SDTM is same then first we rename the raw variable*/
   set raw.dm (rename=(age=agex sex=sexx race=racex ETHNIC=ETHNICX));
   LENGTH ETHNIC $200.;
   STUDYID="AAA-2022";
   DOMAIN='DM';
   SITEID=SITENUM;
   SUBJID=substr(subnum,4);
   USUBJID= strip (STUDYID)||"-"||strip (SITEID)||"-"||strip(SUBJID);

   /*convert to character*/
   BRTHDTC= put (BRTHDAT,IS8601DA.);
   /*if variable name in raw data set and SDTM is same then first we rename the raw variable*/
   AGE=AGEX;
   AGEU="YEARS";
   SEX=sexx;
   RACE= RACEX;
   /*Set to DM.ETHNIC and adjust value per Controlled Terminology*/

   IF ETHNICX='HISP' THEN ETHNIC='HISPANIC OR LATINO';
      ELSE IF ETHNICX='NHISP' THEN ETHNIC='NOT HISPANIC OR LATINO';
      ELSE IF ETHNICX='U' THEN ETHNIC='UNKNOWN';
      ELSE IF ETHNICX='DECLINED TO ANSWER' THEN ETHNIC='NOT REPORTED';

   KEEP STUDYID DOMAIN SITEID SUBJID USUBJID BRTHDTC AGE AGEU SEX RACE ETHNIC;
run;
PROC SORT;BY USUBJID;RUN;

DATA IC;
   SET RAW.IC;
   STUDYID="AAA-2022";
   DOMAIN='DM';
   SITEID=SITENUM;
   SUBJID=substr(subnum,4);
   /*   common join variable*/
   USUBJID= strip (STUDYID)||"-"||strip (SITEID)||"-"||strip(SUBJID);
   RFICDTC1= PUT (ICDAT,YYMMDD10.);
   /*Set to IC.ICDAT*/

   RFICDTC= PUT (ICDAT,is8601da.);
   KEEP USUBJID RFICDTC ;
RUN;
PROC SORT;BY USUBJID;RUN;

DATA DS;
   SET RAW.DS;
   STUDYID="AAA-2022";
   DOMAIN='DM';
   SITEID=SITENUM;
   SUBJID=substr(subnum,4);
   USUBJID= strip (STUDYID)||"-"||strip (SITEID)||"-"||strip(SUBJID);
   IF DSDTHDAT NE . THEN DTHDTC = PUT (DSDTHDAT,YYMMDD10.);
   IF DTHDTC NE '' THEN DTHFL='Y';
   IF DSLVDAT NE . THEN   RFPENDTC= PUT (DSLVDAT,YYMMDD10.);
   KEEP USUBJID DTHDTC DTHFL RFPENDTC;
RUN;

PROC SORT;BY USUBJID;RUN;

DATA EX;
   SET RAW.EX;
   STUDYID="AAA-2022";
   DOMAIN='DM';
   SITEID=SITENUM;
   SUBJID=substr(subnum,4);
   USUBJID= strip (STUDYID)||"-"||strip (SITEID)||"-"||strip(SUBJID);

   IF EXSTDAT NE . THEN DO;
      RFXSTDTC=PUT (EXSTDAT,YYMMDD10.)||"T"||PUT (EXSTTIM,TOD8.);
      RFSTDTC=PUT (EXSTDAT,YYMMDD10.)||"T"||PUT (EXSTTIM,TOD8.);

      RFXENDTC=PUT (EXSTDAT,YYMMDD10.)||"T"||PUT (EXSTTIM,TOD8.);
      RFENDTC=PUT (EXSTDAT,YYMMDD10.)||"T"||PUT (EXSTTIM,TOD8.);
   END;
   KEEP USUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC;
RUN;
PROC SORT;BY USUBJID RFSTDTC;RUN;

PROC SORT NODUPKEY;BY USUBJID;RUN;
/*@32.56*/
DATA TRT;
   SET RAW.DUMMY_RND;
   LENGTH ARMCD ACTARMCD $8. ARM ACTARM $200.;
   STUDYID="AAA-2022";
   DOMAIN='DM';

   SITEID=SUBSTR(USUBJID,12,3);
   SUBJID=substr(USUBJID,15);
   USUBJID= strip (STUDYID)||"-"||strip (SITEID)||"-"||strip(SUBJID);


   ARMCD=TRTCD;
   IF ARMCD='TQ' THEN ARM='TQU';
   IF ARMCD='PLACEBO' THEN ARM='PLACEBO';

   ACTARMCD=TRTCD;
   IF ACTARMCD='TQ' THEN ACTARM='TQU';
   IF ACTARMCD='PLACEBO' THEN ACTARM='PLACEBO';

   KEEP USUBJID ARMCD ARM ACTARMCD ACTARM;
RUN;
PROC SORT;BY USUBJID;RUN;

DATA SCF;
   SET RAW.DAT_SUB;
   STUDYID="AAA-2022";
   DOMAIN='DM';
   SITEID=SITENUM;
   SUBJID=substr(subnum,4);
   USUBJID= strip (STUDYID)||"-"||strip (SITEID)||"-"||strip(SUBJID);

   IF STATUSID=15 THEN DO;
   ARMNRS='SCREEN FAILURE';
   ACTARMUD='SCREEN FAILURE';
   END;

   KEEP USUBJID ARMNRS ACTARMUD;
RUN;
PROC SORT;BY USUBJID;RUN;


DATA FINAL;
   MERGE DM1 (IN=A) IC DS EX TRT SCF;
   BY USUBJID;
   IF A;
   IF ARM='ASSIGNED, NOT TREATED' AND ACTARM EQ '' THEN DO;
      ARMNRS='NOT ASSIGNED';
   END;
   COUNTRY='USA';
RUN;


DATA FINAL1;
RETAIN
STUDYID
DOMAIN
USUBJID
SUBJID
RFSTDTC
RFENDTC
RFXSTDTC
RFXENDTC
RFICDTC
RFPENDTC
DTHDTC
DTHFL
SITEID
BRTHDTC
AGE
AGEU
SEX
RACE
ETHNIC
ARMCD
ARM
ACTARMCD
ACTARM
ARMNRS
ACTARMUD
COUNTRY;
SET FINAL;
KEEP
STUDYID
DOMAIN
USUBJID
SUBJID
RFSTDTC
RFENDTC
RFXSTDTC
RFXENDTC
RFICDTC
RFPENDTC
DTHDTC
DTHFL
SITEID
BRTHDTC
AGE
AGEU
SEX
RACE
ETHNIC
ARMCD
ARM
ACTARMCD
ACTARM
ARMNRS
ACTARMUD
COUNTRY
;
RUN;

/*APPLY ATTRIBUTES AND SAVE IN PERMENANT LIB*/

DATA SDTM.DM_ (LABEL='Demographics');
SET FINAL1;
RUN;
