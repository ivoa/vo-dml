/*
 * Created on 4 May 2023 
 * Copyright 2023 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.testing;

import static org.junit.jupiter.api.Assertions.*;

import org.ivoa.vodml.ModelManagement;
import org.ivoa.vodml.VodmlModel;
import org.ivoa.vodml.jpa.JPAManipulationsForObjectType;
import org.junit.jupiter.api.Test;

/**
 * Base Test that will additionally run a database round-trip test. This is a bit trickier to make useful
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 4 May 2023
 */
public abstract class AutoDBRoundTripTest <M extends VodmlModel<M>, I, T extends JPAManipulationsForObjectType<I>> extends AutoRoundTripTest<M> {
    /**
     * an entity for testing.
     * @return the entity to be persisted to the database.
     */
    public abstract T entityForDb(); 
    
    /**
     * Run some integrity tests on the entity.
     * @param e the entity to be tested.
     */
    public abstract void testEntity(T e);

    @Test
    void testRDBRoundTrip()
    {
       final M model = createModel();
       ModelManagement<M> management = model.management();
       final T entity = entityForDb();
       RoundTripResult<T> result = roundtripRDB(management, entity);
        assertTrue(result.isValid, "reading entity back from DB had errors");
        assertNotNull(result.retval,"returned entity back from DB null");
        testEntity(result.retval);
       
    }
 
}


