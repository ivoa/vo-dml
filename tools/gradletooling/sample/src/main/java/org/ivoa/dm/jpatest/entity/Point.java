package org.ivoa.dm.jpatest.entity;

import org.geolatte.geom.G2D;

import static org.geolatte.geom.builder.DSL.g;
import static org.geolatte.geom.builder.DSL.point;
import static org.geolatte.geom.crs.CoordinateReferenceSystems.WGS84;

/**
 * A test "point" class. Note that this is hacked to "work" (in the sense of allowing tests to pass)
 * with minimal effort
 *
 * <p>dataType: Point
 *
 * @author Paul Harrison
 */

@jakarta.xml.bind.annotation.XmlAccessorType(jakarta.xml.bind.annotation.XmlAccessType.NONE)
@jakarta.xml.bind.annotation.XmlType(name = "Point")
@com.fasterxml.jackson.annotation.JsonTypeInfo(
    use = com.fasterxml.jackson.annotation.JsonTypeInfo.Id.NONE)

// @jakarta.xml.bind.annotation.XmlRootElement( name = "Point")

@org.ivoa.vodml.annotation.VoDml(
    id = "jpatest:Point",
    role = org.ivoa.vodml.annotation.VodmlRole.dataType)
@org.eclipse.microprofile.openapi.annotations.media.Schema(description = "")
public class Point  implements org.ivoa.vodml.jpa.JPAManipulations  {

  /** . : Attribute x : multiplicity 1 */
  @org.ivoa.vodml.annotation.VoDml(
      id = "jpatest:Point.x",
      role = org.ivoa.vodml.annotation.VodmlRole.attribute,
      type = "ivoa:real",
      typeRole = org.ivoa.vodml.annotation.VodmlRole.primitiveType)
  @org.eclipse.microprofile.openapi.annotations.media.Schema(description = "")
  @jakarta.xml.bind.annotation.XmlElement(name = "x", required = true, type = Double.class)
  
  @jakarta.persistence.Transient
  protected Double x;

  /** . : Attribute y : multiplicity 1 */
  @org.ivoa.vodml.annotation.VoDml(
      id = "jpatest:Point.y",
      role = org.ivoa.vodml.annotation.VodmlRole.attribute,
      type = "ivoa:real",
      typeRole = org.ivoa.vodml.annotation.VodmlRole.primitiveType)
  @org.eclipse.microprofile.openapi.annotations.media.Schema(description = "")
  @jakarta.xml.bind.annotation.XmlElement(name = "y", required = true, type = Double.class)

  @jakarta.persistence.Transient
  protected Double y;

  /** Creates a new Point */
  public Point() {
    super();
  }

  /**
   * full parameter constructor.
   *
   * @param x .
   * @param y .
   */
  public Point(final Double x, final Double y) {
    super();

    this.x = x;

    this.y = y;
  }

  /**
   * Copy Constructor. Note that references will remain as is rather than be copied.
   *
   * @param other the object to be copied.
   */
  public Point(final Point other) {

    super();

    this.x = other.x;

    this.y = other.y;
  }


  /**
   * Update this object with the content of the given object. Note that references will remain as is
   * rather than be copied.
   *
   * @param other the object to be copied.
   */
  public void updateUsing(final Point other) {

    this.x = other.x;

    this.y = other.y;
  }

  /**
   * Returns x Attribute.
   *
   * @return x Attribute
   */
  public Double getX() {
    return (Double) this.x;
  }

  /**
   * Set x Attribute.
   *
   * @param pX value to set
   */
  public void setX(final Double pX) {

    this.x = pX;
  }

  /**
   * fluent setter for x Attribute.
   *
   * @param pX value to set
   * @return Point
   */
  public Point withX(final Double pX) {
    setX(pX);
    return this;
  }

  /**
   * Returns y Attribute.
   *
   * @return y Attribute
   */
  public Double getY() {
    return (Double) this.y;
  }

  /**
   * Set y Attribute.
   *
   * @param pY value to set
   */
  public void setY(final Double pY) {

    this.y = pY;
  }

  /**
   * fluent setter for y Attribute.
   *
   * @param pY value to set
   * @return Point
   */
  public Point withY(final Double pY) {
    setY(pY);
    return this;
  }

  /** A builder class for Point, mainly for use in the functional builder pattern. */
  public static class PointBuilder {

    /** . */
    public Double x;

    /** . */
    public Double y;

    private PointBuilder with(java.util.function.Consumer<PointBuilder> f) {
      f.accept(this);
      return this;
    }

    /**
     * create a Point from this builder.
     *
     * @return an object initialized from the builder.
     */
    public Point create() {
      return new Point(x, y);
    }
  }

  /**
   * create a Point in functional builder style.
   *
   * @param f the functional builder.
   * @return an object initialized from the builder.
   */
  public static Point createPoint(java.util.function.Consumer<PointBuilder> f) {
    return new PointBuilder().with(f).create();
  }

  @Override
  public void forceLoad() {}

  @Override
  public boolean equals(Object o_) {
    if (!(o_ instanceof Point oc_)) return false;

    boolean retval = java.util.Objects.equals(x, oc_.x) && java.util.Objects.equals(y, oc_.y);

    return retval;
  }

  @Override
  public int hashCode() {

    return java.util.Objects.hash(x, y);
  }
}
