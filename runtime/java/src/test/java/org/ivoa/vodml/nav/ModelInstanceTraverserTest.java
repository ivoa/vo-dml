package org.ivoa.vodml.nav;

import org.ivoa.vodml.annotation.VoDml;
import org.ivoa.vodml.annotation.VodmlRole;
import org.junit.jupiter.api.BeforeEach;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.Arrays;
import java.util.Date;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/*
 * Created on 19/10/2022 by Paul Harrison (paul.harrison@manchester.ac.uk).
 * 
 * this is not a great test, needs lots of manual setup - however, it "works" within the java runtime lib constraints - i.e. no autogeneration of models
 * and does constrain some of the usage of various annotation constructs.
 */

class ModelInstanceTraverserTest {


    @org.ivoa.vodml.annotation.VoDml(id = "sample:catalog.LuminosityType", role=org.ivoa.vodml.annotation.VodmlRole.enumeration) 
    enum LuminosityType {MAGNITUDE("m"),FLUX("f");
        private LuminosityType(String val) {
            this.val = val;
        }

        private final String val;

    }

    @VoDml(id = "test:exNested",role = VodmlRole.dataType)
    static class ANestedExample {
        public ANestedExample(String sval, LuminosityType ltype) {
            this.sval = sval;
            this.ltype = ltype;
        }

        @VoDml(id = "test:exNested.sval",role = VodmlRole.attribute, type="ivoa:string")
        final String sval;
        @VoDml(id = "test.exNested.lval",role = VodmlRole.attribute,type = "sample:catalog.LuminosityType")
        final LuminosityType ltype;
    }


    @VoDml(id = "test:ex",role = VodmlRole.dataType)
    static class AnExample {
        public AnExample(String sval, LuminosityType ltype) {
            this.sval = sval;
            this.ltype = ltype;
        }

        @VoDml(id = "test:ex.sval",role = VodmlRole.attribute, type="ivoa:string")
        final String sval;
        @VoDml(id = "test.ex.lval",role = VodmlRole.attribute, type="sample:catalog.LuminosityType")
        final LuminosityType ltype;
    }

    @VoDml(id = "test:aent", role= VodmlRole.objectType )
    static class TestEntity {
        @VoDml(id = "test:aent.val",role = VodmlRole.attribute,type="ivoa:real")
        final double val;
        @VoDml(id = "test:aent.ex2",role = VodmlRole.attribute, type="test:ex")
        final AnExample ex2;
        @VoDml(id = "test:aent.nested",role = VodmlRole.composition, type="test:exNested")
        final List<ANestedExample> nested;
        public TestEntity(double val, AnExample ex2, List<ANestedExample> nested) {
            this.val = val;
            this.ex2 = ex2;
            this.nested = nested;
        }
    }
    @VoDml(id = "test:mod",role = VodmlRole.objectType)
    static class TestModel {
        @VoDml(id = "test:mod.date", role = VodmlRole.attribute, type="ivoa:date")
        final Date date;
        @VoDml(id = "test:mod.ents", role = VodmlRole.composition, type="test:aent")
        final List<TestEntity> ents;
        @VoDml(id = "test:mod.nulled", role = VodmlRole.attribute, type="ivoa:integer")
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
    private TestModel tmod;

    
        /**
     * @throws java.lang.Exception
     */
    @BeforeEach
    void setUp() throws Exception {
         AnExample ex = new AnExample("teststring",LuminosityType.FLUX);
        ANestedExample ne0 = new ANestedExample("firstnested",LuminosityType.MAGNITUDE);
        ANestedExample ne1 = new ANestedExample("secondnested",LuminosityType.FLUX);
        TestEntity ent = new TestEntity(3.2, ex,Arrays.asList(ne0,ne1 ));
        tmod = new TestModel(new Date(), Arrays.asList(ent));
   }

  
    
    @org.junit.jupiter.api.Test
    void testVisit() {

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