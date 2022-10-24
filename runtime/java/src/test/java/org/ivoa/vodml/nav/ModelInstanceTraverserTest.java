package org.ivoa.vodml.nav;

import org.ivoa.vodml.annotation.VoDml;
import org.ivoa.vodml.annotation.VodmlType;

import java.io.BufferedOutputStream;
import java.io.BufferedWriter;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.Arrays;
import java.util.Date;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/*
 * Created on 19/10/2022 by Paul Harrison (paul.harrison@manchester.ac.uk).
 * 
 * 
 */

class ModelInstanceTraverserTest {


    @org.ivoa.vodml.annotation.VoDml(ref="sample:catalog.LuminosityType", type=org.ivoa.vodml.annotation.VodmlType.enumeration) 
    enum LuminosityType {MAGNITUDE("m"),FLUX("f");
        private LuminosityType(String val) {
            this.val = val;
        }

        private final String val;

    }

    @VoDml(ref="test:exNested",type = VodmlType.dataType)
    static class ANestedExample {
        public ANestedExample(String sval, LuminosityType ltype) {
            this.sval = sval;
            this.ltype = ltype;
        }

        @VoDml(ref="test:exNested.sval",type = VodmlType.attribute)
        final String sval;
        @VoDml(ref="test.exNested.lval",type = VodmlType.attribute)
        final LuminosityType ltype;
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
        @VoDml(ref="test:aent.nested",type =VodmlType.composition)
        final List<ANestedExample> nested;
        public TestEntity(double val, AnExample ex2, List<ANestedExample> nested) {
            this.val = val;
            this.ex2 = ex2;
            this.nested = nested;
        }
    }
    @VoDml(ref="test:mod",type = VodmlType.objectType)
    static class TestModel {
        @VoDml(ref = "test:mod.date", type = VodmlType.attribute)
        final Date date;
        @VoDml(ref="test:mod.ents", type = VodmlType.composition)
        final List<TestEntity> ents;
        @VoDml(ref = "test:mod.nulled", type = VodmlType.attribute)
        final Long nulled = null;
        //a field that is not in the model - should be silently (apart from logging) ignored.
        final String notinmodel="extra";

        public TestModel(Date date, List<TestEntity> ents) {
            this.date = date;
            this.ents = ents;
        }
    }

    static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
            .getLogger(ModelInstanceTraverserTest.class);

    @org.junit.jupiter.api.Test
    void testVisit() {

        AnExample ex = new AnExample("teststring",LuminosityType.FLUX);
        ANestedExample ne0 = new ANestedExample("firstnested",LuminosityType.MAGNITUDE);
        ANestedExample ne1 = new ANestedExample("secondnested",LuminosityType.FLUX);
        TestEntity ent = new TestEntity(3.2, ex,Arrays.asList(ne0,ne1 ));
        TestModel tmod = new TestModel(new Date(), Arrays.asList(ent));
        StringWriter sw = new StringWriter();
        PrintWriter out = new PrintWriter(sw);
       

        ModelInstanceTraverser.traverse(tmod, new ModelInstanceTraverser.FullVisitor() {
            
            @Override
            public void startInstance(Object o, VodmlTypeInfo v, boolean firstVisit) {
                out.printf("\"%s\" : {\n", v.vodmlRef);
                
            }
            @Override
            public void leaf(Object o, VodmlTypeInfo v, boolean firstVisit) {
               out.printf("\"%s\" : %s\n",v.vodmlRef,o.toString());
            }
            
            @Override
            public void endInstance(Object o, VodmlTypeInfo v, boolean firstVisit) {
                out.println("}");
                
            }
        });
        System.out.println(sw.toString());
        
        ModelInstanceTraverser.traverse(tmod, new ModelInstanceTraverser.Visitor() {
            
            @Override
            public void startInstance(Object o, VodmlTypeInfo v, boolean firstVisit) {
                System.out.println(v);
                
            }
        });
        //TODO put some actual tests in./
    }
}