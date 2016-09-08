#!/usr/bin/perl

use strict;
use File::Basename;

# ========================================================================================
# Globals 
my $LOG_TOKEN = '<dmount>';
my $MOUNT_PATH = '/var/lib/docker';
my $CWD = dirname(__FILE__);
# ========================================================================================

# Check for root user
check_run_with_root();

# Check /var/lib/docker
check_path_exists_already();

# Check /etc/fstab for xvdb1
check_existing_fstab();

# Call fdisk wrapper
call_fdisk_xvdb_wrapper();

# Make partition
create_partition();

# Create /var/lib/docker
create_var_lib_docker_path();

# Update fstab config
update_fstab();

# Run mount
mount_var_lib_docker();


myprint("Mount complete.\n");

exit;

sub check_run_with_root { 
  print_section("Checking for root user");
  mydie("error: must run as root\n") if($>);
}

sub check_path_exists_already {
  print_section("Checking for existing mount path");
  mydie("error: mount path exists already: $MOUNT_PATH\n") if(-d "$MOUNT_PATH");
}

sub check_existing_fstab {
  print_section("Checking for existing fstab entry for xvdb1");
  mydie("error: xvdb1 mount config already exists in fstab\n") if(`grep '/dev/xvdb1' /etc/fstab`);
}

sub call_fdisk_xvdb_wrapper {
  print_section("Calling fdisk wrapper");
  runcmd("${CWD}/fdisk_xvdb_wrapper.sh");
}

sub create_partition {
  print_section("Create ext4 partition");
  runcmd("mkfs.ext4 /dev/xvdb1");
}

sub create_var_lib_docker_path {
  print_section("Creating mount path: $MOUNT_PATH");
  runcmd("mkdir -p $MOUNT_PATH");
}

sub update_fstab {
  print_section("Updating fstab config");
  runcmd("echo \"# Mount xvdb1 for docker\" >> /etc/fstab");
  runcmd("echo \"/dev/xvdb1    /var/lib/docker    ext4    defaults    0    1    \" >> /etc/fstab");
}

sub mount_var_lib_docker {
  print_section("Mounting /var/lib/docker...");
  runcmd("mount /dev/xvdb1 /var/lib/docker");
}


###
# PRIVATE METHODS
###

sub runcmd {
  my $cmd = shift;
  myprint("Executing: $cmd...\n");
  system($cmd) == 0 or mydie("error: command failed to complete successfully. Return code: $?\n");
}

sub mydie {
  my $m = shift;
  myprint($m);
  exit 1;
}

sub myprint {
  my $m = shift;
  print $LOG_TOKEN . " " . $m;
}

sub print_section {
  my $m = shift;
  print $LOG_TOKEN . "\n";
  print $LOG_TOKEN . " ========================================================\n";
  myprint("* " . $m . "\n");
}
