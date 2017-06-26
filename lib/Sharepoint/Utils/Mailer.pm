package DevelopmentUtils::Mailer;

use Moose;
use Mail::Mailer;
use Sys::Hostname;
use File::Spec;
use File::Basename;

use DevelopmentUtils::Logger;

use constant TRUE => 1;
use constant FALSE => 0;

use constant DEFAULT_TO_EMAIL_ADDRESS   => '';
use constant DEFAULT_FROM_EMAIL_ADDRESS => '';
use constant DEFAULT_SUBJECT            => File::Basename::basename($0);
use constant DEFAULT_MESSAGE            => File::Spec->rel2abs($0) . " executed on server " . hostname() . " on date " . localtime() . "\n";

use constant DEFAULT_MAIL_HOST => 'mail.some.com';
use constant DEFAULT_TIMEOUT => 60;
use constant DEFAULT_AUTHUSER => '';

## Singleton support
my $instance;

has 'to_email' => (
    is     => 'rw',
    isa    => 'Str',
    writer => 'setToEmail',
    reader => 'getToEmail'
    );

has 'from_email' => (
    is     => 'rw',
    isa    => 'Str',
    writer => 'setFromEmail',
    reader => 'getFromEmail'
    );

has 'message' => (
    is     => 'rw',
    isa    => 'Str',
    writer => 'setMessage',
    reader => 'getMessage'
    );

has 'subject' => (
    is     => 'rw',
    isa    => 'Str',
    writer => 'setSubject',
    reader => 'getSubject'
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Mailer(@_);

        if (!defined($instance)){
        
            confess "Could not instantiate DevelopmentUtils::Mailer";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);
}

sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);
    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}

sub sendNotification {

    my $self = shift;

    return $self->createAndSendEmailUsingMailer(@_);
}

sub createAndSendEmailUsingMailer {

    my $self = shift;

    my $fromEmail = $self->getFromEmail();

    my $toEmail = $self->getToEmail();

    my $subject = $self->getSubject();

    my $messageBody = $self->getMessage();


    my $mailer = Mail::Mailer->new('sendmail');
    if (!defined($mailer)){
        $self->{_logger}->logconfess("Could not instantiate Mail::Mailer");
    }

    $mailer->open({To      => $toEmail,
                   From    => $fromEmail,
                   Subject => $subject,
                  });
    
    print $mailer $messageBody;

    $mailer->close() || $self->{_logger}->logconfess("Couldn't send whole message: $!");

    $self->{_logger}->info("Sent email to '$toEmail' from '$fromEmail' with subject '$subject'");
}

# sub createAndSendEmail {

#     my $self = shift;


#     my $fromEmailAddress = $self->_getFromEmailAddress(@_);

#     my $toEmailAddress = $self->_getToEmailAddress(@_);

#     my $mailHost = $self->_getMailHost(@_);

#     my $subject = $self->_getSubject(@_);

#     my $messageBody = $self->_getMessageBody(@_);

#     if ($self->_hasResultsPageURL(@_)){
# 	$messageBody .= "\nYour results are available here:\n" . $self->_getResultsPageURL(@_);
#     }

#     my $authuser = $self->_getAuthuser(@_);

#     my $timeout = $self->_getTimeOut(@_);

#     my $file = $self->_getFile(@_);

#     my $msg = MIME::Lite->new (
# 	From    => $fromEmailAddress,
# 	To      => $toEmailAddress,
# 	Subject => $subject,
# 	Type    =>'multipart/mixed'
# 	) or $self->{_logger}->logconfess("Error creating multipart container: $!");
    

#     $self->{_logger}->info("Created MIME::Lite object");

#     ### Add the text message part
#     $msg->attach (
# 	Type => 'TEXT',
# 	Data => $messageBody
# 	) or $self->{_logger}->logconfess("Error adding the text message part: $!");

#     $self->{_logger}->info("Attached body message");


#     my $basename = File::Basename::basename($file);

#     $self->{_logger}->info("Will attach the file '$file'");

#     ### Add the ZIP file
#     $msg->attach (
# 	Type => 'application/zip',
# 	Path => $file,
# 	Filename => $basename,
# 	Disposition => 'attachment'
# 	) or $self->{_logger}->logconfess("Error adding $file: $!");

#     $self->{_logger}->info("File has been attached - going to call MIME::Lite::send method");

#     ### Send the Message

#     MIME::Lite->send('sendmail', $mailHost, Time=>$timeout, AuthUser=>$authuser);

#     $msg->send;

#     $self->{_logger}->info("Email attachment sent '$toEmailAddress'");

#     $self->{_sent_email_notification_with_attachment} = TRUE;

# }


no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 DevelopmentUtils::Mailer
 A module for sending notification emails.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Mailer;
 my $mailer = DevelopmentUtils::Mailer::getInstance(@_);
 $mailer->sendNotification();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut