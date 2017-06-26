package Sharepoint::Utils::Report::File::Text::Writer;

use Moose;
use Data::Dumper;
use Carp;
use Try::Tiny;

use Sharepoint::Utils::Config::Manager;

use constant TRUE => 1;
use constant FALSE => 0;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();


has 'outdir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutdir',
    reader   => 'getOutdir',
    required => FALSE,
    default  => DEFAULT_OUTDIR
    );

has 'outfile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutfile',
    reader   => 'getOutfile',
    required => FALSE,
    );

has 'column_name_list' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    writer   => 'setColumnNameList',
    reader   => 'getColumnNameList',
    required => FALSE,
    );


## Singleton support
my $instance;

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

}


sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);

    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}

sub _initConfigManager {

    my $self = shift;

    my $manager = Sharepoint::Utils::Config::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate Sharepoint::Utils::Config::Manager");
    }

    $self->{_config_manager} = $manager;
}

sub getInstance {

    if (!defined($instance)){

        $instance = new Sharepoint::Utils::Report::File::Text::Writer(@_);

        if (!defined($instance)){

            confess "Could not instantiate Sharepoint::Utils::Report::File::Text::Writer";
        }
    }

    return $instance;
}

sub writeFile {

    my $self = shift;

     my ($record_list) = @_;

    if (!defined($record_list)){
        $self->{_logger}->logconfess("record_list was not defined");
    }

     my $outfile = $self->getOutfile();
    
    if (!defined($outfile)){

        my $outdir = $self->getOutdir();

        $outfile = $outdir . '/' . File::Basename::basename($0) . '.txt';

        $self->{_logger}->info("outfile was not defined and therefore was set to '$outfile'");
    }

    open (OUTFILE, ">$outfile") || $self->{_logger}->logconfess("Could not open '$outfile' in write mode : $!");
 

    my $ctr = 0;

    my $column_name_list = $self->getColumnNameList();
    if (!defined($column_name_list)){
        $self->{_logger}->logconfess("column_name_list was not defined");
    }

    foreach my $record (@{$record_list}){

        print Dumper $record;

        $ctr++;

        if ($ctr == 1){
            $self->_writeHeader();
        }

        my $list = [];

        foreach my $column_name (@{$column_name_list}){

            if (exists $record->{$column_name}){

                my $val = $record->{$column_name};

                if ($column_name eq 'Contact'){

                    print Dumper $val;
                    try {

                        if (defined($val)){
                            if (($val ne '') || (scalar(@{$val}) > 0)){
                        
                                $val = $self->_derive_contact_name($val);
                            }
                        }
                    } catch {
                        $self->{_logger}->warn("Could not process contact info for record :" . Dumper $record);
                        $val = 'N/A';
                    };
                }

                push(@{$list}, $val);
            }
            else {
                $self->{_logger}->logconfess("column_name '$column_name' does not exist in record : " . Dumper $record);
            }
        }

        print OUTFILE join("\t", @{$list}) . "\n";
    }

    close OUTFILE;

    print "Wrote '$ctr' records to output file '$outfile'\n";  
}

sub _writeHeader {

    my $self = shift;

    my $column_name_list = $self->getColumnNameList();
    if (!defined($column_name_list)){
        $self->{_logger}->logconfess("column_name_list was not defined");
    }

    print OUTFILE join("\t", @{$column_name_list}) . "\n";
}

sub _derive_contact_name {

    my $self = shift;
    my ($contact_list) = @_;

    print Dumper $contact_list;

    my $final_contact_list = [];

    foreach my $contact_lookup (@{$contact_list}){
        
        if (exists $contact_lookup->{value}){
        
            my $last_name_first_name = $contact_lookup->{value};
        
            push(@{$final_contact_list}, $last_name_first_name);
        }
        else {
            $self->{_logger}->logconfess("key value does not exist in contact : " . Dumper $contact_lookup);
        }
    }

    my $val = join("; ", @{$final_contact_list});

    return $val;
}

no Moose;
__PACKAGE__->meta->make_immutable;


__END__


=head1 NAME

 Sharepoint::Utils::Report::File::Text::Writer

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use Sharepoint::Utils::Report::File::Text::Writer;

 my $writer = Sharepoint::Utils::Report::File::Text::Writer(
   outdir      => $outdir,
   record_list => $record_list,
   outfile     => $outfile
 );

 $writer->writeFile();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

 new
 _init
 DESTROY

=over 4

=cut