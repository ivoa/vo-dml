package org.ivoa.dm.serializationsample;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.List;
import org.junit.jupiter.api.Test;

/*
 * Created on 16/05/2023 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */
public class SerializationExampleTest
    extends org.ivoa.vodml.testing.AutoDBRoundTripTest<MyModelModel,Long,SomeContent> {

  private MyModelModel themodel;
private SomeContent someContent;
private Refa refa;
private Refb refb;

@Override
  public MyModelModel createModel() {
    themodel = new MyModelModel();
    refa = new Refa("a value");
    refb = new Refb("a name", "another val");

    List<BaseC> clist = List.of(new Dcont("a D", "dval"), new Econt("cube", "eval"));

    someContent = new SomeContent(refa, refb, List.of("some","z","values"), clist);
    themodel.addContent(someContent);

    return themodel;
  }

  @Override
  public void testModel(org.ivoa.dm.serializationsample.MyModelModel myModelModel) {
      //should test the model integrity
  }

 

/**
 * {@inheritDoc}
 * overrides @see org.ivoa.vodml.testing.AutoDBRoundTripTest#entityForDb()
 */
@Override
public SomeContent entityForDb() {
   return someContent;
}

/**
 * {@inheritDoc}
 * overrides @see org.ivoa.vodml.testing.AutoDBRoundTripTest#testEntity(org.ivoa.vodml.jpa.JPAManipulationsForObjectType)
 */
@Override
public void testEntity(SomeContent e) {
    //test that the array transformation to string working.
  assertEquals("some",e.getZval().get(0));
  assertEquals("z",e.getZval().get(1));
  assertEquals("values",e.getZval().get(2));
    
}

/**
 * {@inheritDoc}
 * overrides @see org.ivoa.vodml.validation.AbstractBaseValidation#setDbDumpFile()
 */
@Override
protected String setDbDumpFile() {
  return "serialization_dump.sql";
    
}

}
