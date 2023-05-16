package org.ivoa.dm.serializationsample;
/*
 * Created on 16/05/2023 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */
public class SerializationExampleTest extends org.ivoa.vodml.testing.AutoRoundTripTest<MyModelModel>{

   @Override
   public MyModelModel createModel() {
      MyModelModel retval = new MyModelModel();
      Refa refa = new Refa("a value");
      Refb refb = new Refb("a name", "another val");
      SomeContent c = new SomeContent("a z val", refa, refb);
      retval.addContent(c);

      return retval;
   }

   @Override
   public void testModel(org.ivoa.dm.serializationsample.MyModelModel myModelModel) {

   }
}
