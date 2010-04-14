#!/bin/bash

[ $UID -eq 0 ] || { echo "Run with root user."; exit 1; }

apt-get update;
apt-get -y upgrade;

apt-get -y install apache2-mpm-prefork libapache2-mod-rpaf
apt-get -y install mysql-server mysql-client
apt-get -y install erlang-nox
apt-get -y install unzip zip rsync libopenssl-ruby libhmac-ruby rubygems irb ri rdoc sysstat
apt-get -y install apache2-prefork-dev ruby-dev make g++ libopenssl-ruby subversion
apt-get -y install memcached

apt-get clean

(cd /tmp;
wget http://www.rabbitmq.com/releases/rabbitmq-server/v1.6.0/rabbitmq-server_1.6.0-1_all.deb
dpkg -i rabbitmq-server_1.6.0-1_all.deb
)


if ! getent group wakame >/dev/null; then
    addgroup --system wakame
fi

if ! getent passwd wakame >/dev/null; then
    adduser --system --ingroup wakame --disabled-password wakame
fi

mkdir /home/wakame/config
chown wakame:wakame /home/wakame/config
mkdir /home/wakame/mysql
mkdir /home/wakame/mysql/data
mkdir /home/wakame/mysql/data-slave
chown mysql:mysql /home/wakame/mysql/data /home/wakame/mysql/data-slave

if ! grep GEM_HOME /etc/environemnt >/dev/null; then
    cat <<EOF > /etc/environment
GEM_HOME=/usr/local/gems
EOF
fi

cat <<EOF > /etc/default/wakame
WAKAME_ROOT=/home/wakame/wakame.proj
GEM_HOME=/usr/local/gems
EOF

update-rc.d -f apache2 remove
update-rc.d -f mysql remove
update-rc.d -f mysql-ndb remove
update-rc.d -f mysql-ndb-mgm remove
update-rc.d -f mysql-ndb-mgm memcached
# Disable apparmor
update-rc.d -f apparmor remove

cat <<'EOF' > /usr/local/bin/passenger_ruby.sh
#!/bin/sh
. /etc/environment
export RUBYLIB GEM_HOME
exec /usr/bin/ruby $@
EOF
chmod 755 /usr/local/bin/passenger_ruby.sh

# Create root ssh key
ssh-keygen -t rsa -N '' -f /home/wakame/config/root.id_rsa
chown wakame:wakame /home/wakame/config/root.id_rsa /home/wakame/config/root.id_rsa.pub
cat /home/wakame/config/root.id_rsa.pub >> /root/.ssh/authorized_keys

#gem install rake rails eventmachine amqp log4r daemons passenger hoe amazon-ec2 --no-ri --no-rdoc
#(cd $GEM_HOME/gems/passenger-*; rake)

#update-rc.d wakame-master defaults 41
#update-rc.d wakame-agent defaults 40

# 
# /root/.ssh/authorized_keys /root/.bash_history
# /home/ubuntu/.ssh/authorized_keys /home/ubuntu/.bash_history
# Clear logs
# logrotate -f /etc/logrotate.conf
# rm -f /var/log/apache2/* /var/log/rabbitmq/* /var/log/wakame-* /var/log/*.gz /var/log/*.0 /var/log/*.1
