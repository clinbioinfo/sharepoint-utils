package Sharepoint::Utils::File::JSON::Writer;

use Moose;
use Carp;
use JSON;

use Sharepoint::Utils::Config::Manager;

use constant TRUE  => 1;

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

        $instance = new Sharepoint::Utils::File::JSON::Writer(@_);

        if (!defined($instance)){

            confess "Could not instantiate Sharepoint::Utils::File::JSON::Writer";
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

    my $count = scalar(@{$record_list});

    my $json_string = encode_json($record_list);


    my $outfile = $self->getOutfile();
    
    if (!defined($outfile)){

        my $outdir = $self->getOutdir();

        $outfile = $outdir . '/' . File::Basename::basename($0) . '.json';

        $self->{_logger}->info("outfile was not defined and therefore was set to '$outfile'");
    }

    open (OUTFILE, ">$outfile") || $self->{_logger}->logconfess("Could not open '$outfile' in write mode : $!");
    
    print OUTFILE $json_string;

    close OUTFILE;

    print "Wrote '$count' records to output file '$outfile'\n";  
}




no Moose;
__PACKAGE__->meta->make_immutable;


__END__


=head1 NAME

 Sharepoint::Utils::File::JSON::Writer

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use Sharepoint::Utils::File::JSON::Writer;

 my $writer = Sharepoint::Utils::File::JSON::Writer(
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