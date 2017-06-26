package Sharepoint::Utils::Logger;

use strict;
use Carp;
use Term::ANSIColor;
use Log::Log4perl;

use constant TRUE => 1;
use constant FALSE => 0;

use constant NOTIFY_UNSPECIFIED_VALUES => FALSE;

use constant DEFAULT_OUTDIR => '/tmp';
use constant DEFAULT_LOGFILE_EXTENSION => 'log';

use constant DEBUG => 5;
use constant INFO  => 4;
use constant WARN  => 3;
use constant ERROR => 2;
use constant FATAL => 1;

use constant DEFAULT_LEVEL => INFO;

my $logLevelLookup = {};
my $logfile;
my $logLevel;
my $webMode = TRUE;

my $instance;

## Do not buffer output stream
$|=1;

=item new()

B<Description:> Instantiate Sharepoint::Utils::Logger object

B<Parameters:> 

 %args

B<Returns:> Returns a reference to Sharepoint::Utils::Logger

=cut

sub new  {

    my $class = shift;

    my $self = {};

    bless $self, $class;    

    return $self->_init(@_);

    return $self;
}

=item $self->_init(%args)

B<Description:> Typical Perl init() method

B<Parameters:> 

 %args

B<Returns:> None

=cut

sub _init {

    my $self = shift;
    my (%args) = @_;

    foreach my $key (keys %args ){
        $self->{"_$key"} = $args{$key};
    }
    
    if (( exists $self->{_web_mode}) && ( defined $self->{_web_mode}) && ($self->{_web_mode})){
        $webMode = TRUE;
    }

    $self->_setDefaultLogfile(@_);

    $self->_setDefaultLogLevel(@_);

    $self->_loadLogLevelLookup(@_);

    return $self->_initLog4perl(@_);
}
    
sub _initLog4perl {

    my $self = shift;

    if (( exists $self->{_log4perl_init_config_file}) && 
        ( defined $self->{_log4perl_init_config_file})){

        $self->_initConfigurationFromInitFile(@_);
    }
    else {
        $self->_initConfiguration(@_);
    }

    my $logger = Log::Log4perl->get_logger();
    if (!defined($logger)){
        confess "Could not instantiate Log::Log4perl";
    }

    $self->{_logger} = $logger;

    return $logger;
}

sub getLogger {

    my ($namespace) = @_;

    my $logger = Log::Log4perl->get_logger($namespace);
    if (!defined($logger)){
        confess "Could not instantiate Log::Log4perl";
    }

    return $logger;   
}

sub _initConfiguration {

    my $self = shift;

    my $conf = q(
    log4perl.logger                    = sub {return Sharepoint::Utils::Logger::_getLogLevel();}

    log4perl.appender.Logfile          = Log::Log4perl::Appender::File
    log4perl.appender.Logfile.filename = sub { return Sharepoint::Utils::Logger::_getLogfile(); }
    log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Logfile.layout.ConversionPattern = %p - [%r | %d | %H | %P] %F %L %m%n

    log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr  = 0
    log4perl.appender.Screen.layout = Log::Log4perl::Layout::SimpleLayout
  );

   
    Log::Log4perl::init(\$conf);
}

sub _getLogfile {

    return $logfile;
}

sub _getLogLevel {

    my $level = $logLevelLookup->{$logLevel};

    if ($webMode){
        return "$level, Logfile";
    }
    else {
        return "$level, Logfile, Screen";
    }
}

sub _loadLogLevelLookup {

    my $self = shift;

    $logLevelLookup =  { 5 => 'DEBUG',
                         4  => 'INFO',
                         3  => 'WARN',
                         2 => 'ERROR',
                         1 => 'FATAL'};
}

sub getInstance {
    
    if (!defined($instance)){

        $instance = new Sharepoint::Utils::Logger(@_);

        if (!defined($instance)){
            confess "Could not instantiate Sharepoint::Utils::Logger";
        }
    }

    return $instance;
}

=item DESTROY

B<Description:> Sharepoint::Utils::Logger class destructor

B<Parameters:> None

B<Returns:> None

=cut

sub DESTROY  {

    my $self = shift;
}


sub _setDefaultLogfile {

    my $self = shift;
    my (%args) = @_;

    if (( exists $args{logfile}) && ( defined $args{logfile})){

        $self->{_logfile} = $args{logfile};
    }
    elsif (( exists $self->{_logfile}) && ( defined $self->{_logfile})){

        ## okay - do nothing
    }
    else {
        my $logfile = $self->_getOutdir(@_) . '/' . File::Basename::basename($0) . '.' . $self->_getLogFileExt(@_);

        $self->{_logfile} = $logfile;
    }

    $logfile = $self->{_logfile};
}

sub _setDefaultLogLevel {

    my $self = shift;
    my (%args) = @_;

    if (( exists $args{log_level}) && ( defined $args{log_level})){

        $self->{_log_level} = $args{log_level};
    }
    elsif (( exists $self->{_log_level}) && ( defined $self->{_log_level})){

        ## okay - do nothing
    }
    else {

        $self->{_log_level} = DEFAULT_LEVEL;
    }

    $logLevel = $self->{_log_level};
}

sub _getOutdir {

    my $self = shift;
    my (%args) = @_;

    if (( exists $args{outdir}) && ( defined $args{outdir})){

        $self->{_outdir} = $args{outdir};
    }
    elsif (( exists $self->{_outdir}) && ( defined $self->{_outdir})){

        ## okay - do nothing
    }
    else {
        $self->{_outdir} = DEFAULT_OUTDIR;
    }

    if (!-e $self->{_outdir}){

	mkpath($self->{_outdir}) || confess "Could not create output directory '$self->{_outdir}'";
    }

    return $self->{_outdir};
}

sub _getLogFileExt {

    my $self = shift;
    my (%args) = @_;

    if (( exists $args{log_file_ext}) && ( defined $args{log_file_ext})){

	$self->{_log_file_ext} = $args{log_file_ext};
    }
    elsif (( exists $self->{_log_file_ext}) && ( defined $self->{_log_file_ext})){

	## okay - do nothing
    }
    else {
	$self->{_log_file_ext} = DEFAULT_LOGFILE_EXTENSION;
    }

    return $self->{_log_file_ext};
}

sub _isLevelValid {

    my $self = shift;
    my ($level) = @_;

    if (!defined($level)){
        return FALSE;
    }
    
    if (($level == DEBUG) || ($level == INFO) || ($level == WARN) || ($level == ERROR) || ($level == FATAL)){
	return TRUE;
    }

    return FALSE;
}


1==1; ## end of module

__END__

=head1 NAME

 Sharepoint::Utils::Logger
 A logger for this project.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use Sharepoint::Utils::Logger;
 my $obj = Sharepoint::Utils::Logger::getInstance();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

 new
 _init
 DESTROY

=over 4

=cut
