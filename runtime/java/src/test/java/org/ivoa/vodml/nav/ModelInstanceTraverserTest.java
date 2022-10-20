package org.ivoa.vodml.nav;

import org.ivoa.vodml.annotation.VoDml;
import org.ivoa.vodml.annotation.VodmlType;

import java.util.Arrays;
import java.util.Date;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/*
 * Created on 19/10/2022 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

class ModelInstanceTraverserTest {

    
     @org.ivoa.vodml.annotation.VoDml(ref="sample:catalog.LuminosityType", type=org.ivoa.vodml.annotation.VodmlType.enumeration) 
    enum LuminosityType {MAGNITUDE("m"),FLUX("f");
        private LuminosityType(String val) {
        this.val = val;
    }

        private final String val;
        
        }

        
   
    @VoDml(ref="test:ex",type = VodmlType.dataType)
    static class AnExample {
        public AnExample(String sval, LuminosityType ltype) {
            this.sval = sval;
            this.ltype = ltype;
        }

        @VoDml(ref="test:ex.sval",type = VodmlType.attribute)
        final String sval;
        @VoDml(ref="test.ex.lval",type = VodmlType.attribute)
        final LuminosityType ltype;
    }

   @VoDml(ref="test:aent", type= VodmlType.reference )
   static class TestEntity {
      @VoDml(ref="test:aent.val",type = VodmlType.attribute)
      final double val;
      @VoDml(ref="test:aent.ex2",type =VodmlType.attribute)
      final AnExample ex2;
      public TestEntity(double val, AnExample ex2) {
        this.val = val;
        this.ex2 = ex2;
      }
   }
   @VoDml(ref="test:mod",type = VodmlType.objectType)
   static class TestModel {
      @VoDml(ref = "test:mod.date", type = VodmlType.attribute)
      final Date date;
      @VoDml(ref="test:mod.ents", type = VodmlType.composition)
      final List<TestEntity> ents;

      public TestModel(Date date, List<TestEntity> ents) {
         this.date = date;
         this.ents = ents;
      }
   }

   static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
         .getLogger(ModelInstanceTraverserTest.class);

   @org.junit.jupiter.api.Test
   void testbad() {

    AnExample ex = new AnExample("teststring",LuminosityType.FLUX);
    TestEntity ent = new TestEntity(3.2, ex);
      TestModel tmod = new TestModel(new Date(), Arrays.asList(ent));

      ModelInstanceTraverser.traverse(tmod, new ModelInstanceTraverser.Visitor() {
         @Override
         public void process(Object o, VodmlTypeInfo v) {
            System.out.println(o.getClass()+" "+v);
         }
      });
   }
}