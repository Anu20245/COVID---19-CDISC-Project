/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: lis8.SAS  
*
* Program Type: Listing
*
* Purpose: To produce 16.2.2.2 Serious Adverse Events Leading to Death       
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

DATA ADAE;
   SET ADAM.ADAE;
   /* filter logic - Serious Adverse Events Leading to Death       */
   IF AESER EQ 'Y' AND AEOUT EQ 'FATAL';
RUN;

PROC SQL NOPRINT;
   SELECT COUNT (*) INTO: NBR FROM ADAE;
QUIT;
%PUT &NBR;

DATA ADAE;
   usubjid='';
   TEXT="NO OBSERVATION";
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
title3 j=c '16.2.2.2 Serious Adverse Events Leading to Death';

footnote1 j=l 'C:\C1\ST\Jul2022\CL\program\LIS8.SAS';


options orientation=landscape;
ods escapechar='^';
ods rtf file='C:\C1\ST\Jul2022\CL\OUTPUTS\l_16_2_2_2.rtf' style=styles.test;



proc report data=ADAE split='|' style= {outputwidth=100%};

   column usubjid TEXT;

   define usubjid/ "Subject|Number"
   style (column)={just=l cellwidth=5%}
   style (header)={just=l cellwidth=5%}
   ;
   
   define TEXT/order ""
   style (column)={just=C cellwidth=80%}
   style (header)={just=C cellwidth=80%}
   ;

   compute before _page_;
      line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;


   compute after _page_;
      line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;

run;

ods _all_ close;








