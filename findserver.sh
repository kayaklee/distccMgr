#!/bin/sh

port=$1
ts=`date +"%s"`
list=""

while read line
do
  if [ -f ./run/$line ]
  then
    sts=`cat ./run/$line`
    let interval=$ts-$sts
    if [ $interval -le 60 ]
    then
      list=`echo $line:$port $list`
    fi
  fi
done <iplist

if [ -f /tmp/restart_distcc ]
then
  last_stat=`cat ./run/last_distcc_stat`
  cur_stat=`stat /tmp/restart_distcc -c "%y"`
  if [[ $cur_stat != $last_stat ]]
  then
    echo "echo $ts;killall -9 distccd; cd ~/distccd; export PATH=\$PATH:\$HOME/distccd/core/bin; distccd -P distccd.pid -p $port --allow=0.0.0.0/0 --stats --stats-port 33333 --log-file=distccd.log --daemon --log-level=debug" >./run/cmd
    echo $cur_stat >./run/last_distcc_stat
  fi
fi

tf=udistcc.$ts
echo "#!/bin/sh" >$tf
echo "export DISTCC_HOSTS='$list'" >>$tf
echo "export CC=distcc" >>$tf
echo "export CXX=\"distcc g++\"" >>$tf
mv $tf /tmp/udistcc
