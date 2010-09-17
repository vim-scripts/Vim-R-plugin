""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" This script was part of the first attempt of making the plugin work on
" Windows. It was based on the perl code written by Johannes Ranke (based on
" code written by Bill West). Below are the installation instruction that
" would be part of this approach and its know bugs.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" This plugin requires users to install several external dependencies:
"    * ActiveState Perl: http://www.activestate.com/activeperl
"
"      Note: Perl must be added to the PATH environment variable during its
"            installation.
"
"    * rcom package for R. Run R with administrator privileges and do the
"      following commands:
"
"      install.packages("rcom")
"      library(rcom)
"      comRegisterRegistry()
"
"      Note: The statconnDCOM software is automatically downloaded and
"	    installed when the "rcom" library is loaded for the first time,
"	    but currently it is not strictly a prerequisite to make the
"	    r-plugin work because the plugin does not receive direct feedback
"	    from R through DCOM.  Future versions of rcom may require
"	    statconnDCOM to receive commands from Vim, but, currently, we only
"	    need a Windows registry key value, which is registered by the
"	    command comRegisterRegistry().
"
" For your convenience, put the command "library(rcom)" in your Rprofile because
" this library must be loaded to make it possible the communication between Vim
" and R.


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" The use of perl and rcom was abandoned because of some annoying bugs:
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Vim's input is blocked while R is evaluating commands (Windows only)

" You cannot do anything with Vim while R is executing the commands sent to it.
" One possible solution is the use of another instance of Vim as a server, as in
" the rcom plugin (http://www.vim.org/scripts/script.php?script_id=2991). If you
" are an user of vim-r-plugin under Windows and has the ability to fix the
" problem, please, send a patch to me.
" 
" 
" R output is slower (Windows only)
" 
" The output of long results is slower if the command is sent by Vim to R than
" if it is typed directly in R's Console. Example:
" 
"    x <- 1:100000
"    x
" 
" 
" R evaluates immediately incomplete commands (Windows only)
" 
" If you send to R a line with an incomplete command, the line will be
" immediately evaluated by R and this will cause an error. You must always
" select and send all the lines necessary to complete the command. In the
" example below, the four lines should be sent at once:
" 
"    sumxy <- function(x, y){
"      z <- x + y
"      z
"    }
" 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" The python solution has its own problems but we considered them less
" annoying. This dead code is distributed with the plugin just to give a
" starting point for someone who wants to try to improve this approach.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


perl << EOF
sub rsourceclipboard
{
  use Win32::OLE;
  use Win32::Clipboard;
  my ($rcmd) = @_;
  Win32::Clipboard::Set($rcmd);
  my $R = Win32::OLE->GetActiveObject('RCOMServerLib.StatConnector')
  || Win32::OLE->new('RCOMServerLib.StatConnector');
  if($R){    
    $R->EvaluateNoReturn("source('clipboard', echo=TRUE)");
    $R->Close;
  } else {
    VIM::DoCommand("call RWarningMsg('r-plugin/rperl.vim:')");
    VIM::DoCommand("call RWarningMsg('  Is R running?')");
    VIM::DoCommand("call RWarningMsg('  Did you install rcom package?')");
    VIM::DoCommand("call RWarningMsg('  Did you load it?')");
    VIM::DoCommand("call RWarningMsg('  Did you run the command comRegisterRegistry() ?')");
    VIM::DoCommand("call input('Press Enter to continue...    ')");
  }
}

sub getrpath
{
  use Win32::Registry;
  my ($rkey);
  my ($var);
  my ($type);
  $HKEY_LOCAL_MACHINE->Open('SOFTWARE\R-core\R', $rkey);
  $rkey->QueryValueEx("InstallPath", $type, $var);
  VIM::DoCommand("let b:rinstallpath = '$var'");
}

EOF 

