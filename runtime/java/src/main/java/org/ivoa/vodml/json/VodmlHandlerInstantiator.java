/*
 * Created on 8 Oct 2022 
 * Copyright 2022 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.json;

import com.fasterxml.jackson.databind.DeserializationConfig;
import com.fasterxml.jackson.databind.JsonDeserializer;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.KeyDeserializer;
import com.fasterxml.jackson.databind.SerializationConfig;
import com.fasterxml.jackson.databind.cfg.MapperConfig;
import com.fasterxml.jackson.databind.introspect.Annotated;
import com.fasterxml.jackson.databind.jsontype.TypeIdResolver;
import com.fasterxml.jackson.databind.jsontype.TypeResolverBuilder;

import org.ivoa.vodml.ModelDescription;

/**
 * A handler instantiator for configuring a Jackson objectmapper instance.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 8 Oct 2022
 */
public class VodmlHandlerInstantiator extends com.fasterxml.jackson.databind.cfg.HandlerInstantiator  {

   
    private ModelDescription md;

    /**
     * @param md the model description.
     */
    public VodmlHandlerInstantiator(ModelDescription md) {
        this.md = md;
    }

    /**
     * {@inheritDoc}
     * overrides @see com.fasterxml.jackson.databind.cfg.HandlerInstantiator#deserializerInstance(com.fasterxml.jackson.databind.DeserializationConfig, com.fasterxml.jackson.databind.introspect.Annotated, java.lang.Class)
     */
    @Override
    public JsonDeserializer<?> deserializerInstance(
            DeserializationConfig config, Annotated annotated,
            Class<?> deserClass) {
        return null;
        
    }

    /**
     * {@inheritDoc}
     * overrides @see com.fasterxml.jackson.databind.cfg.HandlerInstantiator#keyDeserializerInstance(com.fasterxml.jackson.databind.DeserializationConfig, com.fasterxml.jackson.databind.introspect.Annotated, java.lang.Class)
     */
    @Override
    public KeyDeserializer keyDeserializerInstance(DeserializationConfig config,
            Annotated annotated, Class<?> keyDeserClass) {
      return null;
        
    }

    /**
     * {@inheritDoc}
     * overrides @see com.fasterxml.jackson.databind.cfg.HandlerInstantiator#serializerInstance(com.fasterxml.jackson.databind.SerializationConfig, com.fasterxml.jackson.databind.introspect.Annotated, java.lang.Class)
     */
    @Override
    public JsonSerializer<?> serializerInstance(SerializationConfig config,
            Annotated annotated, Class<?> serClass) {
        return null;
    }

    /**
     * {@inheritDoc}
     * overrides @see com.fasterxml.jackson.databind.cfg.HandlerInstantiator#typeResolverBuilderInstance(com.fasterxml.jackson.databind.cfg.MapperConfig, com.fasterxml.jackson.databind.introspect.Annotated, java.lang.Class)
     */
    @Override
    public TypeResolverBuilder<?> typeResolverBuilderInstance(
            MapperConfig<?> config, Annotated annotated,
            Class<?> builderClass) {
       return null;
        
    }

    /**
     * {@inheritDoc}
     * overrides @see com.fasterxml.jackson.databind.cfg.HandlerInstantiator#typeIdResolverInstance(com.fasterxml.jackson.databind.cfg.MapperConfig, com.fasterxml.jackson.databind.introspect.Annotated, java.lang.Class)
     */
    @Override
    public TypeIdResolver typeIdResolverInstance(MapperConfig<?> config,
            Annotated annotated, Class<?> resolverClass) {
      
        return new VodmlTypeResolver(md);
        
    }

}


