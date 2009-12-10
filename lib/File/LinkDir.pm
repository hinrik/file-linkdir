package File::LinkDir;

use strict;
use warnings;

use Cwd qw<abs_path getcwd>;
use File::Find;
use File::Path qw<remove_tree>;
use File::Spec::Functions qw<catpath splitpath>;
use Getopt::Long qw<:config auto_help bundling>;
use Pod::Find qw<pod_where>;
use Pod::Usage;

our $VERSION = '0.02';
my ($dry_run, $source, $dest, $recursive, $force, @add_ignore);
my $ignore = '^\.(?:git|svn)(?:/.*)?$';

sub run {
    GetOptions(
        'n|dry-run'      => \$dry_run,
        's|source=s'     => \$source,
        'd|dest=s'       => \$dest,
        'r|recursive'    => \$recursive,
        'i|ignore=s'     => \$ignore,
        'a|add-ignore=s' => \@add_ignore,
        'f|force'        => \$force,
        'v|version'      => sub { print "link-files version $VERSION\n"; exit },
    ) or pod2usage(-input => pod_where({-inc => 1}, 'link-files'));

    $source = abs_path($source) if defined $source;
    die "You must supply a --source directory\n" if !defined $source || !-d $source;
    die "You must supply a --dest directory\n" if !defined($dest) || !-d $dest;
    chdir $source or die "Couldn't chdir to '$source'\n";

    eval { $ignore = qr/$ignore/ };
    die "Invalid regex passed to --ignore: $@\n" if $@;
    for my $rx (@add_ignore) {
        eval { $rx = qr/$rx/ };
        die "Invalid regex passed to --add-ignore: $@\n" if $@;
    }

    $recursive
        ? find({wanted => \&recursive, no_chdir => 1}, $source)
        : normal()
    ;
}

sub recursive {
    my $file = $File::Find::name;
    $file =~ s{^$source/}{};

    return if $file =~ $ignore;
    return if grep { $file =~ /$_/ } @add_ignore;
    return if !-f $file && !-l $file;

    if (-l $file && -l "$dest/$file") {
        # skip if it's a symlink which is already in place
        return if readlink($file) eq readlink("$dest/$file");
    }

    if (!-l $file && -l "$dest/$file" && stat "$dest/$file") {
        # skip if it's file that has already been symlinked
        return if (stat "$dest/$file")[1] == (stat $file)[1];
    }
    
    if (-e "$dest/$file" || -l "$dest/$file") {
        if (!-l "$dest/$file" && -d "$dest/$file") {
            warn "Won't replace dir '$dest/$file' with a symlink\n";
            return;
        }

        if (!$force) {
            $dry_run
                ? print "--force is off, would not overwrite '$dest/$file'\n"
                : print "--force is off, not overwriting '$dest/$file'\n"
            ;
            return;
        }
        
        if ($dry_run) {
            print "Would overwrite '$dest/$file' -> '$source/$file'\n";
            return;
        }
        else {
            print "Overwriting '$dest/$file' -> '$source/$file'\n";
            if (!unlink "$dest/$file") {
                warn "Can't remove '$dest/$file': $!\n";
                return;
            }
        }
    }
    else {
        $dry_run
            ? print "Would create '$dest/$file' -> '$source/$file'\n"
            : print "Creating '$dest/$file -> '$source/$file''\n"
        ;
    }
    
    return if $dry_run;

    my $path = catpath((splitpath("$dest/$file"))[0,1]);
    if (!-d $path) {
        eval { make_path($path) };
        if ($@) {
            warn "Failed to create dir '$path': $@\n";
            return;
        }
    }

    my $success = -l $file
        ? symlink readlink($file), "$dest/$file"
        : symlink "$source/$file", "$dest/$file"
    ;

    warn "Can't create '$dest/$file': $!\n" if !$success;
}

sub normal {
    opendir my $dir_handle, $source or die "Can't open the dir $source: $!; aborted";

    while (defined (my $file = readdir $dir_handle)) {
        next if $file =~ /^\.{1,2}$/;
        next if $file =~ $ignore;
        next if grep { $file =~ /$_/ } @add_ignore;

        if (-l "$dest/$file" && stat "$dest/$file") {
            next if (stat "$dest/$file")[1] == (stat $file)[1];
        }
        
        if (-e "$dest/$file" || -l "$dest/$file") {
            if (!$force) {
                $dry_run
                    ? print "--force is off, would not overwrite '$dest/$file'\n"
                    : print "--force is off, not overwriting '$dest/$file'\n"
                ;
                next;
            }
            
            if ($dry_run) {
                print "Would overwrite '$dest/$file' -> '$source/$file'\n";
                next;
            }
            else {
                print "Overwriting '$dest/$file' -> '$source/$file'\n";

                if (-d "$dest/$file") {
                    eval { remove_tree("$dest/$file") };
                    if ($@) {
                        warn "Failed to remove directory '$dest/$file': $@\n";
                        next;
                    }
                }
                elsif (!unlink("$dest/$file")) {
                    warn "Failed to remove file '$dest/$file': $!\n";
                    next;
                }
            }
        }
        else {
            $dry_run
                ? print "Would create '$dest/$file' -> '$source/$file'\n"
                : print "Creating '$dest/$file' -> '$source/$file'\n"
            ;
        }
        
        next if $dry_run;
        symlink "$source/$file", "$dest/$file" or warn "Can't create '$dest/$file': $!\n";
    }
}

=encoding UTF-8

=head1 NAME

File::LinkDir - Create symlinks in one directory for files in another

=head1 SYNOPSIS

 use File::LinkDir;
 File::LinkDir->run();

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
