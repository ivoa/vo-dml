package org.ivoa.dm.jpatest;


/*
 * Created on 13/03/2025 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import org.ivoa.vodml.testing.AutoDBRoundTripTest;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.ArrayList;
import java.util.List;

public class JPAStdTest extends AutoDBRoundTripTest<JpatestModel,Long,Parent> {
   private Parent atest;

   @Override
   public Parent entityForDb() {
      return atest;
   }

   @Override
   public void testEntity(Parent e) {

   }

   @Override
   public JpatestModel createModel() {
      final ReferredTo1 referredTo = new ReferredTo1("top level ref");
      final ReferredTo2 referredToin = new ReferredTo2("lower ref");
      Child refcont = new Child(referredToin);
      List<LChild> ll = new ArrayList<LChild>(//IMPL make mutable
            List.of(new LChild("First", 1), new LChild("Second", 2), new LChild("Third", 3)));

      atest =
            Parent.createParent(
                  a -> {
                     ReferredTo3 ref3 = new ReferredTo3(3,"ref in dtype");
                     a.dval = new ADtype(1.1, "astring","intatt", "base", ref3);
                     a.eval = new AEtype(1.2, "evals", "intatt_e", "basestre_e", ref3);
                     a.rval = referredTo;
                     a.cval = refcont;
                     a.lval = ll;
                     a.tval = new DThing(new Point(1.5,3.0), "thing");
                  });
      JpatestModel retval = new JpatestModel();
      retval.addContent(atest);
      return retval;
   }

   /**
 * {@inheritDoc}
 * overrides @see org.ivoa.vodml.validation.AbstractBaseValidation#setDbDumpFile()
 */
@Override
protected String setDbDumpFile() {
   return "jpa_test.sql";
    
}

   @Override
   public void testModel(JpatestModel jpatestModelTest) {
      Parent pl = jpatestModelTest.getContent(Parent.class).get(0);
      assertNotNull(pl);
      assertEquals("intatt", pl.getDval().getIntatt());
      assertEquals("intatt_e", pl.getEval().getIntatt());
   }
}
