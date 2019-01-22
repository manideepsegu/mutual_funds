#!/usr/bin/perl

use strict;
use warnings;

use Excel::Writer::XLSX;
use Getopt::Long;
use Data::Dumper;
use LWP::Simple qw(get);

my $url  = "https://www.amfiindia.com/spages/NAVAll.txt";
my $cams = "$ENV{HOME}/CAMS.pdf";
my $pwd  = "123456";
my $csv  = "$ENV{HOME}/mutual_funds.xlsx";
my $textFile;

GetOptions ("url=s"       => \$url, 
            "cams=s"      => \$cams,
            "pwd=s"       => \$pwd,
            "xlsx=s"      => \$csv,
            "help"        => \&help_msg)
or help_msg();

sub help_msg {
  print "\n===================================   mutual_funds.pl   ======================================\n\n";
  print "Script to process latest NAV from AMF website and process CAMS file to generate a XLS summary\n\n";
  print "Options:\n";
  print "\turl       =>      Specify different URL for latest NAVs other than AMF (Optional)\n";
  print "\tcams      =>      Path for the CAMS PDF file. Defaults to \$HOME/CAMS.pdf\n";
  print "\tpwd       =>      Password for CAMS PDF. Defaults to 123456\n";
  print "\txlsx      =>      Path for final XLSX file. Defaults to \$HOME/mutual_funds.xlsx\n";
  print "\thelp      =>      Print this message\n";
  print "\nExample:\n\tperl mutual_funds.pl -cams CAMS.pdf -pwd qwerty -xlsx latest_summary.xlsx\n";
  print "\nContact:\n\tManideep Segu (msegu\@gmail.com)\n\n";
  exit 1;
}

my ($latestNav, $codeMapping) = getLatestNAV();

processCAMS($cams, $latestNav, $codeMapping);

sub getLatestNAV {
  my @navall = split /\n/, get $url;
  @navall = grep !/^\s*$/, @navall;
  chomp @navall;
  foreach(@navall) {
    $_ =~ s/\W$//;
  }
  my @titleData = split /;/, $navall[0];
  shift @navall, 
  my $parentFund;
  my %fundData;
  my %codeMapping;
  my $fundNameIdx;
  my $fundCodeIdx;
  my $fundDateIdx;
  my $fundNAVIdx;
  for(my $i=0; $i<=$#titleData; $i++) {
    if($titleData[$i] =~ /Name/i) {
      $fundNameIdx = $i;
    }
    if($titleData[$i] =~ /Code/i) {
      $fundCodeIdx = $i;
    }
    if($titleData[$i] =~ /Date/i) {
      $fundDateIdx = $i;
    }
    if($titleData[$i] =~ /Net Asset Value/i) {
      $fundNAVIdx = $i;
    }
  }
  foreach my $navall (@navall) {
    if($navall =~ /;/) {
      my @temp = split /;/, $navall;
      if($temp[$fundNameIdx] !~ /(direct|regular)/i) {
        $temp[$fundNameIdx] = $temp[$fundNameIdx] . " Regular";
      }
      $fundData{$temp[$fundCodeIdx]}{parentFund}  = $parentFund;
      $fundData{$temp[$fundCodeIdx]}{name}        = $temp[$fundNameIdx];
      $fundData{$temp[$fundCodeIdx]}{date}        = $temp[$fundDateIdx];
      $fundData{$temp[$fundCodeIdx]}{nav}         = $temp[$fundNAVIdx];
      if(!exists $codeMapping{$parentFund}{$temp[$fundNameIdx]}) {
        $codeMapping{$parentFund}{$temp[$fundNameIdx]} = $temp[$fundCodeIdx];
      } else {
        die "Duplicate entry for $temp[$fundNameIdx] found";
      }
    } else {
      $parentFund = $navall;
    }
  }
  return (\%fundData, \%codeMapping);
}

sub processCAMS {
  my ($camsPdf, $latestNav, $codeMapping) = @_;

  if(not defined $textFile) {
    $textFile = $camsPdf;
    $textFile =~ s/.pdf//;
  }

  system("pdftotext -raw -q -upw $pwd $camsPdf $textFile");
  
  open(FILE, "<", $textFile) or die $!;
  
  my @text;
  
  while(<FILE>){
    chomp($_);
    push @text, $_;
  }
  
  my %fund;
  my $fund_name;
  my $fund_code;
  my $i=0;
  foreach(@text) {
    my $txt = $_;
    $txt =~ s/\\n//;
    if($txt =~ /KYC: /) {
      my $fund_info = $text[$i+1];
      my @fund_info = split /-/, $fund_info, 2;
      $fund_name = $fund_info[1];
      if($fund_name !~ /(direct|regular)/i) {
        $fund_name = $fund_name . "- Regular - ";
      }
      $fund_name =~ s/\(Advisor.*?\)//;
      $fund_name =~ s/reinvest//i;
      $fund_name =~ s/\((.*?(direct|regular).*?)\)/ - $1 -/i;
      $fund_name =~ s/\(.*?\)//;
      $fund_name =~ s/Registrar\s*:\s*\w*//;
      $fund_name =~ s/-/ - /g;
      $fund_name =~ s/\s+/ /g;
      $fund_name =~ s/\s*$//;
      $fund_name = join(" ", split(/[ -]+/, $fund_name));
      $fund_code = getFundCode($fund_name, $codeMapping);
    }
    if(($txt =~ /^[0-3][0-9]-\w+-\d\d\d\d/) && (($txt =~ /Purchase/i) || ($txt =~ /Investment/i) || ($txt =~ /Subscription/i))){
      $txt =~ /^([0-3][0-9]-\w+-\d\d\d\d) ([\d,.()]+) /;
      my $date = $1;
      my $amount = $2;
      if($amount =~ /\((.*)\)/) {
        $amount = "-$1";
      }
      $amount =~ s/,//;
      $fund{$fund_code}{purchase}{$date} += $amount;
      $fund{$fund_code}{total_value} += $amount;
      if($fund{$fund_code}{purchase}{$date} == 0) {
        delete $fund{$fund_code}{purchase}{$date};
      }
    }
    if($txt =~ /Valuation on ([0-3][0-9]-\w+-\d\d\d\d): INR ([\d,.()]+)/) {
      my $date = $1;
      my $amount = $2;
      $amount =~ s/,//;
      $fund{$fund_code}{present_value} += $amount;
    }
    if($txt =~ /Closing Unit Balance: ([\d,.]+)/i) {
      my $units = $1;
      $units =~ s/,//;
      $fund{$fund_code}{units} += $units;
    }
    $i++;
  }

  # Create a new Excel workbook
  my $workbook = Excel::Writer::XLSX->new( $csv ) or die $!;

  # Add a worksheet
  my $worksheet = $workbook->add_worksheet("Summary");

  #  Add and define a format
  my %props = (
    bold    => 0,
    border  => 1,
    bottom  => 1,
    top     => 1,
    left    => 1,
    right   => 1
  );
  my $format = $workbook->add_format(%props);
  $props{bold}  = 1;
  $props{align} = 'center',
  my $formatHeader = $workbook->add_format(%props);

  my @headers = ("Fund Name", "Invested", "CAMS Value", "Present Value", "Increase");
  my $row = 0;
  my $column = 0;
  $worksheet->write($row, $column, \@headers, $formatHeader);
  foreach my $fund (keys %fund) {
    $row++;
    if($fund{$fund}{units}) {
      $worksheet->write( $row, $column, $latestNav->{$fund}{name}, $format );
      $column++;
      $worksheet->write( $row, $column, sprintf('%.2f',$fund{$fund}{total_value}), $format );
      $column++;
      $worksheet->write( $row, $column, sprintf('%.2f',$fund{$fund}{present_value}), $format );
      $column++;
      $worksheet->write( $row, $column, sprintf('%.2f',$fund{$fund}{units}*$latestNav->{$fund}{nav}), $format );
      $column++;
      $worksheet->write( $row, $column, sprintf('%.2f',100*(($fund{$fund}{units}*$latestNav->{$fund}{nav})-$fund{$fund}{total_value})/$fund{$fund}{total_value}), $format );
      $column++;
    }
    $column = 0;
  }
  $worksheet->write(0, 7, 'Total Invested', $formatHeader);
  $worksheet->write(1, 7, '=sum(B:B)', $format);
  $worksheet->write(0, 8, 'Total Value', $formatHeader);
  $worksheet->write(1, 8, '=sum(C:C)', $format);
  $worksheet->write(0, 9, 'Total Increase', $formatHeader);
  $worksheet->write(1, 9, '=(I2-H2)*100/H2', $format);
  $worksheet->set_column('A:A', 80);
  $worksheet->set_column('B:B', 15);
  $worksheet->set_column('C:C', 15);
  $worksheet->set_column('D:D', 15);
  $worksheet->set_column('E:E', 12);
  $worksheet->set_column('H:H', 15);
  $worksheet->set_column('I:I', 15);
  $worksheet->set_column('J:J', 12);
  $workbook->close();
}

sub getFundCode {
  my ($name, $mapping) = @_;
  my @name = split /[ -]+/, $name;
  my $code;
  my %fundCodeMatching;
  @name = grep !/plan/i, @name;
  foreach my $parentFund (keys %{$mapping}) {
    next if ($parentFund !~ /$name[0]/i);
    foreach my $fund (keys %{$mapping->{$parentFund}}) {
      my @fund = split /[ -]+/, $fund;
      @fund = grep !/plan/i, @fund;
      my $match = 1;
      foreach my $word (@name) {
        if($fund !~ /$word/i) {
          $match = 0;
          last;
        }
      }
      if($match) {
        if($code) {
          #print "$name -- $code($fundCodeMatching{$name}), $mapping->{$parentFund}{$fund}(".numMatches(\@name, \@fund).")\n";
          if(numMatches(\@name, \@fund) < $fundCodeMatching{$name}) {
            next;
          }
        }
        $fundCodeMatching{$name} = numMatches(\@name, \@fund);
        $code = $mapping->{$parentFund}{$fund};
      }
    }
  }
  if($code) {
    return $code;
  } else {
    print "Not able to find scheme code for $name\n";
  }
}

sub numMatches {
  my ($fund1, $fund2) = @_;
  if($#{$fund1} > $#{$fund2}) {
    ($fund1, $fund2) = ($fund2, $fund1);
  }
  my @fund1 = sort @{$fund1};
  my @fund2 = sort @{$fund2};
  my $match = 0;
  for(my $i=0; $i<=$#fund1; $i++) {
    if(uc($fund1[$i]) eq uc($fund2[$i])) {
      $match++;
    }
  }
  return $match*100/($#fund2+1);
}
