﻿/*******************************************************************
* Client:  xxx                                                          
* Project:  yyy                                                   
* Program: VS.SAS  
*
* Program Type: SDTM
*
* Purpose: VS
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

OPTION VALIDVARNAME=UPCASE;
proc datasets lib=work kill;
run;
QUIT;

DATA VS1;
   LENGTH USUBJID $40.;
   SET RAW.VS;
      STUDYID = 'AA-2020-06';
      DOMAIN = 'VS';
      USUBJID = STRIP(STUDYID)||"-"||STRIP(SUBNUM);
      VISIT=VISNAME;
      VISITNUM=VISITID;

      IF NOT MISSING(VSDAT) AND NOT MISSING(VSTIM) THEN VSDTC = STRIP(PUT(VSDAT ,??YYMMDD10.)) || "T" || STRIP(PUT(VSTIM,??TOD5.));
      ELSE IF NOT MISSING(VSDAT) AND MISSING(VSTIM) THEN VSDTC = STRIP(PUT(VSDAT ,??YYMMDD10.));
      ELSE VSDTC = " ";
RUN;

data vs1;
   set vs1;
   informat _all_;
   format _all_;
run;
 
/*vital signs are captured in column, in sdtm its required in row*/
/*need to handle each vital signs individualy*/
data DIABP;
   length  VSORRESU VSSTRESU VSSTRESC $200 ;
   set vs1;
   if strip(upcase(VSSTATBP)) in ("NO" "N") then do;
      VSTESTCD='DIABP';
      VSTEST='Diastolic Blood Pressure';
      VSORRES = "";
      VSORRESU = "";
      VSSTRESC = "";
      VSSTAT = "NOT DONE";
      VSREASND = " ";
      output;
   end;

   if strip(upcase(VSSTATBP)) in ("YES" "Y") OR not missing(VSDBP) then do;
      VSTESTCD='DIABP';
      VSTEST='Diastolic Blood Pressure';
      VSORRES_=strip(put(VSDBP,??best.));
      VSORRESU="mmHg";
      VSSTRESC=VSORRES_;
      VSSTRESN=VSDBP;
      VSSTRESU="mmHg";
      VSSTAT = " ";
      VSREASND = " ";
      OUTPUT;
   END;
run;

/*transform Systolic Blood Pressure*/
data SYSBP;
   length  VSORRESU VSSTRESU VSSTRESC $200 ;
   set vs1;
   if strip(upcase(VSSTATBP)) in ("NO" "N") then do;
      VSTESTCD='SYSBP';
      VSTEST='Systolic Blood Pressure';
      VSORRES = "";
      VSORRESU = "";
      VSSTRESC = "";
      VSSTAT = "NOT DONE";
      VSREASND = " ";
      output;
   end;
   if strip(upcase(VSSTATBP)) in ("YES" "Y") or not missing(VSSBP) then do;
      VSTESTCD='SYSBP';
      VSTEST='Systolic Blood Pressure';
      VSORRES_=strip(put(VSSBP,??best.));
      VSORRESU="mmHg";
      VSSTRESC=VSORRES_;
      VSSTRESN=VSSBP;
      VSSTRESU="mmHg";
      VSREASND = "" ;
      VSSTAT = " ";
      OUTPUT;
   END;
run;
/* Heart Rate*/
data HR;
   length  VSORRESU VSSTRESU VSSTRESC $200 ;
   set vs1;
   if strip(upcase(VSSTATHR)) in ("NO" "N") then do;
      VSTESTCD='HR';
      VSTEST='Heart Rate';
      VSORRES = "";
      VSORRESU = "";
      VSSTRESC = "";
      VSSTAT = "NOT DONE";
      VSREASND = " ";
      output;
   end;
   if strip(upcase(VSSTATHR)) in ("YES" "Y") or not missing(VSHR) then do;
      VSTESTCD='HR';
      VSTEST='Heart Rate';
      VSORRES_=strip(put(VSHR,??best.));
      VSORRESU="beats/min";
      VSSTRESC=VSORRES_;
      VSSTRESN=VSHR;
      VSSTRESU="beats/min";
      VSREASND = "" ;
      VSSTAT = " ";
      OUTPUT;
   END;
run;

/*Respiratory Rate*/
data RESP;
   length  VSORRESU VSSTRESU VSSTRESC $200 ;
   set vs1;
   if strip(upcase(VSRRSTAT)) in ("NO" "N") then do;
      VSTESTCD='RESP';
      VSTEST='Respiratory Rate';
      VSORRES = "";
      VSORRESU = "";
      VSSTRESC = "";
      VSSTAT = "NOT DONE";
      IF NOT MISSING(VSRRREAS) THEN  VSREASND = strip(upcase(VSRRREAS));
      
      output;
   end;
   if strip(upcase(VSRRSTAT)) in ("YES" "Y") or not missing(VSRR) then do;
      VSTESTCD='RESP';
      VSTEST='Respiratory Rate';
      VSORRES_=strip(put(VSRR,??best.));
      VSORRESU="breaths/min";
      VSSTRESC=VSORRES_;
      VSSTRESN=VSRR;
      VSSTRESU="breaths/min";
      VSSTAT = "";
      VSREASND = " ";
      OUTPUT;
   END;
run;
/* Oxygen Saturation*/
data OXSAT;
   length  VSORRESU VSSTRESU VSSTRESC $200 ;
   set vs1;
   if strip(upcase(VSOXSTAT)) in ("NO" "N") then do;
      VSTESTCD='OXYSAT';
      VSTEST='Oxygen Saturation';
      VSORRES = "";
      VSORRESU = "";
      VSSTRESC = "";
      VSSTAT = "NOT DONE";
      IF NOT MISSING(VSOXREAS) THEN  VSREASND = strip(upcase(VSOXREAS));
      
   output;
   end;
   if strip(upcase(VSOXSTAT)) in ("YES" "Y") or not missing(VSOXSAT) then do;
      VSTESTCD='OXYSAT';
      VSTEST='Oxygen Saturation';
      VSORRES_=strip(put(VSOXSAT,??best.));
      VSORRESU="%";
      VSSTRESC=VSORRES_;
      VSSTRESN=VSOXSAT;
      VSSTRESU="%";
       VSSTAT = "";
       VSREASND = " ";
      OUTPUT;
   END;
run;
/*Temperature*/
data TEMP;
   length VSORRESU  VSSTRESU VSSTRESC $200 ;
   set vs1;
   if strip(upcase(VSTMSTAT)) in ("NO" "N") then do;
      VSTESTCD='TEMP';
      VSTEST='Temperature';
      VSORRES = "";
      VSORRESU = "";
      VSSTRESC = "";
      VSSTAT = "NOT DONE";
      IF NOT MISSING(VSTMREAS) THEN  VSREASND = strip(upcase(VSTMREAS));
      
   output;
   end;
   if strip(upcase(VSTMSTAT)) in ("YES" "Y") or not missing(VSTEMP) then do;
      VSTESTCD='TEMP';
      VSTEST='Temperature';
      VSORRES_=strip(put(VSTEMP,??best.));   
       IF NOT MISSING(VSTEMP) AND  missing(VSTEMUNI) then VSORRESU = "C";
       ELSE VSORRESU = VSTEMUNI;
      VSSTRESU=VSORRESU;
      VSSTRESC=VSORRES_;
      VSSTRESN=VSTEMP;
      IF VSORRESU='F' then do;
         VSSTRESN= (VSTEMP-32)*(5/9);
         IF NOT MISSING(VSSTRESN) THEN VSSTRESC=strip(put(VSSTRESN, ??best.));
         ELSE VSSTRESC = VSORRES_;
         VSSTRESU="C";
      end;
      VSSTAT = "";
      VSREASND = " ";
      OUTPUT;
   END;

run;
/*Weight*/
data WEIGHT;
   length  VSORRESU VSSTRESU VSSTRESC $200 ;
   set vs1;
   IF NOT MISSING(VSWEIGHT) THEN DO;
      VSTESTCD='WEIGHT';
      VSTEST='Weight';
      VSORRES_=strip(put(VSWEIGHT,??best.));
      VSORRESU=VSWEIUNI;
      VSSTRESU="kg";
      VSREASND = "" ;
      /*      convert pound to kg*/
      IF VSORRESU='lb' then do;
         VSSTRESN=  (VSWEIGHT* 0.4536);
         IF VSSTRESN NE . THEN VSSTRESC=strip(put(VSSTRESN, ??best.));
         ELSE VSSTRESC = VSORRES_;
         VSORRESU ="LB";
      end;
      IF VSORRESU='kg' then do;
         VSSTRESC = VSORRES_;
         VSSTRESN = VSWEIGHT ;
      END;
      VSSTAT=" " ;
      OUTPUT;
   END;
run;
/*Height*/
data HEIGHT;
   length  VSORRESU VSSTRESU VSSTRESC $200 ;
   set vs1;
   if not missing(VSHEIGHT) then do;
      VSTESTCD='HEIGHT';
      VSTEST='Height';
      VSORRES_=strip(put(VSHEIGHT,??best.));
      VSORRESU=VSHEIUNI;
      VSSTRESU=VSORRESU;
      VSREASND = "" ;
      /*      convert inch to cm*/
      IF VSORRESU='in' then do;
         VSSTRESN=  (VSHEIGHT*2.54);
         IF NOT MISSING(VSSTRESN) THEN VSSTRESC=strip(put(VSSTRESN, ??best.));
         ELSE VSSTRESC = VSORRES_;
         VSSTRESU="cm";
      end;
      IF VSORRESU='cm' then do;
         VSSTRESC = VSORRES_;
         VSSTRESN = VSHEIGHT ;
      END;
      VSSTAT=" " ;
      OUTPUT;
   END;
run;

data VSALL;
   set vs1;
   if strip(upcase(VSNY)) in ("NO" "N") then do;
      VSTESTCD="VSALL";
      VSTEST="Vital Signs";
      VSORRES_="";
      VSORRESU=" ";
      VSSTRESC=" ";
      VSSTRESN=.;
      VSSTRESU=" ";
      VSREASND = "" ;
      VSSTAT="NOT DONE";
      OUTPUT;
   end;  
run;
/*stack all vital signs*/
data ALL;
   length VSORRES VSREASND  VSORRESU VSSTRESU VSSTRESC $200 VSTESTCD $8;
     set DIABP SYSBP HR OXSAT TEMP RESP WEIGHT HEIGHT VSALL;

     IF VSORRES_ ^= "." THEN VSORRES = VSORRES_;
     ELSE IF VSORRES_ = "." THEN VSORRES = " ";
run;


proc sort data=ALL out=VS2;
by  USUBJID ;
run;
proc sort data=SDTM.DM(KEEP =USUBJID RFSTDTC RFXSTDTC) OUT=DM;
by  USUBJID ;
run;

DATA VS3; 
  LENGTH USUBJID $40;
     MERGE VS2(IN=A) DM(IN=B) ;
      BY USUBJID;
      IF A AND B;
      VSDTCN=INPUT(VSDTC,YYMMDD10.);
      RFSTDTCN=INPUT(RFSTDTC,YYMMDD10.);
      IF NOT MISSING(VSDTCN) AND NOT MISSING(RFSTDTCN) THEN DO;
         if VSDTCN >=RFSTDTCN then VSDY=(VSDTCN - RFSTDTCN)+1; 
         else  VSDY=VSDTCN-RFSTDTCN;
      END;
RUN;


                     /**********************     DERIVING VSBLFL      *******************/


DATA VS4 ;
   SET vs3;
   if VSDTC ne '' and RFXSTDTC ne ''   and input(VSDTC,is8601da.) =< input(RFXSTDTC,is8601da.) 
      and VSSTAT ne 'NOT DONE'; 
RUN;
PROC SORT DATA=VS4 NODUPKEY;BY USUBJID VSTESTCD VSDTC ;RUN;

DATA VS5(KEEP=STUDYID USUBJID VSTESTCD VISITNUM VSDTC VSBLFL VSORRES);
   SET VS4;
   BY USUBJID VSTESTCD VSDTC ;
   IF LAST.VSTESTCD THEN VSBLFL="Y" ;
RUN;
PROC SORT DATA=VS5 OUT=VS5_1 NODUPKEY DUPOUT=AA;BY USUBJID VSTESTCD VSDTC ;RUN;
PROC SORT DATA=VS3 ;BY USUBJID VSTESTCD VSDTC ;RUN;

data VS6;
   merge VS5_1 VS3;
   BY USUBJID VSTESTCD VSDTC ;
      drop visitnum;
RUN;



*EPOCH;;
PROC SORT DATA=VS6;
   BY USUBJID;
RUN;

DATA VS7_1;
   LENGTH epoch $200 domain $2;
   MERGE sdtm.se(WHERE=(taetord=1) RENAME=(sestdtc=scrnst seendtc=scrnend) KEEP=usubjid taetord sestdtc seendtc)
        sdtm.se(WHERE=(taetord=2) RENAME=(sestdtc=cycle1st seendtc=cycle1end) KEEP=usubjid taetord sestdtc seendtc)
        sdtm.se(WHERE=(taetord=3) RENAME=(sestdtc=ltfupst seendtc=ltfupend) KEEP=usubjid taetord sestdtc seendtc)
        VS6(in=a);
   BY usubjid;
   IF a;
   IF ltfupst^='' & substr(ltfupst,1,10)<=vsdtc<=SUBSTR(ltfupend,1,10) THEN EPOCH='FOLLOW-UP';
      ELSE IF cycle1st^='' & substr(cycle1st,1,10)<=vsdtc<=SUBSTR(cycle1end,1,10) THEN EPOCH='TREATMENT';
      ELSE IF scrnst^='' & SUBSTR(scrnst,1,10)<=vsdtc<=SUBSTR(scrnend,1,10) THEN EPOCH='SCREENING';
RUN;


PROC SORT DATA = VS7_1;BY VISIT;RUN;

DATA VISIT(KEEP=STUDYID VISIT VISITNUM);
   SET SDTM.TV;
RUN;
PROC SORT DATA=VISIT;BY VISIT;RUN;
DATA VS7_1;
   LENGTH VISIT $200 STUDYID $20  ;
   MERGE VS7_1(IN=A) VISIT(IN=B);
   BY VISIT;
   IF A ;
RUN;

PROC SORT DATA =VS7_1;BY USUBJID VISITNUM VSDTC VSTESTCD  ;RUN;

                     /**********************     DERIVING VSSEQ       *******************/

DATA VS_;
   SET VS7_1;
      BY USUBJID VISITNUM VSDTC VSTESTCD  ;
         IF FIRST.USUBJID THEN VSSEQ   =1;
            ELSE VSSEQ+1;
         VSLOBXFL=VSBLFL;
RUN;

                        /*****************   VS FINAL DATASET  ******************/



DATA VS(LABEL="Vital Signs");
    Retain STUDYID DOMAIN USUBJID VSSEQ VSTESTCD VSTEST VSORRES VSORRESU VSSTRESC VSSTRESN VSSTRESU VSSTAT VSREASND VSLOBXFL 
VSBLFL VISITNUM VISIT EPOCH VSDTC VSDY ;
   ATTRIB 
     STUDYID       LENGTH=$20    LABEL="Study Identifier"
     DOMAIN        LENGTH=$2     LABEL="Domain Abbreviation"
     USUBJID       LENGTH=$200     LABEL="Unique Subject Identifier"
     VSSEQ         LENGTH=8         LABEL="Sequence Number"
     VSTESTCD      LENGTH=$8       LABEL="Vital Signs Test Short Name"
     VSTEST        LENGTH=$40      LABEL="Vital Signs Test Name"
     VISIT           LENGTH=$200       LABEL="Visit Name"
     VISITNUM      LENGTH=8      LABEL="Visit Number"
     VSLOBXFL      LENGTH=$1      LABEL="Last Observation Before Exposure Flag"
     VSBLFL    LENGTH=$1       LABEL="Baseline Flag"
     VSDTC           LENGTH=$19      LABEL="Date/Time of Measurements"
     VSDY            LENGTH=8       LABEL="Study Day of Vital Signs"
     VSORRES         LENGTH=$200     LABEL="Result or Finding in Original Units"
     VSORRESU     LENGTH=$200     LABEL="Original Units"
     VSSTAT    LENGTH=$200     LABEL="Completion Status"
     VSSTRESC        LENGTH=$200     LABEL="Character Result/Finding in Std Format"
     VSSTRESN     LENGTH=8       LABEL="Numeric Result/Finding in Standard Units"
     VSSTRESU        LENGTH=$200     LABEL="Standard Units"
     VSREASND     LENGTH=$200     LABEL="Reason Not Performed"
     EPOCH        LENGTH=$200     LABEL="Epoch";

    
  SET VS_;
   /*  format _all_;*/
   /*  informat _all_;*/
  keep STUDYID USUBJID DOMAIN VSSEQ VSTEST VSTESTCD VSORRES VSORRESU VSSTRESC VSSTRESN VSSTRESU VSSTAT VSDTC VSDY EPOCH VSBLFL VISITNUM VISIT VSREASND
VSLOBXFL; 
RUN;
