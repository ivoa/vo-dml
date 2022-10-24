/*
 * Created on 31 Aug 2021 
 * Copyright 2021 Paul Harrison (paul.harrison@manchester.ac.uk)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License in file LICENSE
 */

package org.ivoa.vodml.nav;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Deque;
import java.util.HashMap;
import java.util.IdentityHashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import org.ivoa.vodml.annotation.VoDml;

/**
 * Traverses a VODML model instance tree and executes a visitor.
 * Uses introspection of the {@link VoDml} annotation on the class members.
 * 
 * @author Paul Harrison (paul.harrison@manchester.ac.uk)
 * @since 31 Aug 2021
 */
public class ModelInstanceTraverser {

    /** logger for this class */
    private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory
            .getLogger(ModelInstanceTraverser.class);

    /**
     * Simple visitor that is only fired at start.
     * Useful for e.g. just enumerating the types used.
     *
     */ 
    @FunctionalInterface
    public interface Visitor {

        /**
         * perform an action at the start of an object instance.
         * @param o the object.
         * @param v the vodml model information for the object.
         * @param firstVisit if true this is the first visit to this particular instance.
         */
        void startInstance(final Object o, final VodmlTypeInfo v, boolean firstVisit );
    }

    public interface FullVisitor extends Visitor {
        /**
         * perform an action on a "leaf" object i.e. has no model children.
         * @param o the object.
         * @param v  the vodml model information for the object.
         * @param firstVisit if true this is the first visit to this particular instance.
         */
        void leaf(final Object o, final VodmlTypeInfo v, boolean firstVisit );
        /**
         * perform an action at the end of the instance.
         * @param o the object.
         * @param v  the vodml model information for the object.
         * @param firstVisit if true this is the first visit to this particular instance.
         */
        void endInstance(final Object o, final VodmlTypeInfo v, boolean firstVisit);
    }

    private final Map<Object, VodmlTypeInfo> objVisited = new IdentityHashMap<>();
    private final Map<Class<?>, ClassInfo> classCache = new HashMap<>();

    public static FullVisitor makeFullVisitor (Visitor vis) {
        return new FullVisitor() {

            @Override
            public void startInstance(Object o, VodmlTypeInfo v, boolean firstVisit) {
                vis.startInstance(o, v, firstVisit);
            }

            @Override
            public void leaf(Object o, VodmlTypeInfo v, boolean firstVisit) {
                // do nothing
            }

            @Override
            public void endInstance(Object o, VodmlTypeInfo v, boolean firstVisit) {
                // do nothing
            }
        };
    }
    /**
     * @param o Any Java Object
     * @param visitor Visitor is called for every object encountered during
     * the Java object graph traversal.
     */
    public static void traverse(Object o,  Visitor visitor)
    {
        ModelInstanceTraverser traverse = new ModelInstanceTraverser();
        traverse.walk(o, makeFullVisitor(visitor));
        traverse.objVisited.clear();
        traverse.classCache.clear();
    }
    public static void traverse(Object o,  FullVisitor visitor)
    {
        ModelInstanceTraverser traverse = new ModelInstanceTraverser();
        traverse.walk(o, visitor);
        traverse.objVisited.clear();
        traverse.classCache.clear();
    }

    /**
     * Traverse the object graph referenced by the passed in root.
     * @param root An instance of an object from a VODML generated model.
     * @param leaf Set of classes to skip (ignore).  Allowed to be null.
     */
    private void walk(Object root, FullVisitor visitor)
    {
        Deque<ObjInfo> stack = new LinkedList<>();
        final ObjInfo oiroot = new ObjInfo(root);
        stack.add(oiroot);
        visitor.startInstance(root, oiroot.ob.vodmlt, !oiroot.isReference);    

        while (!stack.isEmpty())
        {
            ObjInfo oi = stack.peekLast();
            Object current = oi.ob.o;

            if (current == null )
            {
                stack.removeLast();
                continue;
            }

            if(objVisited.containsKey(current))
            {
                logger.info("already visited {}",current.toString());
                stack.removeLast();
                continue; //if the object has been visited before do not process the children again.
            }
            if(oi.children.hasNext())
            {
                ObjBase next = oi.children.next();
                if(next != null) { // IMPL for now ignore nulls, but might want to include in some serializations.
                    if(next.c.leaf)
                    {
                        visitor.leaf(next.o,next.vodmlt,!objVisited.containsKey(next.o));
                    }
                    else {
                        final ObjInfo loi = new ObjInfo(next.o);
                        visitor.startInstance(next.o, next.vodmlt, !loi.isReference);    
                        stack.add(loi);
                    }
                }
            }
            else
            {
                visitor.endInstance(current, oi.ob.vodmlt, !oi.isReference);  
                objVisited.put(current, oi.ob.vodmlt);
                stack.removeLast(); //discard as this object has been finished.
            }

        }
    }




    private ClassInfo getClassInfo(Object o)
    {
        Class<? extends Object> current = o.getClass();
        ClassInfo cc = classCache.get(current);
        if (cc != null)
        {
            return cc;
        }

        cc = new ClassInfo(o);
        classCache.put(current, cc);
        return cc;
    }
    private static boolean donotexaminefields(Class<?> c) {
        return c.isPrimitive()||c.isEnum() || c.getCanonicalName().startsWith("java");
    }

    private class ObjBase {
        final Object o;
        final VodmlTypeInfo vodmlt;
        final ClassInfo c;
        public ObjBase(Object o) {
            this.o = o;
            this.c = getClassInfo(o);
            if(!donotexaminefields(c.clazz))
                this.vodmlt = new ReflectIveVodmlTypeGetter(o.getClass()).vodmlInfo();
            else
                this.vodmlt = null;
        }
        public ObjBase(Object o,VodmlTypeInfo t ) {
            this.o = o;
            this.c = getClassInfo(o);

            this.vodmlt = t;
        }


    }

    private class ObjInfo {
        final Iterator<ObjBase> children;
        final boolean isReference;
        final ObjBase ob;
        @SuppressWarnings({ "unchecked", "rawtypes" })
        public ObjInfo(Object inobj) {
            this.ob = new ObjBase(inobj);
            if(objVisited.containsKey(inobj))
            {
                logger.trace("object {} has already been visited");
                children = new ArrayList().iterator(); //nothing
                isReference = true;
            }
            else {
                isReference = false;


                if(ob.o.getClass().isArray()) { //FIXME think about arrays of primitives.... not yet in out models...
                    children = Arrays.stream((Object[]) ob.o).map(ao->{return ao != null ? new ObjBase(ao): null;}).iterator();
                }
                else if(ob.o instanceof Collection) {
                    Collection<Object> col = (Collection<Object>) ob.o;
                    List<ObjBase> vals = new ArrayList<>(col.size());  
                    col.forEach(co -> {if (co != null)vals.add(new ObjBase(co));});
                    children = vals.iterator();

                } else if (ob.o instanceof Map) { ///IMPL there are actually no maps created by current model generation....
                    Map m = ((Map) ob.o);
                    List<ObjBase> vals = new ArrayList<>(m.size()*2);   
                    m.forEach((t, u) -> {vals.add(new ObjBase(t));vals.add(new ObjBase(u));});
                    children = vals.iterator();

                } else if (!ob.c.leaf)
                {
                    List<ObjBase> vals = new ArrayList<>(ob.c.refFields.size());   
                    for (Field field : ob.c.refFields)
                    {
                        try
                        {
                            Object value = field.get(ob.o);
                            if(value!= null && field.isAnnotationPresent(VoDml.class))
                            {
                                vals.add(new ObjBase(value, new ReflectIveVodmlTypeGetter(field).vodmlInfo()));
                            }
                            else {
                                logger.debug("field {} ignored as it is NULL or has no VO-DML type information", field); //IMPL might want to have a special annotation to indicated where a key has been added...
                            }
                        }
                        catch (IllegalAccessException ignored) {
                            logger.warn("ignored exception", ignored);
                        }
                    }
                    children = vals.iterator();

                } else
                {
                    children = new ArrayList().iterator(); //nothing
                }
            }

        }



    }

    /**
     * This class wraps a class in order to cache the fields so they
     * are only reflectively obtained once.
     */
    private static class ClassInfo
    {

        boolean leaf = false;
        boolean container = false;
        final Collection<Field> refFields = new ArrayList<>();
        final Class<?> clazz;

        public ClassInfo(Object o)
        {
            clazz = o.getClass();
            if (donotexaminefields(clazz))
            {
                if(clazz.isArray() || o instanceof Collection<?> || o instanceof Map<?, ?>)
                {
                    this.container = true;
                }
                else {
                    this.leaf = true;
                }
                return; // don't examine fields
            }

            Collection<Field> fields = getDeepDeclaredFields(clazz);
            for (Field field : fields)
            {
                this.refFields.add(field);
            }
        }



        private static Collection<Field> getDeepDeclaredFields(Class<?> c)
        {
            Collection<Field> fields = new ArrayList<>();
            Class<?> curr = c;

            while (curr != null)
            {
                if(!donotexaminefields(curr)) {
                    getDeclaredFields(curr, fields);
                }
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

}


