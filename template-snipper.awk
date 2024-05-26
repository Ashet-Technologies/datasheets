/office:text/ {
  if(found == 0) {
    print $0 "\n    [DOCUMENT BODY]";
  }
  found = 1 - found
}
{ if (found == 0) print $0; }
