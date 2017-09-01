%let dir = C:\Users\caofk\Desktop\�Ķ�ϰ�ߵ���\;
libname ds "&dir\Raw Data\";



DATA city2report;
	input city :$6. out :$4.;
/*	import = trim(cat("&dir.", "Raw Data\", compress(city)," ����.xlsx")); */
	import = trim(cat("&dir.", "Raw Data\", compress(city),".xls")); 
	report1 = trim(cat("&dir.", "Report\",trim(compress(city)),"ͳ�Ʊ������.xls"));  
	report2 = trim(cat("&dir.", "Report\",trim(compress(city)),"ͳ�Ʊ��潻��.xls"));  
	sheet = city;
datalines;
���� A1
���� A2
���� A3
÷�� A4
��ͷ A5
��β A6
���� A7
��Զ A8
տ�� A9
���� A10
���� A11
ï�� A12
���� A13
�ع� A14
�Ƹ� A15
��ݸ A16
���� A17
�麣 A18
��ɽ A19
��Դ A20
��ɽ A21
;
RUN;

PROC datasets lib=work noprint;
	delete all_city;
RUN;
%let many = [city2report];
%for(import sheet out report1 report2, in=&many., do = %nrstr(
  %put import = &import. sheet = &sheet. out = &out. report1 = &report1. report2 = &report2.;
  %importXlsx(&import, &sheet, &out.);
  %outXls1(&report1, &out, &sheet.);
  %outXls2(&report2, &out, &sheet.);
  PROC append base=All_city data=&out.(drop=Date) force;
  RUN;
));
