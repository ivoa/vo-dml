/*
 * Created on 7 Oct 2024 
 * Copyright 2024 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.jpa;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import jakarta.persistence.AttributeConverter;

/**
 * JPA Attribute converters to convert lists to comma separated strings.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 */
/**
 *  .
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 * @since 21 Oct 2024
 */
public class AttributeConverters {

    private static final String SPLIT_CHAR = ";";
    /**
     * A  .
     * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
     * 
     */
    public static class StringListConverter implements AttributeConverter<List<String>, String> {

       
        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.AttributeConverter#convertToDatabaseColumn(java.lang.Object)
         */
        @Override
        public String convertToDatabaseColumn(List<String> attribute) {
            return attribute != null ? String.join(SPLIT_CHAR, attribute) : "";
        }

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.AttributeConverter#convertToEntityAttribute(java.lang.Object)
         */
        @Override
        public List<String> convertToEntityAttribute(String dbData) {
           return dbData != null ? Arrays.asList(dbData.split(SPLIT_CHAR)) : new ArrayList<String>() ;
        }
        
    }
    
    /**
     *  The base class for converters.
     * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
     *
     */
    public static abstract class NumberListConverter <T> implements AttributeConverter<List<T>, String> {

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.AttributeConverter#convertToDatabaseColumn(java.lang.Object)
         */
        @Override
        public String convertToDatabaseColumn(List<T> attribute) {
            
            if(attribute!= null)
            {
               return attribute.stream().map(T::toString).collect(Collectors.joining (SPLIT_CHAR)); 
            }
            else
            {
                return "";
            }
        }

    
    }
    /**
     * A converter for Integers.
     * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
     * 
     */
    public static class IntListConverter extends NumberListConverter<Integer>
    {

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.AttributeConverter#convertToEntityAttribute(java.lang.Object)
         */
        @Override
        public List<Integer> convertToEntityAttribute(String dbData) {
           if (dbData != null)
           {
               return Stream.of(dbData.split(SPLIT_CHAR)).map(Integer::parseInt).toList();
           }
           else return new ArrayList<>();
            
        }
        
    }
    /**
     *  A converter for doubles.
     * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
     * 
     */
    public static class DoubleListConverter extends NumberListConverter<Double>
    {

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.AttributeConverter#convertToEntityAttribute(java.lang.Object)
         */
        @Override
        public List<Double> convertToEntityAttribute(String dbData) {
           if (dbData != null)
           {
               return Stream.of(dbData.split(SPLIT_CHAR)).map(Double::parseDouble).toList();
           }
           else return new ArrayList<>();
            
        }
        
    }
    
    /**
     * A converter for booleans.
     * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
     * 
     */
    public static class BooleanListConverter extends NumberListConverter<Boolean> 
    {

        /**
         * {@inheritDoc}
         * overrides @see jakarta.persistence.AttributeConverter#convertToEntityAttribute(java.lang.Object)
         */
        @Override
        public List<Boolean> convertToEntityAttribute(String dbData) {
            if (dbData != null)
           {
               return Stream.of(dbData.split(SPLIT_CHAR)).map(Boolean::parseBoolean).toList();
           }
           else return new ArrayList<>();
            
          
        }
        
    }
}


