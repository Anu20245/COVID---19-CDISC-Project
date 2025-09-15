/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: tab5_1.SAS  
*
* Program Type: Table
*
* Purpose: To produce Table 14.1.6 Subject Demographics -Sex and Race  (Safety Population)
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
/*   to maintain male - female order and race oder per mock shell need to keep couplevariables sexn racen*/
   KEEP USUBJID TRT01A TRT01AN sex sexn race racen ;
RUN;


DATA ADSL_2;
   SET ADAM.ADSL;
   IF TRT01A NE '' and SAFFL EQ 'Y';
   TRT01A="ALL";
   TRT01AN=3;
   KEEP USUBJID TRT01A TRT01AN sex sexn race racen ;
RUN;

DATA ADSL_3;
   SET ADSL_1 ADSL_2;
RUN;

PROC SORT ;BY USUBJID;RUN;


PROC FREQ DATA=ADSL_3 NOPRINT;
   TABLES SEXN*SEX*TRT01AN/OUT=GENDER (DROP=PERCENT);
RUN;

DATA GENDER;
   SET GENDER;
   LENGTH CAT stat $200.;
   CAT='Gender'; /* first column in mock shell */
   CATN=1;


   IF SEXN=1 THEN DO; STAT='Male';end; /* second column in mock shell */
   IF SEXN=2 THEN DO; STAT='Female';end;
run;


PROC FREQ DATA=ADSL_3 NOPRINT;
   TABLES racen*race*TRT01AN/OUT=race (DROP=PERCENT);
RUN;

/*create Asian race (presented in mock shell), which is not present in data*/
proc sort data=race out=race1 (keep=trt01an) nodupkey;
   by trt01an;
run;

data dummy;
   set race1;
   length race $200.;
   DO RACE='ASIAN' , 'BLACK OR AFRICAN AMERICAN','WHITE';
      output;
   end;
run;

proc sort data=dummy;by trt01an race;run;
proc sort data=race;by trt01an race;run;


data race_dum;
   merge dummy race;
   by trt01an race;

   if count eq . then count=0;
   if race='ASIAN' then racen=1;
run;


DATA race_dum2;
   SET race_dum;
   LENGTH CAT stat $200.;
   /*first column per mock shell*/
   CAT='Race';
/*   to maintain Gender and Race order in template*/
   CATN=2;

   /*second column per mock shell*/
   IF racen=1 THEN DO; STAT='Asian';end;
   IF racen=3 THEN DO; STAT='Black or african american';end;
   IF racen=5 THEN DO; STAT='White';end;

run;

data final;
   set GENDER race_dum2;
run;

proc sort;by trt01an;run;

data pct;
   merge final (in=a) trt (in=b);
   by trt01an;
   if a;
run;

/*calculate actual cell values n (%)*/
data pct1;
   set pct;
   length grp $100.;
   grp= strip(put (count,4.))||" ("|| strip(put (count/denom*100,5.1))||")";
   if grp='0 (0.0)' then grp='0';
run;

proc sort;by CATN sexn racen ;run;



proc transpose data=pct1 out=final2 prefix=t;
   id trt01an;
   by catn cat sexn racen stat;
   var grp;
run;


DATA FINAL2;
   SET FINAL2;

   IF T1='' THEN T1='  0';
   IF T2='' THEN T2='  0';
   IF T3='' THEN T3='  0';
/*   introduce new order variable having sexn and racen for proc report*/
   if sexn ne . then do; od=sexn;end;
   if racen ne . then do;od=racen;end;
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
title3 j=c 'Table 14.1.6 Subject Demographics -Sex and Race  (Safety Population)';

footnote1 j=l 'C:\C1\ST\Jul2022\CL\program\tab5_1.SAS';


options orientation=landscape;
ods escapechar='^';
ods rtf file='C:\C1\ST\Jul2022\CL\OUTPUTS\t_14_1_6.rtf' style=styles.test;

proc report data=final2 split='|' style= {outputwidth=100%};

   column catn cat od stat  t1 t2 t3;

   define catn/order noprint;
   define cat/group "Category"
   style (column)={just=l cellwidth=20% asis=on}
   style (header)={just=l cellwidth=20% asis=on}
   ;

/*   maintain order for column two statistic*/
   define od/order noprint;
   define stat/ "Statistic"
   style (column)={just=l cellwidth=20% asis=on}
   style (header)={just=l cellwidth=20% asis=on}
   ;



   define t1/ "DRUG A|(N=&N1)"
   style (column)={just=l cellwidth=10% asis=on}
   style (header)={just=l cellwidth=10% asis=on}
   ;


   define t2/ "DRUG B|(N=&N2)"
   style (column)={just=l cellwidth=10% asis=on}
   style (header)={just=l cellwidth=10% asis=on}
   ;


   define t3/ "ALL|(N=&N3)"
   style (column)={just=l cellwidth=10% asis=on}
   style (header)={just=l cellwidth=10% asis=on}
   ;

   compute before _page_;
   line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;


   compute after _page_;
   line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;

   compute before catn;
   line '';
   endcomp;

run;

ods _all_ close;
