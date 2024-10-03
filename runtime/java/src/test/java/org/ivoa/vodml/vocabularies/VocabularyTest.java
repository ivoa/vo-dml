package org.ivoa.vodml.vocabularies;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/*
 * Created on 11/09/2024 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

class VocabularyTest {

   @Test
   void load() {

      Vocabulary v = Vocabulary.load("http://www.ivoa.net/rdf/product-type");
      assertNotNull(v);

      Term cube = v.terms.get("cube");
      assertNotNull(cube);
      assertTrue(cube.hasWiderTerm(v.terms.get("spatially-resolved-dataset")));
      assertTrue(cube.hasNarrowerTerm(v.terms.get("spectral-cube")));

   }

   @Test
   void deprecated() {
      Vocabulary v2 = Vocabulary.load("http://www.ivoa.net/rdf/voresource/relationship_type");
      assertNotNull(v2);
      Term term = v2.terms.get("mirror-of");
      System.out.println(term.toString());
      assertTrue(term.isDeprecated(),"should be deprecated");

   }

   /* FIXME desise does not show parent
   @Test
   void parent() {
      Vocabulary v2 = Vocabulary.load("http://www.ivoa.net/rdf/datalink/core");
      assertNotNull(v2);
      Term bias = v2.terms.get("bias");
      assertNotNull(bias);
      assertEquals(v2.terms.get("calibration"),bias.getParent());

   }

    */

}