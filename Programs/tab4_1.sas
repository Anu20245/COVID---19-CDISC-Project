/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: tab4_1.SAS  
*
* Program Type: Table
*
* Purpose: To produce Table 14.1.5  Subject Demographics (Safety Population)
* Usage Notes: 
*
* SAS Version: 9.4
* Operating System: Windows 2003 R2 Standard Edition.                   
*
* Author: 
* Date Created: 
* Modification History:
*******************************************************************/          
libname adam "C:\C1\ST\Jul2022\CL\ADAM datasets";

proc datasets lib=work kill nolist;
run; quit;

DATA ADSL_1;
   SET ADAM.ADSL;
   IF TRT01A NE '' and SAFFL EQ 'Y';
/*   keep heigh weight and bmi*/
   KEEP USUBJID TRT01A TRT01AN BHGHTSI BWGHTSI BBMISI;
RUN;


DATA ADSL_2;
   SET ADAM.ADSL;
   IF TRT01A NE '' and SAFFL EQ 'Y';
   TRT01A="ALL";
   TRT01AN=3;
/*   keep heigh weight and bmi*/
   KEEP USUBJID TRT01A TRT01AN BHGHTSI BWGHTSI BBMISI;
RUN;

DATA ADSL_3;
   SET ADSL_1 ADSL_2;
RUN;

PROC SORT ;BY USUBJID;RUN;

PROC SQL NOPRINT;
   CREATE TABLE TRT AS 
      SELECT TRT01AN,TRT01A,COUNT (USUBJID) AS DENOM
      FROM ADSL_3
      GROUP BY TRT01AN ,TRT01A
      ORDER BY TRT01AN,TRT01A
      ;

   SELECT DENOM INTO: N1 - :N3 FROM TRT;
QUIT;
%PUT &N1 &N2 &N3;

/*structure to store intermediate result of all categories*/
proc sql;
create table WORK.ADSL_SUM51
  (
   stat char(100),
   od num,
   _NAME_ char(8) label='NAME OF FORMER VARIABLE',
   t1 char(5),
   t2 char(5),
   t3 char(5),
   grp_cat num
  );
quit;

/*create macro to derive stat for all category*/
%macro categ(var_nm= , cat_first_row=, ord_index=);
   /*get five stat as required in mock shell*/
   PROC SUMMARY DATA=ADSL_3 nway;
      CLASS TRT01AN;
      VAR &var_nm;
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

   /*transpose all five stat from COLUMN to ROW*/
   proc transpose data=adsl_sum2 out=adsl_sum3 prefix=t;
      id trt01an;
      var cn cmean cmedian cstd cmin cmax;
   run;

   /*create first column per mock shell*/
   data adsl_sum4;
      set adsl_sum3;
      length stat $100. od 8.;
      if _NAME_ ='cn' then do; stat='N';od=%eval(&ord_index. + 1 );end;
      if _NAME_ ='cmean' then do; stat='Mean';od=%eval(&ord_index. + 2 );end;
      if _NAME_ ='cstd' then do; stat='SD';od=%eval(&ord_index. + 3 );end;
      if _NAME_ ='cmedian' then do; stat='Median';od=%eval(&ord_index. + 4 );end;
      if _NAME_ ='cmin' then do; stat='Minimum';od=%eval(&ord_index. + 5 );end;
      if _NAME_ ='cmax' then do; stat='Maximum';od=%eval(&ord_index. + 6 );end;
   run;
   proc sort;by od;run;
   /*create first row in each category*/
   data label;
      length stat $100. od 8.;
      stat="&cat_first_row";
      od=%eval(&ord_index. + 0 );
   run;


   data adsl_sum5;
      set label adsl_sum4;
      grp_cat=&ord_index;
   run;
   proc sort;by od;run;

   proc append base=ADSL_SUM51 data=ADSL_SUM5 ; run;

%mend categ;

%categ(var_nm=BHGHTSI, cat_first_row=%str (Height (cm)), ord_index=10);
%categ(var_nm=BWGHTSI, cat_first_row=%str (Weight (cm)), ord_index=20);
%categ(var_nm=BBMISI, cat_first_row=%str (BMI (kg/m2)), ord_index=30);


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
title3 j=c 'Table 14.1.5  Subject Demographics (Safety Population)';

footnote1 j=l 'C:\C1\ST\Jul2022\CL\program\tab4_1.SAS';


options orientation=landscape;
ods escapechar='^';
ods rtf file='C:\C1\ST\Jul2022\CL\OUTPUTS\t_14_1_5.rtf' style=styles.test;


proc report data=adsl_sum51 split='|' style= {outputwidth=100%};

   column grp_cat od stat t1 t2 t3 ;

   define grp_cat / order noprint;

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

   compute before grp_cat;
      line '';
   endcomp;

run;

ods _all_ close;






