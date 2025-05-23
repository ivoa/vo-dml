package org.ivoa.dm.serializationsample;

import static org.junit.jupiter.api.Assertions.fail;

import org.ivoa.dm.serializationsample.types.BaseC;
import org.ivoa.dm.serializationsample.types.Econt;
import org.junit.jupiter.api.Test;

import jakarta.persistence.EntityManager;

/*
 * Created on 16/05/2023 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */
public class SerializationExampleVocabTest {
   
  
  @Test
  public void testConstructor() {
    try {
        new Econt("an E", "eval");
        fail("should have thown exception for value outside vocab");
    } catch (Exception e) {
        // it should throw exception
    }
  }
  
 @Test
  public void testSuperConstructor() {
    try {
        new Econt(new BaseC() {
            
            @Override
            public BaseC copyMe() {
                // TODO Auto-generated method stub
                throw new UnsupportedOperationException(
                        "Type1728055728713.copyMe() not implemented");
                
            }

            @Override
            public void delete(EntityManager em) {
                // TODO Auto-generated method stub
                throw new  UnsupportedOperationException("JPAManipulationsForObjectType<Long>.delete() not implemented");
                
            }
        }, "eval");
        fail("should have thown exception for value outside vocab");
    } catch (Exception e) {
        // it should throw exception
    }
  }
   
}
