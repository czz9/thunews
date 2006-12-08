#!/usr/bin/perl -w

$RECFILE="/tmp/thunews_rec";
$WGET="/usr/bin/wget";

sub dosth{
	($title, $body) = @_;

	print "\033[1;32m".$title."\033[m\n";
	print $body;
}

$BASEURL="http://oars.tsinghua.edu.cn";
$NEWSINDEX="http://oars.tsinghua.edu.cn/zzh/30630.nsf/1fa2?ReadForm&TemplateType=2&TargetUNID=FA65745AE14925D2C825669E002C5ECF&AutoFramed";
$TMPINDEX="/tmp/thunews_index";
$TODAY=`date "+%Y.%m.%d"`;
chomp($TODAY);
$got=0;

system("$WGET -q -O $TMPINDEX \"$NEWSINDEX\"");
open(IN, $TMPINDEX) || die("Error open index file");
while(<IN>){
	chomp($_);
	$temp .= $_;
}
close(IN);
unlink($TMPINDEX);

if (open(IN, $RECFILE)){
	$lasturl=<IN>;
	close(IN);
} else {
	$lasturl="";
}

#<TR VALIGN=top><TD><IMG SRC="/icons/ecblank.gif" BORDER=0 HEIGHT=1 WIDTH=16 ALT=""><td width=6><img src=/icons/info/dot1.gif width=7 height=7>　</td></TD><TD><FONT FACE="宋体"><A HREF="/zzh/30630.nsf/fa65745ae14925d2c825669e002c5ecf/0e16389a19d170afc8257235002dc3d0?OpenDocument" TARGET="_blank"><a href =/zzh/30630.nsf/(AllDocsByUnid)/0E16389A19D170AFC8257235002DC3D0?opendocument target=_blank>IC卡学生证及纸制学生证招领名单 [注册中心]</a></A></FONT></TD><TD><FONT FACE="宋体">2006.11.29</FONT></TD></TR>
@tmp=($temp=~/<a href =(.*?) target=_blank>(.*?)<\/a>.*?<FONT FACE="宋体">(.*?)<\/FONT>/g);
$nums=(@tmp) / 3;

if ($nums <= 0){
	exit;
}

$newrec=$tmp[0];
if ($newrec ne $lasturl){
	if (open(OUT, ">$RECFILE")){
		print OUT $newrec;
		close(OUT);
	} else {
		print "Error open $RECFILE for write";
	}
}

for ($i = 0; $i < $nums; $i++){
	last if ($tmp[$i * 3 + 2] ne $TODAY);
	last if ($tmp[$i * 3] eq $lasturl);
	getfile($BASEURL.$tmp[$i * 3], $tmp[$i * 3 + 1]);
}

#getfile("http://oars.tsinghua.edu.cn/zzh/30630.nsf/(AllDocsByUnid)/4E67F260EF89B0A6C825722F00387619?opendocument", "test");

sub getfile{
	($url, $title) = @_;
	my @tmp;
	my $temp;
	my $targetfile="/tmp/thunews_file_".time."_".$got;
	system("$WGET -q -O $targetfile \"$url\"");
	if (open(IN, $targetfile)){
		while(<IN>){
			chomp($_);
			$temp .= $_;
		}
		close(IN);
		unlink($targetfile);

		@tmp = ($temp=~/class=p3>(.*?)<TT>/ig);
		@atts = ($temp=~/target=_blank href=([^>]*?)>[^>]+>([^<]*?)</ig);
		$temp = $tmp[0];
		$temp=~s/<BR>/\n/ig;
		$temp=~s/<P>/\n/ig;
		$temp=~s/&nbsp;/ /ig;
		$temp=~s/&quot;/"/ig;
		$temp=~s/&amp;/&/ig;
		$temp=~s/&#039/'/ig;
		$temp=~s/&lt;/</ig;
		$temp=~s/&gt;/>/ig;
		$temp=~s/<[^>]+>//ig;
		$temp .= "\n";

		my $numatts=(@atts) / 2;
		if ($numatts > 0){
			for (my $i = 0; $i < $numatts; $i++){
				$temp .= "附件: ".$atts[$i * 2 + 1]."\n";
				$temp .= $BASEURL.$atts[$i * 2]."\n";
			}
		}
		$got++;
		dosth($title, $temp);
	}
}
