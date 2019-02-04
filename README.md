# Mutual Fund Summary
Perl code to get latest NAVs, process CAMS PDF and generate a XLSX summary

Required Perl Modules:
- Getopt::Long
- Data::Dumper
- Excel::Writer
 
Unix:
- pdftotext
- curl

Options:
- url       =>      Specify different URL for latest NAVs other than AMF (Optional)
- cams      =>      Path for the CAMS PDF file. Defaults to \$HOME/CAMS.pdf
- pwd       =>      Password for CAMS PDF. Defaults to 123456
- xlsx      =>      Path for final XLSX file. Defaults to \$HOME/mutual_funds.xlsx
- help      =>      Print this message

Example:
- perl mutual_funds/mutual_funds.pl -cams $HOME/MF_Summary/CAMS_mail1.pdf -cams $HOME/MF_Summary/CAMS_mail2.pdf -xlsx $HOME/MF_Summary/CAMS.xlsx

CAMS Statement can be downloaded from:
- https://www.camsonline.com/COL_InvestorServices.aspx 
- (MailBackServices -> Consolidated Account Statement - CAMS+Karvy+FTAMIL+SBFS -> Detailed Statement with long time period).

Future Enhancements:
- Move URL parsing and XLS generation functions to Perl Modules
- Add options to keep track of NAVs for each day
