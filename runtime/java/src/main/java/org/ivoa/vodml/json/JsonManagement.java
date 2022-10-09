/*
 * Created on 6 Oct 2022 
 * Copyright 2022 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.json;

import java.text.SimpleDateFormat;
import java.util.TimeZone;

import com.fasterxml.jackson.annotation.PropertyAccessor;
import com.fasterxml.jackson.annotation.JsonAutoDetect.Visibility;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectMapper.DefaultTyping;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.json.JsonMapper;
import com.fasterxml.jackson.databind.jsontype.BasicPolymorphicTypeValidator;
import com.fasterxml.jackson.databind.jsontype.PolymorphicTypeValidator;

import org.ivoa.vodml.ModelDescription;

/**
 * Utility class for JSON serialization.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 6 Oct 2022
 */
public class JsonManagement {
    
    /**
     * return an ObjectMapper suitably configured for use with the VODML generated models. 
     * @return
     */
    static public ObjectMapper jsonMapper(ModelDescription md) {
                    final TimeZone utc = TimeZone.getTimeZone("UTC");
            final SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ"); //FIXME Jackson seems to ignore the date format to get desired Z
            df.setTimeZone(utc);
           
            PolymorphicTypeValidator sv = BasicPolymorphicTypeValidator.builder().allowIfBaseType("org.ivoa.dm").build();
            DefaultTyping app;
            return  JsonMapper.builder()
                      .visibility(PropertyAccessor.FIELD, Visibility.ANY)
                      .visibility(PropertyAccessor.GETTER, Visibility.NONE)
                      .defaultTimeZone(utc)
                      .configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false)
                      .configure(SerializationFeature.WRITE_DATES_WITH_ZONE_ID, true)
                      .defaultDateFormat(df)
                      .configure(SerializationFeature.WRAP_ROOT_VALUE, false)
                      .configure(SerializationFeature.WRITE_SINGLE_ELEM_ARRAYS_UNWRAPPED, false)  
                      .handlerInstantiator(new VodmlHandlerInstantiator(md))
                      .build();

    }

}


