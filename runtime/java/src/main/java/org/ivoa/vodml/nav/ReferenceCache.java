package org.ivoa.vodml.nav;
/*
 * Created on 12/02/2024 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import java.util.HashMap;
import java.util.List;
import java.util.Map;


public class ReferenceCache <T> {
    
   private Map<T, T> valmap = new HashMap<>(); 
   
  public  void setValues(List<T> inital, List<T> cloned)
   {
       for (int i = 0; i < inital.size(); i++) {
       valmap.put(inital.get(i), cloned.get(i)) ;  
    }
   }

/**
 * @param refcont
 * @return
 */
   public T get(T initial) {
   return valmap.get(initial);
}
  


}
