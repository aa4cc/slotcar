
echo Copy $1 $2


sshpass -p temppwd scp -r $1.zip debian@$2:~/

# unzip not in default bbb
sshpass -p temppwd ssh debian@$2 "unzip -o $1.zip -d $1; exit " 

# Copy missing make files (.mk and some other)
sshpass -p temppwd scp -r $1_ert_rtw/*.mk $1_ert_rtw/*.tmw debian@$2:~/$1

echo Make $1
sshpass -p temppwd ssh debian@$2 "cd $1 ; make -f $1.mk all ; exit" 


# echo Run $1

# sshpass -p temppwd ssh debian@$2 "sudo ./$1.elf > $1.log 2>&1 & "

exit
