DATA zone;
	length city $20.;
	set all_city(in=a)
		all_city(in=b)
		all_city(in=c);
	if a then city = "广东";
	if b then do;
		if city in ("汕头", "揭阳", "潮州", "汕尾") then city = "粤东";
		else if city in ("阳江", "湛江", "茂名") then city = "粤西";
		else if city in ("清远", "韶关", "云浮", "河源", "梅州") then city = "粤北";
		else city = "珠三角";
	end;
	if c then do;
		if city in ("汕头", "揭阳", "潮州", "汕尾","阳江", "湛江", "茂名","清远", 
			"韶关", "云浮", "河源", "梅州") then city = "粤东西北";
		else delete;
	end;
RUN;


DATA zone2report;
	input city :$20. out :$4.;
/*	import = trim(cat("&dir.", "Raw Data\", compress(city)," 线下.xlsx")); */
	report1 = trim(cat("&dir.", "Report\",trim(compress(city)),"统计报告汇总.xls"));  
	report2 = trim(cat("&dir.", "Report\",trim(compress(city)),"统计报告交叉.xls"));   
	sheet = city;
datalines;
广东 A23
粤东 A24
粤西 A25
粤北 A26
珠三角 A27
粤东西北 A28
;
RUN;

%let many = [zone2report];
%for(sheet out report1 report2, in=&many., do = %nrstr(
  %put sheet = &sheet. out = &out. report1 = &report1. report2 = &report2.;
  DATA &out.;
  	set zone;
	if city = "&sheet.";
  RUN;
  %outXls1(&report1, &out, &sheet.);
  %outXls2(&report2, &out, &sheet.);
));