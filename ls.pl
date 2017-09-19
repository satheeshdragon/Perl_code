#!/usr/bin/perl -w
#

# ls.pl -- ls command implementation in perl. {{{1
#
# Author:  soarpenguin <soarpenguin@gmail.com>
#          First release Nov.14 2012
# 1}}}

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
#use Smart::Comments;
use File::Spec::Functions;
use POSIX qw(strftime);
use Cwd;
use feature 'state';

use Term::ANSIColor;
#print color("red"), "Stop!\n", color("reset");
#print color("green"), "Go!\n", color("reset");

my $script = basename $0;
my $myversion = '0.2.0';

my $usage = "Usage: $script [OPTION]... [FILE]...

List information about the FILEs (the current directory by default).
Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.

Mandatory arguments to long options are mandatory for short options too.
  -a, --all                  do not ignore entries starting with .
  -g                         like -l, but do not list owner
  -1                         list one file per line
  -n, --numeric-uid-gid      like -l, but list numeric user and group IDs
  -o                         like -l, but do not list group information
  -r, --reverse              reverse order while sorting
      --help     display this help and exit
      --version  output version information and exit

SIZE may be (or may be an integer optionally followed by) one of following:
KB 1000, K 1024, MB 1000*1000, M 1024*1024, and so on for G, T, P, E, Z, Y.

Using color to distinguish file types is disabled both by default and
with --color=never.  With --color=auto, ls emits color codes only when
standard output is connected to a terminal.  The LS_COLORS environment
variable can change the settings.  Use the dircolors command to set it.

Exit status:
 0  if OK,
 1  if minor problems (e.g., cannot access subdirectory),
 2  if serious trouble (e.g., cannot access command-line argument).
";
my ($all, $list, $reverse, $nogid, $numeric_uid_gid); 
my ($noowner);

my $ret = GetOptions( 
    'l'         => \$list,
    'n|numeric-uid-gid' => \$numeric_uid_gid,
    'all'       => \$all,
    'g'         => \$noowner,
    'o'         => \$nogid,
    'reverse|r' => \$reverse,
    'help'	    => \&usage,
    'version|V' => \&version
);

if(! $ret) {
    &usage();
}

#------------------------------------------------------

&main();

sub main {
    if (@ARGV == 0) {
        $ARGV[0] = getcwd();
    }

    if($numeric_uid_gid or $noowner) {
        $list = 1;
    }

    foreach my $myfile (@ARGV) {
        if($myfile eq '.') {
            $myfile = getcwd();
        }

        print "---------------------$myfile-----------------------\n";
        if(-e $myfile) {
            if(-d -x _) {
                ## $myfile
                &listdir($myfile);
                # opendir($myfile)
            } elsif (-f _) {
                if($list or $nogid) {
                    &listfile($myfile);
                } else {
                    printf "%18s", "$myfile";
                }
            } else {
                print "$myfile unknown type or have no right.\n";
            }
        } else {
            print "$myfile is not existed.\n";
        }

    }
}

#------------------------------------------------------
# list file
sub listfile {
    my $file = shift;

    # get file info use the stat.
    my ($right, $nlink, $uid, $gid, $size, $ctime) = 
                        (stat $file)[2, 3, 4, 5, 7, 10];
    
    my $type = &filetype($file);

    $right = &right_string($right);
    if(! $numeric_uid_gid) {
        $uid   = getpwuid($uid); #from user id to user name.
        $gid   = getgrgid($gid); #from group id to group name.
    }

    # the format of below: Sun Nov 11 14:18:02 2012
    # $ctime = strftime "%a %b %e %H:%M:%S %Y", localtime($info[10]);
    $ctime = strftime "%b %e %H:%M %Y", localtime($ctime);

    # the -o option just like -l, no group id.
    if($nogid) {
        printf "%1s%9s %3d %8s %8d %12s", $type, $right, $nlink, $uid, $size, $ctime;
    } elsif($noowner) {
        printf "%1s%9s %3d %8s %8d %12s", $type, $right, $nlink, $gid, $size, $ctime;
    } else {
        printf "%1s%9s %3d %8s %8s %8d %12s", $type,$right,$nlink,$uid,$gid,$size,$ctime;
    }

    print "\n";
}

# list dir
sub listdir {
    state $count = 0;
    my $mydir = shift;
    ## $mydir
    my $dh;
    opendir $dh, $mydir or die "Can't open the $mydir\n";

    $| = 1;
    my @files = readdir $dh;
    closedir($dh);

    if($reverse) {
        @files = sort by_code_reverse @files;
    } else {
        @files = sort by_code @files;
    }

    foreach my $file (@files) {
        ## $file;
        if($list or $nogid) {
            unless ($all) {
                next if($file =~ /^\.+$/);
            }

            my $fname = $file;
            $file = catfile($mydir, $file);
            $count++;
            ## $file
            # get file info use the stat.
            my ($right, $nlink, $uid, $gid, $size, $ctime) = 
                                (stat $file)[2, 3, 4, 5, 7, 10];
            
            my $type = &filetype($file);

            $right = &right_string($right);
            if(! $numeric_uid_gid) {
                $uid   = getpwuid($uid); #from user id to user name.
                $gid   = getgrgid($gid); #from group id to group name.
            }

            # the format of below: Sun Nov 11 14:18:02 2012
            # $ctime = strftime "%a %b %e %H:%M:%S %Y", localtime($info[10]);
            $ctime = strftime "%b %e %H:%M %Y", localtime($ctime);

            # the -o option just like -l, no group id.
            if($nogid) {
                printf "%1s%9s %3d %8s %8d %12s", $type, $right, $nlink, $uid, $size, $ctime;
            } elsif($noowner) {
                printf "%1s%9s %3d %8s %8d %12s", $type, $right, $nlink, $gid, $size, $ctime;
            } else {
                printf "%1s%9s %3d %8s %8s %8d %12s", $type,$right,$nlink,$uid,$gid,$size,$ctime;
            }

            if(-d $file) {
                print color("blue");
                $fname .= '/';
            } elsif (-x _) {
                print color("green"); 
                $fname .= '*';
            }
            printf " %-18s\n", $fname;
            print color("reset");

        } else {
            unless ($all) {
                next if($file =~ /^\.+$/);
            }
            my $fname = $file;
            $file = catfile($mydir, $file);
            $count++;
            ## $file
            if(-d $file) {
                print color("blue");
            } elsif (-x _) {
                print color("green"); 
            }
            printf "%-18s", $fname;
            print color("reset");

            if($count % 5 == 0) {
                print "\n";
            } 
        }
    }

    if($count % 5 and !$list) {
        print "\n";
    }
}

# function for signal action
sub catch_int {
    my $signame = shift;
    print color("red"), "Stoped by SIG$signame\n", color("reset");
    exit;
}
$SIG{INT} = __PACKAGE__ . "::catch_int";
$SIG{INT} = \&catch_int; # best strategy

sub usage {
    print $usage;
    exit;
}

sub version {
    print "$script version $myversion\n";
    exit;
}

sub by_code {
    return "\L$a" cmp "\L$b";
}

sub by_code_reverse {
    return "\L$b" cmp "\L$a";
}

sub filetype {
    my $file = shift;
    my $type = '';

    if (-f $file) {
        $type = '-';
    } elsif (-d _) {
        $type = 'd';
        #$fname .= '/';
    } elsif (-l _) {
        $type = 'l';
    } elsif (-S _) {
        $type = 's';
    } elsif (-b _) {
        $type = 'b';
    } elsif (-c _) {
        $type = 'c';
    } elsif (-p _) {
        $type = 'p';
    } else {
        $type = 'u';
    }
}
# convert a decimal to right string like 'rwx---rw-'
sub right_string {
    my $right = shift;
    $right &= 0x777;

    #my $dec_perms = $right & 07777;
    #my $oct_perm_str = sprintf "%o", $dec_perms;
    $right = sprintf "%o", $right & 0777;
    $right =~ s/0/---/g;
    $right =~ s/1/--x/g;
    $right =~ s/2/-w-/g;
    $right =~ s/3/-wx/g;
    $right =~ s/4/r--/g;
    $right =~ s/5/r-x/g;
    $right =~ s/6/rw-/g;
    $right =~ s/7/rwx/g;
    ## $right

    return $right;
}
## $myfile
## @ARGV

