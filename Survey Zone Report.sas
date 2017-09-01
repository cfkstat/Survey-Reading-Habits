DATA zone;
	length city $20.;
	set all_city(in=a)
		all_city(in=b)
		all_city(in=c);
	if a then city = "�㶫";
	if b then do;
		if city in ("��ͷ", "����", "����", "��β") then city = "����";
		else if city in ("����", "տ��", "ï��") then city = "����";
		else if city in ("��Զ", "�ع�", "�Ƹ�", "��Դ", "÷��") then city = "����";
		else city = "������";
	end;
	if c then do;
		if city in ("��ͷ", "����", "����", "��β","����", "տ��", "ï��","��Զ", 
			"�ع�", "�Ƹ�", "��Դ", "÷��") then city = "��������";
		else delete;
	end;
RUN;


DATA zone2report;
	input city :$20. out :$4.;
/*	import = trim(cat("&dir.", "Raw Data\", compress(city)," ����.xlsx")); */
	report1 = trim(cat("&dir.", "Report\",trim(compress(city)),"ͳ�Ʊ������.xls"));  
	report2 = trim(cat("&dir.", "Report\",trim(compress(city)),"ͳ�Ʊ��潻��.xls"));   
	sheet = city;
datalines;
�㶫 A23
���� A24
���� A25
���� A26
������ A27
�������� A28
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