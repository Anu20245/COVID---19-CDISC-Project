/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: tab10_1.SAS  
*
* Program Type: Table
*
* Purpose: To produce Table 14.1.12 Summary of Hospitalization Rate Due to COVID-19 Symptoms with a 2x2 Contingency Table
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
proc datasets lib=work kill;
run;
quit;


DATA ADSL;
   SET ADAM.ADSL;
   /*to reorder main drug vs placebo*/
   IF TRT01P='Placebo' THEN TRTCD='B';
   IF TRT01P='Tquine' THEN TRTCD='A';

   IF hospcofl NE 'Y' THEN hospcofl='N';
   IF TRT01P NE '';
   KEEP USUBJID TRT01P TRT01PN hospcofl TRTCD;
RUN;


PROC SQL NOPRINT;
   SELECT COUNT (DISTINCT USUBJID) INTO: n1-:n2
   FROM ADSL
   GROUP BY TRT01PN,TRT01P
   ORDER BY TRT01PN,TRT01P;
QUIT;

%PUT &n1 &n2;


proc sql noprint;
   create table count as
   select count (distinct usubjid) as cnt,trtcd,hospcofl from adsl
   group by trtcd,hospcofl
   order by trtcd,hospcofl;

   create table bign as /* to calculate percentage */
   select count (distinct usubjid) as bign,trtcd from adsl
   group by trtcd
   order by trtcd;

quit;

data all;
   merge count (in=a) bign (in=b);
   by trtcd;

   npct= put (cnt,3.)||" ("|| put (cnt/bign*100,5.1)||")";
run;

proc transpose data=all out=trans ;
/*   need only Hospitalised subject*/
   where hospcofl ne 'N' ;
   var npct;
   id trtcd;
run;


data npct;
   set trans;
   length value $100.;
   value='n (%)';
   ord=1;
run;
/*Row 'n (%)	Xx (xx.x)	Xx(xx.x))'*/


ODS TRACE ON;
ODS OUTPUT  BinomialCLs=CI;
proc freq data=all;
   by trtcd;
   tables hospcofl/binomial (level="Y" EXACT);
   WEIGHT CNT/ZEROS;

RUN;
ODS TRACE OFF;


DATA C1;
   SET CI;
   CI="("|| STRIP (PUT (LowerCL,5.1))||", "|| STRIP (PUT (UpperCL,5.1))||")";
   length value $100.;
   value='95% CI for Hospitalization Rate[a]';
   ord=2;

RUN;
/*Row '95% CI for Hospitalization Rate[a]	x.xx, x.xx)	x.xx, x.xx)'*/

proc transpose data=C1 out=trans2 ;
   BY ORD value;
   var CI;
   id trtcd;
run;

ODS TRACE ON;
ODS OUTPUT  FishersExact= FISHER (WHERE=(Name1='XP2_FISH'));
PROC FREQ DATA=ALL;
   TABLES TRTCD*hospcofl/CHISQ;
   WEIGHT CNT;
RUN;
ODS TRACE OFF;


DATA FISHER1;
   SET FISHER;
   A= STRIP (PUT (nValue1,6.4));
   length value $100.;
   value='p-value[b]';
   ord=3;
   KEEP ORD VALUE A;
RUN;
/*Row 'p-value[b]	x.xxxx	'*/
DATA ALL;
   SET npct TRANS2 FISHER1;
   DROP _NAME_;
RUN;
/*stack all rows*/



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
title3 j=c 'Table 14.1.12 Summary of Hospitalization Rate Due to COVID-19 Symptoms with a 2x2 Contingency Table';

footnote1 j=l "[b] p-value is provided byFisher Exact test";
footnote2 j=l  "C:\C1\ST\Jul2022\CL\program\tab10_1.SAS";



options orientation=landscape;
ods escapechar='^';
ods rtf file='C:\C1\ST\Jul2022\CL\OUTPUTS\t_14_1_12.rtf' style=styles.test;

proc report data=ALL split='|' style= {outputwidth=100%};

   column ord VALUE A B;

   define ord/order noprint;

   define VALUE/ "Statistic"
   style (column)={just=l cellwidth=30% asis=on}
   style (header)={just=l cellwidth=30% asis=on};

   define A/ "Tafenoquine|(N=&N1)"
   style (column)={just=l cellwidth=20% }
   style (header)={just=l cellwidth=20% };

   define B/ "Placebo|(N=&N2)"
   style (column)={just=l cellwidth=20% }
   style (header)={just=l cellwidth=20% };

   compute before _page_;
   line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;


   compute after _page_;
   line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;

run;

ods _all_ close;

