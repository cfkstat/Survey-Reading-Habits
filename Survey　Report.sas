%let dir = C:\Users\caofk\Desktop\阅读习惯调查\;
libname ds "&dir\Raw Data\";



DATA city2report;
	input city :$6. out :$4.;
/*	import = trim(cat("&dir.", "Raw Data\", compress(city)," 线下.xlsx")); */
	import = trim(cat("&dir.", "Raw Data\", compress(city),".xls")); 
	report1 = trim(cat("&dir.", "Report\",trim(compress(city)),"统计报告汇总.xls"));  
	report2 = trim(cat("&dir.", "Report\",trim(compress(city)),"统计报告交叉.xls"));  
	sheet = city;
datalines;
广州 A1
惠州 A2
揭阳 A3
梅州 A4
汕头 A5
汕尾 A6
深圳 A7
清远 A8
湛江 A9
潮州 A10
肇庆 A11
茂名 A12
阳江 A13
韶关 A14
云浮 A15
东莞 A16
江门 A17
珠海 A18
中山 A19
河源 A20
佛山 A21
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
