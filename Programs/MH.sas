/*******************************************************************
* Client:  xxx                                                          
* Project:  yyy                                                   
* Program: MH.SAS  
*
* Program Type: MH
*
* Purpose: SDTM
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


DATA MH1;
   SET RAW.MH (RENAME=(MHTERM=MHTERMX));
   DOMAIN 	 =	'MH';
   STUDYID  =	'AA-2020-06'; 
   if SUBNUM ne ' ' then USUBJID = strip(STUDYID)||'-'||strip(SUBNUM);

   MHCAT='MEDICAL HISTORY';
   MHTERM=MHTERMX;
   /*MHENRF*/
   /*"Set to ""ONGOING"" for records if MH.MHONGO = ""X"";*/
   /*Set to ""BEFORE"" for records if MH.MHONGO = "" "";"*/

   IF MHONGO EQ 'X' THEN MHENRF='ONGOING' ;
   IF MHONGO EQ '' THEN MHENRF="BEFORE";

   /*remove UNK from mhstdat*/
   _YY= SCAN (MHSTDAT,1,'-');
   _MM = SCAN (MHSTDAT,2,'-');
   _DD =SCAN (MHSTDAT,3,'-');

   IF _YY='UNK' THEN _YY='';
   IF _MM='UNK' THEN _MM='';
   IF _DD='UNK' THEN _DD='';

   MHSTDTC = CATX ("-",_YY,_MM,_DD);

   /*remove UNK from mhendat*/

   _YY= SCAN (MHENDAT,1,'-');
   _MM = SCAN (MHENDAT,2,'-');
   _DD =SCAN (MHENDAT,3,'-');

   IF _YY='UNK' THEN _YY='';
   IF _MM='UNK' THEN _MM='';
   IF _DD='UNK' THEN _DD='';

   MHENDTC = CATX ("-",_YY,_MM,_DD);

   /*MHDECOD Equivalent to the Preferred Term (PT in MedDRA).*/
   MHDECOD= STRIP (PT_TERM);

   /*    MHLLT=llt_name;*/
   /* MHLLTCD=INPUT(llt_code,??best.);*/
   /* MHDECOD=pt_term;*/
   /* MHPTCD=INPUT(pt_code,??best.);*/
   /* MHHLT=hlt_term;*/
   /* MHHLTCD=INPUT(hlt_code,??best.);*/
   /* MHHLGT=hlgt_term;*/
   /* MHHLGTCD=INPUT(hlgt_code,??best.);*/

   /*MHBODSYS*/
   /*When using a multi-axial dictionary such as MedDRA, this should contain the SOC used for the sponsor’s analyses*/
      MHBODSYS=soc_term;
      MHBDSYCD=INPUT(soc_code,??best.);
   /* MHSOC=soc_term;*/
   /* MHSOCCD=INPUT(soc_code,??best.);*/

RUN;

*EPOCH;;
/*Epoch: As part of the design of a trial, the planned period of subjects' participation in the trial is divided into */
/*Epochs. Each Epoch is a period of time that serves a purpose in the trial as a whole. That purpose will be at the level */
/*of the primary objectives of the trial. Typically, the purpose of an Epoch will be to expose subjects to a treatment, or */
/*to prepare for such a treatment period (e.g., determine subject eligibility, wash out previous treatments) or to gather */
/*data on subjects after a treatment has ended*/
PROC SORT DATA=MH1;
   BY USUBJID;
RUN;



/*Section 5 – SE Domain / Subject Elements*/
/*The subject element table describes the actual order of elements followed by the subject, together with the start date/time*/
/*and end date/time for each element.*/
DATA MH2;
   LENGTH epoch $200 domain $2;
   MERGE sdtm.se(WHERE=(taetord=1) RENAME=(sestdtc=scrnst seendtc=scrnend) KEEP=usubjid taetord sestdtc seendtc)
        sdtm.se(WHERE=(taetord=2) RENAME=(sestdtc=cycle1st seendtc=cycle1end) KEEP=usubjid taetord sestdtc seendtc)
        sdtm.se(WHERE=(taetord=3) RENAME=(sestdtc=ltfupst seendtc=ltfupend) KEEP=usubjid taetord sestdtc seendtc)
        MH1(in=a);
   BY usubjid;
   IF a;
   IF ltfupst^='' & substr(ltfupst,1,10)<=MHSTDTC<=SUBSTR(ltfupend,1,10) THEN EPOCH='FOLLOW-UP';
      ELSE IF cycle1st^='' & substr(cycle1st,1,10)<=MHSTDTC<=SUBSTR(cycle1end,1,10) THEN EPOCH='TREATMENT';
      ELSE IF scrnst^='' & SUBSTR(scrnst,1,10)<=MHSTDTC<=SUBSTR(scrnend,1,10) THEN EPOCH='SCREENING';
RUN;

*DY;
/*study day derivation*/
proc sort data=sdtm.dm out=dm1 nodupkey;by usubjid;run;
DATA DM1;
   SET dm1;
   RFSTDTC_N = DATEPART (INPUT (RFSTDTC,??IS8601DT.));

   FORMAT RFSTDTC_N YYMMDD10.;
   KEEP USUBJID RFSTDTC_N;
RUN;

/*MHSTDY*/
/**/
/*"MHSTDTC - DM.RFSTDTC + 1 if MHSTDTC >= DM.RFSTDTC; */
/*MHSTDTC - DM.RFSTDTC if MHSTDTC < DM.RFSTDTC"*/


DATA MH4;
   MERGE MH2(in=a)
        DM1(IN=b KEEP=USUBJID  RFSTDTC_N );
   BY USUBJID;
   IF a & b;   
   MHSTDTC_N = INPUT (MHSTDTC,??YYMMDD10.);
    MHENDTC_N = INPUT (MHENDTC,??YYMMDD10.);

IF MHSTDTC_N NE . AND RFSTDTC_N NE . THEN DO;
IF MHSTDTC_N >= RFSTDTC_N THEN MHSTDY= MHSTDTC_N - RFSTDTC_N +1;
ELSE IF MHSTDTC_N < RFSTDTC_N THEN MHSTDY = MHSTDTC_N - RFSTDTC_N;
END;


IF MHENDTC_N NE . AND RFSTDTC_N NE . THEN DO;
IF MHENDTC_N >= RFSTDTC_N THEN MHENDY= MHENDTC_N - RFSTDTC_N +1;
ELSE IF MHENDTC_N < RFSTDTC_N THEN MHENDY = MHENDTC_N - RFSTDTC_N;
END;

RUN;


*MHSEQ;
/*Order MH by STUDYID, USUBJID, MHSTDTC,MHENDTC,MHTERM then assign integer values sequentially within USUBJID.*/

PROC SORT DATA=mh4 out=mh5;
   BY STUDYID USUBJID MHDECOD MHTERM MHSTDTC;
RUN;

DATA mh6;
   SET mh5;
   BY studyid usubjid MHDECOD mhterm mhstdtc;
   IF first.usubjid THEN mhSEQ=1;
      ELSE mhSEQ+1;

   LABEL
   STUDYID  ='Study Identifier'
   USUBJID  ='Unique Subject Identifier'
   MHSEQ ='Sequence Number'
   MHTERM   ='Reported Term for the Medical History'
   MHLLT ='Lowest Level Term'
   MHLLTCD  ='Lowest Level Term Code'
   MHDECOD  ='Dictionary-Derived Term'
   MHPTCD   ='Preferred Term Code'
   MHHLT ='High Level Term'
   MHHLTCD  ='High Level Term Code'
   MHHLGT   ='High Level Group Term'
   MHHLGTCD ='High Level Group Term Code'
   MHCAT ='Category for Medical History'
   MHBODSYS ='Body System or Organ Class'
   MHBDSYCD ='Body System or Organ Class Code'
   MHSOC ='Primary System Organ Class'
   MHSOCCD  ='Primary System Organ Class Code'
   EPOCH ='Epoch'
   MHSTDTC  ='Start Date/Time of Medical History Event'
   MHENDTC  ='End Date/Time of Medical History Event'
   MHSTDY   ='Study Day of Start of Medical History Event'
   MHENDY   ='Study Day of End of Medical History Event'
   MHENRF   ='End Relative to Reference Period'
   ;
RUN;
option validvarname=upcase;
PROC SQL NOPRINT;
   CREATE TABLE MH(label='Medical History') as
      SELECT 
            STUDYID label='Study Identifier' length=200,
            USUBJID length=200,DOMAIN LENGTH=3 LABEL="Domain Abbreviation", 
            MHSEQ, MHTERM,  MHDECOD,   MHCAT length=15, MHBODSYS, MHBDSYCD, 
            /*MHSOC, MHSOCCD,*/ EPOCH, MHSTDTC length=10, MHENDTC length=10,
                        MHSTDY, MHENDY, /*MHSTRF,*/ MHENRF length=20
   FROM mh6;
QUIT;


/*/*/*/*/*/*/*/*  SUPPMH*/*/*/*/*/*/*/*/;
/**/
/*STUDYID*/
/*RDOMAIN*/
/*USUBJID*/
/**/
/**/
/*IDVAR*/
/*IDVARVAL*/
/*QNAM*/
/*QLABEL*/
/*QVAL*/
/*QORIG*/
/*QEVAL*/







DATA SMH;
SET MH6;
RDOMAIN='MH';

/*IDVAR*/
/*IDVARVAL*/
/*are always sequence variables*/
IDVAR='MHSEQ';
IDVARVAL=MHSEQ;

/*fixed value*/
QORIG='CRF';
/*fixed value - like investigator or leave blank*/
QEVAL='';
/*all variables covered till now are common across all domain*/

/*MHREL*/
/** Is the condition related to COVID-19*/
/*Present in CRF but not in main dataset*/
QVAL=MHREL;
QLABEL='Is the condition related to COVID-19?';
QNAM='MHREL';

OUTPUT;

/*another variable required for TLF*/
RDOMAIN='MH';
IDVAR='MHSEQ';
IDVARVAL=MHSEQ;
QORIG='CRF';
QEVAL='';

QVAL=MHONGO;
QLABEL='Ongoing';
QNAM='MHONGO';

OUTPUT;
KEEP 
STUDYID
RDOMAIN
USUBJID
IDVAR
IDVARVAL
QNAM
QLABEL
QVAL
QORIG
QEVAL
;
RUN;
DATA SUPPMH (LABEL='Supplemental Qualifiers Medical History');
SET SMH;
RUN;
