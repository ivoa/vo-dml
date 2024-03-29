from __future__ import annotations
import dataclasses
from typing import Optional, List, Tuple, Any
from datetime import datetime
import unittest


from xsdata.formats.dataclass.serializers import XmlSerializer
from xsdata.formats.dataclass.context import XmlContext
from xsdata.formats.dataclass.serializers.config import SerializerConfig

from sqlalchemy import create_engine, Identity, Table
from sqlalchemy.orm import Session
from sqlalchemy.orm import DeclarativeBase, Mapped
from sqlalchemy.orm import relationship, composite,mapped_column
from sqlalchemy import Column, ForeignKey, Integer, String, DateTime, Double

from sqlalchemy.orm import registry

mapper_registry = registry()

@dataclasses.dataclass
class Point:
    x: int
    y: int
    def __composite_values__(self) -> Tuple[Any, ...]:
        """generate a row from a  CircleError"""
        return  self.x, self.y

@dataclasses.dataclass
class Vertex:
    start: Point
    end: Point
    @classmethod
    def _generate(cls, x1: int, y1: int, x2: int, y2: int) -> Vertex:
        """generate a Vertex from a row"""
        return Vertex(Point(x1, y1), Point(x2, y2))

    def __composite_values__(self) -> Tuple[Any, ...]:
        """generate a row from a Vertex"""
        return dataclasses.astuple(self.start) + dataclasses.astuple(self.end)

@mapper_registry.mapped
@dataclasses.dataclass
class HasVertex:
    __table__ = Table("vertices", mapper_registry.metadata,
                      Column("id",Integer,Identity(),primary_key=True),
                      Column("x1", Integer),
                      Column("y1", Integer),
                      Column("x2", Integer),
                      Column("y2", Integer),
                      )
    __sa_dataclass_metadata_key__ = "sa"

    id: int = dataclasses.field(init=False,
                                         metadata={
                                             "sa": __table__.c.id
                                         }
                                         )

    vx: Vertex = dataclasses.field(metadata={
        "sa": composite(Vertex._generate,__table__.c.x1,__table__.c.y1,__table__.c.x2,__table__.c.y2)
    }
    )

    def __repr__(self):
        return f"Vertex(start={self.vx.start}, end={self.vx.end})"

class CompositeTest(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.vert = HasVertex(Vertex(Point(1, 2), Point(3, 4)))

    def test_rdbserialize(self):

        engine = create_engine("sqlite+pysqlite:///:memory:", echo=True, future=True)

        mapper_registry.metadata.create_all(engine)
        with Session(engine, expire_on_commit=False) as session:
            session.add_all([self.vert])
            session.commit()
            session.close()
            con = engine.raw_connection()
            con.execute("vacuum main into 'alchemyctest.db'") # dumps the memory db to disk
            with open('alchemycdump.sql', 'w') as p:
                for line in con.iterdump():
                    p.write('%s\n' % line)



if __name__ == '__main__':
    unittest.main()
