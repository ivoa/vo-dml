
package org.ivoa.vodml.stdtypes;


import javax.persistence.Embeddable;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;


/**
*  Must conform to definition of unit in VOUnit spec.
*  PrimitiveType Unit :
*
*  @author generated by https://github.com/ivoa/vo-dml tools
*/

@org.ivoa.vodml.annotation.VoDml(id="ivoa:Unit", role=org.ivoa.vodml.annotation.VodmlRole.primitiveType)
@Embeddable

@javax.xml.bind.annotation.XmlType( name = "Unit")
@XmlAccessorType(XmlAccessType.FIELD)
public class Unit implements java.io.Serializable {

  private static final long serialVersionUID = 1L;

  /**  representation */
  @javax.xml.bind.annotation.XmlValue
  private String value;

  /**
   * Creates a new Unit Primitive Type instance, wrapping a base type.
   *
   * @param v
   */
  public Unit(final String v) {
      this.value = v;
  }
  /**
   * no arg constructor.
   */
  protected Unit() {}

  /**
   * Return the representation of this primitive (value)
   * @return string representation of this primitive( value)
   */
  public final String value() {
      return this.value;
  }

  /**
   * Return the string representation of this primitive value
   * @see #value()
   * @return string representation of this primitive
   */
  @Override
  public final String toString() {
      return value().toString();
  }


}
  