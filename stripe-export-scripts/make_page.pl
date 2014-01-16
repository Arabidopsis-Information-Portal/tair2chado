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
my ($locid)=$ARGV[0];
my ($toid);
if (!defined($locid)) {
#   This example has external links but no publications.
    $toid=1005716525;    $locid=1000429852;
#   This example has lots of everything including comments and publications
    $toid = 2005487;     $locid=26521;
}
print STDERR "Open database connection...\n";
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
    print STDERR "Received $NUM_ROWS rows from $SQL\n";
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
	    print STDOUT "$stripe_name\t". join("\t",@COLUMNS) ."\n";
	}
    }
}

$SQL = sprintf ("select tair_object_id,locus_id from aip.Locus WHERE locus_id = %d", $locid);
&execute_multiple_row();
@COLUMNS = @{$RESULTS->[0]};
$toid = $COLUMNS[0];
&print_rows("Tair_Object_ID");
die ("NOT FOUND") unless ($NUM_ROWS > 0);

# we may not need any of this
# seems to be counts for looping later on
$SQL = sprintf ("SELECT tairObjectId,accession,locusId,name,taxonId,chromosome,obsolete,repGeneName,repGeneId,repGeneTairObjectId,repGeneModelType,repGeneDescription,spanStartPosition,spanEndPosition,dateLastModified,polymorphismCount,germplasmCount,publicationCount FROM aip.LocusDetail WHERE tairObjectId = %d", $toid);
&print_rows("Tair_Object_Counts");

# this can be empty
$SQL = sprintf ("SELECT tairObjectId,updateHistoryId,locusName,updateType,affectedTairObjectId,affectedTairObjectType,affectedTairObjectName,updateHistoryDate FROM aip.LocusUpdateHistory WHERE tairObjectId = %d", $toid);
&print_rows("Update_History");

$SQL = sprintf ("SELECT tairObjectId,updateHistoryId,tairObjectName,objectType,updateType,updateHistoryDate FROM aip.AffectedLocusUpdateHistory WHERE tairObjectId = %d", $toid);
&print_rows("Update_History_Date");

$SQL = sprintf ("SELECT tairObjectId,name FROM aip.LocusOtherName WHERE tairObjectId = %d", $toid);
&print_rows("Other_Names");

$SQL = sprintf ("SELECT tairObjectId,transposonId,name,chromosome FROM aip.LocusTransposon WHERE tairObjectId = %d", $toid);
&print_rows("Transposons");

$SQL = sprintf ("SELECT tairObjectId,geneId,name,spliceVariant FROM aip.LocusGeneModel WHERE tairObjectId = %d", $toid);
&print_rows("Gene_Model");

# This table contains links as HTML anchor tags
$SQL = sprintf ("SELECT tairObjectId,category,relationshipType,keyword,keywordLink FROM aip.LocusAnnotation WHERE tairObjectId = %d ORDER BY 2, 3, 4", $toid);
&print_rows("Annotation_Keywords");

# Does "single=T/F" mean single-gene?
$SQL = sprintf ("SELECT tairObjectId,arrayElementId,name,single,avgLogRatio,stdError,avgIntensity,avgIntensityStdError,avgSignalPercentile,avgSignalPercentileStdError,viewerData,externalId FROM aip.LocusArrayElement WHERE tairObjectId = %d AND single = 'F' ", $toid);
&print_rows("Locus_Array_Element_NotSingle");

# Does "single=T/F" mean single-gene?
$SQL = sprintf ("SELECT tairObjectId,arrayElementId,name,single,avgLogRatio,stdError,avgIntensity,avgIntensityStdError,avgSignalPercentile,avgSignalPercentileStdError,viewerData,externalId FROM aip.LocusArrayElement WHERE tairObjectId = %d AND single = 'T' ", $toid);
&print_rows("Locus_Array_Element_IsSingle");

# This table contains partial URLs
$SQL = sprintf ("SELECT tairObjectId,transcriptType,searchLink,transcriptCount FROM aip.LocusTranscriptCount WHERE LocusTranscriptCount.tairObjectId = %d", $toid);
&print_rows("Transcripts");

$SQL = sprintf ("SELECT tairObjectId,nucleotideSequenceId,sequenceName,sequenceLink FROM aip.LocusNucleotideSequence WHERE tairObjectId = %d", $toid);
&print_rows("Nucleotide_Sequence");

$SQL = sprintf ("SELECT tairObjectId,aaSequenceId,sequenceTairObjectId,name,length,molecularWeight,isoelectricPoint FROM aip.LocusProteinSequence WHERE tairObjectId = %d", $toid);
&print_rows("Protein_Sequence");

# The Locus Detail page gets one set of domains per protein sequence (first SQL).
# Here, we just get them all (second SQL).
$SQL = "SELECT aaSequenceId,tairObjectId,accession,interproLink,domainCount FROM aip.LocusProteinSequenceDomain WHERE aaSequenceId = %d AND tairObjectId = %d";
$SQL = sprintf ("SELECT aaSequenceId,tairObjectId,accession,interproLink,domainCount FROM aip.LocusProteinSequenceDomain WHERE tairObjectId = %d", $toid);
&print_rows("Protein_Domains");

$SQL = sprintf ("SELECT tairObjectId,globalAssignmentId,chromosome,mapId,mapName,mapType,mapElementType,length,units,orientation,startPosition,endPosition,annotations,attributions FROM aip.LocusGlobalAssignment WHERE tairObjectId = %d", $toid);
&print_rows("Global_Assignment");

# The Locus Detail page gets super assignment for each assignment (first SQL).
# Here, we just get all (second SQL).
$SQL = "SELECT globalAssignmentId,tairObjectId,localAssignmentId,chromosome,objectName,objectId,objectType,length,units,orientation,startPosition,endPosition FROM aip.LocusGlobalSuperAssignment WHERE globalAssignmentId = ? AND LocusGlobalSuperAssignment.tairObjectId = ?";
$SQL = sprintf ("SELECT globalAssignmentId,tairObjectId,localAssignmentId,chromosome,objectName,objectId,objectType,length,units,orientation,startPosition,endPosition FROM aip.LocusGlobalSuperAssignment WHERE LocusGlobalSuperAssignment.tairObjectId = %d", $toid);
&print_rows("Super_Assignment");

$SQL = sprintf ("SELECT tairObjectId,geneticMarkerId,markerTairObjectId,name,markerType,chromosome FROM aip.LocusMarker WHERE tairObjectId = %d", $toid);
&print_rows("Genetic_Marker");

# The Locus Detail page gets one set of global assignments per parmer (first SQL).
# Here, we just get all of them (second SQL).
$SQL = "SELECT geneticMarkerId,tairObjectId,globalAssignmentId,startPosition,endPosition,units,chromosome,mapName FROM aip.LocusMarkerGlobalAssignment WHERE geneticMarkerId = ? AND tairObjectId = ?";
$SQL = sprintf ("SELECT geneticMarkerId,tairObjectId,globalAssignmentId,startPosition,endPosition,units,chromosome,mapName FROM aip.LocusMarkerGlobalAssignment WHERE tairObjectId = %d", $toid);
&print_rows("Genetic_Marker_Assignment");

# The Locus Detail page gets one alias per marker ID (first SQL).
# Here, we just get all of them (second SQL).
$SQL = "SELECT geneticMarkerId,tairObjectId,alias FROM LocusMarkerAlias WHERE geneticMarkerId = ? AND tairObjectId = ?";
$SQL = sprintf ("SELECT geneticMarkerId,tairObjectId,alias FROM LocusMarkerAlias WHERE tairObjectId = %d", $toid);
&print_rows("Genetic_Marker_Alias");

# The sub-select is merely to limit the row count, obtained at the beginning.
$SQL = sprintf ("SELECT * FROM (SELECT tairObjectId,polymorphismId,name,polymorphismType,geneFeatureSite,NVL(alleleMode, 'unknown') AS alleleMode FROM aip.LocusPolymorphism WHERE tairObjectId = %d ORDER BY LOWER(name) ) WHERE rownum <= 20", $toid);
&print_rows("Polymorphism");

# The sub-select is merely to limit the row count, obtained at the beginning.
$SQL = sprintf ("SELECT * FROM (SELECT tairObjectId,germplasmTairObjectId,name,speciesVariantAbbrevName,polymorphismCount,stockCount,imageCount,phenotypeCount FROM aip.LocusGermplasm WHERE tairObjectId = %d ORDER BY phenotypeCount + imageCount + stockCount DESC,polymorphismCount DESC ) WHERE rownum <= 20", $toid);
&print_rows("Germplasm");

# The Locus Detail page gets one Germplasm Polymorphism per Germplasm object (first SQL).
# Here, we just get all of them (second SQL).
$SQL = "SELECT germplasmTairObjectId,tairObjectId,polymorphismId,name FROM aip.LocusGermplasmPolymorphism WHERE germplasmTairObjectId = ? AND tairObjectId = ? ORDER BY name";
$SQL = sprintf ("SELECT germplasmTairObjectId,tairObjectId,polymorphismId,name FROM aip.LocusGermplasmPolymorphism WHERE tairObjectId = ? ORDER BY name", $toid);
&print_rows("Germplasm_Polymorphism");

# The Locus Detail page gets one Stock Number per Germplasm object (first SQL).
# Here, we just get all of them (second SQL).
$SQL = "SELECT germplasmTairObjectId,tairObjectId,stockId,stockNumber,availabilityType FROM aip.LocusGermplasmStock WHERE germplasmTairObjectId = ? AND tairObjectId = ? ORDER BY stockNumber";
$SQL = sprintf ("SELECT germplasmTairObjectId,tairObjectId,stockId,stockNumber,availabilityType FROM aip.LocusGermplasmStock WHERE tairObjectId = ? ORDER BY stockNumber", $toid);
&print_rows("Stock_Number");

$SQL = sprintf ("SELECT tairObjectId,externalLinkId,COALESCE(urlVariable, 'NONE') AS urlVariable,webSiteName,baseUrl,name FROM aip.LocusExternalLink WHERE tairObjectId = %d ORDER BY UPPER(webSiteName), UPPER(name)", $toid);
&print_rows("External_Link");

$SQL = sprintf ("SELECT tairObjectId,notepadId,communityId,name,commentText,dateEntered FROM aip.LocusComment WHERE tairObjectId = %d ORDER BY dateEntered DESC", $toid);
&print_rows("Comment");

$SQL = sprintf ("SELECT tairObjectId,attributionId,attributionType,linkType,communityId,name,attributionDate FROM aip.LocusAttribution WHERE tairObjectId = %d", $toid);
&print_rows("Atrribution");

$SQL = sprintf ("SELECT tairObjectId,referenceId,name,authorName,communicationDate FROM aip.LocusCommunication WHERE tairObjectId = %d ORDER BY communicationDate", $toid);
&print_rows("Communication");

# The sub-select is merely to limit the row count, obtained at the beginning.
$SQL = sprintf ("SELECT * FROM (SELECT a.referenceId,a.title,a.pubSourceName,a.publicationYear,a.lociCount FROM aip.PublicationView a JOIN aip.LocusPublication b ON a.referenceId = b.referenceId WHERE b.tairObjectId = %d ORDER BY 4 DESC, 2) WHERE rownum <= 20", $toid);
&print_rows("Publication");

# The sub-select is merely to limit the row count, obtained at the beginning.
# The Locus Detail page gets references for each publication. We ignore this for now since Tair Object ID is not used.
$SQL = "SELECT * FROM (SELECT referenceId,name FROM aip.PublicationLocus WHERE referenceId = ? ORDER BY 2 ) WHERE rownum <= 20";

print STDERR "Done\n";
