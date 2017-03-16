#!/usr/bin/perl

use Digest::MD5 qw(md5_hex);

sub usability {
	my $user=shift;
	my $state=shift;
	my $name=shift;
	my $email=shift;
	($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
	$Month++;
	$Month="0".$Month if ($Month<10);
	$Day="0".$Day if ($Day<10);
	$Hour="0".$Hour if ($Hour<10);
	$Minute="0".$Minute if ($Minute<10);
	$Second="0".$Second if ($Second<10);
	$time="2006-".$Month."-".$Day." ".$Hour.":".$Minute.":".$Second;
	$input="/home/httpd/html/chilibot/$user/$name/input";
	$user=md5_hex($user);
	open (TERM, $input) ||die "no $input";
	@terms=<TERM>;
	open (ULog,">>usability.xml") || die "no xml file found";
	flock(ULog, 2);
	print ULog "\n<query>\n\t<user>$user</user>\n\t<time>$time CST</time>\n\t\t<terms>\t@terms\t\t</terms>\n" ;
	print ULog "\t<name>$name</name>\n";
	print ULog "\t<stat>$state</stat>\n";
	print ULog "\t<email>$email</email>\n";
	print ULog "\t<ip>$ENV{REMOTE_ADDR}</ip>\n";
	print ULog "</query>\n";
	close (Ulog);
}


1;
