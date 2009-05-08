#!/usr/bin/perl

# By Larry Clapp, vim@theclapp.org
# Copyright 2002
#
# Last updated: Sun Oct 02 08:11:54 EDT 2005 
#
# spawn() adapted from the function of the same name in Expect.pm.  Docs for
# IO::Pty leave a lot to be desired, esp. if you haven't fiddled with ttys
# before.
#
# $Header: /home/lmc/lisp/briefcase/VIlisp/devel/RCS/funnel.pl,v 1.4 2003/02/20 20:02:47 lmc Exp lmc $

# Adapted to run R from vim by Jakson Aquino (May 2009):
#   - Save PID of R's parent process in a file to kill it from within vim, if
#   necessary. 

use IO::Pty;                    # This appears to require 5.004
use Term::ReadLine;
use Getopt::Std;

use POSIX;                      # For setsid. 
use Fcntl;                      # For checking file handle settings.

$QUIT = "(ext:quit)\n";
$rparent_pid = 0;

sub catch_sig
{
    my $signame = shift;

    print "signal $signame caught; lisp_pid == $rparent_pid\n"
	if $debug > 1;
    kill( $signame, $rparent_pid );
}


sub spawn
{
    # spawn is passed command line args.
    my(@cmd) = @_;

    my( $tty, $name_of_tty );

    # Create the pty which we will use to pass process info.
    my($self) = new IO::Pty;

    $name_of_tty = $self->IO::Pty::ttyname();
    die "ERROR: Could not assign a pty" 
	unless $name_of_tty;
    $self->autoflush();

    $rparent_pid = fork();
    unless (defined( $rparent_pid )) {
	warn "Cannot fork: $!";
	return undef;
    }

    if ($rparent_pid > 0){
      open (RpidFile, ">$pipe_name.Rpid");
      print RpidFile "$rparent_pid\n";
      close (RpidFile);
    }

    unless ($rparent_pid) {
	# Child
	# Create a new 'session', lose controlling terminal.
	POSIX::setsid() 
	    or warn "Couldn't perform setsid. Strange behavior may result.\r\n  Problem: $!\r\n";
	$tty = $self->IO::Pty::slave(); # Create slave handle.

	# We have to close everything and then reopen ttyname after to get a
	# controlling terminal.
	close($self);
	close STDIN; close STDOUT;
	open(STDIN,"<&". $tty->fileno()) || die "ERROR: Couldn't reopen ". $name_of_tty ." for reading, $!\r\n";
	open(STDOUT,">&". $tty->fileno()) || die "ERROR: Couldn't reopen ". $name_of_tty ." for writing, $!\r\n";

	# put this here or we would never see those die's above...
	close STDERR;
	open(STDERR,">&". $tty->fileno()) || die "ERROR: Couldn't redirect STDERR, $!\r\n";

	exec (@cmd);
#	open(STDERR,">&2");
	die "ERROR: Cannot exec `@cmd': $!\n";
	# End Child.
    }

    # sleep 1/4 second; allow child to start
    # select( undef, undef, undef, 0.25 );

    $self->close_slave();
    return $self;
}



sub process_readline_data2
{
    print "got a line\n"
	if $debug > 1;
    $lineread2 = $_[ 0 ];
    $got_a_line2 = 1; 				# global

    &uninstall_handler();
}


sub last_partial
{
    my( $fragment ) = @_;
    $last_partial_line = $fragment eq '' ? undef : $fragment;
    if ($debug >= 3) {
	if ($last_partial_line) {
	    print "\nlast partial line is >$last_partial_line<\n";
	} else {
	    print "\nresetting last_partial_line\n";
	}
    }
    $told_readline = 0;
}


sub check_tty_data
{
    my( $tty_read, $rout, $n, $l );

    $tty_read = 0;

    # poll tty
    $n = select( $rout = $tty_rin, undef, undef, 0 );

    if ($n)
    {
	while ($n) {
	    # print ( "\nreading from spawned tty ...\n" );
	    $tty_read = sysread( $master, $l, $tty_block_size );
	    if ($tty_read)
	    {
		print "check_tty_data: $tty_read bytes read from tty\n"
		    if $debug >= 1;

		if ($stdin_data eq '')
		{
		    print "check_tty_data: no stdin data\n"
			if $debug >= 1;
		}
		else
		{
		    print "check_tty_data: stdin_data is >$stdin_data<\n",
		    "tty_data is >$l<\n"
			if $debug >= 1;

		    $stdin_data =~ s/[\r\n]+$//;
		    if ($l =~ /(\Q$stdin_data\E[\r\n]*)/)
		    {
			$match = $1;
			print "check_tty_data: Deleting >$match< from tty_data\n"
			    if $debug >= 1;
			$l =~ s/\Q$match\E//;

			$stdin_data = undef;
		    }
		    else
		    {
			print "tty data doesn't match stdin_data\n"
			    if $debug >= 1;
		    }
		}

		print $l;
		$tty_data = $l;

		if ($tty_data !~ /[\r\n]$/)
		{
		    $tty_data =~ /\n?([^\r\n]*)$/;
		    &last_partial( $1 );
		}
	    }
	    else
	    {
		$tty_open = 0;
		if (defined( $tty_read ))
		{
		    print "sysread of tty returned 0\n";
		}
		else
		{
		    if ($debug >= 1)
		    {
			print "sysread of tty returned undef\n";
			print "error code is $!\n";
		    }
		}
		last;
	    }
	    $n = select( $rout = $tty_rin, undef, undef, 0.1 );
	    if ($n) {
		print "check_tty_data: more input; looping\n"
		    if $debug >= 3;
	    }
	}
    }
    else
    {
	print "nothing read from tty\n"
	    if $debug >= 2;
    }

    return( $tty_read );
}


sub show_vec
{
    my( $name, $vec ) = @_;
    print "vec $name is ", scalar( reverse( split( //, unpack( "b*", $vec ) ) ) ), "\n";
}

	    
sub check_pipe_data
{
    my( $pipe_read, $rout, $eout, $n, $l );

    $pipe_read = 0;
    $l = '';

    # poll the outgoing tty; return if not empty
    my $wout;
    $n = select( undef, $wout = $tty_rin, $eout = $pipe_rin, 0 );
    if ($n == 0) {
	# sleep for a tenth of a second to try to let the other end catch up
	select( undef, undef, undef, 0.1 );
	return;
    }

    # poll fifo
    $n = select( $rout = $pipe_rin, undef, $eout = $pipe_rin, 0 );

    if ($n > 0)
    {
	if ($debug >= 3)
	{
	    &show_vec( "rout", $rout );
	    &show_vec( "eout", $eout );
	}

	print( "select returned $n; reading from pipe ...\n" )
	    if $debug >= 1;
	$pipe_read = sysread( PIPE, $l, $pipe_block_size );
	if (defined( $pipe_read ))
	{
	    if ($pipe_read)
	    {
		print "$pipe_read bytes read from pipe\n"
		    if $debug >= 1;

		if ($l =~ /^VIlisp_reload_interpreter$/)
		{
		    $l = $QUIT;
		    $reload_interpreter = 1;
		}
		print $master $l;
	    }
	    else
	    {
		print "sysread on pipe returned 0 -- EOF\n";
		print "\$! is $!\n";
		print $master $QUIT;
		$pipe_open = 0;
	    }
	}
	else
	{
	    print "sysread on pipe returned undef -- EOF??\n";
	    print "\$! is $!\n";
	    print $master $QUIT;
	    $pipe_open = 0;
	}
    }
    else
    {
	print "select returned $n; nothing read from pipe\n"
	    if $debug >= 2;
    }

    return( $pipe_read );
}


sub install_handler
{
    if (defined( $last_partial_line ))
    {
	print "*** Installing handler with prompt >$last_partial_line<\n",
	    "resetting last_partial_line\n"
	    if $debug >= 3;
	$rl->{already_prompted} = 1;
	$rl->callback_handler_install( $last_partial_line, \&process_readline_data2 );
	$handler_installed = 1;
	$told_readline = 1;
	$last_partial_line = undef;
    }
    else
    {
	print "*** Installing handler with no prompt\n"
	    if $debug >= 3;
	$rl->{already_prompted} = 0;
	$rl->callback_handler_install( '', \&process_readline_data2 );
	$handler_installed = 1;
	$told_readline = 0;
    }
}

sub uninstall_handler
{
    print "*** Uninstalling handler\n"
	if $debug >= 3;
    $rl->callback_handler_install( '', undef );
    $handler_installed = 0;
}


sub check_stdin_data
{
    my( $stdin_read, $rout, $n );

    $stdin_read = 0;

    if ($handler_installed)
    {
	if ($last_partial_line
	    && !$told_readline)
	{
	    print "*** Telling readline on new line; resetting prompt to ",
		"'$last_partial_line'\n"
		if $debug >= 3;
	    $told_readline = 1;
	    $rl->set_prompt( $last_partial_line );
	    $rl->on_new_line_with_prompt;
	    $last_partial_line = undef;
	}

	# poll stdin
	$n = select( $rout = $stdin_rin, undef, undef, 0 );

	if ($n)
	{
	    # process the character
	    $rl->callback_read_char();
	}
    }
    else
    {
	&install_handler();
    }

    # process the line *after* you process the character, if any
    if ($got_a_line2)
    {
	$got_a_line2 = 0;
	if (defined( $lineread2 ))
	{
	    # $lineread .= "\n";
	    print $master $lineread2, "\n";
	    $stdin_data = $lineread2;
	    $stdin_read = length( $stdin_data );

	    $lineread2 =~ s/[\r\n]+//;
	    if ($lineread2 ne '')
	    {
		print "Adding history >$lineread2<\n"
		    if $debug >= 2;
		$rl->AddHistory( $lineread2 );
		if ($debug >= 2)
		{
		    printf "where_history is %d\n", $rl->where_history;
		    foreach $f ($rl->GetHistory)
		    {
			printf( "History is %s ", $f );
		    }
		}
	    }
	}
	else
	{
	    print "\nEnd Of File on stdin: exiting\n";
	    $stdin_open = 0;
	    print $master $QUIT;
	}
    }

    return( $stdin_read );
}


select( STDERR ); $| = 1;
select( STDOUT ); $| = 1;

$got_a_line2 = 0;
$lineread2 = '';

$debug = 0;

# should be < 4096, at least on my system
$pipe_block_size = 1024;
$tty_block_size = 1024;

&getopt( 'D' );
$debug = $opt_D 	if $opt_D;

$pipe_name = shift @ARGV;

$rl = new Term::ReadLine 'funnel';
$rl->initialize();
$rl->prep_terminal( 0 );
$rl->using_history();

if ($debug >= 2)
{
    @features = keys %{ $rl->Features };
    print "ReadLine features: @features\n";
}

&install_handler();
$SIG{ WINCH } = sub {};

do {
    my $num_children = 0;

    $reload_interpreter = 0;

    if (! -e $pipe_name)
    {
	print "Making fifo $pipe_name\n"
	    if $debug >= 3;
	($rc = system( "mkfifo -m go-rwx $pipe_name" ))
	    && die "ERROR: Couldn't make fifo $pipe_name: $!";

	print "mkfifo returned $rc\n"
	    if $debug >= 3;

	system( "ls -l $pipe_name" )
	    if ($debug >= 2);
    }

    if (! -p $pipe_name)
    {
	print STDERR "$pipe_name exists, and is not a fifo\n";
	exit( 1 );
    }

    $writer_pid = fork();
    die "ERROR: fork failed for 'writer': $!\n"
	if !defined( $writer_pid );
    if (0 == $writer_pid)
    {
	# child

	$SIG{ HUP } = sub { exit; };
	$SIG{ INT } = 'IGNORE';
	$SIG{ WINCH } = 'IGNORE';

	# Open it for output, so the open-for-input call doesn't block.  This allows
	# any other process to just open it, write to it, and close it, and we don't
	# have to worry about it closing due to lack of writers.
	open( PIPE_OUT, ">$pipe_name" ) 
	    or die "ERROR: couldn't open pipe for output: $!";

	print "'writer' process opened $pipe_name for output\n"
	    if $debug >= 3;

	# sleep for a year
	sleep( 3600 * 24 * 365 );
	exit;
    } else {
	$num_children++;
    }

    print "spawned 'writer' process; pid is $writer_pid\n"
	if $debug >= 1;

    # don't need to sleep to wait for above child -- the OS will block us until
    # the child opens the pipe
    open( PIPE, "<$pipe_name" ) 
	or die "ERROR: Couldn't open fifo $pipe_name: $!";

    $last_partial_line = undef;
    $tty_open = 1;
    $pipe_open = 1;
    $stdin_open = 1;

    $master = &spawn( @ARGV );
    print "spawned @ARGV\n"
	if $debug >= 1;
    $num_children++
	if $master;

    $SIG{ INT } = \&catch_sig;

    $tty_rin = '';   vec( $tty_rin, $master->fileno(), 1 ) = 1;
    $pipe_rin = '';  vec( $pipe_rin, fileno( PIPE ), 1 ) = 1;
    $stdin_rin = ''; vec( $stdin_rin, fileno( STDIN ), 1 ) = 1;

    $rin_all = '';
    vec( $rin_all, $master->fileno(), 1 ) = 1;
    vec( $rin_all, fileno( PIPE ), 1 ) = 1;
    vec( $rin_all, fileno( STDIN ), 1 ) = 1;

    while ($tty_open
	   && $pipe_open
	   && $stdin_open)
    {
	$tty_read = &check_tty_data();
	$pipe_read = &check_pipe_data();
	$stdin_read  = &check_stdin_data();

	if (!$tty_read
	    && !$pipe_read
	    && !$stdin_read
	    && $tty_open
	    && $pipe_open
	    && $stdin_open)
	{
	    # wait for *any* data
	    print "waiting for any data\n"
		if $debug;
	    my $rout;
	    select( $rout = $rin_all, undef, undef, undef );
	}
    }
    
    if (kill( 0, $writer_pid ))
    {
	print "Signaling writer\n"
	    if $debug >= 1;
	kill 1, $writer_pid;
    }
    else
    {
	print STDERR "ERROR: 'writer' pid $writer_pid no longer exists!\n";
	$num_children--;
    }

    # Wait for both children (if they're still around): the Lisp listener and
    # the "writer" process
    print "Waiting for $num_children children to end\n"
	if $debug;
    while ($num_children > 0) {
	$rc = wait();
	print "wait returned $rc; \$? = $?\n"
	    if $debug;
	$num_children--;
    }

    # FIXME: probably need to do something to close down the tty, but I don't know
    # exactly what

    # delete the fifo
    unlink( $pipe_name );
} while ($reload_interpreter);

&uninstall_handler();
$rl->deprep_terminal();

system( "stty sane" );

