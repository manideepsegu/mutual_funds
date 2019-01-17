# mutual_funds
Perl code to get latest NAVs, process CAMS PDF and generate a CSV summary

Required Perl Modules:
- Getopt::Long
- Data::Dumper
- LWP::Simple
 
Unix:
- pdftotext

Options:
- url       =>      Specify different URL for latest NAVs other than AMF (Optional)
- cams      =>      Path for the CAMS PDF file. Defaults to \$HOME/CAMS.pdf
- pwd       =>      Password for CAMS PDF. Defaults to 123456
- csv       =>      Path for final CSV file. Defaults to \$HOME/mutual_funds.csv
- help      =>      Print this message

Example:
- mutual_funds.pl -cams CAMS.pdf -pwd qwerty -csv latest_summary.csv
