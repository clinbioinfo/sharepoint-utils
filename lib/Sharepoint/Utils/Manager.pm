package Sharepoint::Utils::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use File::Slurp;
use Term::ANSIColor;

use Sharepoint::Utils::Logger;
use Sharepoint::Utils::Config::Manager;
use Sharepoint::Utils::RawSource::File::Text::Parser;
use Sharepoint::Utils::Report::File::Text::Writer;
use Sharepoint::Utils::File::JSON::Writer;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();


## Singleton support
my $instance;

has 'test_mode' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setTestMode',
    reader   => 'getTestMode',
    required => FALSE,
    default  => DEFAULT_TEST_MODE
    );

has 'config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setConfigfile',
    reader   => 'getConfigfile',
    required => FALSE,
    );

has 'outdir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutdir',
    reader   => 'getOutdir',
    required => FALSE,
    default  => DEFAULT_OUTDIR
    );

has 'indir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setIndir',
    reader   => 'getIndir',
    required => FALSE
    );

has 'report_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setReportFile',
    reader   => 'getReportFile',
    required => FALSE
    );

has 'outfile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutfile',
    reader   => 'getOutfile',
    required => FALSE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new Sharepoint::Utils::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate Sharepoint::Utils::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->_initRawSourceFileParser(@_);

    $self->_initReportWriter(@_);

    $self->_initJSONWriter(@_);

    $self->{_logger}->info("Instantiated ". __PACKAGE__);
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

sub _initRawSourceFileParser {

    my $self = shift;

    my $parser = new Sharepoint::Utils::RawSource::File::Text::Parser(@_);
    if (!defined($parser)){
        $self->{_logger}->logconfess("Could not instantiate Sharepoint::Utils::RawSource::File::Text::Parser");
    }

    $self->{_parser} = $parser;
}

sub _initReportWriter {

    my $self = shift;

    my $writer = Sharepoint::Utils::Report::File::Text::Writer::getInstance(@_);
    if (!defined($writer)){
        $self->{_logger}->logconfess("Could not instantiate Sharepoint::Utils::Report::File::Text::Writer");
    }

 
    $self->{_report_writer} = $writer;
}

sub _initJSONWriter {

    my $self = shift;

    my $writer = Sharepoint::Utils::File::JSON::Writer::getInstance(@_);
    if (!defined($writer)){
        $self->{_logger}->logconfess("Could not instantiate Sharepoint::Utils::File::JSON::Writer");
    }
    
    $self->{_json_writer} = $writer;
}

sub generateReport {

    my $self = shift;

    my $record_list = $self->{_parser}->getRecordList();
    if (!defined($record_list)){
        $self->{_logger}->logconfess("record_list was not defined");
    }

    my $column_name_list = $self->{_parser}->getQualifiedColumnNameList();
    if (!defined($column_name_list)){
        $self->{_logger}->logconfess("column_name_list was not defined");
    }

    $self->{_report_writer}->setColumnNameList($column_name_list);
    
    $self->{_report_writer}->writeFile($record_list);

    $self->{_json_writer}->writeFile($record_list);

}

sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
}

sub printYellow {

    my ($msg) = @_;
    print color 'yellow';
    print $msg . "\n";
    print color 'reset';
}

sub printGreen {

    my ($msg) = @_;
    print color 'green';
    print $msg . "\n";
    print color 'reset';
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 Sharepoint::Utils::Manager
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use Sharepoint::Utils::Manager;
 my $manager = Sharepoint::Utils::Manager::getInstance(
    infile      => $infile,
    config_file => $config_file,
    outdir      => $outdir
 );
 $manager->generateReport();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut