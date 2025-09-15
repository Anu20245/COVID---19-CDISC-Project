/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: CM.SAS  
*
* Program Type: SDTM
*
* Purpose: To produce CM
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
options nofmterr;
libname raw "C:\C1\ST\Jul2022\CL\RAW";

PROC DATASETS LIB=WORK KILL;
RUN;
QUIT;

DATA CM1;
   SET RAW.CM (RENAME=(CMTRT=CMTRTX CMINDC=CMINDCX CMROUTE=CMROUTEX CMDOSE=CMDOSEX));
   CMTRT=CMTRTX;
   CMINDC=CMINDCX;
   CMROUTE=CMROUTEX;
   CMDOSE=CMDOSEX;

   /*not required for this data*/
   IF CMDOSE EQ . THEN CMDOSTXT= PUT (CMDOSEX,BEST.);
   IF CMTRT NE '';




   _YY= SCAN (CMSTDAT,1,'-');
   _MM = SCAN (CMSTDAT,2,'-');
   _DD =SCAN (CMSTDAT,3,'-');

   IF _YY='UNK' THEN _YY='';
   IF _MM='UNK' THEN _MM='';
   IF _DD='UNK' THEN _DD='';

   IF CMSTTIM='U' THEN CMSTTIM='';
   IF CMSTTIM NE '' THEN DO;
   CMSTDTC = CATX ("-",_YY,_MM,_DD)||"T"||STRIP (CMSTTIM);END;

   IF CMSTTIM EQ '' THEN DO;
   CMSTDTC = CATX ("-",_YY,_MM,_DD);
   END;

   _YY= SCAN (CMENDAT,1,'-');
   _MM = SCAN (CMENDAT,2,'-');
   _DD =SCAN (CMENDAT,3,'-');

   IF CMENTIM='U' THEN CMENTIM='';

   IF _YY='UNK' THEN _YY='';
   IF _MM='UNK' THEN _MM='';
   IF _DD='UNK' THEN _DD='';

   IF CMENTIM NE '' THEN DO;
   CMENDTC = CATX ("-",_YY,_MM,_DD)||"T"||STRIP (CMENTIM);END;


   IF CMENTIM EQ '' THEN DO;
   CMENDTC = CATX ("-",_YY,_MM,_DD);
   END;

   IF CMONGO EQ 'X' THEN CMENRF='ONGOING' ;
   IF CMONGO EQ '' THEN CMENRF="BEFORE";

   /*CMDECOD is the standardized medication/therapy term derived by the sponsor from the coding dictionary. It is expected that the reported term */
   /*(CMTRT) or the modified term (CMMODIFY) will be coded using a standard dictionary. */
   CMDECOD= STRIP (PREFERRED_NAME);

   CMCAT='CONCOMITANT MEDICATION';

   CMDOSU=CMDOSEU;
   if CMDOSU="APPL" then CMDOSU="APPLICATION";
   CMDOSFRQ=CMFREQ;


      STUDYID  =  'AA-2020-06'; 
      if SUBNUM ne ' ' then USUBJID = strip(STUDYID)||'-'||strip(SUBNUM);

   DOMAIN='CM';
   SITEID=SITENUM;
   SUBJID=substr(subnum,4);


RUN;



/*Concomitant PROCEDURES*/
DATA CM1_P;
   SET RAW.CMP (RENAME=(CMTRT=CMTRTX CMINDC=CMINDCX));
   CMTRT=CMTRTX;
   CMINDC=CMINDCX;
   IF CMTRT NE '';


   _YY= SCAN (CMSTDAT,1,'-');
   _MM = SCAN (CMSTDAT,2,'-');
   _DD =SCAN (CMSTDAT,3,'-');

   IF _YY='UNK' THEN _YY='';
   IF _MM='UNK' THEN _MM='';
   IF _DD='UNK' THEN _DD='';

   IF CMSTTIM='U' THEN CMSTTIM='';
   IF CMSTTIM NE '' THEN DO;
   CMSTDTC = CATX ("-",_YY,_MM,_DD)||"T"||STRIP (CMSTTIM);END;

   IF CMSTTIM EQ '' THEN DO;
   CMSTDTC = CATX ("-",_YY,_MM,_DD);
   END;

   _YY= SCAN (CMENDAT,1,'-');
   _MM = SCAN (CMENDAT,2,'-');
   _DD =SCAN (CMENDAT,3,'-');

   IF CMENTIM='U' THEN CMENTIM='';

   IF _YY='UNK' THEN _YY='';
   IF _MM='UNK' THEN _MM='';
   IF _DD='UNK' THEN _DD='';

   IF CMENTIM NE '' THEN DO;
   CMENDTC = CATX ("-",_YY,_MM,_DD)||"T"||STRIP (CMENTIM);END;


   IF CMENTIM EQ '' THEN DO;
   CMENDTC = CATX ("-",_YY,_MM,_DD);
   END;

   IF CMONGO EQ 'X' THEN CMENRF='ONGOING' ;
   IF CMONGO EQ '' THEN CMENRF="BEFORE";

   CMDECOD= STRIP (PT_TERM);

   CMCAT='PROCEDURE';

      STUDYID  =  'AA-2020-06'; 
      if SUBNUM ne ' ' then USUBJID = strip(STUDYID)||'-'||strip(SUBNUM);

   DOMAIN='CM';
   SITEID=SITENUM;
   SUBJID=substr(subnum,4);

RUN;

DATA CM2;
   SET CM1 CM1_P;
RUN;


*EPOCH;;
PROC SORT DATA=CM2;
   BY USUBJID;
RUN;




*EPOCH;;
DATA CM22;
   LENGTH epoch $200 domain $2;
   MERGE SDTM.SE(WHERE=(taetord=1) RENAME=(sestdtc=scrnst seendtc=scrnend) KEEP=usubjid taetord sestdtc seendtc)
        SDTM.SE(WHERE=(taetord=2) RENAME=(sestdtc=cycle1st seendtc=cycle1end) KEEP=usubjid taetord sestdtc seendtc)
        SDTM.SE(WHERE=(taetord=3) RENAME=(sestdtc=ltfupst seendtc=ltfupend) KEEP=usubjid taetord sestdtc seendtc)
        CM2(in=a);
   BY usubjid;
   IF a;
   IF ltfupst^='' & substr(ltfupst,1,10)<=substr(CMSTDTC,1,10)<=SUBSTR(ltfupend,1,10) THEN EPOCH='FOLLOW-UP';
      ELSE IF cycle1st^='' & substr(cycle1st,1,10)<=substr(CMSTDTC,1,10)<=SUBSTR(cycle1end,1,10) THEN EPOCH='TREATMENT';
      ELSE IF scrnst^='' & SUBSTR(scrnst,1,10)<=substr(CMSTDTC,1,10)<=SUBSTR(scrnend,1,10) THEN EPOCH='SCREENING';
RUN;



*DY;
proc sort data=sdtm.dm out=dm1 nodupkey;by usubjid;run;
DATA DM1;
SET dm1;
RFSTDTC_N = DATEPART (INPUT (RFSTDTC,??IS8601DT.));

FORMAT RFSTDTC_N YYMMDD10.;
KEEP USUBJID RFSTDTC_N;
RUN;



DATA CM4;
   MERGE CM22(in=a)
        DM1(IN=b KEEP=USUBJID  RFSTDTC_N );
   BY USUBJID;
   IF a & b;   
   CMSTDTC_N = INPUT (CMSTDTC,??YYMMDD10.);
    CMENDTC_N = INPUT (CMENDTC,??YYMMDD10.);

/*   Study day of start of medication relative to the sponsor-defined RFSTDTC.*/
   IF CMSTDTC_N NE . AND RFSTDTC_N NE . THEN DO;
   IF CMSTDTC_N >= RFSTDTC_N THEN CMSTDY= CMSTDTC_N - RFSTDTC_N +1;
   ELSE IF CMSTDTC_N < RFSTDTC_N THEN CMSTDY = CMSTDTC_N - RFSTDTC_N;
   END;

/*Study day of end of medication relative to the sponsor-defined RFSTDTC. */
   IF CMENDTC_N NE . AND RFSTDTC_N NE . THEN DO;
   IF CMENDTC_N >= RFSTDTC_N THEN CMENDY= CMENDTC_N - RFSTDTC_N +1;
   ELSE IF CMENDTC_N < RFSTDTC_N THEN CMENDY = CMENDTC_N - RFSTDTC_N;
   END;

RUN;

*SEQ;;
PROC SORT DATA=CM4 out=CM5;
   BY STUDYID USUBJID CMTRT CMSTDTC
;
RUN;

DATA CM6;
   SET CM5;
   BY STUDYID USUBJID CMTRT CMSTDTC;
   IF first.usubjid THEN CMSEQ=1;
      ELSE CMSEQ+1;
RUN;

DATA FINAL;
RETAIN

STUDYID
DOMAIN
USUBJID
CMSEQ
/*CMSPID*/
CMTRT
CMDECOD
CMCAT
CMINDC
CMDOSE
CMDOSTXT
CMDOSU
CMDOSFRQ
CMROUTE
EPOCH
CMSTDTC
CMENDTC
CMSTDY
CMENDY
CMENRF;
SET CM6;
KEEP
STUDYID
DOMAIN
USUBJID
CMSEQ
/*CMSPID*/
CMTRT
CMDECOD
CMCAT
CMINDC
CMDOSE
CMDOSTXT
CMDOSU
CMDOSFRQ
CMROUTE
EPOCH
CMSTDTC
CMENDTC
CMSTDY
CMENDY
CMENRF
;
RUN;
