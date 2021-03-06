# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "debian/jessie64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # SSH Agent Forwarding
  #
  # Enable agent forwarding on vagrant ssh commands. This allows you to use ssh keys
  # on your host machine inside the guest. See the manual for `ssh-add`.
  # config.ssh.private_key_path = '~/.ssh/id_rsa'
  # config.ssh.forward_agent = true

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    vb.name = "debian-jessie64"
    # Display the VirtualBox GUI when booting the machine
    # vb.gui = true
    # Customize the number of CPUs on the VM:
    vb.cpus = "1"
    # Customize the amount of memory on the VM:
    vb.memory = "2048"
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
    sudo sed -i "s/$(hostname -f)/debian.dev/g" /etc/hosts
    sudo sed -i "s/$(hostname -s)/debian/g" /etc/hosts
    sudo sh -c "echo debian.dev > /etc/hostname"
    sudo hostname debian.dev
    sudo /etc/init.d/hostname.sh start
    sudo apt-get -y install software-properties-common
    sudo rm /etc/apt/sources.list
    sudo touch /etc/apt/sources.list
    sudo add-apt-repository 'deb http://mirrors.kernel.org/debian jessie main contrib non-free'
    sudo add-apt-repository 'deb http://security.debian.org/ jessie/updates main contrib non-free'
    sudo add-apt-repository 'deb http://mirrors.kernel.org/debian jessie-updates main contrib non-free'
    sudo add-apt-repository 'deb http://download.virtualbox.org/virtualbox/debian jessie contrib'
    wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install dos2unix git php5 php5-curl php5-fpm php5-gd php5-mcrypt php5-mysqlnd php5-redis php-pear redis-server mariadb-server nginx virtualbox-5.0
    sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade
    sudo apt-get autoremove --purge -y
    sudo apt-get autoclean
    sudo apt-get clean
    curl -sS https://getcomposer.org/installer | php
    chmod +x composer.phar
    sudo mv composer.phar /usr/local/bin/composer
    curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -o /home/vagrant/.git-prompt.sh
    curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o /home/vagrant/.git-completion.bash
    export HOME=/home/vagrant
    export COMPOSER_HOME=/home/vagrant/.composer
    composer global require drush/drush
    composer global require drupal/coder
    composer global require squizlabs/php_codesniffer
    composer global require pantheon-systems/terminus
cat << "EOF" >> .bashrc
export PATH="$HOME/.composer/vendor/bin:/sbin:/usr/sbin:$PATH"
source $HOME/.composer/vendor/drush/drush/examples/example.bashrc
source $HOME/.composer/vendor/drush/drush/drush.complete.sh
source $HOME/.composer/vendor/pantheon-systems/terminus/utils/terminus-completion.bash
source $HOME/.git-prompt.sh
source $HOME/.git-completion.bash
export GIT_PS1_SHOWDIRTYSTATE=1
if [ "$(type -t __git_ps1)" ] && [ "$(type -t __drush_ps1)" ]; then
    if [ "$color_prompt" = yes ]; then
        PS1='${debian_chroot:+($debian_chroot)}\\[\\033[01;32m\\]$(whoami)@\\h\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]$(__git_ps1 " (%s)")$(__drush_ps1 "[%s]")\\$ '
    else
        PS1='${debian_chroot:+($debian_chroot)}$(whoami)@\\h:\\w$(__git_ps1 " (%s)")$(__drush_ps1 "[%s]")\\$ '
    fi
fi
EOF
cat << "EOF" >> .bash_aliases
alias ll='ls -lA'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias ip='ifconfig | grep "inet " | grep -v 127.0.0.1 | cut -d":" -f2 | cut -d" " -f1'
alias git-who='git log --oneline --pretty=format:"%cn" | sort | uniq'
alias composer-up="cd $HOME/.composer \&\& composer update \&\& cd -"
alias vim-up="cd $HOME/.vim \&\& git submodule foreach git pull \&\& cd -"
alias drupalcs="phpcs --standard=$HOME/.composer/vendor/drupal/coder/coder_sniffer/Drupal --report=full --extensions=php,module,inc,install,test,profile,theme,js,css,info,txt"
alias drupalcbf="phpcbf --standard=$HOME/.composer/vendor/drupal/coder/coder_sniffer/Drupal --report=full --extensions=php,module,inc,install,test,profile,theme,js,css,info,txt"
alias git-config='/vagrant/git-config.sh'
alias ssh-config='/vagrant/ssh-config.sh'
alias restart-lemp='/vagrant/restart-lemp.sh'
alias site-fix='/vagrant/site-fix.sh'
alias site-install='/vagrant/site-install.sh'
alias site-log='/vagrant/site-log.sh'
alias site-db='/vagrant/site-db.sh'
alias site-files='/vagrant/site-files.sh'
alias site-sync='/vagrant/site-sync.sh'
alias phpmyadmin-install='/vagrant/phpmyadmin-install.sh'
alias vim-install='/vagrant/vim-install.sh'
alias webmin-install='/vagrant/webmin-install.sh'
alias codespell-install='/vagrant/codespell-install.sh'
alias compass-install='/vagrant/compass-install.sh'
alias less-install='/vagrant/less-install.sh'
alias xhprof-install='/vagrant/xhprof-install.sh'
alias xdebug-install='/vagrant/xdebug-install.sh'
EOF
    sed -i 's/^#force_color_prompt/force_color_prompt/g' .bashrc
    sed -i 's/^unset color_prompt/#unset color_prompt/g' .bashrc
    sudo chown -R vagrant:vagrant /home/vagrant
    sudo chown -R vagrant:vagrant /var/www
    source .bashrc
    $HOME/.composer/vendor/bin/phpcs --config-set installed_paths $HOME/.composer/vendor/drupal/coder/coder_sniffer
    cd /etc/php5/fpm/
    sudo sed -i 's/^memory_limit = 128M/memory_limit = 256M/' php.ini
    sudo sed -i 's/^max_execution_time = 30/max_execution_time = 90/' php.ini
    sudo sed -i 's/^max_input_time = 60/max_input_time = 90/' php.ini
    sudo sed -i 's/^post_max_size = 8M/post_max_size = 128M/' php.ini
    sudo sed -i 's/^upload_max_filesize = 2M/upload_max_filesize = 128M/' php.ini
    sudo sed -i 's/^error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL/' php.ini
    sudo sed -i 's/^display_errors = Off/display_errors = On/' php.ini
    sudo sed -i 's/^display_startup_errors = Off/display_startup_errors = On/' php.ini
    sudo sed -i 's/^track_errors = Off/track_errors = On/' php.ini
    sudo sed -i 's/^;always_populate_raw_post_data = -1/always_populate_raw_post_data = -1/' php.ini
    sudo sed -i 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' php.ini
    cd /etc/php5/fpm/pool.d
    sudo sed -i 's,^listen = 127.0.0.1:9000,listen = /var/run/php5-fpm.sock,' www.conf
    sudo sed -i 's,^;listen.owner = www-data,listen.owner = www-data,' www.conf
    sudo sed -i 's,^;listen.group = www-data,listen.group = www-data,' www.conf
    sudo sed -i 's,^;listen.mode = 0660,listen.mode = 0660,' www.conf
sudo sh -c 'cat << "EOF" > /etc/nginx/conf.d/drupal.conf.example
# Example Drupal Recipe
# See https://www.nginx.com/resources/wiki/start/topics/recipes/drupal/
server {
    listen 80;
    server_name example.com;
    root /var/www/drupal7;
    index index.php;
    access_log /var/log/nginx/drupal7-access.log;
    error_log /var/log/nginx/drupal7-error.log;

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Very rarely should these ever be accessed outside of your lan
    location ~* \\.(txt|log)$ {
        allow 192.168.0.0/16;
        deny all;
    }

    location ~ \\..*/.*\\.php$ {
        return 403;
    }

    location ~ ^/sites/.*/private/ {
        return 403;
    }

    # Block access to "hidden" files and directories whose names begin with a
    # period. This includes directories used by version control systems such
    # as Subversion or Git to store control files.
    location ~ (^|/)\\. {
        return 403;
    }

    location / {
        # try_files $uri @rewrite; # For Drupal <= 6
        try_files $uri /index.php?$query_string; # For Drupal >= 7
    }

    location @rewrite {
        rewrite ^/(.*)$ /index.php?q=$1;
    }

    location ~ \\.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        #NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $request_filename;
        fastcgi_intercept_errors on;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        #fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
    }

    # Fighting with Styles? This little gem is amazing.
    # location ~ ^/sites/.*/files/imagecache/ { # For Drupal <= 6
    location ~ ^/sites/.*/files/styles/ { # For Drupal >= 7
        try_files $uri @rewrite;
    }

    location ~* \\.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires max;
        log_not_found off;
    }
}
EOF'
    sudo /etc/init.d/php5-fpm restart
    sudo /etc/init.d/redis-server restart
    sudo /etc/init.d/nginx restart
    sudo /etc/init.d/mysql restart
    cd
  SHELL
end
