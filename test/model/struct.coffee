should = require('should')

Struct = require('../../lib/model/struct').Struct

describe 'Struct', ->
  describe 'core', ->
    it 'should construct', ->
      (new Struct()).should.be.an.instanceof(Struct)

    it 'should construct with an attribute bag', ->
      (new Struct( test: 'attr' )).attributes.test.should.equal('attr')

    it 'should call preinitialize before attributes are populated', ->
      result = -1
      class TestStruct extends Struct
        _preinitialize: -> result = this.get('a')

      new TestStruct({ a: 42 })
      should(result).equal(null)

    it 'should call initialize after attributes are populated', ->
      result = -1
      class TestStruct extends Struct
        _initialize: -> result = this.get('a')

      new TestStruct({ a: 42 })
      result.should.equal(42)

  describe 'attribute', ->
    describe 'get', ->
      it 'should be able to get a shallow attribute', ->
        struct = new Struct( vivace: 'brix' )
        struct.get('vivace').should.equal('brix')

      it 'should be able to get a deep attribute', ->
        struct = new Struct( cafe: { vivace: 'brix' } )
        struct.get('cafe.vivace').should.equal('brix')

      it 'should return null on nonexistent attributes', ->
        struct = new Struct( broad: 'way' )
        (struct.get('vivace') is null).should.be.true
        (struct.get('cafe.vivace') is null).should.be.true

    describe 'set', ->
      it 'should be able to set a shallow attribute', ->
        struct = new Struct()
        struct.set('colman', 'pool')

        struct.attributes.colman.should.equal('pool')
        struct.get('colman').should.equal('pool')

      it 'should be able to set a deep attribute', ->
        struct = new Struct()
        struct.set('colman.pool', 'slide')

        struct.attributes.colman.pool.should.equal('slide')
        struct.get('colman.pool').should.equal('slide')

      it 'should be able to set an empty object', ->
        struct = new Struct()
        struct.set('an.obj', {})

        struct.attributes.an.obj.should.eql({})
        struct.get('an.obj').should.eql({})

      it 'should be able to set a deep attribute bag', ->
        struct = new Struct()
        struct.set('colman.pool', { location: 'west seattle', length: { amount: 50, unit: 'meter' } })

        struct.get('colman.pool.location').should.equal('west seattle')
        struct.get('colman.pool.length.amount').should.equal(50)
        struct.get('colman.pool.length.unit').should.equal('meter')

      it 'should accept a bag of attributes', ->
        struct = new Struct()
        struct.set( the: 'stranger' )

        struct.attributes.the.should.equal('stranger')

      it 'should do nothing if setting an equal value', ->
        struct = new Struct( test: 47 )
        evented = false
        struct.on('changed:test', => evented = true)

        struct.set('test', 47)
        evented.should.equal(false)
        struct.set('test', 42)
        evented.should.equal(true)

      it 'should deep write all attributes in a given bag', ->
        struct = new Struct( the: { stranger: 'seattle' } )
        struct.set( the: { joule: 'apartments' }, black: 'dog' )

        struct.attributes.the.stranger.should.equal('seattle')
        struct.get('the.stranger').should.equal('seattle')

        struct.attributes.the.joule.should.equal('apartments')
        struct.get('the.joule').should.equal('apartments')

        struct.attributes.black.should.equal('dog')
        struct.get('black').should.equal('dog')

    describe 'unset', ->
      it 'should be able to unset an attribute', ->
        struct = new Struct( cafe: { vivace: 'brix' } )
        struct.unset('cafe.vivace')

        (struct.get('cafe.vivace') is null).should.be.true

      it 'should be able to unset an attribute tree', ->
        struct = new Struct( cafe: { vivace: 'brix' } )
        struct.unset('cafe')

        (struct.get('cafe.vivace') is null).should.be.true
        (struct.get('cafe') is null).should.be.true

    describe 'setAll', ->
      it 'should set all attributes in the given bag', ->
        struct = new Struct()
        struct.setAll( the: { stranger: 'seattle', joule: 'apartments' } )

        struct.attributes.the.stranger.should.equal('seattle')
        struct.get('the.stranger').should.equal('seattle')

        struct.attributes.the.joule.should.equal('apartments')
        struct.get('the.joule').should.equal('apartments')

      it 'should clear attributes not in the given bag', ->
        struct = new Struct( una: 'bella', tazza: { di: 'caffe' } )
        struct.setAll( tazza: { of: 'cafe' } )

        should.not.exist(struct.attributes.una)
        (struct.get('una') is null).should.be.true
        should.not.exist(struct.attributes.tazza.di)
        (struct.get('tazza.di') is null).should.be.true

        struct.attributes.tazza.of.should.equal('cafe')
        struct.get('tazza.of').should.equal('cafe')

  describe 'shadowing', ->
    describe 'creation', ->
      it 'should create a new instance of the same struct class', ->
        class TestStruct extends Struct

        struct = new TestStruct()
        shadow = struct.shadow()

        shadow.should.not.equal(struct)
        shadow.should.be.an.instanceof(TestStruct)

      it 'should optionally take a different class to shadow with', ->
        class TestStruct extends Struct

        struct = new Struct()
        shadow = struct.shadow(TestStruct)

        shadow._parent.should.equal(struct)
        shadow.should.be.an.instanceof(TestStruct)

      it 'should return the original of a shadow', ->
        struct = new Struct()
        struct.shadow().original().should.equal(struct)

      it 'should return the original of a shadow\'s shadow', ->
        struct = new Struct()
        struct.shadow().shadow().original().should.equal(struct)

      it 'should return itself as the original if it is not a shadow', ->
        struct = new Struct()
        struct.original().should.equal(struct)

    describe 'attributes', ->
      it 'should return the parent\'s values', ->
        struct = new Struct( test1: 'a' )
        shadow = struct.shadow()

        shadow.get('test1').should.equal('a')

        struct.set('test2', 'b')
        shadow.get('test2').should.equal('b')

      it 'should override the parent\'s values with its own', ->
        struct = new Struct( test: 'x' )
        shadow = struct.shadow()

        shadow.get('test').should.equal('x')
        shadow.set('test', 'y')
        shadow.get('test').should.equal('y')

        struct.get('test').should.equal('x')

      it 'should revert to the parent\'s value on revert()', ->
        struct = new Struct( test: 'x' )
        shadow = struct.shadow()

        shadow.set('test', 'y')
        shadow.get('test').should.equal('y')

        shadow.revert('test')
        shadow.get('test').should.equal('x')

      it 'should do nothing on revert() if there is no parent', ->
        struct = new Struct( test: 'x' )
        struct.revert('test')
        struct.get('test').should.equal('x')

      it 'should return null for values that have been set and unset, even if the parent has values', ->
        struct = new Struct( test: 'x' )
        shadow = struct.shadow()

        shadow.set('test', 'y')
        shadow.get('test').should.equal('y')

        shadow.unset('test')
        (shadow.get('test') is null).should.equal(true)

        shadow.revert('test')
        shadow.get('test').should.equal('x')

      it 'should return null for values that have been directly unset, even if the parent has values', ->
        struct = new Struct( test: 'x' )
        shadow = struct.shadow()

        shadow.unset('test')
        (shadow.get('test') is null).should.equal(true)

      it 'should return a shadow substruct if it sees a struct', ->
        substruct = new Struct()
        struct = new Struct( test: substruct )

        shadow = struct.shadow()
        shadow.get('test').original().should.equal(substruct)

    describe 'events', ->
      it 'should event when an inherited attribute value changes', ->
        struct = new Struct( test: 'x' )
        shadow = struct.shadow()

        evented = false
        shadow.watch('test').react (value) ->
          evented = true
          value.should.equal('y')

        struct.set('test', 'y')
        evented.should.equal(true)

      it 'should not event when an overriden inherited attribute changes', ->
        struct = new Struct( test: 'x' )
        shadow = struct.shadow()

        shadow.set('test', 'y')

        evented = false
        shadow.watch('test').react(-> evented = true)

        struct.set('test', 'z')
        evented.should.equal(false)

