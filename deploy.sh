#/bin/sh
self_dir=$(cd `dirname $0`; pwd)

source $self_dir/setup.conf

$SUDO yum install -y gcc
$SUDO yum install -y gcc-c++

#prepare for master
rm -rf $DISTCC_DIR
mkdir -p $DISTCC_DIR
mkdir -p $DISTCC_DIR/run
cp $self_dir/iplist        $DISTCC_DIR/
cp $self_dir/findserver.sh $DISTCC_DIR/

# prepare for slave
rm -rf $MASTER_DIR
mkdir -p $MASTER_DIR
cp $self_dir/distcc-3.1.tar.gz $MASTER_DIR/
echo -e "$SLAVE_KEEPALIVE"     >$MASTER_DIR/keepalive.sh
echo -e "$SLAVE_SETUP"         >$MASTER_DIR/distcc_slave_setup.sh
echo -e "$DISTCC_INSTALL"      >$MASTER_DIR/install_distcc
echo -e "$DISTCC_SUDO_INSTALL" >$MASTER_DIR/sudo_install_distcc
rm -rf $MASTER_DIR/udistcc
ln -s /tmp/udistcc             $MASTER_DIR/

# launch http server
cd $MASTER_DIR
ps aux | grep "python -m SimpleHTTPServer $MASTER_PORT" | grep grep -v | awk '{print $2}' | xargs kill -9
nohup python -m SimpleHTTPServer $MASTER_PORT >/dev/null 2>&1 &
sleep 1
cd -

# install distcc
#curl -s http://$MASTER_ADDR:$MASTER_PORT/sudo_install_distcc | $SUDO sh

#prapre master crontab
crontab -l >old_crontab.tmp
echo -n -e "$MASTER_CRON" >>old_crontab.tmp
cat old_crontab.tmp | sort | uniq >new_crontab.tmp
crontab new_crontab.tmp
rm -rf old_crontab.tmp new_crontab.tmp
crontab -l

mkdir -p cmd
echo -e "$SLAVE_DEPLOY_CMD" >cmd/slave_deploy.sh; chmod 775 cmd/slave_deploy.sh
echo -e "$DISTCC_INSTALL_CMD" >cmd/distcc_install.sh; chmod 775 cmd/distcc_install.sh
