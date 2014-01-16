#!/usr/local/bin/perl
use warnings; 
use strict;
use DBI;
my ($SQL);
my (@COLUMNS);
my (@ROWS);
my ($NUM_ROWS);
my (@VALUES);
my ($RESULTS);
my ($row,$col,$size);

#print STDERR "Open database connection...\n";
my $dbh = DBI->connect('dbi:Oracle:host=tairdb01.tacc.utexas.edu;sid=tairtest;port=1521', 'aip', 'bi9frud6feb5tud7');

sub execute_multiple_row() {
    my ($sth);
    my ($i)=0;
    @{$RESULTS} = ();
    $sth = $dbh->prepare($SQL); 
    $sth->execute();
    while (@COLUMNS = $sth->fetchrow_array()) {
	my ($fld,$num_fld);
	$num_fld = scalar(@COLUMNS);
	for ($fld=0; $fld<$num_fld; $fld++) {
	    $COLUMNS[$fld] = "NULL" unless (defined($COLUMNS[$fld]));
	}
	push (@{$RESULTS->[$i++]}, @COLUMNS);
    }
    $NUM_ROWS = $i;
    $sth->finish();
    #print STDERR "Received $NUM_ROWS rows from $SQL\n";
}


sub print_rows () {
    my ($stripe_name) = shift;
    my ($rr);
    &execute_multiple_row();
    if ($NUM_ROWS == 0) {
	print STDOUT "$stripe_name\tEMPTY\n";
    } else {
	for ($rr = 0; $rr < $NUM_ROWS; $rr++) {
	    @COLUMNS = @{$RESULTS->[$rr]};
	    print STDOUT join("\t",@COLUMNS) ."\n";
	}
    }
}

$SQL = sprintf ("SELECT * FROM (SELECT tairObjectId, polymorphismId, name, polymorphismType, geneFeatureSite, NVL(alleleMode, 'unknown') AS alleleMode FROM aip.LocusPolymorphism  ORDER BY LOWER(name)) ");

&print_rows(1);
die ("NOT FOUND") unless ($NUM_ROWS > 0);

