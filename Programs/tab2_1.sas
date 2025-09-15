﻿/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: tab2_1.SAS  
*
* Program Type: Table
*
* Purpose: Table 14.1.2  Subject Disposition by Treatment (Safety Population) 
* Usage Notes: 
*
* SAS  Version: 9.4
* Operating System: Windows 2003 R2 Standard Edition.                   
*
* Author: 
* Date Created: 
* Modification History:
*******************************************************************/          
libname adam "C:\C1\ST\Jul2022\CL\ADAM datasets";

proc datasets lib=work kill nolist;
run;

DATA ADSL1;
   SET ADAM.ADSL;
   IF TRT01A NE '' and saffl eq 'Y';
   KEEP USUBJID TRT01A TRT01AN;
RUN;


DATA ADSL2;
   SET ADAM.ADSL;
   IF TRT01A NE '' and saffl eq 'Y';
   TRT01A="ALL";
   TRT01AN=3;
   KEEP USUBJID TRT01A TRT01AN;
RUN;

DATA ADSL3;
   SET ADSL1 ADSL2;
RUN;

PROC SORT ;BY USUBJID;RUN;


PROC SQL NOPRINT;
   CREATE TABLE TRT AS 
      SELECT TRT01AN,TRT01A,COUNT (USUBJID) AS DENOM
      FROM ADSL3
      GROUP BY TRT01AN ,TRT01A
      ORDER BY TRT01AN,TRT01A;

   SELECT DENOM INTO :N1 - :N3 FROM TRT;
QUIT;
%PUT &N1 &N2 &N3;


/*/*/*/*/*/*/*/*/*/*BODY SECTION STATS*/*/*/*/*/*/*/*/*/*/;


DATA ADSL_1;
   SET ADAM.ADSL;
   IF TRT01A NE '' and SAFFL EQ 'Y';
   KEEP USUBJID TRT01A TRT01AN RANDFL EOSSTT   DCSREAS;
RUN;


DATA ADSL_2;
   SET ADAM.ADSL;
   IF TRT01A NE '' and SAFFL EQ 'Y';
   TRT01A="ALL";
   TRT01AN=3;
   KEEP USUBJID TRT01A TRT01AN EOSSTT  RANDFL DCSREAS;
RUN;

DATA ADSL_3;
   SET ADSL_1 ADSL_2;
RUN;

PROC SORT ;BY USUBJID;RUN;

/*Subjects Actual treatment */

PROC SQL NOPRINT;
   CREATE TABLE SAF AS
      SELECT TRT01AN,TRT01A,COUNT (DISTINCT USUBJID) AS nn,
      "Subjects Actual treatment" AS POP LENGTH=100, 1 AS ORD
      FROM ADSL_3
      WHERE TRT01A NE ''
      GROUP BY TRT01AN,TRT01A
      ORDER BY TRT01AN,TRT01A;
QUIT;

/*Subjects Randomized */

PROC SQL NOPRINT;
   CREATE TABLE RAND AS
      SELECT TRT01AN,TRT01A,COUNT (DISTINCT USUBJID) AS nn,
      "Subjects Randomized" AS POP LENGTH=100, 2 AS ORD
      FROM ADSL_3
      WHERE RANDFL  EQ 'Y'
      GROUP BY TRT01AN,TRT01A
      ORDER BY TRT01AN,TRT01A;
QUIT;

/*Subjects Withdrawn */


PROC SQL NOPRINT;
   CREATE TABLE WTH AS
      SELECT TRT01AN,TRT01A,COUNT (DISTINCT USUBJID) AS nn,
      "Subjects Withdrawn" AS POP LENGTH=100, 3 AS ORD
      FROM ADSL_3
      WHERE EOSSTT  EQ 'Discontinued'
      GROUP BY TRT01AN,TRT01A
      ORDER BY TRT01AN,TRT01A;
QUIT;

/*REASONS*/


PROC SQL NOPRINT;
   CREATE TABLE WTHR AS
      SELECT TRT01AN,TRT01A,COUNT (DISTINCT USUBJID) AS nn,
      DCSREAS AS POP LENGTH=100, 4 AS ORD
      FROM ADSL_3
      WHERE EOSSTT  EQ 'Discontinued'
      GROUP BY TRT01AN,TRT01A,DCSREAS /* need to report discontinue reason - so DCSREAS is required in group by */
      ORDER BY TRT01AN,TRT01A,DCSREAS;
QUIT;

DATA FINAL;
   SET SAF RAND WTH WTHR;
   IF ORD EQ 4 THEN DO;
      POP='   '||STRIP(POP);
   END;
RUN;


proc sort;by trt01an;run;

data pct;
   merge final (in=a) trt (in=b);
   by trt01an;
   if a;
run;


data pct1;
   set pct;
   length grp $100.;
   grp= strip(put (nn,4.))||" ("|| strip(put (nn/denom*100,5.1))||")";

run;


proc sort;by ord pop;run;

proc transpose data=pct1 out=final2 prefix=t;
   id trt01an;
   by ord pop;
   var grp;
run;

DATA FINAL2;
   SET FINAL2;

   IF T1='' THEN T1='  0';
   IF T2='' THEN T2='  0';
   IF T3='' THEN T3='  0';
RUN;


%macro _RTFSTYLE_;

proc template;
 define style styles.test;
     parent=styles.rtf;
    replace fonts /
     'BatchFixedFont' = ("Courier New",9pt)
     'TitleFont2' = ("Courier New",9pt)
     'TitleFont' = ("Courier New",9pt)
     'StrongFont' = ("Courier New",9pt)
     'EmphasisFont' = ("Courier New",9pt)
     'FixedEmphasisFont' = ("Courier New",9pt)
     'FixedStrongFont' = ("Courier New",9pt)
     'FixedHeadingFont' = ("Courier New",9pt)
     'FixedFont' = ("Courier New",9pt)
     'headingEmphasisFont' = ("Courier New",9pt)
     'headingFont' = ("Courier New",9pt)
     'docFont' = ("Courier New",9pt);
      replace table from output /
      cellpadding = 0pt
      cellspacing = 0pt
       borderwidth = 0.50pt
      background=white
      frame=void;
    replace color_list  /
     'link' = black
     'bgH' = white
     'fg' = black
     'bg' = white;

    replace Body from Document /
      bottommargin = 1.00in
      topmargin = 1.00in
      rightmargin = 1.00in
      leftmargin = 1.00in; 
   end;
run;

%MEND _RTFSTYLE_;
%_RTFSTYLE_;

title1 j=l 'COVID-19 AA';
title2 j=l 'Protocol: 043';
title3 j=c 'Table 14.1.2  Subject Disposition by Treatment (Safety Population)';

footnote1 j=l 'C:\C1\ST\Jul2022\CL\program\tab2_1.SAS';


options orientation=landscape;
ods escapechar='^';
ods rtf file='C:\C1\ST\Jul2022\CL\OUTPUTS\t_14_2_1.rtf' style=styles.test;


proc report data=final2 split='|' style= {outputwidth=100%};

   column ord pop  t1 t2 t3;

   define ord/order noprint;

   define pop/ "Population"
   style (column)={just=l cellwidth=20% asis=on}
   style (header)={just=l cellwidth=20% asis=on}
   ;




   define t1/ "DRUG A|(N=&N1)"
   style (column)={just=l cellwidth=10%}
   style (header)={just=l cellwidth=10%}
   ;


   define t2/ "DRUG B|(N=&N2)"
   style (column)={just=l cellwidth=10%}
   style (header)={just=l cellwidth=10%}
   ;


   define t3/ "ALL|(N=&N3)"
   style (column)={just=l cellwidth=10%}
   style (header)={just=l cellwidth=10%}
   ;

   compute before _page_;
      line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;


   compute after _page_;
      line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;

run;

ods _all_ close;
