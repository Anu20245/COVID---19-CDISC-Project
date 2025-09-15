/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: tab1_1.SAS  
*
* Program Type: Table
*
* Purpose: To produce Table 14.1.1 Subject Assignment to Analysis Populations
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
   IF TRT01A NE '';
   KEEP USUBJID TRT01A TRT01AN;
RUN;

/*Total / All level is not available in data. It has to be calculated programatically*/
DATA ADSL2;
   SET ADAM.ADSL;
   IF TRT01A NE '';
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
      ORDER BY TRT01AN,TRT01A
      ;
   /* to display total subject numbers in table column label - store it in macro vars */
   SELECT DENOM INTO :N1 - :N3 FROM TRT;
QUIT;
%PUT &N1 &N2 &N3;



/*/*/*/*/*/*/*/*/*/*BODY SECTION STATS*/*/*/*/*/*/*/*/*/*/;


DATA ADSL_1;
   SET ADAM.ADSL;
   IF TRT01A NE '';
   KEEP USUBJID TRT01A TRT01AN SAFFL ITTFL RANDFL PPROTFL;
RUN;


DATA ADSL_2;
   SET ADAM.ADSL;
   IF TRT01A NE '';
   TRT01A="ALL";
   TRT01AN=3;
   KEEP USUBJID TRT01A TRT01AN SAFFL ITTFL RANDFL PPROTFL;
RUN;

DATA ADSL_3;
   SET ADSL_1 ADSL_2;
RUN;

PROC SORT ;BY USUBJID;RUN;


/*Safety Population - First row in mockshell */

PROC SQL NOPRINT;
   CREATE TABLE SAF AS
      SELECT TRT01AN,TRT01A,COUNT (USUBJID) AS nn, "Safety Population" AS POP LENGTH=100 /* First column in mock shell */
         , 1 AS ORD /* to maintain order in mock shell */
      FROM ADSL_3
      WHERE SAFFL EQ 'Y' /* Safety Population */
      GROUP BY TRT01AN,TRT01A /* to report numbers for different treatments 'Drug A' , 'Drug B' and 'ALL' */
      ORDER BY TRT01AN,TRT01A
      ;
QUIT;

/*ITT Population*/
PROC SQL NOPRINT;
   CREATE TABLE ITT  AS
      SELECT TRT01AN,TRT01A,COUNT (USUBJID) AS nn,
      "ITT Population" AS POP LENGTH=100, 2 AS ORD
      FROM ADSL_3
      WHERE ITTFL EQ 'Y'
      GROUP BY TRT01AN,TRT01A
      ORDER BY TRT01AN,TRT01A;
QUIT;


/*Randomization Population*/
PROC SQL NOPRINT;
   CREATE TABLE RAND  AS
      SELECT TRT01AN,TRT01A,COUNT (USUBJID) AS nn,
      "Randomization Population" AS POP LENGTH=100, 3 AS ORD
      FROM ADSL_3
      WHERE RANDFL EQ 'Y'
      GROUP BY TRT01AN,TRT01A
      ORDER BY TRT01AN,TRT01A;
QUIT;

/*Per-Protocol Population*/
PROC SQL NOPRINT;
   CREATE TABLE PP  AS
      SELECT TRT01AN,TRT01A,COUNT (USUBJID) AS nn,
      "Per-Protocol Population" AS POP LENGTH=100, 4 AS ORD
      FROM ADSL_3
      WHERE PPROTFL EQ 'Y'
      GROUP BY TRT01AN,TRT01A
      ORDER BY TRT01AN,TRT01A;
QUIT;
/*Stack all population*/
DATA FINAL;
   SET SAF ITT RAND PP;
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
   grp= put (nn,4.)||" ("|| put (nn/denom*100,5.1)||")"; /* calculate cell value per mock shell */
run;


proc sort;by ord pop;run;

proc transpose data=pct1 out=final2 prefix=t;
   id trt01an; /* name of transpose variables */
   by ord pop; /* to keep population in transposed data set */
   var grp; /* transpose cell values - numbers and percentage */
run;

data final2;
   set final2;
   stat="n (%)"; /* second column in template */
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
title3 j=c 'Table 14.1.1 Subject Assignment to Analysis Populations';

footnote1 j=l 'C:\C1\ST\Jul2022\CL\program\tab1_1.SAS';


options orientation=landscape;
ods escapechar='^';
ods rtf file='C:\C1\ST\Jul2022\CL\OUTPUTS\t_14_1_1.rtf' style=styles.test;


proc report data=final2 split='|' style= {outputwidth=100%};

   column ord pop stat t1 t2 t3;

   define ord/order noprint;

   define pop/ "Population"
   style (column)={just=l cellwidth=20%}
   style (header)={just=l cellwidth=20%}
   ;


   define stat/ "Statistic"
   style (column)={just=l cellwidth=10%}
   style (header)={just=l cellwidth=10%}
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
