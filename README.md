# Mutual Fund Summary
Perl code to get latest NAVs, process CAMS PDF and generate a XLSX summary

Required Perl Modules:
- Getopt::Long
- Data::Dumper
- Excel::Writer
 
Unix:
- pdftotext
- curl

Usage:
- perl mutual_funds.pl -pwd <password> -xlsx <summary> <statement1.pdf> <statement2.pdf> ...

Options:
- url       =>      Specify different URL for latest NAVs other than AMF (Optional)
- pwd       =>      Password for CAMS PDF. Defaults to 123456
- xlsx      =>      Path for final XLSX file. Defaults to \$HOME/mutual_funds.xlsx
- help      =>      Print this message

Example:
- perl mutual_funds/mutual_funds.pl -xlsx $HOME/MF_Summary/CAMS.xlsx $HOME/MF_Summary/CAMS_mail1.pdf $HOME/MF_Summary/CAMS_mail2.pdf

CAMS Statement can be downloaded from:
- https://www.camsonline.com/COL_InvestorServices.aspx 
- (MailBackServices -> Consolidated Account Statement - CAMS+Karvy+FTAMIL+SBFS -> Detailed Statement with long time period).

Future Enhancements:
- Move URL parsing and XLS generation functions to Perl Modules
- Add options to keep track of NAVs for each day
