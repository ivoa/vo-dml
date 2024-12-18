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
import org.ivoa.vodml.annotation.VodmlRole;

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

    /**
     * A visitor with more action points.
     * @author Paul Harrison (paul.harrison@manchester.ac.uk) 
     * 
     */
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
    private Deque<ObjInfo> stack;

    /**
     * 
     */
    public ModelInstanceTraverser() {
        stack = new LinkedList<>();
    }
    /**
     * Create a full visitor from a visitor.
     * @param vis the visitor.
     * @return the FullVisitor.
     */
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
        traverse(o,makeFullVisitor(visitor));
    }
    /**
     * Traverse an object tree with a FullVisitor.
     * @param o the base of the object tree.
     * @param visitor the FullVisitor.
     */
    public static void traverse(Object o,  FullVisitor visitor)
    {
        ModelInstanceTraverser traverser = new ModelInstanceTraverser();
        ObjInfo oi = traverser.new ObjInfo(o);
        traverser.walk(oi, visitor);
    }
    /**
     * Traverse a list of object trees with a Visitor.
     * @param o the list of object trees.
     * @param visitor the Visitor.
     */
    public static void traverse(List<Object> o,  Visitor visitor)
    {
        traverse(o,makeFullVisitor(visitor));
    }
     /**
     * Traverse a list of object trees with a FullVisitor.
     * @param o the list of object trees.
     * @param visitor the FullVisitor.
     */
    public static void traverse(List<Object> o ,  FullVisitor visitor)
    {
        ModelInstanceTraverser traverser = new ModelInstanceTraverser();
        ObjInfo oi = traverser.new ObjInfo(o, new VodmlTypeInfo("", VodmlRole.model)); //IMPL this is a bit ugly - perhaps change the API to have the modelManagement as single entry point
        traverser.walk(oi, visitor);
    }

    /**
     * Traverse the object graph referenced by the passed in root.
     * @param root An instance of an object from a VODML generated model.
     * @param visitor The visitor.
     */
    private void walk( ObjInfo oiroot, FullVisitor visitor)
    {

        stack.add(oiroot);
        visitor.startInstance(oiroot.ob.o, oiroot.ob.vodmlt, !oiroot.alreadyVisited);    

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
                logger.debug("already visited {}",current.toString());
                stack.removeLast();
                continue; //if the object has been visited before do not process the children again.
            }
            if(oi.children.hasNext())
            {
                ObjBase next = oi.children.next();
                if(next.vodmlt.role == VodmlRole.attribute && next.vodmlt.vodmlTypeRole == VodmlRole.primitiveType) 
                {
                    visitor.leaf(next.o,next.vodmlt,!objVisited.containsKey(next.o));
                }
                else {
                    final ObjInfo loi = new ObjInfo(next.o,next.vodmlt);
                    visitor.startInstance(next.o, next.vodmlt, !loi.alreadyVisited);    
                    stack.add(loi);
                }
            }
            else
            {
                visitor.endInstance(current, oi.ob.vodmlt, !oi.alreadyVisited);  
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
    private class ObjBase {
        final Object o;
        final VodmlTypeInfo vodmlt;
        final ClassInfo c;
        public ObjBase(Object o) {
            this (o,
                    getClassInfo(o),
                    new ReflectIveVodmlTypeGetter(o.getClass()).vodmlInfo());

        }
        public ObjBase(Object o,VodmlTypeInfo t ) {
            this( o, getClassInfo(o), t);

        }

        private ObjBase(Object o, ClassInfo c, VodmlTypeInfo vodmlt) {
            this.o = o;
            this.vodmlt = vodmlt;
            this.c = c;

        }
    }

    private class ObjInfo {
        final Iterator<ObjBase> children;
        final boolean alreadyVisited;
        final ObjBase ob;
        public ObjInfo(Object o, VodmlTypeInfo t) {
            this(new ObjBase(o, t));
        }
        /**
         * @param o
         */
        public ObjInfo(Object o) {
            this(new ObjBase(o));
        }
        @SuppressWarnings({ "unchecked", "rawtypes" })
        private ObjInfo(ObjBase inob) {
            this.ob = inob;
            if(objVisited.containsKey(ob.o))
            {
                logger.trace("object {} has already been visited");
                children = new ArrayList<ObjBase>().iterator(); //nothing
                alreadyVisited = true;

            }
            else {
                alreadyVisited = false;

                if(ob.o.getClass().isArray()) { //FIXME think about arrays of primitives.... not yet in our models...
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

                } else if (ob.vodmlt.role != VodmlRole.primitiveType)
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
                    children = new ArrayList<ObjBase>().iterator(); //nothing
                }
            }

        }

        /**
          constructor for when the object is null.
         */
        public ObjInfo(ClassInfo c, VodmlTypeInfo vodmlt)
        {
            ob = new ObjBase(null,c, vodmlt);
            children = new ArrayList<ObjBase>().iterator(); //nothing
            alreadyVisited = false;
        }



    }
    private static boolean donotexaminefields(Class<?> c) {
        //note that this could probably just be whether the class has a VODML annotation or not - although there are annotated enums generated
        return c.isPrimitive()||c.isEnum() || c.getCanonicalName().startsWith("java")||c.getAnnotation(VoDml.class)==null;
    }


    /**
     * This class wraps a class in order to cache the fields so they
     * are only reflectively obtained once.
     */
    private static class ClassInfo
    {

        boolean container = false; //IMPL  not actually used
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


