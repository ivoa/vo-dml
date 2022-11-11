/*
 * Created on 8 Oct 2022 
 * Copyright 2022 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.json;

import java.util.Map;

import com.fasterxml.jackson.annotation.JsonTypeInfo.Id;
import com.fasterxml.jackson.databind.DatabindContext;
import com.fasterxml.jackson.databind.JavaType;
import com.fasterxml.jackson.databind.jsontype.impl.TypeIdResolverBase;
import com.fasterxml.jackson.databind.type.TypeFactory;

import org.ivoa.vodml.ModelDescription;
import org.ivoa.vodml.annotation.VoDml;
import org.ivoa.vodml.nav.ReflectIveVodmlTypeGetter;

/**
 *  .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 8 Oct 2022
 */
public class VodmlTypeResolver extends TypeIdResolverBase {


    @SuppressWarnings("rawtypes")
    private Map<String, Class> typeMap;

    public VodmlTypeResolver(ModelDescription md)
    {
        this.typeMap = md.utypeToClassMap();
    }
    
    /**
     * {@inheritDoc}
     * overrides @see com.fasterxml.jackson.databind.jsontype.TypeIdResolver#idFromValue(java.lang.Object)
     */
    @Override
    public String idFromValue(Object value) {
       return new ReflectIveVodmlTypeGetter(value.getClass()).vodmlInfo().vodmlType;      
    }

    /**
     * {@inheritDoc}
     * overrides @see com.fasterxml.jackson.databind.jsontype.TypeIdResolver#idFromValueAndType(java.lang.Object, java.lang.Class)
     */
    @Override
    public String idFromValueAndType(Object value, Class<?> suggestedType) {
        // TODO suggested type ignored for now
        return idFromValue(value);
    }
    
    

    /**
     * {@inheritDoc}
     * overrides @see com.fasterxml.jackson.databind.jsontype.impl.TypeIdResolverBase#typeFromId(com.fasterxml.jackson.databind.DatabindContext, java.lang.String)
     */
    @Override
    public JavaType typeFromId(DatabindContext context, String id) {
       if (typeMap.containsKey(id))
       {
        return  context.getTypeFactory().constructFromCanonical(typeMap.get(id).getCanonicalName());
       }
       else
           return TypeFactory.unknownType();
        
    }

    /**
     * {@inheritDoc}
     * overrides @see com.fasterxml.jackson.databind.jsontype.TypeIdResolver#getMechanism()
     */
    @Override
    public Id getMechanism() {
       return Id.NAME;
        
    }
    


}


