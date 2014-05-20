#!/bin/awk -f
{
  if ($0 == "#ES_HEAP_SIZE=2g") {
    print $0;
    print "ES_HEAP_SIZE=512m";
  }
  else if ($0 == "ES_HEAP_SIZE=512m") {
  }
  else if ($0 == "#ES_JAVA_OPTS=") {
    print $0;
    print "ES_JAVA_OPTS=\"-Des.max-open-files=true\"";
  }
  else if ($0 == "ES_JAVA_OPTS=\"-Des.max-open-files=true\"") {
  }
  else if ($0 == "#MAX_LOCKED_MEMORY=") {
    print $0;
    print "MAX_LOCKED_MEMORY=unlimited";
  }
  else if ($0 == "MAX_LOCKED_MEMORY=unlimited") {
  }
  else {
    print $0;
  }
}
