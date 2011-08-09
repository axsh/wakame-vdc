# extraoverride.pl
# generate ExtraOverride file
# use as follows :-
# extraoverride.pl < /opt/cd-image/dists/lucid/main/binary-amd64/Packages >> /opt/indices/override.lucid.extra.main

while (<>) {
        chomp;
        next if /^ /;
        if (/^$/ && defined($task)) {
                print "$package Task $task\n";
                undef $package;
                undef $task;
        }
        ($key, $value) = split /: /, $_, 2;
        if ($key eq 'Package') {
                $package = $value;
        }
        if ($key eq 'Task') {
                $task = $value;
        }
}
