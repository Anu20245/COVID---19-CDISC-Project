/*******************************************************************
* Client:                                                            
* Project:                                                     
* Program: tab7_1.SAS  
*
* Program Type: table
*
* Purpose: To produce Table 14.1.8 Summary of Changes in Vital Signs from Baseline to Final Visit (Safety Population)                                                              

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

proc summary data=adam.advs nway;
/*   filter data for safety population*/
   where saffl eq 'Y';
   /* classification variables - need to report data per parameters, per Treatment, per Visit */
   class paramn param trt01an trt01a avisitn avisit;
   var aval; /* column 'Observed' to be calculated in mockshell */
   output out=adsl_sum n=_n mean=_mean median=_median std=_std min=_min max=_max; /* Stats to be reported */
run;


data adsl_sum2;
   set adsl_sum;
   /*convert all numers to character*/
   cn= left (put (_n,4.));
   cmin=left (put (_min,4.));
   cmax=left (put (_max,4.));

   cmedian=left (put (_median,5.1));
   cmean=left (put (_mean,5.1));
   cstd= left (put (_std,6.2));

run;



proc summary data=adam.advs nway;
   /*change only to be posted if more than one visit*/
   where saffl eq 'Y' and avisitn gt 1;
   /*need to report data per parameter, per treatment, per visit*/
   class paramn param trt01an trt01a avisitn avisit;
   /*column - 'Change from baseline '*/
   var chg; 
   /*stats to be reported*/
   output out=adsl_chg_sum n=_n mean=_mean median=_median std=_std min=_min max=_max; 
run;


data adsl_chg_sum2;
   set adsl_chg_sum;
     /*convert all numers to character*/
   hn= left (put (_n,4.));
   hmin=left (put (_min,4.));
   hmax=left (put (_max,4.));

   hmedian=left (put (_median,5.1));
   hmean=left (put (_mean,5.1));
   hstd= left (put (_std,6.2));

run;

data final;
   merge adsl_sum2 adsl_chg_sum2;
   by paramn param trt01an trt01a avisitn avisit;
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



title1 j=l "COVID-19 AA";
title2 j=l "Protocol: 043";
title3 j=c "Table 14.1.8 Summary of Changes in Vital Signs from Baseline to Final Visit (Safety Population)";

footnote1 j=l "C:\C1\ST\Jul2022\CL\program\tab7_1.SAS";

options orientation=landscape;
ods escapechar="^";

ods rtf file="C:\C1\ST\Jul2022\CL\OUTPUTS\t_14_1_8.rtf" style=styles.test;


proc report data=final nowd split="|" missing style ={outputwidth=100%};

   column paramn param trt01an trt01a avisitn avisit
   ("Observed" "---------------------------" cn cmean cmedian cstd cmin cmax)
   ("Change from baseline" "----------------------------------"  
   hn hmean hmedian hstd hmin hmax);

   define paramn/order noprint;
   define param/order noprint;

   define trt01an/order noprint;
   define trt01a /group "Treatment "
   style (column) ={just=l cellwidth=10% }
   style (header) ={just=l cellwidth=10% };

   define avisitn/order noprint;
   define avisit /group "Visit "
   style (column) ={just=l cellwidth=20% }
   style (header) ={just=l cellwidth=20% };


   define cn /display "n"
   style (column) ={just=l cellwidth=3% }
   style (header) ={just=l cellwidth=3% };


   define cmean /display "Mean"
   style (column) ={just=l cellwidth=5% }
   style (header) ={just=l cellwidth=5% };

   define cmedian /display "Median"
   style (column) ={just=l cellwidth=5% }
   style (header) ={just=l cellwidth=5% };

   define cstd /display "SD"
   style (column) ={just=l cellwidth=5% }
   style (header) ={just=l cellwidth=5% };


   define cmin /display "Min"
   style (column) ={just=l cellwidth=5% }
   style (header) ={just=l cellwidth=5% };

   define cmax /display "Max"
   style (column) ={just=l cellwidth=5% }
   style (header) ={just=l cellwidth=5% };



   define hn /display "n"
   style (column) ={just=l cellwidth=3% }
   style (header) ={just=l cellwidth=3% };


   define hmean /display "Mean"
   style (column) ={just=l cellwidth=5% }
   style (header) ={just=l cellwidth=5% };

   define hmedian /display "Median"
   style (column) ={just=l cellwidth=5% }
   style (header) ={just=l cellwidth=5% };

   define hstd /display "SD"
   style (column) ={just=l cellwidth=5% }
   style (header) ={just=l cellwidth=5% };


   define hmin /display "Min"
   style (column) ={just=l cellwidth=5% }
   style (header) ={just=l cellwidth=5% };

   define hmax /display "Max"
   style (column) ={just=l cellwidth=5% }
   style (header) ={just=l cellwidth=5% };


   compute before _page_;
   line@1 "Parameter:  " param $;
   line@1 "^{style [outputwidth=100% borderbottomwidth=0.5pt]}";
   endcomp;



   compute after _page_;
   line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;

   break after paramn/page;

run;

ods _all_ close;
