/*
 * Created on 1 Sep 2021 
 * Copyright 2021 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.nav;

import org.ivoa.vodml.annotation.VodmlRole;

import java.util.Objects;

/**
 *  .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 1 Sep 2021
 */
public final class VodmlTypeInfo {
  
    public static final VodmlTypeInfo UNKNOWN=new VodmlTypeInfo("", VodmlRole.unknown,"");

    
        public VodmlTypeInfo(String vodmlRef, VodmlRole role, String type, VodmlRole typeRole) {
        this.vodmlRef = vodmlRef;
        this.role = role;
        this.vodmlType = type;
        this.vodmlTypeRole = typeRole;
           
        }

    
    public VodmlTypeInfo(String vodmlRef, VodmlRole role, String type) {
        this(vodmlRef, role, vodmlRef, role);
        if (role ==  VodmlRole.attribute)
        {
            throw new IllegalArgumentException("programming error - cannot call three argument constructor for "+role);
        }

    }
    
    public VodmlTypeInfo(String vodmlRef, VodmlRole role) {
        this(vodmlRef, role, vodmlRef);
        
        //IMPL would assertion be better here?
        switch (role) {
        case attribute:
        case composition:
        case reference:
            throw new IllegalArgumentException("programming error - cannot call two argument constructor for "+role);

        default:
            break;
        }
    }

    /**
     * the full VODML reference for the entity (including the model prefix).
     */
    public final String vodmlRef;    
    
    /**
     * the role
     */
    public final VodmlRole role;
    
     /**
     * the full VODML reference for the type (including the model prefix).
     */
    public final String vodmlType;
    
    
    /** the role of the type pointed to for an attribute
     */
    public final VodmlRole vodmlTypeRole;


    /**
     * {@inheritDoc}
     * overrides @see java.lang.Object#hashCode()
     */
    @Override
    public int hashCode() {
        return Objects.hash(role, vodmlRef, vodmlType, vodmlTypeRole);
    }


    /**
     * {@inheritDoc}
     * overrides @see java.lang.Object#equals(java.lang.Object)
     */
    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (!(obj instanceof VodmlTypeInfo))
            return false;
        VodmlTypeInfo other = (VodmlTypeInfo) obj;
        return role == other.role && Objects.equals(vodmlRef, other.vodmlRef)
                && Objects.equals(vodmlType, other.vodmlType)
                && vodmlTypeRole == other.vodmlTypeRole;
    }


    /**
     * {@inheritDoc}
     * overrides @see java.lang.Object#toString()
     */
    @Override
    public String toString() {
        return String.format(
                "VodmlTypeInfo [vodmlRef=%s, role=%s, vodmlType=%s, vodmlTypeRole=%s]",
                vodmlRef, role, vodmlType, vodmlTypeRole);
    }

 
    

}


