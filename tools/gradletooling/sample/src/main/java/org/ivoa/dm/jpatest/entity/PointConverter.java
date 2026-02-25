package org.ivoa.dm.jpatest.entity;


/*
 * Created on 24/02/2026 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

import jakarta.persistence.AttributeConverter;
import org.geolatte.geom.G2D;

import static org.geolatte.geom.builder.DSL.g;
import static org.geolatte.geom.builder.DSL.point;
import static org.geolatte.geom.crs.CoordinateReferenceSystems.WGS84;

public class PointConverter implements AttributeConverter<Point, org.geolatte.geom.Point<G2D>> {
   @Override
   public org.geolatte.geom.Point<G2D> convertToDatabaseColumn(Point point) {
      return point(WGS84,g(point.x,point.y));
   }

   @Override
   public Point convertToEntityAttribute(org.geolatte.geom.Point<G2D> g2DPoint) {
      return new Point(g2DPoint.getPosition().getCoordinate(0), g2DPoint.getPosition().getCoordinate(1));
   }
}
