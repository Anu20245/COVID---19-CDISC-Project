/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: tab3_1.SAS  
*
* Program Type: Table
*
* Purpose: To produce Table 14.1.3  Subject Demographics - Age (Safety Population)
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
   *if saffl eq 'Y';
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
      ORDER BY TRT01AN,TRT01A
      ;

   SELECT DENOM INTO: N1 - :N3 FROM TRT;
QUIT;
%PUT &N1 &N2 &N3;


/*/*/*/*/*/*/*/*/*/*BODY SECTION STATS*/*/*/*/*/*/*/*/*/*/;


DATA ADSL_1;
   SET ADAM.ADSL;
   IF TRT01A NE '' and SAFFL EQ 'Y';
   KEEP USUBJID TRT01A TRT01AN age;
RUN;


DATA ADSL_2;
   SET ADAM.ADSL;
   IF TRT01A NE '' and SAFFL EQ 'Y';
   TRT01A="ALL";
   TRT01AN=3;
   KEEP USUBJID TRT01A TRT01AN age;
RUN;

DATA ADSL_3;
   SET ADSL_1 ADSL_2;
RUN;

PROC SORT ;BY USUBJID;RUN;

/*get five stat as required in mock shell*/
PROC SUMMARY DATA=ADSL_3 nway;
   CLASS TRT01AN;
   VAR AGE;
   OUTPUT OUT=ADSL_SUM n=_n mean=_mean median=_median std=_std min=_min max=_max;
run;

/*convert all stat from numeric to character*/
data adsl_sum2;
   set adsl_sum;

   cn= left (put(_n,3.));
   cmin=left (put(_min,3.));
   cmax=left (put(_max,3.));

   cmedian=left (put(_median,4.1));
   cmean=left (put(_mean,4.1));
   cstd=left (put(_std,5.2));
run;

proc transpose data=adsl_sum2 out=adsl_sum3 prefix=t;
   id trt01an;
   var cn cmean cmedian cstd cmin cmax;
run;

data adsl_sum4;
   set adsl_sum3;
   length stat $100.;
   if _NAME_ ='cn' then do; stat='N';od=1;end;
   if _NAME_ ='cmean' then do; stat='Mean';od=2;end;
   if _NAME_ ='cstd' then do; stat='SD';od=3;end;
   if _NAME_ ='cmedian' then do; stat='Median';od=4;end;
   if _NAME_ ='cmin' then do; stat='Minimum';od=5;end;
   if _NAME_ ='cmax' then do; stat='Maximum';od=6;end;
run;
proc sort;by od;run;


data label;
   length stat $100.;
   stat='Age (Years) ';
   od=0;
run;


data adsl_sum5;
   set label adsl_sum4;
run;
proc sort;by od;run;

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
title3 j=c 'Table 14.1.3  Subject Demographics - Age (Safety Population)';

footnote1 j=l 'C:\C1\ST\Jul2022\CL\program\tab3_1.SAS';


options orientation=landscape;
ods escapechar='^';
ods rtf file='C:\C1\ST\Jul2022\CL\OUTPUTS\t_14_3_1.rtf' style=styles.test;

proc report data=adsl_sum5 split='|' style= {outputwidth=100%};

   column od stat t1 t2 t3;

   define od/order noprint;

   define stat/ "CATEGORY"
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
