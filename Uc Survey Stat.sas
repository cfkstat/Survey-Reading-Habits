PROC sort data=uc;
	by '城市'n '属性'n  '选项'n;
RUN;

PROC transpose data=uc out=uct;
	by '城市'n '属性'n  '选项'n;
RUN;

DATA ucstat;
	set uct;
	"属性"n = substr(compress("属性"n), 4,length(compress("属性"n))-3);
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
	select a."城市"n,a."属性"n,a."选项"n,a.count, b.question_name, b.value_text,b.question_id, b.choice
		from ucstat a left join code b
		on a.question_id = b.question_id and compress(a.value_text) = compress(b.value_tmp);
QUIT;


DATA ucstat;
	length value_text $50.;
	length "城市"n $50.;
	format "城市"n $50.;
	set ucstat(in=a)
		ucstat(in=b)
		ucstat(in=c)
		ucstat(in=d);
	if a then "城市"n = "广东";
	if b then do;
		if "城市"n in ("汕头", "揭阳", "潮州", "汕尾") then "城市"n = "粤东";
		else if "城市"n in ("阳江", "湛江", "茂名") then "城市"n = "粤西";
		else if "城市"n in ("清远", "韶关", "云浮", "河源", "梅州") then "城市"n = "粤北";
		else "城市"n = "珠三角";
	end;
	if d then do;
		if "城市"n in ("汕头", "揭阳", "潮州", "汕尾","阳江", "湛江", "茂名","清远", 
			"韶关", "云浮", "河源", "梅州") then "城市"n = "粤东西北";
		else delete;
	end;
RUN;
