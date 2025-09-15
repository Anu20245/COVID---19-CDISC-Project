/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: lis9.SAS  
*
* Program Type: Listing
*
* Purpose: To produce 16.2.2.3 Serious Adverse Events 
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
   /* filter Serious Adverse Events */
   IF AESER EQ 'Y' ;
/*   column two - Adverse Event/Primary System Organ Class/   Preffered term*/
/*   medical coding team provides Primary System Organ Class/   Preffered term*/
   spa=catx ("/",AETERM,AEBODSYS,AEDECOD);
   keep usubjid spa AESTDTC AEENDTC AESER AACN AREL AEOUT  ARELN ;            
RUN;

PROC SQL NOPRINT;
   SELECT COUNT (*) INTO: NBR FROM ADAE;
QUIT;
%PUT &NBR;


DATA ADAE;
   SET ADAE;
   RETAIN LNT 0 PAGE1 1;
   LNT+1;

   IF LNT>7 THEN DO;
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
title3 j=c '16.2.2.3 Serious Adverse Events';

footnote1 j=l 'C:\C1\ST\Jul2022\CL\program\LIS9.SAS';


options orientation=landscape;
ods escapechar='^';
ods rtf file='C:\C1\ST\Jul2022\CL\OUTPUTS\l_16_2_2_3.rtf' style=styles.test;

proc report data=adae split='|' style= {outputwidth=100%};

   column page1 usubjid spa AESTDTC AEENDTC AESER  AACN ARELN AREL AEOUT;

   define PAGE1/order noprint;

   define usubjid /order "Subject|Number"
   style (column) ={just=l cellwidth=15%}
   style (header) ={just=l cellwidth=15%};

   define spa /order "Adverse Event/Primary System Organ|Class/   Preffered term"
   style (column) ={just=l cellwidth=20%}
   style (header) ={just=l cellwidth=20%};


   define AESTDTC /display "Start|Date/Time"
   style (column) ={just=l cellwidth=10%}
   style (header) ={just=l cellwidth=10%};

   define AEENDTC /display "End |Date/Time"
   style (column) ={just=l cellwidth=10%}
   style (header) ={just=l cellwidth=10%};

   define AESER /display "Serious|Event"
   style (column) ={just=l cellwidth=6%}
   style (header) ={just=l cellwidth=6%};


   define AACN /display "Action taken"
   style (column) ={just=l cellwidth=8%}
   style (header) ={just=l cellwidth=8%};

   define ARELN/order noprint; /* couple variables */
   define AREL /display "Relationship|to|Study Drug"
   style (column) ={just=l cellwidth=10%}
   style (header) ={just=l cellwidth=10%};

   define AEOUT /display "Outcome"
   style (column) ={just=l cellwidth=10%}
   style (header) ={just=l cellwidth=10%};


   compute before _page_;
      line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;

   compute after _page_;
      line@1 "^{style [outputwidth=100% bordertopwidth=0.5pt]}";
   endcomp;

   break after PAGE1/page;

run;

ods _all_ close;
