#!/bin/awk -f
{
  if ($0 == "# cluster.name: elasticsearch") {
    print $0;
    print "cluster.name: sugarcrm";
  }
  else if ($0 == "# node.name: \"Franz Kafka\"") {
    print $0;
    print "node.name: \"Node_1\"";
  }
  else if ($0 == "# bootstrap.mlockall: true") {
    print $0;
    print "bootstrap.mlockall: true";
  }
  else {
    print $0;
  }
}
