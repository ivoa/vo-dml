package org.ivoa.dm.jpatest;

import org.w3c.dom.Node;
import org.xmlunit.builder.Input;
/*
 * Created on 10/03/2026 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import org.junit.jupiter.api.Test;
import org.xmlunit.xpath.JAXPXPathEngine;
import org.xmlunit.xpath.XPathEngine;

import javax.xml.transform.Source;

public class TapSchemaTest {

   @Test
   void checkSchema(){
      Source source = Input.fromStream(JpatestModel.TAPSchema()).build();
      XPathEngine xpath = new JAXPXPathEngine();
      Iterable<Node> allMatches = xpath.selectNodes("/*/schema", source);
      assert allMatches.iterator().hasNext();
      //TODO add more tap schema tests
   }
}
