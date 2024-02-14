package org.ivoa.vodml;
/*
 * Created on 12/02/2024 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import org.ivoa.vodml.nav.ReferenceCache;

import java.util.Map;
import java.util.Set;

public class ModelContext {
    private ModelContext() {
    };

    private static ModelContext instance;

    public ModelContext(Map<Class, ReferenceCache> mm) {
        this.mm = mm;
    }

    private Map<Class, ReferenceCache> mm;

    public static ModelContext current() {
        if (instance != null)
            return instance;
        else
            throw new IllegalStateException("the context has not been set");
    }

    public static  void create(Map<Class, ReferenceCache> m) {
        instance = new ModelContext(m);
    }

    @SuppressWarnings("unchecked")
    public <T> ReferenceCache<T> cache(Class<T> clazz) {
        return mm.get(clazz);
    }

    /**
     * @return
     */
    @SuppressWarnings("rawtypes")
    public Set<Class> containedRefs() {
       return mm.keySet();
        
    }
   

}
