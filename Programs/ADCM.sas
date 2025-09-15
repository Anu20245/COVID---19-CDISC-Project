/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: ADCM.SAS  
*
* Program Type: ADAM
*
* Purpose: To produce ADCM
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

DATA CM1;
   SET SDTM.CM;
RUN;
PROC SORT;BY USUBJID CMSEQ;RUN;

/*bring required variables from suppcm*/
DATA SUPPCM;
   SET SDTM.SUPPCM;
   CMSEQ= INPUT (IDVARVAL,BEST.);
RUN;

PROC SORT;BY USUBJID CMSEQ;RUN;

PROC TRANSPOSE DATA=SUPPCM OUT=SUPPCM_TRANS;
   BY USUBJID CMSEQ;
   ID QNAM;
   VAR QVAL;
   IDLABEL QLABEL;
RUN;


DATA CM2;
   MERGE CM1 (IN=A) SUPPCM_TRANS (IN=B);
   BY USUBJID CMSEQ;
   IF A ;
RUN;

DATA CM3;
   LENGTH STUDYID $20.;
   MERGE CM2 (IN=A DROP=ARM ACTARM) ADAM.ADSL (IN=B);
   BY USUBJID;
   IF A AND B;
   ATC4=CODE4;
   ATC4TXT=TEXT4;
RUN;


DATA CM4;
   SET CM3 ;

   CMSTDTC_ = SUBSTR (CMSTDTC,1,10);
   LEN_CM= LENGTH (CMSTDTC_);
   /*general date imputation rules*/
   IF LEN_CM=4 THEN DO; CMSTDTC_C= STRIP (CMSTDTC_)||"-01-01";ASTDTF='M';END;
   IF LEN_CM=7 THEN DO; CMSTDTC_C= STRIP (CMSTDTC_)||"-01";ASTDTF='D';END;
   IF LEN_CM=10 THEN DO; CMSTDTC_C= STRIP (CMSTDTC_);ASTDTF='';END;

/*   Convert CMSTDTC to Numeric format.*/

   ASTDT=INPUT (CMSTDTC_C,YYMMDD10.);
   FORMAT ASTDT DATE9.;
RUN;

/*to find last day of month dynamically*/
/*data my1;*/
/*   CMENDTC_="2013-02";*/
/*   CMENDTC_C=INTNX ('MONTH',INPUT (STRIP(CMENDTC_)||"-01",YYMMDD10.),0,'end');*/
/*   format CMENDTC_C date9.;*/
/*run;*/

DATA CM5;
   SET CM4 ;

   CMENDTC_ = SUBSTR (CMENDTC,1,10);
   LEN_CM= LENGTH (CMENDTC_);
   /*general date imputation rules*/
   IF LEN_CM=4 THEN DO; CMENDTC_C= STRIP (CMENDTC_)||"-12-31";AENDTF='M';END;


   IF LEN_CM=10 THEN DO; CMENDTC_C= STRIP (CMENDTC_);AENDTF='';END;


   IF LEN_CM=7 THEN DO; 

       CMENDTC_C=INTNX ('MONTH',INPUT (STRIP(CMENDTC_)||"-01",YYMMDD10.),0,'end');

      AENDTF='D';
   END;
   /*Convert CMENDTC to numeric format.*/
   AENDT=INPUT (CMENDTC_C,YYMMDD10.);
   FORMAT AENDT DATE9.;
RUN;


DATA CM6;
   SET CM5 ;

   NEW1= ASTDT;
   NEW2= TRTSDT;
   NEW3= AENDT;

   FORMAT NEW1 NEW2 DATE9.;
   /*   ASTDY*/
   /*"If ASTDT < TRTSDT then Set to ASTDT - TRTSDT */
   /*Else Set to (ASTDT - TRTSDT) +1"*/

   IF NEW1 NE . AND NEW2 NE . THEN DO;
      /*      CM started after treatment*/
      IF NEW1 >= NEW2 THEN DO;
         ASTDY= (NEW1-NEW2)+1;
      END;

      /*CM started before treatement*/
      IF NEW1 < NEW2 THEN DO;
         ASTDY= (NEW1-NEW2);
      END;
   END;
   /*AENDY*/
   /*"If AENDT < TRTSDT then Set to AENDT - TRTSDT;*/
   /*Else Set to (AENDT - TRTSDT) +1;"*/

   IF NEW2 NE . AND NEW3 NE . THEN DO;

      IF NEW3 >= NEW2 THEN DO;
         AENDY= (NEW3-NEW2)+1;
      END;


      IF NEW3 < NEW2 THEN DO;
         AENDY= (NEW3-NEW2);
      END;
   END;

RUN;

DATA CM7;
   SET CM6;
   /*ONTRTFL*/
   /**/
   /*"Set to 'Y' if ASTDT >= TRTSDT or (ASTDT < TRTSDT and CMENRF=ONGOING); Set to null if else;*/
   /*"*/

   if ASTDT >= TRTSDT or (ASTDT < TRTSDT and CMENRF="ONGOING")   THEN ONTRTFL ="Y";
   ELSE ONTRTFL=''; 
RUN;

DATA CM8;
SET CM7;
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
RANDFL
TRT01P
TRT01PN
TRT01A
TRT01AN
TRTSDT
TRTEDT
CMSEQ
CMTRT
CMDECOD
CMINDC
CMDOSE
CMDOSU
CMDOSFRQ
CMROUTE
CMSTDTC
CMENDTC
CMENRF
CMINDSPE
ATC4
ATC4TXT
CMFRQOTH
CMONGO
CMDSEOTH
CMAENUM
CMMHNUM
ASTDT
ASTDY
AENDT
AENDY
ONTRTFL
;
RUN;

/*apply attributes as per spec*/
DATA ADCM (LABEL="Concomitant Medications Analysis Dataset");
SET CM8;
RUN;

