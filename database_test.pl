#!/usr/local/bin/perl
use strict;
use warnings;

use Fina::Corp::Config;
use List::MoreUtils qw(any);

my $dbh = Fina::Corp::Config->connect();
my @user_arg = qw(users id);

my $sql = "SELECT pg_tables.tablename FROM pg_catalog.pg_tables WHERE pg_tables.tableowner = 'mcfapps' ORDER BY pg_tables.tablename ASC";
my $sth = $dbh->prepare($sql);
$sth->execute();
my @tables;
while (my $r = $sth->fetchrow_hashref){
    push @tables, $r->{tablename};
}
print "$user_arg[0] is a valid table.\n" if (any {$_ eq $user_arg[0]} @tables);
#print "There are ".scalar(@tables)." tables.\n";


my $column_sql = "SELECT * FROM $user_arg[0] LIMIT 1;";
my $column_sth = $dbh->prepare($column_sql);
$column_sth->execute();
my @columns = @{$column_sth->{NAME}};
print "$user_arg[1] is a valid column.\n" if (any {$_ eq $user_arg[1]} @columns);
#print "There are ".scalar(@columns)." columns.\n";
