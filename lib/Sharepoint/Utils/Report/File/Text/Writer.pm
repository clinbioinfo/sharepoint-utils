package Sharepoint::Utils::Report::File::Text::Writer;

use Moose;
use Carp;

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