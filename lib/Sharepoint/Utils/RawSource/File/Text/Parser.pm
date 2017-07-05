package Sharepoint::Utils::RawSource::File::Text::Parser;

use Moose;
use Term::ANSIColor;
use Data::Dumper;
use Carp;
use File::Slurp;
use JSON::Parse 'parse_json';

use constant TRUE => 1;
use constant FALSE => 0;

my @qualified_keys_list = (
    "ID",
    "Title",
    "Status",
    "Initiative_x0020__x002d__x0020_b",
    "Initiative",
    "Priority_x0020_From_x0020_TA_x00",
    "Who_x0020_requested_x0020_it_x00",
    "Estimated_x0020_time_x0020_requi",
    "Who_x0027_s_x0020_responsible_x0",
    "Notes",
    "Expected_x0020_delivery_x0020_da",
    "Contact_x0020_name"
    );

my @known_keys_list = (
    "ID", 
    "PermMask",
    "FSObjType",
    "LinkTitle",
    "Title", 
    "LinkTitleNoMenu", 
    "LinkFilenameNoMenu",
    "FileLeafRef",
    "Created_x0020_Date.ifnew",
    "FileRef",
    "File_x0020_Type",
    "File_x0020_Type.mapapp",
    "HTML_x0020_File_x0020_Type.File_x0020_Type.mapcon",
    "HTML_x0020_File_x0020_Type.File_x0020_Type.mapico",
    "HTML_x0020_File_x0020_Type",
    "ContentTypeId",
    "_EditMenuTableStart2",
    "_EditMenuTableEnd",
    "Status",
    "Initiative_x0020__x002d__x0020_b",
    "Initiative",
    "TA_x0020__x002f__x0020_Fcn",
    "Priority_x0020_From_x0020_TA_x00",
    "Who_x0020_requested_x0020_it_x00",
    "Estimated_x0020_time_x0020_requi",
    "Who_x0027_s_x0020_responsible_x0",
    "Notes",
    "Expected_x0020_delivery_x0020_da",
    "Contact_x0020_name");

my @translation_keys_list = (
    "ID", 
    "PermMask", 
    "FSObjType", 
    "LinkTitle", 
    "Title", 
    "LinkTitleNoMenu", 
    "LinkFilenameNoMenu", 
    "FileLeafRef", 
    "Date_Created",
    "FileRef", 
    "File_x0020_Type",
    "File_x0020_Type.mapapp",
    "HTML_x0020_File_x0020_Type.File_x0020_Type.mapcon",
    "HTML_x0020_File_x0020_Type.File_x0020_Type.mapico",
    "HTML_x0020_File_x0020_Type",
    "ContentTypeId",
    "_EditMenuTableStart2",
    "_EditMenuTableEnd",
    "Status",
    "Initiative - business benefit",
    "Initiative",
    "TA/Function",
    "Priority Level According to TA",
    "Requestor",
    "Effort Estimate",
    "Assignee",
    "Notes",
    "Anticipated Delivery Date",
    "Contact");

my $translation_key_lookup = {};

has 'infile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setInfile',
    reader   => 'getInfile',
    required => FALSE,
    );


## Singleton support
my $instance;

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_load_qualified_keys(@_);

    $self->_load_known_keys(@_);


    $self->_parseFile(@_);

    $self->{_is_parsed} = FALSE;
}

sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);

    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}


sub getInstance {

    if (!defined($instance)){

        $instance = new Sharepoint::Utils::RawSource::File::Text::Parser(@_);

        if (!defined($instance)){

            confess "Could not instantiate Sharepoint::Utils::RawSource::File::Text::Parser";
        }
    }

    return $instance;
}

sub _load_qualified_keys {

    my $self = shift;

    my $ctr = 0;

    foreach my $key (@qualified_keys_list){
    
        $ctr++;

        $self->{_qualified_keys_lookup}->{$key}++;
    }

    print "Loaded '$ctr' qualified keys\n";
}

sub _load_known_keys {

    my $self = shift;

    my $ctr = 0;

    my $count = scalar(@known_keys_list);

    for (my $i = 0; $i < $count ; $i++){
    
        my $known_key = $known_keys_list[$i];
        my $translation_key = $translation_keys_list[$i];

        $ctr++;
    
        $self->{_known_keys_lookup}->{$known_key}++;

        $self->{_translation_key_lookup}->{$known_key} = $translation_key;
    }


    foreach my $qualified_key (@qualified_keys_list){

        if (exists $self->{_translation_key_lookup}->{$qualified_key}){
        
            my $translated_key = $self->{_translation_key_lookup}->{$qualified_key};
        
            push(@{$self->{_qualified_column_name_list}}, $translated_key);
        }
        else {
            $self->{_logger}->logconfess("'$qualified_key' does not exists in the translation key lookup");
        }
    }

    # print Dumper $self->{_translation_key_lookup};die;
    print "Loaded '$ctr' known keys\n";
}

sub getQualifiedColumnNameList {

    my $self = shift;

    return $self->{_qualified_column_name_list};
}

sub getRecordList {

    my $self = shift;

    if (! exists $self->{_record_list}){
        $self->_parseFile(@_);
    }

    return $self->{_record_list};
}


sub _parseFile {

    my $self = shift;

    my $infile = $self->getInfile();

    if (!defined($infile)){
        $self->{_logger}->logconfess("infile was not defined");
    }

    $self->_checkInfileStatus($infile);

    my $good_lines = [];

    my @lines = read_file($infile);

    my $line_ctr = 0;
    
    my $start_found = FALSE;
    
    my $end_found = FALSE;

    foreach my $line (@lines){

        chomp $line;

        $line_ctr++;

        if ($line =~ m|^\s*$|){
            next;
        }

        if ($line =~ m|^\#|){
            next;
        }

        if ($line =~ m|var WPQ1ListData = \{ \"Row\" \:|){
            $start_found = TRUE;
            next;
        }

        if ($line =~ m|\]\,\"FirstRow\" \: 1\,|){
            $end_found = TRUE;
            push(@{$good_lines}, ']');
            last;
        }

        if ($start_found){

            if ($line =~ m|^\[\{\s*$|){
                push(@{$good_lines}, $line);    
            }
            elsif ($line =~ m|^\}\s*$|){
                push(@{$good_lines}, $line);    
            }
            elsif ($line =~ m|^,\{\s*$|){
                push(@{$good_lines}, $line);    
            }
            elsif ($line =~ m|\"(.+)\"\:\s*|){

                push(@{$good_lines}, $line);            
            }
        }

        if ($end_found){
            last;
        }
    }

    print "Processed '$line_ctr' lines\n";

    $self->{_is_parsed} = TRUE;

    $self->_convert_to_json_records($good_lines);

    # print Dumper $self->{_record_list};die;

}

sub _convert_to_json_records {

    my $self = shift;
    my ($good_lines) = @_;

    my $content = join("\n", @{$good_lines});

    # print $content;;die;
    my $lookup = parse_json($content);

    $self->{_found_unknown_keys_lookup} = {};
    $self->{_found_unknown_keys_ctr} = 0;
    
    # print Dumper $lookup;die;

    foreach my $record (@{$lookup}){

        foreach my $key (keys %{$record}){
       
            if (! exists $self->{_known_keys_lookup}->{$key}){
                
                if (! exists $self->{_found_unknown_keys_lookup}->{$key}){
                    $self->{_found_unknown_keys_lookup}->{$key}++;
                    $self->{_found_unknown_keys_ctr}++;
                }
            }

            if (!exists $self->{_qualified_keys_lookup}->{$key}){
        
                delete $record->{$key};
            }
            else {
                if (exists $self->{_translation_key_lookup}->{$key}){

                    my $translation_key = $self->{_translation_key_lookup}->{$key};
                    my $val = $record->{$key};
                    delete $record->{$key};
                    $record->{$translation_key} = $val;
                }
                else {
                    $self->{_logger}->logconfess("key '$key' does not exist in the translation key lookup");
                }
            }
        }
    }

    $self->{_record_list} = $lookup;


    if ($self->{_found_unknown_keys_ctr} > 0){
        printBoldRed("Found the following '$self->{_found_unknown_keys_ctr}' unknown keys:");
        printBoldRed(join("\n", sort keys %{$self->{_found_unknown_keys_lookup}})) . "\n";
    }
}


sub _checkInfileStatus {

    my $self = shift;
    my ($infile) = @_;

    if (!defined($infile)){
        $self->{_logger}->logconfess("infile was not defined");
    }

    my $errorCtr = 0 ;

    if (!-e $infile){
        
        $self->{_logger}->error("input file '$infile' does not exist");
        
        $errorCtr++;
    }
    else {

        if (!-f $infile){
            
            $self->{_logger}->error("'$infile' is not a regular file");
            
            $errorCtr++;
        }

        if (!-r $infile){
            
            $self->{_logger}->error("input file '$infile' does not have read permissions");
            
            $errorCtr++;
        }
        
        if (!-s $infile){
            
            $self->{_logger}->error("input file '$infile' does not have any content");
            
            $errorCtr++;
        }
    }
     
    if ($errorCtr > 0){
        
        $self->{_logger}->logconfess("Encountered issues with input file '$infile'");        
    }
}

sub printGreen {

    my ($msg) = @_;
    print color 'green';
    print $msg . "\n";
    print color 'reset';
}

sub printYellow {

    my ($msg) = @_;
    print color 'yellow';
    print $msg . "\n";
    print color 'reset';
}

sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
}


no Moose;
__PACKAGE__->meta->make_immutable;


__END__


=head1 NAME

 Sharepoint::Utils::RawSource::File::Text::Parser

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use Sharepoint::Utils::RawSource::File::Text::Parser;

 my $parser = Sharepoint::Utils::RawSource::File::Text::Parser(infile => $infile);

 my $record_list = $parser->getRecordList();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

 new
 _init
 DESTROY


=over 4

=cut