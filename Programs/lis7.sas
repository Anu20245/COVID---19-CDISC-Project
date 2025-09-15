/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: lis7.SAS  
*
* Program Type: Listing
*
* Purpose: To produce 16.2.1.7 Vital Signs 
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

DATA ADSL;
   SET ADAM.ADVS;
   /*   time part of measurement is not available for all subject, need to derive it using ADTM and ADT*/
/*   OR use variable VSDTC*/
   if adtm ne . then adtc=strip(put(adtm,e8601dt.));
   else adtc=strip(put(adt,e8601da.));
   AVISIT=strip(AVISIT);
   KEEP USUBJID PARAMN PARAM AVISITN AVISIT  AVALC adtc TRT01A; * keep only required columns ;
RUN;

data adsl;
   set adsl;
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
title2 j=l 'Protocol: 043-1810';
title3 j=c '16.2.1.7 Vital Signs ';

footnote1 j=l 'C:\C1\ST\Jul2022\CL\Program\LIS7.SAS';

options orientation=landscape;
ods escapechar='^';
ods rtf file='C:\C1\ST\Jul2022\CL\Outputs\l_16_2_1_7.rtf' style=styles.test;

proc report data=adsl split='|' style= {outputwidth=100%};

   column page1 USUBJID PARAMN PARAM AVISITN AVISIT  AVALC adtc TRT01A;

   define page1/order noprint;

   define usubjid/order "Subject"
   style (column)={just=l cellwidth=15%}
   style (header)={just=l cellwidth=15%}
   ;

   define PARAMN/ order noprint; /* couple variables */
   define PARAM/ "Parameter (unit)"
   style (column)={just=l cellwidth=20%}
   style (header)={just=l cellwidth=20%}
   ;

   define AVISITN/ order noprint; /* couple variables */
   define AVISIT/ "Visit"
   style (column)={just=l cellwidth=19%}
   style (header)={just=l cellwidth=19%}
   ;

   define AVALC/ "Observed value"
   style (column)={just=l cellwidth=12%}
   style (header)={just=l cellwidth=12%}
   ;

   define adtc/ "Date/Time of|Measurements"
   style (column)={just=l cellwidth=19%}
   style (header)={just=l cellwidth=19%}
   ;
   define TRT01A/ "Treatment"
   style (column)={just=l cellwidth=13%}
   style (header)={just=l cellwidth=13%}
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
