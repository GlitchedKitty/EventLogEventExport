# EventLogEventExport
This is a collection of Powershell scripts that will pull specified Event IDs from Windows Event Viewer.

Scripts:

PS7-GetEventLogActions_CSV

  This script will pull logs for the following Event IDs and ezport them to a CSV file:
  
  4800 - Workstation locked
    
  4801 - Workstation unlocked
    
  4802 - Screen saver invoked
    
  4803 - Screensaver dismissed
    
  This script will need to be run on the target workstation.
  
  **PLEASE NOTE** You will need to configure the System Audit Policies for Logon, Logoff, and Other Logon/Logoff Events PRIOR to running this script.
