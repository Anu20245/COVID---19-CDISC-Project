data one;
   input X Y Type $;
   datalines;
1 3 A
2 4 A
3 5 A
5 8 A
6 9 B
7 10 A
8 1 A
;
run;

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

ods listing close;

/* Point to the new style using the STYLE= option on the ODS HTML statement */
ods html path='C:\C1\ST\Jul2022\CL\OUTPUTS' (url=none) file='sastest.html' style=styles.symbols;

proc sgplot data=one;
   title 'Highlight a Value on a Graph';
   series x=X y=Y;
   scatter x=X y=Y / group=Type;
run;

ods html close;
ods listing;

libname adam "C:\C1\ST\Jul2022\CL\ADAM datasets";

data adsl;
set adam.adsl;
label x="AGE";
label y="Weight";
x=age;
y=BWGHTSI;
Type=trt01a;
if trt01a ne '';
keep  x y  Type;
run;

proc sort nodupkey;by x y type;run;

ods listing close;

/* Point to the new style using the STYLE= option on the ODS HTML statement */
ods html path='C:\C1\ST\Jul2022\CL\OUTPUTS' (url=none) file='sastest.html' style=styles.symbols;

title1 j=l "COVID-19 AA";
title2 j=l "Protocol: 043-1810";
title3 j=c "Figure 16.1.2 Highlight a Weight Value on a Graph";

options orientation=landscape;
ods escapechar='^';
ods rtf file ="C:\C1\ST\Jul2022\CL\OUTPUTS\16_1_2.rtf" style=styles.symbols;

proc sgplot data=adsl;
   series x=X y=Y;
   scatter x=X y=Y / group=Type;
run;

ODS _all_ close; 
