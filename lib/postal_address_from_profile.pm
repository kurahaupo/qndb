# This is the algorithm used by the national label printer...

sub CSV::qndb::postal_address {
  my $r = shift;

  my (     $poboxno, $suburb, $streetname, $rdno, $city, $postcode)
  = @$r{qw( poboxno   suburb   streetname   rdno   city   postcode )};
  my @lines;

  if ($poboxno) {
    push @lines, "PO Box $poboxno";
    if ($suburb) {
      push @lines, $suburb;
    }
  }
  else {
    if ($streetname) {
      push @lines, $streetname;
    }
    if ($rdno) {
      push @lines, "RD $rdno" ;
    }
    elsif ($suburb) {
      push @lines, $suburb;
    }
  }
  push @lines, "$city $postcode";

  return \@lines;
}

