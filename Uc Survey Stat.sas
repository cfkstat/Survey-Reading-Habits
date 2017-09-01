PROC sort data=uc;
	by '����'n '����'n  'ѡ��'n;
RUN;

PROC transpose data=uc out=uct;
	by '����'n '����'n  'ѡ��'n;
RUN;

DATA ucstat;
	set uct;
	"����"n = substr(compress("����"n), 4,length(compress("����"n))-3);
	if _label_ = " " then _label_ = _name_;
	question = scan(_label_, 1, "|");
	value_text = compress(scan(_label_, 2, "|"));
	count = int(COL1);
	question_id = input(substr(compress(question), 1, 2),8.);
	drop _: COL1;
RUN;

DATA code;
	set code;
	if index(value_text, ".") then value_tmp = scan(value_text, 2, ".");
	else value_tmp = value_text;
RUN;

PROC sql;
	create table ucstat
	as 
	select a."����"n,a."����"n,a."ѡ��"n,a.count, b.question_name, b.value_text,b.question_id, b.choice
		from ucstat a left join code b
		on a.question_id = b.question_id and compress(a.value_text) = compress(b.value_tmp);
QUIT;


DATA ucstat;
	length value_text $50.;
	length "����"n $50.;
	format "����"n $50.;
	set ucstat(in=a)
		ucstat(in=b)
		ucstat(in=c)
		ucstat(in=d);
	if a then "����"n = "�㶫";
	if b then do;
		if "����"n in ("��ͷ", "����", "����", "��β") then "����"n = "����";
		else if "����"n in ("����", "տ��", "ï��") then "����"n = "����";
		else if "����"n in ("��Զ", "�ع�", "�Ƹ�", "��Դ", "÷��") then "����"n = "����";
		else "����"n = "������";
	end;
	if d then do;
		if "����"n in ("��ͷ", "����", "����", "��β","����", "տ��", "ï��","��Զ", 
			"�ع�", "�Ƹ�", "��Դ", "÷��") then "����"n = "��������";
		else delete;
	end;
RUN;
