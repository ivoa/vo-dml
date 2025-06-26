/*
 * Created on 7 Oct 2024 
 * Copyright 2024 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */ 

package org.ivoa.vodml.jpa;

import java.io.Serializable;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.hibernate.engine.spi.SharedSessionContractImplementor;
import org.hibernate.usertype.ParameterizedType;
import org.hibernate.usertype.UserType;

/**
 * Hibernate converters to convert lists to delimited strings.
 * Delimiter is passed as parameter annotation.
 * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
 */
public class AttributeConverters {

    /**
     * List converter that uses Hibernate @Type annotation.
     */
    public static abstract class  ListConcatenatedType<T> implements UserType<List<T>>,ParameterizedType {

        /** the concatenation character that will be used to store the list */
        protected String concatenationChar;
        /** the regexp that will be used to split the single string into a list */
        protected String regexp;

        /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.ParameterizedType#setParameterValues(java.util.Properties)
         */
        @Override
        public void setParameterValues(Properties parameters) {
            java.lang.String sep = parameters.getProperty("separator"); 
            if (sep != null) {
                concatenationChar = sep;
                //some heuristics to derive suitable regex for splitting.
               if (concatenationChar.matches("[|+*=\\-]")) {//IMPL note that backslash itself is not allowed - just too complicated to deal with!
                  regexp = "\\"+concatenationChar;
               } else {
                  regexp = concatenationChar;
               }

            }
            else {
                concatenationChar = ";";
                regexp = ";";
            }
        }

        /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#getSqlType()
         */
        @Override
        public int getSqlType() {
            return Types.VARCHAR;
        }



        /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#returnedClass()
         */
        @Override
        @SuppressWarnings({ "unchecked", "rawtypes" })
        public Class<List<T>> returnedClass() {
            return (Class<List<T>>) ((Class)List.class);
        }



        /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#equals(java.lang.Object, java.lang.Object)
         */
        @Override
        public boolean equals(List<T> x, List<T> y) {
            return Objects.equals(x, y);
        }




        /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#hashCode(java.lang.Object)
         */
        @Override
        public int hashCode(List<T> x) {
            return Objects.hashCode(x);
        }


    /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#nullSafeSet(java.sql.PreparedStatement, java.lang.Object, int, org.hibernate.engine.spi.SharedSessionContractImplementor)
         */
        @Override
        public void nullSafeSet(PreparedStatement st, List<T> value,
                int index, SharedSessionContractImplementor session)
                        throws SQLException {
            if (value == null || value.isEmpty())
            {
                st.setNull(index, Types.VARCHAR);
            }
            else {
                String dbval = value.stream().map(T::toString).collect(Collectors.joining (concatenationChar)); 
                st.setString(index, dbval);
            }

        }



  


        /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#isMutable()
         */
        @Override
        public boolean isMutable() {

            return false;            
        }

        /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#disassemble(java.lang.Object)
         */
        @Override
        public Serializable disassemble(List<T> value) {
            // not implemented on purpose
            throw new  UnsupportedOperationException("UserType<List<String>>.disassemble() not implemented");

        }

        /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#assemble(java.io.Serializable, java.lang.Object)
         */
        @Override
        public List<T> assemble(Serializable cached, Object owner) {
            // not implemented on purpose
            throw new  UnsupportedOperationException("UserType<List<String>>.assemble() not implemented");

        }




    }

    /**
     * A converter for string lists .
     * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
     * 
     */
    public static class StringListConverter extends ListConcatenatedType<String> {

        /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#nullSafeGet(java.sql.ResultSet, int, org.hibernate.engine.spi.SharedSessionContractImplementor, java.lang.Object)
         */

        @Override
        public List<String> nullSafeGet(ResultSet rs, int position,
                SharedSessionContractImplementor session, Object owner)
                        throws SQLException {
            String dbData = rs.getString(position);
            return dbData != null ? Arrays.asList(dbData.split(regexp)) : new ArrayList<String>() ;


        }

        /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#deepCopy(java.lang.Object)
         */
        @Override
        public List<String> deepCopy(List<String> value) {

                 return value!= null ? value.stream().map(String::new).collect(Collectors.toList()): null;
        }
  


    }

   
    /**
     * A converter for Integers.
     * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
     * 
     */
    public static class IntListConverter extends ListConcatenatedType<Integer>
    {

         /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#deepCopy(java.lang.Object)
         */
        @Override
        public List<Integer> deepCopy(List<Integer> value) {
                 return value.stream().map(Integer::valueOf).collect(Collectors.toList());
        }
  
         /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#nullSafeGet(java.sql.ResultSet, int, org.hibernate.engine.spi.SharedSessionContractImplementor, java.lang.Object)
         */

        @Override
        public List<Integer> nullSafeGet(ResultSet rs, int position,
                SharedSessionContractImplementor session, Object owner)
                        throws SQLException {
            String dbData = rs.getString(position);
            return dbData != null ?  Stream.of(dbData.split(regexp)).map(Integer::parseInt).toList() : new ArrayList<Integer>() ;

        }
   
    }
    /**
     *  A converter for doubles.
     * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
     * 
     */
    public static class DoubleListConverter extends ListConcatenatedType<Double>
    {

         /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#deepCopy(java.lang.Object)
         */
        @Override
        public List<Double> deepCopy(List<Double> value) {
                 return value.stream().map(Double::valueOf).collect(Collectors.toList());
        }
  
         /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#nullSafeGet(java.sql.ResultSet, int, org.hibernate.engine.spi.SharedSessionContractImplementor, java.lang.Object)
         */

        @Override
        public List<Double> nullSafeGet(ResultSet rs, int position,
                SharedSessionContractImplementor session, Object owner)
                        throws SQLException {
            String dbData = rs.getString(position);
            return dbData != null ?  Stream.of(dbData.split(regexp)).map(Double::parseDouble).toList() : new ArrayList<Double>() ;

        }
 
    }

    /**
     * A converter for booleans.
     * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
     * 
     */
    public static class BooleanListConverter extends ListConcatenatedType<Boolean> 
    {

         /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#deepCopy(java.lang.Object)
         */
        @Override
        public List<Boolean> deepCopy(List<Boolean> value) {
                 return value.stream().map(Boolean::valueOf).collect(Collectors.toList());
        }
  
         /**
         * {@inheritDoc}
         * overrides @see org.hibernate.usertype.UserType#nullSafeGet(java.sql.ResultSet, int, org.hibernate.engine.spi.SharedSessionContractImplementor, java.lang.Object)
         */

        @Override
        public List<Boolean> nullSafeGet(ResultSet rs, int position,
                SharedSessionContractImplementor session, Object owner)
                        throws SQLException {
            String dbData = rs.getString(position);
            return dbData != null ?  Stream.of(dbData.split(regexp)).map(Boolean::parseBoolean).toList() : new ArrayList<Boolean>() ;

        }
 

    }
}


