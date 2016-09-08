#!/usr/bin/perl

use strict;
use Env;

$| = 1;

# ========================================================================================
# Globals 
my $APT_PKGS        = 'build-essential openssh-server git lxc passwd rinetd sshfs unzip curl vim tree lsb-release sudo libjson-perl ntpdate nfs-common htop ack-grep tree iftop figlet';
my $NTP_SERVER      = '0.amazon.pool.ntp.org';
my $GIT_BOOTSTRAP   = 'https://github.com/awilmore/skyops-bootstrap/archive/master.tar.gz';
my $PROJECT_ROOT    = "/tmp/skyops-bootstrap-master";
# ========================================================================================

my $HOSTNAME = shift or usage();
my $NR_KEY = shift or usage();
my $ART_KEY = shift or usage();

install_packages();

update_gitconfig();

git_init_etc();

update_hostname();

update_environment_config();

sync_time();


# Root user stuff
add_ssh_auth_keys();

update_bashrc();

generate_welcome_txt();

update_crontab();

fetch_project();

setup_vim();

setup_tmux();

setup_ack();

setup_bin_folder();


# Newrelic stuff
install_newrelic();


# Docker stuff
make_var_lib_docker();

install_docker();

configure_docker();

test_docker();

add_docker_newrelic_config();


# Done
move_bootstrap();

request_restart();


exit;

sub usage {
  die "usage: $0 new_hostname nr_key art_key\n";
}

sub git_init_etc {
  logger("Creating git repo in /etc...\n");

  unless(-d "/etc/.git") {
    runcmd("cd /etc && git init && git add . && git commit -m 'Initial commit.' && cd -");
    logger("Done.\n\n");
  } else {
    logger("WARNING: /etc/.git appears to exist already.\n\n");
  }
}

sub update_hostname {
  my $file = "/etc/hostname";
  write_file($file, $HOSTNAME);
}

sub update_environment_config {
  # Fix locale
  logger("Fixing system environment...\n");
  system("cp -p /usr/share/zoneinfo/Australia/Sydney /etc/localtime");

  # Fix global environment
  my $file = "/etc/environment";
  my $addition = get_environment_file_contents();
  my $check = "TZ";
  append_file($file, $addition, $check);
}

sub sync_time {
  logger("Running time sync...\n");
  runcmd("ntpdate $NTP_SERVER");
}

sub update_gitconfig {
  my $file = "/root/.gitconfig";
  my $contents = get_gitconfig_file_contents();
  write_file($file, $contents);
}

sub install_packages {
  logger("Updating package library...\n");
  runcmd("apt-get update");

  logger("Upgrading packages...\n");
  runcmd("apt-get upgrade -y");

  logger("Installing new packages...\n");
  runcmd("apt-get install -y $APT_PKGS");

  logger("Done.\n\n");
}

sub add_ssh_auth_keys {
  my $file1 = "/root/.ssh/authorized_keys";
  my $file2 = "/home/ubuntu/.ssh/authorized_keys";
  my $addition = get_ssh_auth_contents();
  my $check = "skyopsdev";
  append_file($file1, $addition, $check);
  append_file($file2, $addition, $check);
}

sub update_bashrc {
  my $file = "/root/.bashrc";
  my $addition = get_bashrc_file_contents();
  my $check = "ADDITIONS";
  append_file($file, $addition, $check);
}

sub generate_welcome_txt {
  my $file = "/root/welcome.txt";
  my $contents = get_welcome_txt_file_contents();
  write_file($file, $contents);
}

sub update_crontab {
  my $file = "/tmp/cron.tmp";
  my $crontab = get_crontab_file_contents();

  logger("Adding cron jobs...\n");
  write_file($file, $crontab);
 
  runcmd("crontab $file");
  logger("Done.\n\n");
}

sub setup_vim {
  logger("Setting up vim...\n");

  unless(-d "/root/.vim") {
    runcmd("mkdir -p /root/.vim");
    runcmd("tar -zxf $PROJECT_ROOT/configs/root/vim/vim.tgz -C /root/.vim/");
    logger("Done.\n\n");
  } else {
    logger("WARNING: .vim appears to exist already.\n\n");
  }
}

sub setup_tmux {
  logger("Setting up tmux...\n");

  unless(-f "/root/.tmux.conf") {
    runcmd("cp $PROJECT_ROOT/configs/root/tmux/.tmux.conf /root/");
    logger("Done.\n\n");
  } else {
    logger("WARNING: .tmux.conf appears to exist already.\n\n");
  }
}

sub setup_ack {
  logger("Setting up ack...\n");

  unless(-f "/root/.ackrc") {
    runcmd("cp $PROJECT_ROOT/configs/root/ack/.ackrc /root/");
    logger("Done.\n\n");
  } else {
    logger("WARNING: .ackrc appears to exist already.\n\n");
  }
}

sub setup_bin_folder {
  logger("Setting up bin folder...\n");

  unless(-d "/root/bin") {
    runcmd("cp -r $PROJECT_ROOT/configs/root/bin /root");
    logger("Done.\n\n");
  } else {
    logger("WARNING: /root/bin appears to exist already.\n\n");
  }
}

sub install_newrelic {
  logger("Installing newrelic...\n");

  unless(-f "/etc/init.d/newrelic-sysmond") {
    runcmd("$PROJECT_ROOT/scripts/install_newrelic_ubuntu.sh $NR_KEY");
    logger("Done.\n\n");
  } else {
    logger("WARNING: newrelic appears to be installed already. File exists: /etc/init.d/newrelic-sysmond\n\n");
  }
}

sub fetch_project {
  logger("Downloading bootstrap project...\n");

  unless(-d "$PROJECT_ROOT") {
    runcmd("wget -nv -O /tmp/bootstrap.tar.gz $GIT_BOOTSTRAP");
    runcmd("mkdir -p $PROJECT_ROOT");
    runcmd("tar -zxf /tmp/bootstrap.tar.gz -C /tmp");
    logger("Done.\n\n");

  } else {
    logger("WARNING: project folder $PROJECT_ROOT appears to exist already.\n\n");
  }
}

sub make_var_lib_docker {
  logger("Initialising /var/lib/docker volume on xvdb1...\n");
  
  unless(-d "/var/lib/docker") {
    runcmd("$PROJECT_ROOT/scripts/docker/make_var_lib_docker.pl");
    logger("Done.\n\n");
  } else {
    logger("WARNING: /var/lib/docker appears to exist already\n\n");
  }
}

sub install_docker {
  logger("Installing docker...\n");
  
  unless(-f "/etc/init.d/docker") {
    runcmd("$PROJECT_ROOT/scripts/docker/install-docker.sh");
    logger("Done.\n\n");
  } else {
    logger("WARNING: docker appears to be installed already. File exists: /etc/init.d/docker\n\n");
  }
}

sub configure_docker {
  logger("Configuring docker...\n");

  unless(-f "/root/.docker/config.json") {
    my $contents = get_docker_config_contents();
    runcmd("mkdir -p /root/.docker");
    write_file("/root/.docker/config.json", $contents);
    runcmd("service docker restart");
    logger("Done.\n\n");
  } else {
    logger("WARNING: docker appears to be configured already.\n\n");
  }
}

sub test_docker {
  logger("Testing docker...\n");
  runcmd("docker pull alpine:latest");
  runcmd("docker pull repo.skyops.io/alpine:latest");
  logger("Done.\n\n");
}

sub add_docker_newrelic_config {
  logger("Configuring newrelic for docker...\n");
  runcmd("usermod -a -G docker newrelic");

  logger("Restarting newrelic...\n");
  runcmd("service newrelic-sysmond restart");
  
  logger("Done.\n\n");
}

sub move_bootstrap {
  logger("Moving bootstrap project...");

  unless(-d "/root/git/skyops-bootstrap") {
    runcmd("mkdir -p /root/git");
    runcmd("mv $PROJECT_ROOT /root/git/skyops-bootstrap");
    runcmd("cd /root/git/skyops-bootstrap && git init && git remote add origin git\@github.com:awilmore/skyops-bootstrap.git");
    logger("Done.\n\n");
  } else {
    logger("WARNING: bootstrap git project appears to exist already.\n\n");
  }
}

sub request_restart {
  logger("\n");
  logger("*****************\n");
  logger("RESTART REQUIRED!\n");
  logger("*****************\n");
  logger("\n");

  printf " *** Restarting in 20 seconds (Press Ctrl-C to Abort): .";

  for(my $i = 0; $i < 20; $i++) {
    sleep 1;
    printf(".");
  }

  print "\n";

  logger("\n");
  logger("*****************\n");
  logger("RESTARTING NOW!\n");
  logger("*****************\n");
  logger("\n");

  runcmd("shutdown -r now");
  exit;
}

sub write_file {
  my $file = shift;
  my $contents = shift;

  logger("Updating $file...\n");

  open OUT, ">$file" or die "error: can't write to $file: $!\n";
  print OUT $contents;
  close OUT;

  logger("Done.\n\n");
}

sub append_file {
  my $file = shift;
  my $addition = shift;
  my $check = shift;

  unless(`grep $check $file`) {
    logger("Updating $file...\n");
    open OUT, ">>$file" or die "error: can't append to $file: $!\n";
    print OUT $addition;
    close OUT;
    logger("Done.\n\n");
  } else {
    logger("WARNING: $file already appears to be updated.\n\n");
  }
}

sub logger {
  my $msg = shift;
  print " *** $msg";
}

sub runcmd {
  my $cmd = shift;
  system($cmd) == 0 or die("error: command failed to complete successfully. Return code - $?\nCommand - $cmd\n");
  print "\n";
}

sub trycmd {
  my $cmd = shift;
  system($cmd) == 0 or print "WARNING: command failed to complete successfully. Return code - $?\nCommand - $cmd\n";
  print "\n";
}

sub get_gitconfig_file_contents {
  return <<EOF
[user]
  name = root
  email = root\@$HOSTNAME

[color]
  ui = auto

[diff]
  tool = vimdiff

[difftool]
  prompt = false

[alias]
  d  = difftool
  ls = log --pretty=format:"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]" --decorate
  ll = log --pretty=format:"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]" --decorate --numstat
  ld = log --pretty=format:"%C(yellow)%h\\\\ %ad%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]" --decorate --date=relative
  l  = log --pretty=format:"%C(yellow)%h\\\\ %Cred%cd\\\\ %Cblue[%cn]\\\\ %Creset%s" --decorate --date=short
  r  = reset --hard HEAD
  p  = pull origin master
  ps = push origin master
  s  = status
EOF
}

sub get_ssh_auth_contents {
  return <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDn1gOcodqlHJIuHUfFfyYKeIs8j35vTt2BIFTfCgVO9457pY/huf8ql+oo6kF7puUXbB9QbQhU3yHRLTeulLVt569IhBQ0Uy8iYbKYXnfuLhWkS79oKFbBkr4D9cAcq7KWxo1kQ/KNvSPnEkDDUhCh2QyGM97g0N350kb/x8ZBtH6gZ+xPxS4vBQ9avxld6vXu+81kSnsbzbw5SjgDrPBl9onBxqHLQFwByd5424x4P2Hdg24qEuQvAAe6VoztxDXfn9jk3BYk5DCa0ppYmtvi/RiusMUHHzW4+TBwVqWwH/BlRj05DL6sGQL/TLKUCexGrNJYIxZw3oAuZMtSJ3iL aw\@work
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDtMbCsKjNKWT8srIREdfpKEmexVQt+pNTlzw7B/5OfnwyPAxoZWJGKcPyxSslvpo05WACIAc2AmdeVtpBHf7qsy53Xt2Afp3MxRqPkG4I9eRHhFlSA8HmSGVN+3ADzmb3wSm95pjhmpJJEi1JMqoVdFadFrTqG1mrbL6ZEc9V8RXbg7i4JXYsG3CfbmCdm620g9bmZSLLXYeoFlJnKNsngSEr1gE9wsQppwb9JJG8Y/93y29oPBKLgzq3nn774O5Rsd4isciHljuRoKsjfXQfAv8RvMsDvdtV2376gbAfezWzPJ4pxfs1PHHFtMl1DpQ71f93j5vtVScJfGOA66l1 root\@skyopsdev
EOF
}

sub get_bashrc_file_contents {
  return <<EOF


if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

#################
# ADDITIONS
#################

export PATH="\$PATH:~/dbin:~/bin"

# PS1 settings
export COLOUR_PS="\033[1;34m"
source /root/bin/mygitprompt.sh

# Useful
alias c='cd ..'
alias tree='tree -a'
alias ack='ack-grep'
alias ackv='ack -C 2'
alias acki='ack -i'
alias acks='ack --color --noxyz -i -g'

cat /root/welcome.txt

export no_proxy=/var/run/docker.sock
EOF
}

sub get_environment_file_contents {
  return <<EOF
TZ="Australia/Sydney"
TERM="screen"
EDITOR="vim"
EOF
}

sub get_welcome_txt_file_contents {
  my $fig = `figlet -f slant $HOSTNAME`;

  return <<EOF
================================================================
$fig
================================================================

PURPOSE: SKYOPS HOST $HOSTNAME

TBC...

================================================================
EOF
}

sub get_docker_config_contents {
  return <<EOF
{
  "auths": {
    "repo.skyops.io": {
      "auth": "$ART_KEY",
      "email": ""
    }
  }
}
EOF
}

sub get_crontab_file_contents {
  return <<EOF
# Date fix
10 0 * * * /usr/sbin/ntpdate $NTP_SERVER
EOF
}
