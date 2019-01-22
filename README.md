# Mutual Fund Summary
Perl code to get latest NAVs, process CAMS PDF and generate a XLSX summary

Required Perl Modules:
- Getopt::Long
- Data::Dumper
- LWP::Simple
- Excel::Writer
 
Unix:
- pdftotext

Options:
- url       =>      Specify different URL for latest NAVs other than AMF (Optional)
- cams      =>      Path for the CAMS PDF file. Defaults to \$HOME/CAMS.pdf
- pwd       =>      Password for CAMS PDF. Defaults to 123456
- xlsx      =>      Path for final XLSX file. Defaults to \$HOME/mutual_funds.xlsx
- help      =>      Print this message

Example:
- mutual_funds.pl -cams CAMS.pdf -pwd qwerty -xlsx latest_summary.xlsx

CAMS Statement can be downloaded from:
- https://www.camsonline.com/COL_InvestorServices.aspx 
- (MailBackServices -> Consolidated Account Statement - CAMS+Karvy+FTAMIL+SBFS -> Detailed Statement with long time period).

Future Enhancements:
- Move URL parsing and CSV generation functions to Perl Modules
- Add options to keep track of NAVs for each day
- Enhance generation of CSV to XLS for better readability
