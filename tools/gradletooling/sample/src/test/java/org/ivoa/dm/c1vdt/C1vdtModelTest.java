package org.ivoa.dm.c1vdt;

import org.ivoa.vodml.testing.AutoDBRoundTripTest;

/*
 * Created on 21/02/2025 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

class C1vdtModelTest extends AutoDBRoundTripTest<C1vdtModel,Long,O2> {

    private C1vdtModel model;
    private O2 o2;
    @Override
    public O2 entityForDb() {
        return o2;
    }

    @Override
    public void testEntity(O2 e) {

    }

    @Override
    public C1vdtModel createModel() {
        model = new C1vdtModel();
        o2 = new O2(new Ot("otval",1));
        model.addContent(o2);
        O1 o1 = new O1(new Dt("dtval", 5));
        model.addContent(o1);
        return model;
    }

    @Override
    public void testModel(C1vdtModel c1vdtModel) {

    }

    @Override
    protected String setDbDumpFile() {
        return "c1vdt_dump.sql";
    }
}