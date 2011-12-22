#!/bin/bash
#Research Computing EMC Filesystem Creation Script 2.0!
#Matthew Nicholson
#12.21.2011

LOGFILE="create_fs.log"

echo "Please answer the following quesions. Examples will be in parentheses"
echo ""
echo ""
echo "Desired Filesystem/Share Name (Matts_Lab):"
read fs_name
echo "Size (1T, 50G, 200M)":
read fs_size
echo "Please select a datamover:"

#Lets output a list of Datamover => RCFSX mapping, with current filesystem count!
for i in 2 3 4 5 6 7 8
do
        RCFS_NUM=$(($i - 1))
        FS_COUNT=`server_mount server_$i | grep -v ckpt |wc -l`
        echo "server_$i => RCFS$RCFS_NUM Current FS count:$FS_COUNT"
done
echo "Please select a datamover NUMBER(server_2 = 2, server_3 = 3, etc):"
read datamover
echo "Would you like an NFS export? (y|n):"
read nfs_ans
echo "Would you like a CIFS share? (y|n):"
read cifs_ans
echo "Would you like checkpoints? The default schedule is 1 a day and 7 days are kept. (y|n)"
read ckpt_ans
sleep 2
#Logging
echo "!NEW FILESYSTEM CREATION!" >> $LOGFILE
#Logging
echo "Okay! Here is what I've got:" | tee -a $LOGFILE
echo "" | tee -a $LOGFILE
echo "You want to create a filesystem named $fs_name"| tee -a $LOGFILE
echo "$fs_size in size"| tee -a $LOGFILE
echo "On the datamover $datamover"| tee -a $LOGFILE
if [[ $nfs_ans == "y" ]]
then
        echo "With a NFS export"| tee -a $LOGFILE
fi
if [[ $cifs_ans == "y" ]]
then
        echo "With a CIFS share"| tee -a $LOGFILE
fi
if [[ $ckpt_ans == "y" ]]
then
        echo "With Checkpoints"| tee -a $LOGFILE
fi

#Build commands to be run, output them (and we're going to log them as well)
#Create filesystem
do_fs="nas_fs -name $fs_name -create size=$fs_size pool=clarata_archive storage=APM00092302102 -auto_extend no -option slice=y"
#mount
dm="server_$datamover"
do_mount="server_mount $dm -option accesspolicy=NATIVE $fs_name /$fs_name"
#share_root
do_share_root="sudo mkdir /nas/quota/slot_$datamover/$fs_name/share_root"
if [[ $nfs_ans == "y" ]]
then
	do_nfs="server_export $dm -P nfs -option access=10.242.0.0/16,rw=10.242.0.0/16,root=10.242.67.16:10.242.64.31:10.242.64.32:10.242.64.16:10.242.64.19:10.242.74.0/26:10.242.54.0/24 /$fs_name/share_root"
fi
if [[ $cifs_ans == "y" ]]
then
	rcfs_num=$(($datamover - 1))
	do_cifs="server_export $dm -P cifs -name $fs_name -option netbios=RCFS$rcfs_num /$fs_name/share_root"
fi
if [[ $ckpt_ans == "y" ]]
then
	#set ckpts to run $now
	ckpt_time=`date +%H:%M`
	#set stat day to tomorrow
	ckpt_start=`date +%Y-%m-%d -d tomorrow`
	do_ckpt="nas_ckpt_schedule -create $fs_name -filesystem $fs_name -recurrence daily -keep 7 -start_on $ckpt_start -runtimes $ckpt_time"
fi
echo "Does this look good?(y|n)"
read ans1
if [[ $ans1 != "y" ]]
	then
		exit
fi


#Echo out all commands
sleep 2
echo "Okay, here is what I want to do. Please check this to make sure its good. We're relying on EMC to check the imput to their tools. They are good, but please check..."
echo ""
echo "Make FS"
echo $do_fs | tee -a $LOGFILE
echo "Mount it"
echo $do_mount | tee -a $LOGFILE
echo "Create share_root"
echo $do_share_root | tee -a $LOGFILE
if  [[ $nfs_ans == "y" ]]
then
	echo "NFS Export"
	echo $do_nfs | tee -a $LOGFILE
fi
if [[ $cifs_ans == "y" ]]
then
	echo "CIFS Share"
	echo $do_cifs | tee -a $LOGFILE
fi
if [[ $ckpt_ans == "y" ]]
then
	echo "Checkpoint schedule"
	echo $do_ckpt | tee -a $LOGFILE
fi
echo ""
echo "Last chance...look good? Want to proceed making this? (y|n)"
read ans2
if [[ $ans2 != "y" ]]
then
	exit
fi

#Here we go...
echo "Making stuff! In a moment, we'll need the nasadmin password for sudo, so be ready..."
$do_fs | tee -a $LOGFILE
$do_mount | tee -a $LOGFILE
echo "WE NEED SUDO, PLEASE wait to see the prompt here!"
$do_share_root | tee -a $LOGFILE
if  [[ $nfs_ans == "y" ]]
then
	$do_nfs | tee -a $LOGFILE
fi
if [[ $cifs_ans == "y" ]]
then
	$do_cifs | tee -a $LOGFILE
fi
if [[ $ckpt_ans == "y" ]]
then
	$do_ckpt | tee -a $LOGFILE
fi
echo "All DONE!"
echo "Please double check everything"
echo "Don't forget to set ownship/perms on what you just made"
echo "and if this need to be backed up, PUT IN A TICKET!"