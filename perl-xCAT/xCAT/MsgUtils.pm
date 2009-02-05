#!/usr/bin/perl
# IBM(c) 2007 EPL license http://www.eclipse.org/legal/epl-v10.html

package xCAT::MsgUtils;

use strict;
use Sys::Syslog qw (:DEFAULT setlogsock);

#use locale;
use Socket;
use File::Path;

$::NOK = -1;
$::OK  = 0;

#--------------------------------------------------------------------------------

=head1    xCAT::MsgUtils


=head2    Package Description


This program module file, supports the xcat messaging and logging



=cut

#--------------------------------------------------------------------------------

=head2    Package Dependancies

    use strict;
    use Fcntl qw(:flock);
    use File::Basename;
    use File::Find;
    use File::Path;    # Provides mkpath()


=cut

#--------------------------------------------------------------------------------

=head1    Subroutines

=cut

=head3    message

    Display a msg  STDOUT,STDERR,log a msg and/or return to callback function.

    Arguments:
        The arguments of the message() function are:


			If address of the callback is provided,
			then the message will be returned either
			as data to the client's callback routine or to the
			xcat daemon or Client.pm ( bypass) for display/logging.
			See flags below.

			If address of the callback is not provide, then
			the message will be displayed to STDERR or STDOUT or
			added to SYSLOG.  See flags below.
    
        	If logging (L) is requested, the message structure 
			must be a simple string. The routine will convert 
			it to the appropriate callback structure, if a callback 
        	is provided.
	        Note for logging xCAT:MsgUtils->start_logging and
	        xCAT:MstUtils->stop_logging must be used to 
			open and close the log.

			For compatibility with existing code, the message routine will
			move the data into the appropriate callback structure, if required.
			See example below, if the input to the message routine
			has the "data" structure  filled in for an error message, then
			the message routine will move the $rsp->{data}->[0] to
			$rsp->{error}->[0]. This will allow xcatd/Client.pm will process
			all but "data" messages.

			The current client code should not have to change.

		      my %rsp;
		         $rsp->{data}->[0] = "Job did not run. \n";
	             xCAT::MsgUtils->message("E", $rsp, $::CALLBACK);

               Here the message routine will move $rsp->{data}->[0] to
			   $rsp->{error}->[0], to match the "E"message code.
			   Note the message
			   routine will only check for the data to either exist in
			   $rsp->{error}->[0] already, or to exist in $rsp->{data}->[0].

            Here's the meaning of the 1st character, if a callback specified:

                D - DATA this is returned to the client callback routine
                N - Node Data this is returned to the client callback routine
                E - error this is displayed/logged by daemon/Client.pm.
                I - informational this is displayed/logged by daemon/Client.pm.
                S - Message will be logged to syslog ( severe error)
					 syslog  facily (local4) and priority (err) will be used.
					 See /etc/syslog.conf file for the destination of the
					 messages.
                     Note S can be combined with other flags for example
					 SE logs message to syslog to also display the
					 message by daemon/ Client.pm.
                V - verbose.  This flag is not valid, the calling routine
				should check for verbose mode before calling the message
				routine and only use the I flag for the message.
				If V flag is detected, it will be changed to an I flag.
                W - warning this is displayed/logged by daemon/Client.pm.
                L - Log error to xCAT Log on the local machine. 
					Routine must have setup log by calling
					MsgUtils->start_log routine which returns 
					$::LOG_FILE_HANDLE.  Log is closed with
					MsgUtils->stop_log routine. Note can be combined with
					other flags:
                    LS - Log to xCAT Log and Syslog  
                    LSE/LSI - Log to xCAT Log and Syslog  and display
					if this option is used the message must be a simple
					string. The message routine will format for callback
					based on the (D,E,I,W) flag. 
 

            Here's the meaning of the 1st character, if no callback specified:

                D - DATA  goes to STDOUT
                E - error.  This type of message will be sent to STDERR.
                I - informational  goes to STDOUT
                N - Node informational  goes to STDOUT
                S - Message will be logged to syslog ( severe error)
                     Note S can be combined with other flags for example
					 SE logs message to syslog and is sent to STDERR.
                V - verbose.  This flag is not valid, the calling routine
				should check for verbose mode before calling the message

				routine and only use the I flag for the message.
				If V flag is detected, it will be changed to an I flag.
                W - warning goes to STDOUT.
                L - log  goes to /var/log/xcat/<logname>
				   ( see MsgUtils->start_log)
					Routine must have setup log by calling
					MsgUtils->start_log routine which returns
					$::LOG_FILE_HANDLE.  Log is closed with
					MsgUtils->stop_log routine. Note can be combined with
					other flags:
                    LS - Log to xCAT Log and Syslog  
                    LSE/LSI - Log to xCAT Log and Syslog  and display

    Returns:
        none

    Error:
        none

    Example:

    Use with no callback
		# Message to STDOUT
        xCAT::MsgUtils->message('I', "Operation $value1 succeeded\n");
        xCAT::MsgUtils->message('N', "Node:$node failed\n");
		# Message to STDERR
        xCAT::MsgUtils->message('E', "Operation $value1 failed\n");
        # Message to Syslog 
        xCAT::MsgUtils->message('S', "Host $host not responding\n");
        # Message to Log and Syslog 
        xCAT::MsgUtils->message('LS', "Host $host not responding\n");
        # Message to Log 
        xCAT::MsgUtils->message('L', "Host $host not responding\n");

    Use with callback
        # Message to callback
      my $rsp = {};
		$rsp->{data}->[0] = "Job did not run. \n";
	    xCAT::MsgUtils->message("D", $rsp, $::CALLBACK);

      my $rsp = {};
		$rsp->{error}->[0] = "No hosts in node list\n";
	    xCAT::MsgUtils->message("E", $rsp, $::CALLBACK);

      my $rsp = {};
     $rsp->{node}->[0]->{name}->[0] ="mynode";
     $rsp->{node}->[0]->{data}->[0] ="mydata";
     xCAT::MsgUtils->message("N", $rsp, $callback);



      my $rsp = {};
		$rsp->{info}->[0] = "No hosts in node list\n";
	    xCAT::MsgUtils->message("I", $rsp, $::CALLBACK);


      my $rsp = {};
		$rsp->{warning}->[0] = "No hosts in node list\n";
	    xCAT::MsgUtils->message("W", $rsp, $::CALLBACK);

      my $rsp = {};
		$rsp->{error}->[0] = "Host not responding\n";
	    xCAT::MsgUtils->message("S", $rsp, $::CALLBACK);


        # Message to Syslog and callback
      my $rsp = {};
		$rsp->{error}->[0] = "Host not responding\n";
	    xCAT::MsgUtils->message("SE", $rsp, $::CALLBACK);

        # Message to Syslog and callback
      my $rsp = {};
		$rsp->{info}->[0] = "Host not responding\n";
	    xCAT::MsgUtils->message("SI", $rsp, $::CALLBACK);

        # Message to Log, Syslog and callback
		my $msg;
		$msg = "Host not responding\n";
	    xCAT::MsgUtils->message("LSI", $msg, $::CALLBACK);

        # Message to Log and callback
		my $msg;
		$msg = "Host not responding\n";
	    xCAT::MsgUtils->message("LI", $msg, $::CALLBACK);





    Comments:


    Returns:
       1 for internal error ( invalid input to the routine) 



=cut

#--------------------------------------------------------------------------------

sub message
{

    # Process the arguments
    shift;    # get rid of the class name
    my $sev       = shift;
    my $rsp       = shift;
    my $call_back = shift;    # optional
    my $exitcode  = shift;    # optional

    # should be I, D, E, S, W , L,N
    #  or S(I, D, E, S, W, L,N)

    my $stdouterrf = \*STDOUT;
    my $stdouterrd = '';
    if ($sev =~ /[E]/)
    {
        $stdouterrf = \*STDERR;
        $stdouterrd = '1>&2';
    }

    # check for logging
    my $logging = 0;
    if ($sev =~ /[L]/)
    {

        # no log opened, we have an error
        if (!defined($::LOG_FILE_HANDLE))
        {
            if ($call_back)
            {

                # build callback structure
                my $newrsp;
                my $sevkey = 'error';
                my $err =
                  "Logging requested without setting up log by calling xCAT:MsgUtils->start_logging.\n";
                push @{$newrsp->{$sevkey}}, $err;
                push @{$newrsp->{errorcode}}, "1";
                $call_back->($newrsp);    # send message to daemon/Client.pm
                return 1;
            }
            else
            {
                print
                  "Logging requested without setting up log by calling xCAT:MsgUtils->start_logging.\n";
                return 1;
            }
        }

        else
        {

            $logging = 1;

        }
    }

    if ($sev eq 'V')
    {    # verbose should have been handled in calling routine
        $sev = "I";
    }
    if ($sev eq 'SV')
    {    # verbose should have been handled in calling routine
        $sev = "SI";
    }

    # Check that correct structure is filled in. If the data is not in the
    # structure corresponding to the $sev,  then look for it in "data"
    #TODO: this is not really right for a few reasons:  1) all the fields in the
    #		response structure are arrays, so can handle multiple lines of text.  We
    #		should not just be check the 0th element.  2) a cmd may have both error
    #		text and data text.  3) this message() function should just take in a plain
    #		string and put it in the correct place based on the severity.

    #
    # if a callback routine is provided
    #
    if ($call_back)
    {    # callback routine provided
        my $sevkey;
        if    ($sev =~ /D/) { $sevkey = 'data'; }
        elsif ($sev =~ /N/) { $sevkey = 'node'; }
        elsif ($sev =~ /I/) { $sevkey = 'info'; }
        elsif ($sev =~ /W/) { $sevkey = 'warning'; }
        elsif ($sev =~ /E/)
        {
            $sevkey = 'error';
            if (!defined($exitcode))
            {
                $exitcode = 1;
            }    # default to something non-zero
        }
        else
        {

            # build callback structure
            my $newrsp;
            my $sevkey = 'error';
            my $err =
              "Invalid or no severity code passed to MsgUtils::message().\n";
            push @{$newrsp->{$sevkey}}, $err;
            push @{$newrsp->{errorcode}}, "1";
            $call_back->($newrsp);    # send message to daemon/Client.pm
            return 1;
        }

        # check if logging to xCAT log, must be handled
        # separately because message data is a simple string
        #
        if (!$logging)
        {
            if ($sevkey ne 'data')
            {
                if (!defined($rsp->{$sevkey}) || !scalar(@{$rsp->{$sevkey}}))
                {    # did not pass the text in in the severity-specific field
                        # so fix it
                    if (defined($rsp->{data}) && scalar(@{$rsp->{data}}))
                    {
                        push @{$rsp->{$sevkey}}, @{$rsp->{data}};

                        # assume they passed
                        # in the text in the data field instead
                        @{$rsp->{data}} = ();    # clear out the data field
                    }
                }
            }

            # if still nothing in the array, there is nothing to print out
            if (!defined($rsp->{$sevkey}) || !scalar(@{$rsp->{$sevkey}}))
            {
                return;
            }

            if ($exitcode)
            {
                push @{$rsp->{errorcode}}, $exitcode;
            }
            $call_back->($rsp);    # send message to daemon/Client.pm
            @{$rsp->{$sevkey}} =
              ();    # clear out the rsp structure in case they use it again
            @{$rsp->{data}}      = ();
            @{$rsp->{errorcode}} = ();
        }
        else         # logging
        {

            # write to log
            print $::LOG_FILE_HANDLE $rsp;

            # build callback structure
            my $newrsp;
            push @{$newrsp->{$sevkey}}, $rsp;
            if ($exitcode)
            {
                push @{$newrsp->{errorcode}}, $exitcode;
            }
            $call_back->($newrsp);    # send message to daemon/Client.pm

        }
    }

    else                              # no callback provided
    {
        if ($logging)
        {                             # print to local xcat log
            print $::LOG_FILE_HANDLE $rsp;
        }
        else
        {                             # print to stdout

            print $stdouterrf $rsp;    # print the message
        }
    }

    # is syslog requested
    if ($sev =~ /S/)
    {

        # If they want this msg to also go to syslog, do that now
        eval {
            openlog("xCAT", '', 'local4');
            setlogsock(["tcp", "unix", "stream"]);
            syslog("err", $rsp);
            closelog();
        };
        my $errstr = $@;
        if ($errstr)
        {
            print $stdouterrf
              "Unable to log $rsp to syslog because of $errstr\n";
        }
    }
    return;
}

#--------------------------------------------------------------------------------

=head2    xCAT Logging Routines
		  To use xCAT Logging follow the following sample

	      my $rc=xCAT::MsgUtils->start_logging("mylogname"); # create/open log
						 .
						 .
						 .
            # Message to Log and callback
	     	my $msg;
		    $msg = "Host not responding\n";
	        xCAT::MsgUtils->message("LI", $msg, $::CALLBACK);
						 .
						 .
            # Message to Log
	     	my $msg;
		    $msg = "Host not responding\n";
	        xCAT::MsgUtils->message("L", $msg);
						 .
						  
	      my $rc=xCAT::MsgUtils->stop_logging(); # close log
			 	
                
=cut

#--------------------------------------------------------------------------------

=head3 start_logging

        Start logging messages to a logfile. Return the log file handle so it
        can be used for updates and to close the file when done logging 
		using stop_logging.

        Arguments:
                $logfilename ( just name, path is by default /var/log/xcat)
        Returns:
                $::LOG_FILE_HANDLE
        Globals:
                $::LOG_FILE_HANDLE
        Error:
                $::NOK
        Example:
                xCAT:Utils->start_logging("logname");

=cut

#--------------------------------------------------------------------------------

sub start_logging
{
    my ($class, $logfilename) = @_;
    my ($cmd, $rc);
    my $xCATLogDir = "/var/log/xcat/";

    my $logfile = $xCATLogDir;
    $logfile .= $logfilename;
    xCAT::MsgUtils->backup_logfile($logfile);

    # create the log directory if it's not already there
    if (!-d $xCATLogDir)
    {
        $cmd = "mkdir -m 644 -p $xCATLogDir";
        $rc  = system("$cmd");
        if ($rc >> 8)
        {
            xCAT::MsgUtils->message('SE', "Error running $cmd.\n");
            return ($::NOK);
        }
    }

    # open the log file
    unless (open(LOGFILE, ">>$logfile"))
    {

        # Cannot open file
        xCAT::MsgUtils->message('SE', "Error opening $logfile.\n");
        return ($::NOK);
    }

    $::LOG_FILE_HANDLE = \*LOGFILE;
    $::LOG_FILE_NAME   = $logfile;

    # Print the program name and date to the top of the logfile
    my $sdate = `/bin/date`;
    chomp $sdate;
    my $program = $0;
    xCAT::MsgUtils->message('L', "$program:logging started $sdate.\n");

    return ($::LOG_FILE_HANDLE);
}

#--------------------------------------------------------------------------------

=head3 stop_logging

        Turn off message logging. Routine expects to have a file handle
        passed in via the global $::LOG_FILE_HANDLE.

        Arguments:

        Returns:
                $::OK
        Globals:
                $::LOG_FILE_HANDLE
        Error:
                none
        Example:
                MsgUtils->stop_logging();
        Comments:
                closes the logfile and undefines $::LOG_FILE_HANDLE
                even on error.

=cut

#--------------------------------------------------------------------------------

sub stop_logging
{
    my ($class) = @_;
    if (defined($::LOG_FILE_HANDLE))
    {

        # Print the date at the bottom of the logfile
        my $sdate = `/bin/date`;
        chomp $sdate;
        my $program = $0;
        xCAT::MsgUtils->message('L', "$program:logging stopped $sdate.\n");

        close($::LOG_FILE_HANDLE);
        undef $::LOG_FILE_HANDLE;
    }
    return $::OK;
}

#--------------------------------------------------------------------------------

=head3    backup_logfile

        Backup the current logfile. Move logfile to logfile.1. 
		Shift all other logfiles
        (logfile.[1-3]) up one number. The original logfile.4 is removed as in a FIFO.   

        Arguments:
                $logfile ( full path)
        Returns:
                $::OK
        Error:
                undefined
        Example:
                xCAT::MsgUtils->backup_logfile($logfile);

=cut

#--------------------------------------------------------------------------------

sub backup_logfile
{
    my ($class, $logfile) = @_;

    my ($logfile1) = $logfile . ".1";
    my ($logfile2) = $logfile . ".2";
    my ($logfile3) = $logfile . ".3";
    my ($logfile4) = $logfile . ".4";

    if (-f $logfile)
    {
        rename($logfile3, $logfile4) if (-f $logfile3);
        rename($logfile2, $logfile3) if (-f $logfile2);
        rename($logfile1, $logfile2) if (-f $logfile1);
        rename($logfile,  $logfile1);
    }
    return $::OK;
}

1;

