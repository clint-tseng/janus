should = require('should')

{ Varying } = require('../../lib/core/varying')
{ Map } = require('../../lib/collection/map')
{ Model } = require('../../lib/model/model')
{ attribute } = require('../../lib/model/schema')
{ List } = require('../../lib/collection/list')
attributes = require('../../lib/model/attribute')
{ sum } = require('../../lib/collection/derived/sum-fold').SumFold
{ Traversal } = require('../../lib/collection/traversal')
{ recurse, delegate, defer, varying, value, nothing } = require('../../lib/core/types').traversal


# TODO: ensure that updates to source data propagates as expected.
# (it really ought to given we're built on top of enumeration, in which this is tested).

describe 'traversal', ->
  describe 'as list', ->
    it 'should provide the appropriate basic arguments', ->
      ss = new Map( d: 1 )
      s = new Map( a: 1, b: 2, c: ss )
      results = []
      Traversal.list(s, map: (k, v, o) ->
        if v.isMap is true
          recurse(v)
        else
          results.push(k, v, o)
          nothing
      )
      results.should.eql([ 'a', 1, s, 'b', 2, s, 'd', 1, ss ])

    it 'should process straight value results as a map', ->
      s = new Map( a: 1, b: 2, c: 3 )
      l = Traversal.list(s, map: (k, v) -> value("#{k}#{v}"))

      l.length_.should.equal(3)
      for val, idx in [ 'a1', 'b2', 'c3' ]
        l.at_(idx).should.equal(val)

    it 'should result in undefined when nothing is passed', ->
      s = new Map( a: 1, b: 2, c: 3 )
      l = Traversal.list(s, map: (k, v) -> if v < 3 then nothing else value(v))

      l.length_.should.equal(3)
      for val, idx in [ undefined, undefined, 3 ]
        should(l.at_(idx)).equal(val)

    it 'should delegate to another function given delegate', ->
      s = new Map( a: 1, b: 2, c: 3 )
      l = Traversal.list(s, map: (k, v) ->
        if v < 3
          delegate((k, v) -> if v < 2 then value('x') else value('y'))
        else
          value(v)
      )

      l.length_.should.equal(3)
      for val, idx in [ 'x', 'y', 3 ]
        l.at_(idx).should.equal(val)

    it 'should recurse into subobjects if requested', ->
      s = new Map( a: 1, b: 2, c: new Map( d: 3, e: 4 ) )
      l = Traversal.list(s, map: (k, v) ->
        if v.isMap is true
          recurse(v)
        else
          value("#{k}#{v}")
      )

      l.length_.should.equal(3)
      for val, idx in [ 'a1', 'b2' ]
        l.at_(idx).should.equal(val)

      ll = l.at_(2)
      ll.length_.should.equal(2)
      for val, idx in [ 'd3', 'e4' ]
        ll.at_(idx).should.equal(val)

    it 'should use a varying if passed', ->
      s = new Map( a: 1, b: 2, c: 3 )
      v = new Varying(0)
      l = Traversal.list(s, map: (k, y) -> varying(v.map((x) -> value("#{k}#{y + x}"))))

      l.length_.should.equal(3)
      for val, idx in [ 'a1', 'b2', 'c3' ]
        l.at_(idx).should.equal(val)

      v.set(2)
      l.length_.should.equal(3)
      for val, idx in [ 'a3', 'b4', 'c5' ]
        l.at_(idx).should.equal(val)

    it 'should delegate permanently to another function if defer is passed', ->
      s = new Map( a: 1, b: 2, c: new Map( d: 3, e: 4 ) )
      l = Traversal.list(s, map: (k, v) ->
        if v.isMap is true
          defer((k, v) ->
            if v.isMap is true
              recurse(v)
            else
              value("#{k}#{v}!")
          )
        else
          value("#{k}#{v}")
      )

      l.length_.should.equal(3)
      for val, idx in [ 'a1', 'b2' ]
        l.at_(idx).should.equal(val)

      ll = l.at_(2)
      ll.length_.should.equal(2)
      for val, idx in [ 'd3!', 'e4!' ]
        ll.at_(idx).should.equal(val)

    it 'should reduce with the given function if given', ->
      s = new Map( a: 1, b: 2, c: new Map( d: 3, e: 4 ) )
      f = (_, v) ->
        if v.isMap is true
          recurse(v)
        else
          value(v)
      result = Traversal.list(s, { map: f, reduce: sum }, null)

      result.should.be.an.instanceof(Varying)
      result.get().should.equal(10)

    it 'should provide an attribute if available', ->
      TestModel = Model.build(attribute('b', attributes.BooleanAttribute))

      results = []
      m = new TestModel( a: 1, b: 2 )
      Traversal.list(m, map: (k, v, o, a) -> results.push(k, a))
      results.should.eql([ 'a', undefined, 'b', m.attribute('b') ])

    it 'should pass context through each level', ->
      s = new Map( a: 1, b: new Map( c: 2 ), d: 3 )
      context = { con: 'text' }
      results = []
      Traversal.list(s, (map: (k, v, _, __, context) ->
        if v.isMap is true
          recurse(v)
        else
          results.push(context)
          nothing
      ), context)

      results.should.eql([ context, context, context ])

    it 'should accept context as the second case parameter', ->
      s = new Map( a: 1, b: new Map( c: 2 ), d: 3 )
      context = { z: 0 }
      results = []
      Traversal.list(s, (map: (k, v, _, __, context) ->
        if v.isMap is true
          recurse(v, z: 1 )
        else if k is 'd'
          delegate(((k, v, _, __, context) -> results.push(context); nothing), z: 2 )
        else
          results.push(context)
          nothing
      ), context)

      results.should.eql([ { z: 0 }, { z: 1 }, { z: 2 } ])

    it 'should work with nested lists', ->
      s = new Map( a: 1, b: new List([ 2, 3 ]), d: 4 )
      l = Traversal.list(s, map: (k, v) ->
        if v.isMappable is true
          recurse(v)
        else
          value("#{k}#{v}")
      )

      l.length_.should.equal(3)
      l.at_(0).should.equal('a1')
      ll = l.at_(1)
      ll.length_.should.equal(2)
      ll.at_(0).should.equal('02', '13')
      l.at_(2).should.equal('d4')

    it 'should work with root lists', ->
      l = Traversal.list(new List([ 1, new Map( a: 2, b: 3 ), 4 ]), map: (k, v) ->
        if v.isMap is true
          recurse(v)
        else
          value("#{k}#{v}")
      )

      l.length_.should.equal(3)
      l.at_(0).should.equal('01')
      ll = l.at_(1)
      ll.length_.should.equal(2)
      ll.at_(0).should.equal('a2')
      ll.at_(1).should.equal('b3')
      l.at_(2).should.equal('24')

  describe 'get array', ->
    # largely relies on the list tests for correctness of internal traversal.
    it 'should supply the appropriate basic parameters', ->
      ss = new Map( d: 1 )
      s = new Map( a: 1, b: 2, c: ss )
      results = []
      Traversal.list_(s, map: (k, v, o) ->
        if v.isMap is true
          recurse(v)
        else
          results.push(k, v, o)
          nothing
      )
      results.should.eql([ 'a', 1, s, 'b', 2, s, 'd', 1, ss ])

    it 'should recurse correctly', ->
      s = new Map( a: 1, b: new Map( c: 2, d: 3 ), e: new List([ 4, 5 ]), f: 6 )
      a = Traversal.list_(s, map: (k, v, o) ->
        if v.isEnumerable is true
          recurse(v)
        else
          value("#{k}#{v}")
      )
      a.should.eql([ 'a1', [ 'c2', 'd3' ], [ '04', '15' ], 'f6' ])

    it 'should handle varying results appropriately', ->
      vary = new Varying(2)
      s = new Map( a: 1, b: 2, c: 3 )
      a = Traversal.list_(s, map: (k, v) -> varying(vary.map((x) -> value(v + x))))
      a.should.eql([ 3, 4, 5 ])

    it 'should delegate to another function given delegate', ->
      s = new Map( a: 1, b: 2, c: 3 )
      o = Traversal.list_(s, map: (k, v) ->
        if v < 3
          delegate((k, v) -> if v < 2 then value('x') else value('y'))
        else
          value(v)
      )

      o.should.eql([ 'x', 'y', 3 ])

  describe 'as natural', ->
    # largely relies on the list tests for correctness of internal traversal.
    it 'should supply the appropriate parameters', ->
      results = []
      l = new List([ 4, 8 ])
      Traversal.natural(l, map: (k, v, o) ->
        results.push(k, v, o)
        nothing
      )

      TestModel = Model.build(attribute('b', attributes.BooleanAttribute))
      m = new TestModel( a: 15, b: 16 )
      Traversal.natural(m, map: (k, v, o, a) ->
        results.push(k, v, o, a)
        nothing
      )

      results.should.eql([ 0, 4, l, 1, 8, l, 'a', 15, m, undefined, 'b', 16, m, m.attribute('b') ])

    it 'should map a list to a list', ->
      l = Traversal.natural(new List([ 2, 4, 6, 8, 10 ]), map: (k, v) -> value(k + v))
      l.length_.should.equal(5)
      for val, idx in [ 2, 5, 8, 11, 14 ]
        l.at_(idx).should.equal(val)

    it 'should map a map to a map', ->
      s = Traversal.natural(new Map( a: 1, b: 2, c: 3 ), map: (k, v) -> value("#{k}#{v}"))
      s.data.should.eql({ a: 'a1', b: 'b2', c: 'c3' })

    it 'should recursively map like types', ->
      source = new Map( a: 1, b: new List([ 2, new Map( c: 3, d: 4 ) ]), e: new Map( f: 5 ) )
      s = Traversal.natural(source, map: (k, v) ->
        if v.isEnumerable is true
          recurse(v)
        else
          value("#{k}#{v}")
      )

      s.should.be.an.instanceof(Map)
      s.get_('a').should.equal('a1')
      s.get_('b').should.be.an.instanceof(List)
      s.get_('e').should.be.an.instanceof(Map)

      s.get_('b').length_.should.equal(2)
      s.get_('b').at_(0).should.equal('02')
      s.get_('b').at_(1).should.be.an.instanceof(Map)

      s.get_('b').at_(1).data.should.eql({ c: 'c3', d: 'd4' })

      s.get_('e').data.should.eql({ f: 'f5' })

    it 'should delegate to another function given delegate', ->
      s = new Map( a: 1, b: 2, c: 3 )
      r = Traversal.natural(s, map: (k, v) ->
        if v < 3
          delegate((k, v) -> if v < 2 then value('x') else value('y'))
        else
          value(v)
      )

      r.get_('a').should.equal('x')
      r.get_('b').should.equal('y')
      r.get_('c').should.equal(3)

  describe 'get natural', ->
    # largely relies on the list tests for correctness of internal traversal.
    it 'should supply the appropriate parameters', ->
      results = []
      l = new List([ 4, 8 ])
      Traversal.natural_(l, map: (k, v, o) ->
        results.push(k, v, o)
        nothing
      )

      TestModel = Model.build(attribute('b', attributes.BooleanAttribute))
      m = new TestModel( a: 15, b: 16 )
      Traversal.natural_(m, map: (k, v, o, a) ->
        results.push(k, v, o, a)
        nothing
      )

      results.should.eql([ 0, 4, l, 1, 8, l, 'a', 15, m, undefined, 'b', 16, m, m.attribute('b') ])

    it 'should map a list to a list', ->
      a = Traversal.natural_(new List([ 2, 4, 6, 8, 10 ]), map: (k, v) -> value(k + v))
      a.should.eql([ 2, 5, 8, 11, 14 ])

    it 'should map a map to a map', ->
      o = Traversal.natural_(new Map( a: 1, b: 2, c: 3 ), map: (k, v) -> value("#{k}#{v}"))
      o.should.eql({ a: 'a1', b: 'b2', c: 'c3' })

    it 'should recursively map like types', ->
      source = new Map( a: 1, b: new List([ 2, new Map( c: 3, d: 4 ) ]), e: new Map( f: 5 ) )
      o = Traversal.natural_(source, map: (k, v) ->
        if v.isEnumerable is true
          recurse(v)
        else
          value("#{k}#{v}")
      )

      o.should.eql({ a: 'a1', b: [ '02', { c: 'c3', d: 'd4' } ], e: { f: 'f5' } })

    it 'should delegate to another function given delegate', ->
      s = new Map( a: 1, b: 2, c: 3 )
      o = Traversal.natural_(s, map: (k, v) ->
        if v < 3
          delegate((k, v) -> if v < 2 then value('x') else value('y'))
        else
          value(v)
      )

      o.should.eql({ a: 'x', b: 'y', c: 3 })

  describe 'default implementations', ->
    describe 'serialization', ->
      it 'should return an object with shallow keys intact', ->
        o = (new Map( a: 1, b: 2, c: 3 )).serialize()
        o.should.eql({ a: 1, b: 2, c: 3 })

      it 'should return an array with values intact', ->
        a = (new List([ 4, 8, 15, 16, 23, 42 ])).serialize()
        a.should.eql([ 4, 8, 15, 16, 23, 42 ])

      it 'should handle nested structures appropriately', ->
        o = (new Map( a: 1, b: new List([ 2, new Map( c: 3, d: 4 ) ]), e: new Map( f: 5 ) )).serialize()
        o.should.eql({ a: 1, b: [ 2, { c: 3, d: 4 } ], e: { f: 5 } })

      it 'should rely on attribute serialization methods when available', ->
        TestModel = Model.build(
          attribute('b', class extends attributes.Number
            serialize: -> "number: #{this.getValue_()}")

          attribute('c', class extends attributes.Attribute
            serialize: -> JSON.stringify(this.getValue_()))
        )

        o = (new TestModel( a: 1, b: 2, c: [ 3, 4, 5 ] )).serialize()
        o.should.eql({ a: 1, b: 'number: 2', c: '[3,4,5]' })

      it 'should rely on custom-defined serialize methods when defined', ->
        class TestMap extends Map
          serialize: -> 'test'

        o = (new Map( a: new TestMap( b: 2, c: 3 ), d: 4 )).serialize()
        o.should.eql({ a: 'test', d: 4 })

      it 'should not try to use custom-defined serialize if it is inherited', ->
        class TestMapA extends Map
          serialize: -> 'test'
        class TestMapB extends TestMapA

        o = (new Map( a: new TestMapB( b: 2, c: 3 ), d: 4 )).serialize()
        o.should.eql({ a: { b: 2, c: 3 }, d: 4 })

    describe 'diff', ->
      it 'should consider unlike objects eternally different', ->
        (new List()).diff(new Map()).get().should.equal(true)
        return
        (new Map()).diff(new List()).get().should.equal(true)
        (new Map()).diff(true).get().should.equal(true)
        (new Map()).diff().get().should.equal(true)

      it 'should diff shallow values in maps', ->
        sa = new Map( a: 1, b: 2, c: { d: 3 } )
        sb = new Map( a: 1, b: 2, c: { d: 3 } )

        result = null
        sa.diff(sb).react((x) -> result = x)

        result.should.equal(false)
        sa.set('b', 3)
        result.should.equal(true)
        sb.set('b', 3)
        result.should.equal(false)
        sb.unset('c')
        result.should.equal(true)
        sb.set('c', { d: 3 })
        result.should.equal(false)

      it 'should diff shallow values in lists', ->
        la = new List([ 1, 2, 3, 4, 5 ])
        lb = new List([ 1, 2, 3, 4, 5 ])

        result = null
        la.diff(lb).react((x) -> result = x)

        result.should.equal(false)
        la.add(6)
        result.should.equal(true)
        lb.add(6)
        result.should.equal(false)
        la.removeAt(0)
        result.should.equal(true)
        lb.removeAll()
        lb.add([ 2, 3, 4, 5, 6 ])
        result.should.equal(false)

      it 'should diff maps nested in maps correctly', ->
        sa = new Map( a: 1, b: 2, c: new Map( d: 3 ) )
        sb = new Map( a: 1, b: 2, c: new Map( d: 3 ) )

        result = null
        sa.diff(sb).react((x) -> result = x)

        result.should.equal(false)
        sb.set('c', new Map( d: 3 ))
        result.should.equal(false)
        sb.get_('c').set('e', 4)
        result.should.equal(true)
        sa.get_('c').set('e', 4)
        result.should.equal(false)
        sa.unset('c')
        result.should.equal(true)

      it 'should diff lists nested in maps correctly', ->
        sa = new Map( a: 1, b: 2, c: new List([ 3, 4 ]) )
        sb = new Map( a: 1, b: 2, c: new List([ 3, 4 ]) )

        result = null
        sa.diff(sb).react((x) -> result = x)

        result.should.equal(false)
        sb.set('c', new List([ 3, 4 ]))
        result.should.equal(false)
        sb.get_('c').add(5)
        result.should.equal(true)
        sa.get_('c').add(5)
        result.should.equal(false)
        sa.get_('c').set(0, 0)
        result.should.equal(true)
        sa.unset('c')
        result.should.equal(true)

      it 'should diff lists nested in lists correctly', ->
        la = new List([ 1, new List([ 2, 3 ]), 4 ])
        lb = new List([ 1, new List([ 2, 3 ]), 4 ])

        result = null
        la.diff(lb).react((x) -> result = x)

        result.should.equal(false)
        la.at_(1).add(0)
        result.should.equal(true)
        lb.at_(1).add(0)
        result.should.equal(false)
        lb.set(1, new List([ 2, 3, 0 ]))
        result.should.equal(false)
        la.removeAt(1)
        result.should.equal(true)

      it 'should diff maps nested in lists correctly', ->
        la = new List([ 1, new Map( a: 2, b: 3 ), 4 ])
        lb = new List([ 1, new Map( a: 2, b: 3 ), 4 ])

        result = null
        la.diff(lb).react((x) -> result = x)

        result.should.equal(false)
        la.at_(1).set( c: 4 )
        result.should.equal(true)
        lb.at_(1).set( c: 4 )
        result.should.equal(false)
        lb.set(1, new Map( a: 2, b: 3, c: 4 ))
        result.should.equal(false)
        la.removeAt(1)
        result.should.equal(true)

