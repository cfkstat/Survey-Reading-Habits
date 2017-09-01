%MACRO importXlsx(filepath, sheet, out);
/*	%LET filepath = C:\Users\caofk\Desktop\�Ķ�ϰ�ߵ���\Raw Data\����.xls;*/
/*	%LET sheet = ����; */
/*	%LET OUT = A1;*/
	PROC import datafile = "&filepath." out = &out. replace;
		getnames = yes;
		sheet = "&sheet.";
	RUN;
	PROC sort data=&out.;
		by  '�ʾ���'n '����ʱ��'n;
	RUN;
	PROC sql noprint;
		select cats("'",name,"'n") into :Tvar separated by " " from sashelp.VCOLUMN where memname = "%upcase(&out.)" and index(name, "��");
	QUIT;
	PROC transpose data=&out. out=&out.(drop=_label_ rename=(_name_ = question COL1 = value "�ʾ���"n = No "����ʱ��"n = Date));
		var &Tvar.;
		by  '�ʾ���'n '����ʱ��'n;
	RUN;

	DATA &out.;
		set &out.(rename=(question = _question value = _value));
		if cats(_value) ~= "0" and cats(_value) ~= "";
		_value = compress(_value);
		if index(_question, "��") then question = scan(_question, 1, "��");
		else question = _question;
		if index(_question, "��") then choice = scan(_question,2,"��");
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

	PROC transpose data=&out.(where = (question_id >= 23)) out=&out._person_attr PREFIX=��;
		var value_text ;
		id question_id;
		by No date;
	RUN;
	DATA &out._person_attr;
		set &out._person_attr;
		rename "��23"n = "�Ա�"n "��24"n = "����"n "��25"n = "ѧ��"n "��26"n = "ְҵ���"n "��27"n = "��λ����"n "��28"n = "����"n "��29"n = "����"n;
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
				select "&type."n, value_text, question_name,question_id, count(*) as count, "ʵ�����" as type
					from &ds.
						group by "&type."n, value_text, question_name,question_id
						union
						select "ѡ��"n as "&type."n, value_text,question_name,question_id, count, "�������" as type
							from ucstat
								where  "����"n = "&type." and "����"n = "&city.";
	QUIT;
	DATA &ds._1;
		set &ds._1(in=a)
			&ds._1(in=b)
			&ds._1(in=c);
		if b then do;
			if question_id in (1,2) then question_name = "001.ֽ�ʶ����Ķ�ʱ��";
			if question_id in (3,4) then question_name = "002.���ֻ������Ķ�ʱ��";
			if question_id in (12, 13) then question_name = "004.2016��ֽ�ʺ͵���ͼ�鹺������";
			if question_id in (14, 15) then question_name = "005.2016��ֽ�ʺ͵���ͼ�鹺�򻨷�"; 
			if question_id in (1, 2, 3, 4, 12, 13, 14, 15);
		end;
		if c then do;
			if question_id in (1,2, 3, 4) then question_name = "003.ƽ��ÿ���ۺ��Ķ�ʱ��������ֽ�ʺ����ֻ����";
			if question_id in (1, 2, 3, 4);
		end;
		city = "&city.";
		if question_name > "18" and question_name < "23" then do;
			if index(value_text, "��") then score = input(substr(value_text, 1, 1),8.)*count;
		end;
/*		if question_name >= "19" and question_name <= "22";*/
		
	RUN;
	title1 "�Ķ���Ϊ�ʾ����";
	PROC tabulate data=&ds._1(where=(question_name="01.2016�꣬��ƽ��ÿ���Ķ�ֽ�ʱ���/��־��ʱ���ж೤��"));
		class type;
		var count;
		table type=""*count=""*sum="����"*format=8.;
	QUIT;
	PROC sql;
		create table question1
		as 
		select distinct question_name from &ds._1 where question_name ~=" " and question_name <= "19"
		and type = "�������";
	QUIT;
/*	title1 "һ.�Ķ�ʱ��";*/
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
		select *,sum(score)/sum(count) as "����"n 
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
		var count "����"n;
		table question_name="",  ((value_text="" )*count=""*(ROWPCTSUM=""*f=pctfmt.)) "����"n*mean="";
/*		table question_name="", "&type."n="",  value_text=""*count=""*(ROWPCTSUM=""*f=pctfmt.);*/
	RUN;
	))
%MEND outXls1;
*************************************����********************************;
/*%let ds =A1;*/
/*%let city = ����;*/
/*%let type = �Ա�;*/
/**/
/*%state(ѧ��, &ds);*/
/*%state(�Ա�, A24, ����);*/

%MACRO outXls1(file, ds, city);
	ods  tagsets.excelxp   file="&file." options(sheet_name="�Ա�" sheet_interval='none')  style=analysis;
	%state1(�Ա�, &ds, &city.);
	ods tagsets.excelxp close;
%MEND outXls1;


