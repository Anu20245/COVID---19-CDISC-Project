/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: lis6.SAS  
*
* Program Type: Listing
*
* Purpose: To produce 16.2.1.6 Abnormal Hematology Values 
* Usage Notes: 
*
* SAS  Version: 9.2 [TS2M0]
* Operating System: Windows 2003 R2 Standard Edition.                   
*
* Author: 
* Date Created: 
* Modification History:
*******************************************************************/          
libname adam "C:\C1\ST\Jul2022\CL\ADAM datasets";

proc datasets lib=work kill nolist;
run;

DATA ADLB;

   SET ADAM.ADLB;

   IF PARCAT1='HEMATOLOGY' and ANRIND not in ('NORMAL','');
   ADTC= PUT (ADT,YYMMDD10.);
   AVAL_C= STRIP (PUT (AVAL,BEST.));
   LO_HI= STRIP (PUT (ANRLO,BEST.))||"-"||STRIP (PUT (ANRHI,BEST.));
   KEEP USUBJID PARAMN PARAM AVISITN AVISIT  LO_HI  ADTC AVAL_C ANRIND;
RUN;

PROC SORT;BY USUBJID PARAMN PARAM AVISITN AVISIT;RUN;


DATA ADLB;
   SET ADLB;
   RETAIN LNT 0 PAGE1 1;
   LNT+1;

   IF LNT>15 THEN DO;
      PAGE1=PAGE1+1;
      LNT=1;
   END;
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
title3 j=c "16.2.1.6 Abnormal Hematology Values";

footnote1 j=l 'C:\C1\ST\Jul2022\CL\program\LIS6.SAS';


options orientation=landscape;
ods escapechar='^';
ods rtf file='C:\C1\ST\Jul2022\CL\OUTPUTS\l_16_2_1_6.rtf' style=styles.test;



proc report data=adlb split='|' style= {outputwidth=100%};

   column page1 USUBJID PARAMN PARAM AVISITN AVISIT  LO_HI  ADTC AVAL_C ANRIND;

   define page1/order noprint;

   define usubjid/order "Subject|Number"
   style (column)={just=l cellwidth=15%}
   style (header)={just=l cellwidth=15%}
   ;

   define PARAMN/order noprint;
   define PARAM/ "Test"
   style (column)={just=l cellwidth=25%}
   style (header)={just=l cellwidth=25%}
   ;

   define AVISITN/order noprint;
   define AVISIT/ "Visit"
   style (column)={just=l cellwidth=17%}
   style (header)={just=l cellwidth=17%}
   ;


   define LO_HI/ "Normal Range"
   style (column)={just=l cellwidth=10%}
   style (header)={just=l cellwidth=10%}
   ;


   define ADTC/ "Date/Time of|Measurement"
   style (column)={just=l cellwidth=10%}
   style (header)={just=l cellwidth=10%}
   ;

   define AVAL_C/ "Result"
   style (column)={just=l cellwidth=5%}
   style (header)={just=l cellwidth=5%}
   ;
   define ANRIND/ "Flag"
   style (column)={just=l cellwidth=10%}
   style (header)={just=l cellwidth=10%}
   ;

   compute before _page_;
   line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;


   compute after _page_;
   line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;

   break after page1/page;
run;

ods _all_ close;
