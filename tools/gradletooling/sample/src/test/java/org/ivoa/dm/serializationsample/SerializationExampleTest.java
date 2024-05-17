package org.ivoa.dm.serializationsample;

import java.util.List;
import org.junit.jupiter.api.Test;

/*
 * Created on 16/05/2023 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */
public class SerializationExampleTest
    extends org.ivoa.vodml.testing.AutoRoundTripTest<MyModelModel> {

  @Override
  public MyModelModel createModel() {
    MyModelModel retval = new MyModelModel();
    Refa refa = new Refa("a value");
    Refb refb = new Refb("a name", "another val");

    List<BaseC> cc = List.of(new Dcont("a D", "dval"), new Econt("an E", "eval"));

    SomeContent c = new SomeContent("a z val", cc, refa, refb);
    retval.addContent(c);

    return retval;
  }

  @Override
  public void testModel(org.ivoa.dm.serializationsample.MyModelModel myModelModel) {}

  @Test
  public void testStandaloneList() {
    List<BaseC> cc = List.of(new Dcont("a D", "dval"), new Econt("an E", "eval"));
  }
}
