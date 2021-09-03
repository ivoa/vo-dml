/*
 * Created on 31 Aug 2021 
 * Copyright 2021 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */

package org.ivoa.vodml.nav;

import java.lang.reflect.Array;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Deque;
import java.util.HashMap;
import java.util.IdentityHashMap;
import java.util.LinkedList;
import java.util.Map;

import org.ivoa.vodml.annotation.VoDml;

/**
 * Traverses a VODML model instance tree and executes a visitor.
 * Uses introspection of the {@link VoDml} annotation on the class members.
 * 
 * FIXME still need to decide what is best to do with some of the Java primitive types that are encountered - e.g. as the value of VODML primitiveTypes
 * 
 * @author Paul Harrison (paul.harrison@manchester.ac.uk)
 * @since 31 Aug 2021
 */
public class ModelInstanceTraverser {

    /** logger for this class */
    private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
            .getLogger(ModelInstanceTraverser.class);
    
    /**
     * The visitor that is used in the traversal.
     *
     */ 
    @FunctionalInterface
    public interface Visitor {
        
        /**
         * perform an action on an object.
         * @param o the object.
         * @param v the vodml model information for the object.
         */
        void process(final Object o, final VodmlTypeInfo v );
    }
    
    private final Map<Object, VodmlTypeInfo> objVisited = new IdentityHashMap<>();
    private final Map<Class<?>, ClassInfo> classCache = new HashMap<>();

    
    /**
     * @param o Any Java Object
     * @param visitor Visitor is called for every object encountered during
     * the Java object graph traversal.
     */
    public static void traverse(Object o, Visitor visitor)
    {
        traverse(o, null, visitor);
    }

    /**
     * @param o Any Java Object
     * @param skip Class[] of classes to not include in the traversal.
     * @param visitor Visitor is called for every object encountered during
     * the Java object graph traversal.
     */
    public static void traverse(Object o, Class<?>[] skip, Visitor visitor)
    {
        ModelInstanceTraverser traverse = new ModelInstanceTraverser();
        traverse.walk(o, skip, visitor);
        traverse.objVisited.clear();
        traverse.classCache.clear();
    }

    /**
     * Traverse the object graph referenced by the passed in root.
     * @param root An instance of an object from a VODML generated model.
     * @param skip Set of classes to skip (ignore).  Allowed to be null.
     */
    private void walk(Object root, Class<?>[] skip, Visitor visitor)
    {
        Deque<ObjInfo> stack = new LinkedList<>();
        stack.add(new ObjInfo(root, root.getClass()));

        while (!stack.isEmpty())
        {
            ObjInfo oi = stack.removeLast();
            Object current = oi.o;

            if (current == null || objVisited.containsKey(current))
            {
                continue;
            }

            final Class clazz = current.getClass();
            ClassInfo classInfo = getClassInfo(clazz, skip);
            if (classInfo.skip)
            {  // Do not process any classes that are assignableFrom the skip classes list.
                continue;
            }

            objVisited.put(current, oi.t);
            visitor.process(current, oi.t);

            if (clazz.isArray()) //IMPL still need to decide on array handling....
            {
                final int len = Array.getLength(current);
                Class compType = clazz.getComponentType();

                if (!compType.isPrimitive())
                {   // do not walk primitives
                    ClassInfo info = getClassInfo(compType, skip);
                    if (!info.skip) // Do not walk array elements of a class type that is to be skipped.
                    {   
                        for (int i=0; i < len; i++)
                        {
                            Object element = Array.get(current, i);
                            if (element != null)// Skip processing null array elements
                            {   
                                stack.add(new ObjInfo(Array.get(current, i),compType));
                            }
                        }
                    }
                }
                else {
                    logger.debug("{} is primitive",compType.toString());
                }
            }
            else
            {   // Process fields of an object instance
                if (current instanceof Collection)
                {
                    walkCollection(stack, (Collection) current);
                }
                else if (current instanceof Map)
                {
                    walkMap(stack, (Map) current);
                }
                else
                {
                    walkFields(stack, current, skip);
                }
            }
        }
    }

    private void walkFields(Deque<ObjInfo> stack, Object current, Class<?>[] skip)
    {
        ClassInfo classInfo = getClassInfo(current.getClass(), skip);

        for (Field field : classInfo.refFields)
        {
            try
            {
                Object value = field.get(current);
               
                if ( field.getAnnotation(VoDml.class) == null ) 
                {
                    final Class<?> declaringClass = field.getDeclaringClass();
                    if(!declaringClass.equals(String.class) && field.getAnnotation(javax.persistence.Id.class) == null) { // only report for things that we don't "know" about
                        logger.debug("{} is not a model element in {}", field.getName(), declaringClass.getCanonicalName());
                    }
                    continue;
                }
                stack.add(new ObjInfo(value, field));
            }
            catch (IllegalAccessException ignored) {
                logger.warn("ignored exceotion", ignored);
            }
        }
    }

    private static void walkCollection(Deque<ObjInfo> stack, Collection<?> col)
    {
        for (Object o : col)
        {
            if (o != null && !o.getClass().isPrimitive())
            {
                stack.add(new ObjInfo(o, o.getClass()));
            }
        }
    }

    ///impl there are actually no maps created by model generation....
    private static void walkMap(Deque<ObjInfo> stack, Map<?, ?> map)
    {
        for (Map.Entry entry : map.entrySet())
        {
            Object o = entry.getKey();

            if (o != null && !o.getClass().isPrimitive())
            {
                Object v = entry.getValue();
                stack.add(new ObjInfo(o, o.getClass()));
                stack.add(new ObjInfo(v, v.getClass()));
            }
        }
    }

    private ClassInfo getClassInfo(Class<?> current, Class<?>[] skip)
    {
        ClassInfo cc = classCache.get(current);
        if (cc != null)
        {
            return cc;
        }

        cc = new ClassInfo(current, skip);
        classCache.put(current, cc);
        return cc;
    }
    
    private static class ObjInfo {
        public ObjInfo(Object o, Class c) {
            this.o = o;
            t = new ReflectIveVodmlTypeGetter(c).vodmlInfo();
        }
        /**
         * @param value
         * @param field
         */
        public ObjInfo(Object o, Field field) {
            this.o = o;
            t = new ReflectIveVodmlTypeGetter(field).vodmlInfo();
           
        }
        final Object o;
        final VodmlTypeInfo t;
        
        
    }

    /**
     * This class wraps a class in order to cache the fields so they
     * are only reflectively obtained once.
     */
    private static class ClassInfo
    {
        private boolean skip = false;
        private final Collection<Field> refFields = new ArrayList<>();

        public ClassInfo(Class<?> c, Class<?>[] skip)
        {
            if (skip != null)
            {
                for (Class<?> klass : skip)
                {
                    if (klass.isAssignableFrom(c))
                    {
                        this.skip = true;
                        return;
                    }
                }
            }

            Collection<Field> fields = getDeepDeclaredFields(c);
            for (Field field : fields)
            {
                Class<?> fc = field.getType();

                if (!fc.isPrimitive())
                {
                    this.refFields.add(field);
                }
            }
        }
    }
    
   private static Collection<Field> getDeepDeclaredFields(Class<?> c)
    {
        Collection<Field> fields = new ArrayList<>();
        Class<?> curr = c;

        while (curr != null)
        {
            getDeclaredFields(curr, fields);
            curr = curr.getSuperclass();
        }
        return fields;
    }


   
    private static void getDeclaredFields(Class<?> c, Collection<Field> fields) {
        try
        {
            Field[] local = c.getDeclaredFields();

            for (Field field : local)
            {
                try
                {
                    field.setAccessible(true); // if we want to try to set via reflection?
                }
                catch (Exception ignored) {
                    logger.warn("ignored exception", ignored); // not sure
                }

                int modifiers = field.getModifiers();
                if (!Modifier.isStatic(modifiers) &&
                        !field.getName().startsWith("this$"))
                {   // not count static fields, do not go back up to enclosing object in nested case, do not consider transients
                    fields.add(field);
                }
            }
        }
        catch (Throwable ignored)
        {
            throw new RuntimeException("exception in model reflection code ", ignored);
        }
    }
 
}


