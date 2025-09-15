/*******************************************************************
* Client:  xxxxxx
* Project:  yyyyyyy
* Program: lis3.SAS
*
* Program Type: Listing
*
* Purpose: To produce 16.2.1.3 Subject Demographics
* Usage Notes:
*
* SAS Version: 9.4
* Operating System: Windows 1003 R2 Standard Edition.
*
* Author: 
* Date Created: 
* Modification History:
*******************************************************************/
libname adam "C:\C1\ST\Jul2022\CL\ADAM datasets";
proc datasets lib=work kill nolist;
run;
data ADSL;
   set adam.ADSL;
   keep USUBJID TRT01P AGE SEX RACE BHGHTSI BWGHTSI BBMISI;
run;


data ADSL;
   set adam.ADSL;
   keep USUBJID TRT01P AGE SEX RACE BHGHTSI_C BWGHTSI_C BBMISI_C;
   /* convert all numeric type to character */
   BHGHTSI_C = strip(put(BHGHTSI,best.));
   BWGHTSI_C = strip(put(BWGHTSI,best.));
   BBMISI_C = strip(put(BBMISI,best.));
run;

DATA ADSL;
   SET ADSL;
   RETAIN LNT 0 PAGE1 1;
   LNT+1;
   IF LNT>20 THEN DO;
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
title3 j=c '16.2.1.3 Subject Demographics';

footnote1 j=l 'C:\C1\ST\Jul2022\CL\Program\LIS3.SAS';


options orientation=landscape;
ods escapechar='^';
ods rtf file='C:\C1\ST\Jul2022\CL\Outputs\l_16_2_1_3.rtf' style=styles.test;

proc report data=adsl split='|' style= {outputwidth=100%};

   column page1 USUBJID TRT01P AGE SEX RACE BHGHTSI_C BWGHTSI_C BBMISI_C ;

   define page1/order noprint;

   define usubjid/order "Subject|Number"
   style (column)={just=l cellwidth=20%}
   style (header)={just=l cellwidth=20%}
   ;

   define TRT01P /"Treatment|Sequence"
   style (column)={just=l cellwidth=10%}
   style (header)={just=l cellwidth=10%}
   ;

   define AGE /"Age* (years)"
   style (column)={just=l cellwidth=10%}
   style (header)={just=l cellwidth=10%}
   ;

   define SEX /"Sex"
   style (column)={just=l cellwidth=10%}
   style (header)={just=l cellwidth=10%}
   ;
   define RACE/ "Race"
   style (column)={just=l cellwidth=10%}
   style (header)={just=l cellwidth=10%}
   ;
   define BHGHTSI_C/ "Height (cm)"
   style (column)={just=l cellwidth=10%}
   style (header)={just=l cellwidth=10%}
   ;
   define BWGHTSI_C/ "Weight (kg)"
   style (column)={just=l cellwidth=10%}
   style (header)={just=l cellwidth=10%}
   ;
   define BBMISI_C/ "BMI (kg/m2)"
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
