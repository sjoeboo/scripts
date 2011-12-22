#!/usr/bin/perl

# generate with:
#  873  09/20/10 11:42:09  /nas/sbin/server_tcpdump server_2 -start fsn0 -max 200 -w /root_vdm_1/home07/jc.cap
#  874  09/20/10 11:42:31  /nas/sbin/server_tcpdump server_2 -display
#  875  09/20/10 11:42:52  /nas/sbin/server_tcpdump server_2 -stop fsn0

if ($ARGV[0] eq ""){die "Usage: pounding.pl server_2 or ALL\n"};
# map is based on:
%servermap = (
       server_2 => 'capture_2',
       server_3 => 'capture_3',
       server_4 => 'capture_4',
       server_5 => 'capture_5',
       server_6 => 'capture_6',
       server_7 => 'capture_7',
       server_8 => 'capture_8',
   );

$thisserver=$ARGV[0];

if ($ARGV[0] eq "ALL"){
 foreach $host (sort keys %servermap){
 $thisserver=$host;
 capture();
 }
}

else {capture()};


sub capture {
$rootloc = $servermap{$thisserver};
($server,$slot) = split("_",$thisserver);
$remotecapfile = "/$rootloc/jctmp.cap";
$localcapfile = "/nasmcd/capture/$remotecapfile";

#print "$remotecapfile $localcapfile\n";

#exit;

system ("/nas/sbin/server_tcpdump $thisserver -start fsn0 -s 1500 -w $remotecapfile > /dev/null");
# sleep a while to let the packetz capture ;-)
print "standby: we is waiting for teh packetz from $thisserver...\n";
sleep 1;
system ("/nas/sbin/server_tcpdump $thisserver -stop fsn0 > /dev/null");


$|=1;

open (IN, "/usr/sbin/tcpdump -r $localcapfile src port nfs or src port microsoft-ds |");

while(<IN>){
 @array=split(/ /,$_);
 @client=split(/\./,$array[2]);
 @server=split(/\./,$array[4]);
 $clport=pop @client;
 $slport=pop @server;
 $cl=join(".",@client);
 $sr=join(".",@server);
 if($clport == "nfs" || $clport == "microsoft"){
   $hashline = "$clport: $cl\t\t$sr";
   $hashline = sprintf ("%-20s %-32s %-32s",$clport,$cl,$sr);
   $msg{$hashline} = $msg{$hashline} ? $msg{$hashline} + 1 : 1;
 }

}

printf ("\n\n%12s %-20s %-32s %-32s\n","Packetz","Proto","Virtual Server Name","Client Address");
$i=0;
print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
for(sort { $msg{$b} <=> $msg{$a} } keys %msg) {
  if($i<10){
     ($j,$j,$keepclient[$i])=split(" ",$_);
     printf ("%12s %s\n",$msg{$_},$_);
  }
  $i++;
}
print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n\n\n";
undef %msg;
undef @keepclient;
undef @array;
undef @client;
undef @server;

#print "\n\nThe top active host $keepclient[0] is currently doing this:\n\n\n";
#system ("/usr/sbin/tcpdump -X -c1 -vvv -r $localcapfile src host $keepclient[0]");

};
