/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: tab9_1.SAS  
*
* Program Type: Table
*
* Purpose: To produce Table 14.1.11 Analysis of Clinical Recovery Rate of COVID-19 Symptoms with a 2x2 Contingcy Table (ITT population)
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
quit;


DATA ADSL1;
   SET ADAM.ADSL;
   IF TRT01A NE '' and ittfl eq 'Y';
   KEEP USUBJID TRT01A TRT01AN;
RUN;


PROC SORT ;BY USUBJID;RUN;


PROC SQL NOPRINT;
   CREATE TABLE TRT AS 
   SELECT TRT01AN,TRT01A,COUNT (USUBJID) AS DENOM
   FROM ADSL1
   GROUP BY TRT01AN ,TRT01A
   ORDER BY TRT01AN,TRT01A;

   SELECT DENOM INTO: N1 - :N2 FROM TRT;
QUIT;
%PUT &N1 &N2 ;


/*Clinical Recovery of COVID-19 Symptoms on Day 14*/

data cv14fl;
   set adam.adsl;
   if ittfl eq 'Y';
   if COVD14FL="Y" then  COVD14FLN=1;
   ELSE if COVD14FL IN ("" "N") then  COVD14FLN=2;
RUN;

proc sort;by trt01an;run;

ODS TRACE ON;
ODS OUTPUT  BinomialCLs=CI14 ;
/*
CI14 - Confidence interval
N14 - Frequency OR count
*/
proc freq data=cv14fl;
   BY TRT01AN;
   tables COVD14FLN/binomial (EXACT) ALPHA=0.05 OUT=N14;
RUN;


ODS OUTPUT  FishersExact=FISHEREX_14;
/*FISHEREX_14 - "p-value (vs. placebo) [b]"*/
PROC FREQ DATA=cv14fl;
   TABLES COVD14FLN*TRT01AN/EXACT;
RUN;
ODS TRACE OFF;


DATA PVAL14;
   SET FISHEREX_14;
   LENGTH C0 C1 $100.;

   IF NAME1="XP2_FISH";
   C0='    p-value (vs. placebo) [b]';
   C1= STRIP (PUT (nValue1,6.4));
   ORD1=1;
   ORD2=4;
   KEEP C0 C1 ORD1 ORD2;
RUN;
/*Row '    p-value (vs. placebo) [b]	x.xxxx' is complete */

DATA N14_1;
   SET N14;
/*   need count for recovered subjects ONLY*/
   IF COVD14FLN=1;
RUN;


proc sort;by trt01an;run;

data pct;
   merge N14_1 (in=a) trt (in=b);
   by trt01an;
   if a;
run;


data pct1;
   set pct;
   length grp $100.;
   grp= strip(put (COUNT,4.))||" ("|| strip(put (COUNT/denom*100,5.1))||")";

run;

proc transpose data=pct1 out=N14_2 ;
   id trt01an;
   var grp;
run;



DATA N14_2_TR;
   SET N14_2;
   LENGTH C0 C1 C2 $100.;

   C0='    n(%)';
   C1= _1;
   C2=_2;
   ORD1=1;
   ORD2=2;
   KEEP C0 C1 C2 ORD1 ORD2;
RUN;
/*Row '    n(%)	xx(xx.x)	xx(xx.x)' is complete here*/

DATA CI14_1;
   SET CI14;
   n="("|| STRIP (PUT (LowerCL,5.1))||", "|| STRIP (PUT (UpperCL,5.1))||")";
   KEEP  TRT01AN n;
   if TRT01AN ne .;
RUN;


proc transpose data=CI14_1 out=CI14_2 ;
   id trt01an;
   var n;
run;


DATA CI14_2;
   SET CI14_2;
   LENGTH C0 C1 C2 $100.;

   C0='    95% CI for Clinical Recovery Rate[a]';
   C1= _1;
   C2=_2;
   ORD1=1;
   ORD2=3;
   KEEP C0 C1 C2 ORD1 ORD2;
RUN;
/*Row '    95% CI for Clinical Recovery Rate[a]	(xx.x,xx.x)	(xx.x,xx.x)' is complete here*/

DATA label;
   LENGTH C0 $100.;

   C0='Clinical Recovery of COVID-19 Symptoms on Day 14 ';
   ORD1=1;
   ORD2=1;
   KEEP C0  ORD1 ORD2;
RUN;
/*Row - 'Clinical Recovery of COVID-19 Symptoms on Day 14 ADSL.COVD14FL		' is complete here*/

/*Stack all rows for 14 day recovery*/
data final_14;
set label N14_2_TR CI14_2 PVAL14;
run;

/*Clinical Recovery of COVID-19 Symptoms on Day 28 */

/*all logic remains same except usage of COVD28FL*/
data cv28fl;
   set adam.adsl;
   if ittfl eq 'Y';

   if COVD28FL="Y" then  COVD28FLN=1;
   ELSE if COVD28FL IN ("" "N") then  COVD28FLN=2;
RUN;

proc sort;by trt01an;run;
ODS TRACE ON;
ODS OUTPUT  BinomialCLs= CI28;

proc freq data=cv28fl;
   BY TRT01AN;
   tables COVD28FLN/binomial (EXACT) ALPHA=0.05 OUT=N28;
RUN;


ODS OUTPUT  FishersExact=FISHEREX_28;
PROC FREQ DATA=cv28fl;
   TABLES COVD28FLN*TRT01AN/EXACT;
RUN;
ODS TRACE OFF;



DATA PVAL28;
   SET FISHEREX_28;
   LENGTH C0 C1 $100.;

   IF NAME1="XP2_FISH";
   C0='    p-value (vs. placebo) [b]';
   C1= STRIP (PUT (nValue1,6.4));
   ORD1=2;
   ORD2=4;
   KEEP C0 C1 ORD1 ORD2;
RUN;


DATA N28_1;
   SET N28;
   IF COVD28FLN=1;
RUN;


proc sort;by trt01an;run;

data pct;
   merge N28_1 (in=a) trt (in=b);
   by trt01an;
   if a;
run;


data pct1;
   set pct;
   length grp $100.;
   grp= strip(put (COUNT,4.))||" ("|| strip(put (COUNT/denom*100,5.1))||")";

run;

proc transpose data=pct1 out=N28_2 ;
   id trt01an;
   var grp;
run;



DATA N28_2_TR;
   SET N28_2;
   LENGTH C0 C1 C2 $100.;

   C0='    n(%)';
   C1= _1;
   C2=_2;
   ORD1=2;
   ORD2=2;
   KEEP C0 C1 C2 ORD1 ORD2;
RUN;

DATA CI28_1;
   SET CI28;
   n="("|| STRIP (PUT (LowerCL,5.1))||", "|| STRIP (PUT (UpperCL,5.1))||")";
   KEEP  TRT01AN n;
   if TRT01AN ne .;
RUN;


proc transpose data=CI28_1 out=CI28_2 ;
   id trt01an;
   var n;
run;


DATA CI28_2;
   SET CI28_2;
   LENGTH C0 C1 C2 $100.;

   C0='    95% CI for Clinical Recovery Rate[a]';
   C1= _1;
   C2=_2;
   ORD1=2;
   ORD2=3;
   KEEP C0 C1 C2 ORD1 ORD2;
RUN;


DATA label;
   LENGTH C0 $100.;

   C0='Clinical Recovery of COVID-19 Symptoms on Day 28 ';
   ORD1=2;
   ORD2=1;
   KEEP C0  ORD1 ORD2;
RUN;

data final_28;
   set label N28_2_TR CI28_2 PVAL28;
run;

data final;
   set final_14 final_28;
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
title3 j=c 'Table 14.1.11 Analysis of Clinical Recovery Rate of COVID-19 Symptoms with a 2x2 Contingcy Table (ITT population)';

footnote1 j=l "% is based on ITT population. CI = Confidence Interval.";
footnote2 j=l "[a] Clopper-Pearson exact 95% CI";
footnote3 j=l "[b] p-value is provided byFisher Exact test";
footnote4 j=l  "C:\C1\ST\Jul2022\CL\program\tab9_1.SAS";



options orientation=landscape;
ods escapechar='^';
ods rtf file='C:\C1\ST\Jul2022\CL\OUTPUTS\t_14_1_11.rtf' style=styles.test;


proc report data=final split='|' style= {outputwidth=100%};

   column ord1 ord2 c0 c1 c2;

   define ord1/order noprint;
   define ord2/order noprint;

   define c0/ "Definition / rate|Statistic"
   style (column)={just=l cellwidth=30% asis=on}
   style (header)={just=l cellwidth=30% asis=on};

   define c1/ "Tafenoquine|(N=&N1)"
   style (column)={just=l cellwidth=20% }
   style (header)={just=l cellwidth=20% };

   define c2/ "Placebo|(N=&N2)"
   style (column)={just=l cellwidth=20% }
   style (header)={just=l cellwidth=20% };

   compute before _page_;
   line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;


   compute after _page_;
   line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;

   compute before ord1;
   line '';
   endcomp;
run;

ods _all_ close;


