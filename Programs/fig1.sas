/* Define the symbol markers and the colors of the symbol markers */
proc template;
   define style styles.symbols;
   parent=styles.statistical;
      style graphdata1 /
          markersymbol='circlefilled'
          contrastcolor=green;
      style graphdata2 /
          markersymbol='circlefilled'
          contrastcolor=red;
   end;
run;

libname adam "C:\C1\ST\Jul2022\CL\ADAM datasets";

data lb1;
set adam.adlb;
label value ="Analysis value";
if parcat1 eq 'HEMATOLOGY' and trt01a ne '';
test=paramcd;
drug=trt01a;
value=aval;
keep test drug value;
run;

ods _all_ close; 
/* ERROR: Cannot write image to SGPlot.png. Please ensure that proper disk permissions are set */
ods html path='C:\C1\ST\Jul2022\CL\OUTPUTS' (url=none) file='sastest.html' style=styles.symbols;

TITLE1 J=L "COVID-19 AA";
TITLE2 J=L "Protocol: 043";
title3 j=c "Figure 16.1.1  Distribution of Hemotology Values by Treatment";

options orientation=landscape;
ods escapechar='^';
ods rtf file ="C:\C1\ST\Jul2022\CL\OUTPUTS\16_1_1.rtf" style=styles.symbols;


proc sgplot data=lb1;
   vbox value / category=test group=drug;
   xaxis label="Treatment";
   keylegend / title="Drug Type" ;
run; 

ods _all_ close; 
ods listing;
