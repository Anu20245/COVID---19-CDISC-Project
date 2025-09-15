proc format;
   value $trt
      'B' = "Treatment 20mg"
      'S' = "Treatment 10mg"
      'P' = "Placebo";
   value visit
      1='Baseline'
      2='6 Months'
      3='9 Months';
run;

data response;
   input trt $ week perc lo hi end;
   x1=15;
   format trt $trt.;
   cards;
P  0  0    0     0    .
P  3  2    1.25  2.75 . 
P  6  -.5 -1.2  .5    . 
P  9  1   -.5   1.75  .
P 12  2.25 .5   3.25  2.25
P 15  3    -.25 4.25  3.85
S  0  0    0     0    .
S  3  8    7.25  8.75 .   
S  6  7.5  6.5   8.75 . 
S  9  7.5  6.5   8.75 . 
S 12  7.75 6.5   8.5  7.75 
S 15  7.5  5.0   8.25 3.7
B  0  0    0     0    .
B  3  12   11.25 12.75 .
B  6  13   12.25 13.75 .
B  9  13.25 12.5 14.0  .  
B 12  13    12.25 13.75 13 
B 15  12.85 12.1  13.6  3.6
;
run;

title "Mean Percent Change from Baseline";
title2 " ";

ods listing close;
ods graphics / reset width=600px height=400px imagename='Allergy' imagefmt=gif;
ods html file='allergy.html' path='C:\C1\ST\Jul2022\CL' style=styles.default; 

proc sgplot data=response;
   band y=x1 lower=12.1 upper=15 / transparency=.8 fillattrs=graphdata1;
   scatter x=week y=perc / group=trt yerrorlower=lo yerrorupper=hi
       markerattrs=(symbol=circlefilled) name="scat";
   series x=week y=perc / group=trt lineattrs=(pattern=solid);
   series x=week y=end / group=trt markers lineattrs=(pattern=shortdash)
       markerattrs=(symbol=circle);
   xaxis integer values=(0 to 15 by 3) label="Weeks in Treatment";
   yaxis label="Percent Change";
   refline 0; 
   refline 13.55 / axis=x label="|--Washout--|"
       labelloc=outside labelpos=min lineattrs=(thickness=0px);
   keylegend "scat" / title="" noborder;
run;

ods html close;
ods listing;

libname adam "C:\C1\ST\Jul2022\CL\ADAM datasets";


data lb1;
set adam.adlb;

trt=trt01a;
week=avisitn;
perc=chg;
lo=ANRLO;
hi=ANRHI;
x1=15;
if trt ne '';
if paramcd eq 'ALT';
if week=15 then do;
end=perc;end;
keep trt week perc lo hi x1 end;
run;
proc sort nodupkey;by _all_;run;

ods _all_ close; 
/* ERROR: Cannot write image to SGPlot.png. Please ensure that proper disk permissions are set */
ods html file='allergy.html' path='C:\C1\ST\Jul2022\CL' style=styles.default; 

TITLE1 J=L "COVID-19 AA";
TITLE2 J=L "Protocol: 043";
title3 j=c "Figure 16.1.3 ALT Change from Baseline";



options orientation=landscape;
ods escapechar='^';
ods rtf file ="C:\C1\ST\Jul2022\CL\OUTPUTS\16_1_3.rtf" style=styles.default;

ods graphics / reset width=600px height=400px imagename='Allergy' imagefmt=static;

proc sgplot data=lb1;
   band y=x1 lower=12.1 upper=15 / transparency=.8 fillattrs=graphdata1;
   scatter x=week y=perc / group=trt yerrorlower=lo yerrorupper=hi
       markerattrs=(symbol=circlefilled) name="scat";
   series x=week y=perc / group=trt lineattrs=(pattern=solid);
   series x=week y=end / group=trt markers lineattrs=(pattern=shortdash)
       markerattrs=(symbol=circle);
   xaxis integer values=(0 to 15 by 1) label="Weeks in Treatment";
   yaxis label="Change";
   refline 0; 
   refline 13.55 / axis=x 
       labelloc=outside labelpos=min lineattrs=(thickness=0px);
   keylegend "scat" / title="" noborder;
run;
ODS _all_ close; 
ods listing;

