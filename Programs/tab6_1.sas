/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: tab6_1.SAS  
*
* Program Type: Table
*
* Purpose: To produce Table 14.1.8  Treatment Emergent Adverse Events by Treatment, System Organ Class and Preferred Term (safety Population)
* Usage Notes: 
*
* SAS® Version: 9.4
* Operating System: Windows 2003 R2 Standard Edition.                   
*
* Author: 
* Date Created: 
* Modification History:
*******************************************************************/          
libname adam "C:\C1\ST\Jul2022\CL\ADAM datasets";

proc datasets lib=work kill; 
run; quit;

DATA ADSL1;
   SET ADAM.ADSL;
   IF TRT01A NE '' and saffl eq 'Y';
   KEEP USUBJID TRT01A TRT01AN;
RUN;


DATA ADSL3;
   SET ADSL1 ;
RUN;

PROC SORT ;BY USUBJID;RUN;


PROC SQL NOPRINT;
   CREATE TABLE TRT AS 
      SELECT TRT01AN,TRT01A,COUNT (USUBJID) AS DENOM
      FROM ADSL3
      GROUP BY TRT01AN ,TRT01A
      ORDER BY TRT01AN,TRT01A
      ;

   SELECT DENOM INTO: N1 - :N2 FROM TRT;
QUIT;
%PUT &N1 &N2 ;


/*body part*/

DATA ADAE;
   SET ADAM.ADAE;
   IF SAFFL EQ 'Y' AND /* Treatment Emergent  */ TRTEMFL EQ 'Y';
   IF AETERM NE '' THEN DO;
      IF AEBODSYS EQ '' THEN AEBODSYS="**UNCODED";
      IF AEDECOD EQ '' THEN AEDECOD="**UNCODED";
/*      medical coding team provides AEBODSYS AEDECOD */
   END;
   KEEP USUBJID AEBODSYS AEDECOD TRT01A TRT01AN AETERM;
RUN;

/*Number of Subjects with TEAEs*/

PROC SQL NOPRINT;
   CREATE TABLE ANY1 AS
      SELECT TRT01AN,TRT01A, COUNT (DISTINCT USUBJID) AS nn,
      "Number of Subjects with TEAEs" AS AEBODSYS LENGTH=100,
      1 AS ORD FROM ADAE
      GROUP BY TRT01AN,TRT01A
      ORDER BY TRT01AN,TRT01A
      ;
/*MedDRA® System Organ Class*/

   CREATE TABLE SOC AS
      SELECT TRT01AN,TRT01A,AEBODSYS, COUNT (DISTINCT USUBJID) AS nn,
      2 AS ORD FROM ADAE
      GROUP BY TRT01AN,TRT01A,AEBODSYS
      ORDER BY TRT01AN,TRT01A,AEBODSYS
      ;
/*   MedDRA® Preferred Term*/
   CREATE TABLE PT AS
      SELECT TRT01AN,TRT01A,AEBODSYS,AEDECOD, COUNT (DISTINCT USUBJID) AS nn,
      2 AS ORD FROM ADAE
      GROUP BY TRT01AN,TRT01A,AEBODSYS,AEDECOD
      ORDER BY TRT01AN,TRT01A,AEBODSYS,AEDECOD
      ;

QUIT;

DATA FINAL;
   SET ANY1 SOC PT;
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

PROC SORT;BY ORD AEBODSYS AEDECOD;RUN;

PROC TRANSPOSE DATA=PCT1 OUT=PCT2 PREFIX=t;
   BY ORD AEBODSYS AEDECOD;
   ID TRT01AN;
   VAR GRP;
RUN;

DATA FINAL2;
   SET PCT2;
   LENGTH NEWV $200.;
   IF AEDECOD EQ '' THEN NEWV=AEBODSYS;
   ELSE NEWV='  '||AEDECOD;
RUN;


DATA FINAL2;
   SET FINAL2;

   IF T1='' THEN T1='  0';
   IF T2='' THEN T2='  0';
RUN;



data FINAL2;
   set FINAL2;
   retain lnt 0 page1 1;
   lnt+1;

   if lnt>20 then do;
      page1=page1+1;
      lnt=1;
   end;
run;


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
title3 j=c 'Table 14.1.8  Treatment Emergent Adverse Events by Treatment, System Organ Class and Preferred Term (safety Population)';

footnote1 j=l 'C:\C1\ST\Jul2022\CL\program\tab6_1.SAS';


options orientation=landscape;
ods escapechar='^';
ods rtf file='C:\C1\ST\Jul2022\CL\OUTPUTS\t_14_1_8.rtf' style=styles.test;



proc report data=final2 split='|' style= {outputwidth=100%} MISSING;
/*here AEDECOD have missing values, and it is one of order variable. So need to use MISSING option*/

   column PAGE1 ORD AEBODSYS AEDECOD NEWV
   ("Treatment" "^{style [outputwidth=100% bordertopwidth=0.5pt]}" t1 t2) ;

   define PAGE1/order noprint;
   define ord/order noprint;
   define AEBODSYS/order noprint;
   define AEDECOD/order noprint;


   define NEWV/ORDER "MedDRA® System Organ Class|   MedDRA® Preferred Term"
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



   compute before _page_;
   line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;


   compute after _page_;
   line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;

   BREAK AFTER PAGE1/PAGE;
run;

ods _all_ close;















