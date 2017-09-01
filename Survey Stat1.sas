%MACRO importXlsx(filepath, sheet, out);
/*	%LET filepath = C:\Users\caofk\Desktop\阅读习惯调查\Raw Data\广州.xls;*/
/*	%LET sheet = 广州; */
/*	%LET OUT = A1;*/
	PROC import datafile = "&filepath." out = &out. replace;
		getnames = yes;
		sheet = "&sheet.";
	RUN;
	PROC sort data=&out.;
		by  '问卷编号'n '调查时间'n;
	RUN;
	PROC sql noprint;
		select cats("'",name,"'n") into :Tvar separated by " " from sashelp.VCOLUMN where memname = "%upcase(&out.)" and index(name, "题");
	QUIT;
	PROC transpose data=&out. out=&out.(drop=_label_ rename=(_name_ = question COL1 = value "问卷编号"n = No "调查时间"n = Date));
		var &Tvar.;
		by  '问卷编号'n '调查时间'n;
	RUN;

	DATA &out.;
		set &out.(rename=(question = _question value = _value));
		if cats(_value) ~= "0" and cats(_value) ~= "";
		_value = compress(_value);
		if index(_question, "“") then question = scan(_question, 1, "“");
		else question = _question;
		if index(_question, "“") then choice = scan(_question,2,"“");
		else choice = _value;
		question_id = input(substr(question, 4), 8.);
		if ANYDIGIT(choice) then do;
			choice = byte((64+_value));
		end;
/*		drop _:;*/
	RUN;
    PROC sql;
	    create table missing_&out.
		as 
		select a.*, b.flag
			from 
			(select distinct no, question_id, question, choice from &out.)a 
			left join code b
			on a.question = b.question and upcase(a.choice) = b.choice;
    QUIT;
	DATA missing_&out.;
		set missing_&out.;
		if flag ~= 1;
		city = "&sheet.";
		drop flag;
	RUN;
	PROC sql;
		create table &out.  
		as 
		select a.*, b.value_text, b.question_name
			from &out a left join code b
			on a.question = b.question and upcase(a.choice) = b.choice
			order by No, date;
	QUIT;

	PROC transpose data=&out.(where = (question_id >= 23)) out=&out._person_attr PREFIX=题;
		var value_text ;
		id question_id;
		by No date;
	RUN;
	DATA &out._person_attr;
		set &out._person_attr;
		rename "题23"n = "性别"n "题24"n = "年龄"n "题25"n = "学历"n "题26"n = "职业身份"n "题27"n = "岗位类型"n "题28"n = "收入"n "题29"n = "户口"n;
	RUN;
	PROC sort data=&out.;
		by No date;
	RUN;
	PROC sort data=&out._person_attr;
		by No date;
	RUN;
	DATA &out.;
		merge &out. &&out._person_attr;
		by No date;
		drop _:;
		if question_id <= 22;
		city = "&sheet.";
	RUN;
	PROC sort data=&out.;
		by no date question_id;
	RUN;
%MEND importXlsx;

/*proc format;*/
/*   picture pctfmt low-high='009.9 %';*/
/*run;*/
proc format; 
        picture pctfmt (round) low-high='009.99%'; 
run; 
%MACRO state1(type, ds, city);
	PROC sql;
		create table &ds._1
			as 
				select "&type."n, value_text, question_name,question_id, count(*) as count, "实地民调" as type
					from &ds.
						group by "&type."n, value_text, question_name,question_id
						union
						select "选项"n as "&type."n, value_text,question_name,question_id, count, "网络民调" as type
							from ucstat
								where  "属性"n = "&type." and "城市"n = "&city.";
	QUIT;
	DATA &ds._1;
		set &ds._1(in=a)
			&ds._1(in=b)
			&ds._1(in=c);
		if b then do;
			if question_id in (1,2) then question_name = "001.纸质读物阅读时间";
			if question_id in (3,4) then question_name = "002.数字化读物阅读时间";
			if question_id in (12, 13) then question_name = "004.2016年纸质和电子图书购买总量";
			if question_id in (14, 15) then question_name = "005.2016年纸质和电子图书购买花费"; 
			if question_id in (1, 2, 3, 4, 12, 13, 14, 15);
		end;
		if c then do;
			if question_id in (1,2, 3, 4) then question_name = "003.平均每天综合阅读时长（包括纸质和数字化读物）";
			if question_id in (1, 2, 3, 4);
		end;
		city = "&city.";
		if question_name > "18" and question_name < "23" then do;
			if index(value_text, "分") then score = input(substr(value_text, 1, 1),8.)*count;
		end;
/*		if question_name >= "19" and question_name <= "22";*/
		
	RUN;
	title1 "阅读行为问卷调查";
	PROC tabulate data=&ds._1(where=(question_name="01.2016年，您平均每天阅读纸质报刊/杂志的时间有多长？"));
		class type;
		var count;
		table type=""*count=""*sum="人数"*format=8.;
	QUIT;
	PROC sql;
		create table question1
		as 
		select distinct question_name from &ds._1 where question_name ~=" " and question_name <= "19"
		and type = "网络民调";
	QUIT;
/*	title1 "一.阅读时长";*/
	%let many=[question1];
	%for(question_name, in=&many, do=%nrstr(
	title "&question_name.";
	PROC tabulate data=&ds._1(where=(question_name = "&question_name."));
		class value_text question_name;
		var count;
		table question_name="",  (value_text="" )*count=""*(ROWPCTSUM=""*f=pctfmt.) ;
/*		table question_name="", "&type."n="",  value_text=""*count=""*(ROWPCTSUM=""*f=pctfmt.);*/
	RUN;
	))
	

	PROC sql;
		create table &ds._score
		as 
		select *,sum(score)/sum(count) as "评分"n 
			from &ds._1 
			where question_name > "19" and score ~= .
			group by "&type."n, question_name;
	QUIT; 
 	PROC sql;
		create table question2
		as 
		select distinct question_name from &ds._score;
	QUIT;
	%let many=[question2];
	%for(question_name, in=&many, do=%nrstr(
	PROC tabulate data=&ds._score(where=(question_name = "&question_name."));
		class value_text question_name;
		var count "评分"n;
		table question_name="",  ((value_text="" )*count=""*(ROWPCTSUM=""*f=pctfmt.)) "评分"n*mean="";
/*		table question_name="", "&type."n="",  value_text=""*count=""*(ROWPCTSUM=""*f=pctfmt.);*/
	RUN;
	))
%MEND outXls1;
*************************************广州********************************;
/*%let ds =A1;*/
/*%let city = 广州;*/
/*%let type = 性别;*/
/**/
/*%state(学历, &ds);*/
/*%state(性别, A24, 粤东);*/

%MACRO outXls1(file, ds, city);
	ods  tagsets.excelxp   file="&file." options(sheet_name="性别" sheet_interval='none')  style=analysis;
	%state1(性别, &ds, &city.);
	ods tagsets.excelxp close;
%MEND outXls1;


