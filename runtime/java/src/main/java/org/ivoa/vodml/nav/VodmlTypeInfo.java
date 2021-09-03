/*
 * Created on 1 Sep 2021 
 * Copyright 2021 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.nav;

import org.ivoa.vodml.annotation.VodmlType;

/**
 *  .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 1 Sep 2021
 */
public final class VodmlTypeInfo {
    
    public VodmlTypeInfo(String vodmlRef, VodmlType kind) {
        this.vodmlRef = vodmlRef;
        this.kind = kind;
        
    }

    /**
     * the full VODML reference for the type (including the model prefix).
     */
    public final String vodmlRef;
    
    
    /**
     * the kind
     */
    public final VodmlType kind;
    
    
   

    /**
     * {@inheritDoc}
     * overrides @see java.lang.Object#toString()
     */
    @Override
    public String toString() {
        return String.format("VodmlTypeInfo [vodmlRef=%s, type=%s]", vodmlRef,
                kind);
    }
    
    

}


