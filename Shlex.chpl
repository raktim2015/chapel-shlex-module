private use List;
class shlex
{

	var instream:string;
	var posix:bool;
	var eof:string;
	var eofnone : bool;
	var commenters:string;
	var wordchars:string;
	var whitespace:string;
	var whitespace_split:bool;
	var quotes:string;
	var escape:string;
	var escapedquotes:string;
	var state:string;
	var pushback:list(string);
	var lineno:int;
	var debug:int;
	var token:string;
	var filestack:list(string);
	var source:string;
	var punctuation_chars:string;
	var _pushback_chars:list(string);
	var tokindex:int;
	var sourcenone : bool;
	var statenone : bool;
	

	proc init(instream:string, posix:bool = false, punctuation_chars: bool = false)
	{
		this.instream = instream;
		this.posix = posix;
		if (this.posix==true){
			this.eofnone = true;
		}
		else{
			this.eof = '';
			this.eofnone = false;
		}
		this.commenters='#';
		this.wordchars = 'abcdfeghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_';
		if this.posix==true then this.wordchars+='ßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞ';
		this.whitespace = ' \t\r\n';
		this.whitespace_split = false;
		this.quotes = '\'"';
		this.escape = '\\';
		this.escapedquotes = '"';
		this.state=' ';
		this.lineno = 1;
		this.debug = 0;
		this.token = '';
		this.source = '';
		this.tokindex = 1;
		this.statenone = false;
		if(punctuation_chars==false){
			this.punctuation_chars = '';
		}
		else{
			this.punctuation_chars = '();<>|&';
		}
		if(punctuation_chars == true){
			this.wordchars+="~-./*?=";
			//remove punctuation_chars from wordchars
			for c in this.punctuation_chars{
				this.wordchars = this.wordchars.replace(c,'');
			}	
		}
	}

	proc read_token():string
	{
		var quoted = false;
		var escapedstate = ' ';
		var nextchar:string;
		while(true){
			
			if(this.tokindex==-1) then break;
			if ((this.punctuation_chars!='') && (this._pushback_chars.size>0)){
				nextchar = this._pushback_chars.pop();
			}
			else if((this.tokindex <= this.instream.size) && this.tokindex!=-1){
				nextchar = this.instream[this.tokindex];
				this.tokindex+=1;
			}
			else if((this.tokindex > this.instream.size) && (this.tokindex!=-1)){
				nextchar='';
				this.tokindex = -1;
			}
			if nextchar=='\n' then this.lineno +=1;
			if this.debug >= 3 then writeln("shlex: in state ",this.state," I see character : ",nextchar);
			if(this.statenone == true){
				this.token = '';
				break;
			}
			else if(this.state == ' '){
				if(check(nextchar,this.whitespace)){
					if(this.debug >= 2) then writeln("shlex: I see whitespace");
					if((this.tokindex!=-1)|| ((this.posix) && (quoted))){	
						break;
					}
					else{
						continue;
					}
				}
				else if(check(nextchar,this.commenters)){
					while(instream[this.tokindex]!='\n'){
						this.tokindex+=1;
					}
					this.lineno+=1;
				}
				else if(this.posix && check(nextchar,this.escape)){
					escapedstate = 'a';
					this.state = nextchar;
					this.statenone = false;
				}
				else if(check(nextchar,this.wordchars)){
					this.token = nextchar;
					this.state = 'a';
					this.statenone = false;
				}
				else if(check(nextchar,this.punctuation_chars)){
					this.token = nextchar;
					this.state = 'c';
					this.statenone = false;
				}
				else if(check(nextchar,this.quotes)){
					if(this.posix == false){
						this.token = nextchar;
					}
					this.state = nextchar;
					this.statenone = false;
				}
				else if(this.whitespace_split == true){
					this.token = nextchar;
					this.state = 'a';
					this.statenone = false;
				}
				else{
					this.token = nextchar;
					if((this.tokindex!=-1) || (this.posix && quoted)){
						break;
					}
					else{
						continue;
					}
				}
			}
			else if(check(this.state,this.quotes)){
				quoted = true;
				if(nextchar == ''){
					if(this.debug>=2) then writeln("shlex: I see EOF in quotes state");
				}
				if(nextchar == this.state){
					if(this.posix == false){
						this.token+=nextchar;
						this.state = ' ';
						this.statenone = false;
						break;
					}
					else{
						this.state = 'a';
						this.statenone = false;
					}
				}
				else if(this.posix && check(nextchar,this.escape) && check(this.state,this.escapedquotes)){
					escapedstate = this.state;
					this.state = nextchar;
					this.statenone = false;
				}
				else{
					this.token += nextchar;
				}
			}
			else if(check(this.state,this.escape)){
				if(nextchar==''){
					if(this.debug>=2) then writeln("shlex: I see EOF in escape state");
				}
				if(check(escapedstate,this.quotes) && (nextchar!=this.state) && (nextchar!=escapedstate)){
					this.token += this.state;
				}
				this.token +=nextchar;
				this.state = escapedstate;
				this.statenone = false;
			}
			else if(check(this.state,"a") || check(this.state,"c")){
				if(nextchar==''){
					this.statenone = true;
					this.state = '';
					break;
				}
				else if(check(nextchar,this.whitespace)){
					if(this.debug >= 2){
						writeln("shlex : whitespace in word state");
					}
					this.state = ' ';
					this.statenone = false;
					if((this.token!='') || (this.posix && quoted)){
						break;
					}
					else{
						continue;
          }
				}
				else if(check(nextchar,this.commenters)){
					while(instream[this.tokindex]!='\n'){
						this.tokindex+=1;
					}
					this.lineno+=1;
					if(this.posix==true){
						this.state = ' ';
						this.statenone = false;
						if((this.token!='') || (this.posix && quoted)){
							break;
						}
						else{
							continue;
						}
					}
				}
				else if(this.state == 'c'){
					if(check(nextchar,this.punctuation_chars)){
						this.token += nextchar;
					}
					else{
						if(check(nextchar,this.whitespace)==false){
							this._pushback_chars.append(nextchar);
						}
						this.state= ' ';
						this.statenone = false;
						break;
					}
				}
				else if(this.posix && check(nextchar,this.quotes)){
					this.state = nextchar;
					this.statenone = false;
				}
				else if(this.posix && check(nextchar,this.escape)){
					escapedstate = 'a';
					this.state = nextchar;
					this.statenone = false;
				}
				else if(check(nextchar,this.wordchars) || (check(nextchar,this.quotes)) || (this.whitespace_split == true)){		
					this.token+=nextchar;
				}
				else{
					if(this.punctuation_chars!=''){
						this._pushback_chars.append(nextchar);
					}
					else{
						this.pushback.insert(1,nextchar);
					}
					if(this.debug >= 2){
						writeln("shlex : I see punctuation in word state");
					}
					this.state = ' ';
					this.statenone = false;
					if((this.token!='') || (this.posix && quoted)){
						break;
					}
					else{
						continue;
					}
				}
			}
		}
		var result = this.token;
		this.token = '';
		if(this.posix && (quoted==false) && (result=='')){
			result='';
		}
		if(this.debug > 1){
			if(result!=''){
				writeln("shlex: raw token = "+result);
			}
			else{
				writeln("shlex: raw token = EOF");
			}
		}
		return result;
	}

	inline proc check(first:string, second:string):bool
	{
		for c in second{
			if(c == first) then return true;
		}
		return false;
	}
	
	proc get_token():string
	{
		if(this.tokindex == -1){
			return "";
		}
		var raw = read_token();
		if(raw==''){
			raw = ' ';
		}
		return raw;
	}
}


var lst: list(string);
var f = open("testShlexData.txt",iomode.r);
var r = f.reader();
var line:string;
var count = 0;
while(r.readline(line))
{
	line = line.replace('\n','');
	var s = new shlex(line,posix=true,punctuation_chars=true);
	var x = ' ';
	writeln(" token no :- " , count," ******************************");
	count+=1;
	while(x!='')
	{
		x = s.get_token();
		if(x!=' ' || x!='')
		{
			lst.append(x);
		}
	}
	writeln(lst);
	lst.clear();

}
r.close();

/*config const teststr = 'echo \"please preserve    white space\"';
writeln(teststr);

writeln("Splitted commands :- ");

var s = new shlex(teststr,posix=true,punctuation_chars = false);
var x = ' ';

while(x!='')
{
	x = s.get_token();
	writeln(x);
}*/
