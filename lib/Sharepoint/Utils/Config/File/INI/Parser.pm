package Sharepoint::Utils::Config::File::INI::Parser;

use Moose;
use Carp;
use Config::IniFiles;

use constant TRUE => 1;
use constant FALSE => 0;

has 'config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setConfigFile',
    reader   => 'getConfigFile',
    required => TRUE
    );


## Singleton support
my $instance;

sub BUILD {

    my $self = shift;

    $self->{_is_parsed} = FALSE;
}

sub getInstance {

    if (!defined($instance)){

        $instance = new Sharepoint::Utils::Config::File::INI::Parser(@_);

        if (!defined($instance)){

            confess "Could not instantiate Sharepoint::Utils::Config::File::INI::Parser";
        }
    }

    return $instance;
}

sub _isParsed {

    my $self = shift;

    return $self->{_is_parsed};
}

sub _getValue {

    my $self = shift;
    my ($section, $parameter) = @_;

    if (! $self->_isParsed(@_)){

        $self->_parseFile(@_);
    }

    my $value = $self->{_cfg}->val($section, $parameter);

    if ((defined($value)) && ($value ne '')){
        return $value;
    }
    else {
        return undef;
    }
}

sub _parseFile {

    my $self = shift;
    my $file = $self->_getConfigFile(@_);

    my $cfg = new Config::IniFiles(-file => $file);
    if (!defined($cfg)){
        confess "Could not instantiate Config::IniFiles";
    }

    $self->{_cfg} = $cfg;

    $self->{_is_parsed} = TRUE;
}

sub _getConfigFile {

    my $self = shift;
    my (%args) = @_;

    my $configFile = $self->getConfigFile();

    if (!defined($configFile)){

        if (( exists $args{_config_file})  && ( defined $args{_config_file})){
            $configFile = $args{_config_file};
        }
        elsif (( exists $self->{_config_file}) && ( defined $self->{_config_file})){
            $configFile = $self->{_config_file};
        }
        else {

            confess "config_file was not defined";
        }

        $self->setConfigFile($configFile);
    }

    return $configFile;
}

sub getAdminEmail {

    my $self = shift;

    return $self->_getValue('Email', 'admin_email');
}

sub getAdminEmailAddresses {

    my $self = shift;

    return $self->_getValue('Email', 'admin_email_addresses');
}

sub getOutdir {

    my $self = shift;

    return $self->_getValue('Output', 'directory');
}

sub getOutfile {

    my $self = shift;

    return $self->_getValue('Output', 'outfile');
}

sub getLogFile {

    my $self = shift;

    return $self->_getValue('Log4perl', 'logfile');
}

sub getLogLevel {

    my $self = shift;

    return $self->_getValue('Log4perl', 'log_level');
}


no Moose;
__PACKAGE__->meta->make_immutable;



__END__


=head1 NAME

 Sharepoint::Utils::Config::File::INI::Parser

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use Sharepoint::Utils::Config::File::INI::Parser;

 my $parser = Sharepoint::Utils::Config::File::INI::Parser(masterConfigFile=>$file);

 my $email = $parser->getAdminEmail();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

 new
 _init
 DESTROY


=over 4

=cut
