/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: tab8_1.SAS  
*
* Program Type: Table
*
* Purpose: To produce Table 14.1.10 Shift Table from Baseline to End of period (Safety Population)
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
run; quit;
/*N calculation*/
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
   SELECT TRT01AN,TRT01A,COUNT (distinct USUBJID) AS DENOM
   FROM ADSL3
   GROUP BY TRT01AN ,TRT01A
   ORDER BY TRT01AN,TRT01A;

   SELECT DENOM INTO: N1 - :N3 FROM TRT;
QUIT;
%PUT &N3;

/**/
/*proc sort nodupkey;by usubjid;*/
/**/
/*proc freq data=ADSL3;*/
/*tables trt01an/out=xx;*/
/*run;*/


data adlb;
   set adam.adlb;
   /*Include Biochemistry and Hematology ONLY - for safety population*/
   if saffl eq 'Y' and parcat1 in ("HEMATOLOGY" "CHEMISTRY");
   if bnrind eq '' then bnrind='MISSING';
   if anrind eq '' then anrind='MISSING';

   keep usubjid parcat1 paramn param avisitn avisit bnrind anrind;
run;

proc sort;by usubjid parcat1 paramn param avisitn avisit;run;

data lb;
   set adlb;
   by usubjid parcat1 paramn param avisitn avisit;
   /*keep on 'Treatment  end' status*/
   if last.paramn;
run;

proc freq data=lb noprint;
   /*per parameter category, per Parameter (Unit) frequency distribution of Baseline*Treatment  end*/
   tables parcat1*paramn*param*bnrind*anrind/out=lb2 (drop=percent);
run;

/*to calculate percentage*/
data lb2;
   set lb2;
/*   calculating based on ALL treatement - refer to 'trt' dataset*/
   trt01an=3;
   nn=count;
run;

proc sort;by trt01an;run;

data pct;
/*   bring denominator from 'trt' dataset*/
   merge lb2 (in=a) trt (in=b);
   by trt01an;
   if a;
run;


data pct1;
   set pct;
   length grp $100.;
   grp= strip(put (nn,4.))||" ("|| strip(put (nn/denom*100,5.1))||")";

run;



proc transpose data=pct1 out=final2 ;
   id anrind;
   by parcat1 paramn param bnrind;
   var grp;
run;

data final2;
   set final2;
   if low eq'' then low ='  0';
   if normal  eq '' then normal ='  0';
   if high eq '' then high ='  0';
run;


data final2;
   set final2;
   retain lnt 0 page1 1;
   lnt+1;

   if lnt>15 then do;
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
title3 j=c 'Table 14.1.10 Shift Table from Baseline to End of period (Safety Population)';

footnote1 j=l 'C:\C1\ST\Jul2022\CL\program\tab8_1.SAS';


options orientation=landscape;
ods escapechar='^';
ods rtf file='C:\C1\ST\Jul2022\CL\OUTPUTS\t_14_1_10.rtf' style=styles.test;

proc report data=final2 split='|' style= {outputwidth=100%};

   column page1 parcat1 paramn param bnrind

   ("Treatment  end|(N=&N3)" "^{style [outputwidth=100% bordertopwidth=0.5pt]}"
   low normal high)
   ;
   define page1/order noprint;
   define parcat1/group "Parameter|category "
   style (column)={just=l cellwidth=10% }
   style (header)={just=l cellwidth=10% }
   ;


   define paramn/order noprint;
   define param/group "Parameter (Unit)"
   style (column)={just=l cellwidth=20% }
   style (header)={just=l cellwidth=20% }
   ;

   define bnrind/ "Baseline"
   style (column)={just=l cellwidth=10% }
   style (header)={just=l cellwidth=10% }
   ;


   define low/ "Low"
   style (column)={just=l cellwidth=10% }
   style (header)={just=l cellwidth=10% }
   ;

   define Normal/ "Normal"
   style (column)={just=l cellwidth=10% }
   style (header)={just=l cellwidth=10% }
   ;

   define high/ "High"
   style (column)={just=l cellwidth=10% }
   style (header)={just=l cellwidth=10% }
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

