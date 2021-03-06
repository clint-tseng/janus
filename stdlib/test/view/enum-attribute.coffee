should = require('should')

{ Varying, Model, attribute, List, from } = require('janus')
{ EnumAttributeEditView } = require('../../lib/view/enum-attribute')

$ = require('../../lib/view/dollar')

checkText = (select, expected) -> select.children().eq(idx).text().should.equal(text) for text, idx in expected

describe 'view', ->
  describe 'enum attribute (select)', ->
    it 'renders a select tag', ->
      select = (new EnumAttributeEditView(new attribute.Enum(new Model(), 'test'))).artifact()
      select.is('select').should.equal(true)

    it 'renders an option tag for each value', ->
      class TestAttribute extends attribute.Enum
        _values: -> [ 'alpha', 'bravo', 'charlie' ]

      select = (new EnumAttributeEditView(new TestAttribute(new Model(), 'test'))).artifact()
      select.children().length.should.equal(3)

    it 'renders appropriate text given primitive values', ->
      class TestAttribute extends attribute.Enum
        _values: -> [ 'test', 1, true, false ]

      select = (new EnumAttributeEditView(new TestAttribute(new Model(), 'test'))).artifact()
      select.children().length.should.equal(4)
      checkText(select, [ 'test', '1', 'true', 'false' ])

    it 'renders appropriate text given options.stringify', ->
      class TestAttribute extends attribute.Enum
        _values: -> [ 'test', 1, true, false ]

      stringify = (x) -> "#{x}!"
      select = (new EnumAttributeEditView(new TestAttribute(new Model(), 'test'), { stringify })).artifact()
      select.children().length.should.equal(4)
      checkText(select, [ 'test!', '1!', 'true!', 'false!' ])

    it 'renders appropriate text given attribute#stringify', ->
      class TestAttribute extends attribute.Enum
        _values: -> [ 'test', 1, true, false ]
        stringify: (x) -> "#{x}?"

      select = (new EnumAttributeEditView(new TestAttribute(new Model(), 'test'))).artifact()
      select.children().length.should.equal(4)
      checkText(select, [ 'test?', '1?', 'true?', 'false?' ])

    it 'prefers options.stringify over attribute#stringify', ->
      class TestAttribute extends attribute.Enum
        _values: -> [ 'test', 1, true, false ]
        stringify: (x) -> "#{x}?"

      stringify = (x) -> "#{x}!"
      select = (new EnumAttributeEditView(new TestAttribute(new Model(), 'test'), { stringify })).artifact()
      select.children().length.should.equal(4)
      checkText(select, [ 'test!', '1!', 'true!', 'false!' ])

    it 'updates text values if given a Varying text', ->
      class TestAttribute extends attribute.Enum
        _values: -> [ 'test', 1, true, false ]

      v = new Varying('!')
      stringify = (x) -> v.map((y) -> "#{x}#{y}")
      select = (new EnumAttributeEditView(new TestAttribute(new Model(), 'test'), { stringify })).artifact()
      select.children().length.should.equal(4)
      checkText(select, [ 'test!', '1!', 'true!', 'false!' ])

      v.set('?')
      checkText(select, [ 'test?', '1?', 'true?', 'false?' ])

    it 'renders additional option tags for new values', ->
      values = new List([ 'alpha', 'bravo', 'charlie' ])
      class TestAttribute extends attribute.Enum
        _values: -> values

      select = (new EnumAttributeEditView(new TestAttribute(new Model(), 'test'))).artifact()
      select.children().length.should.equal(3)

      values.add('delta')
      select.children().length.should.equal(4)
      checkText(select, [ 'alpha', 'bravo', 'charlie', 'delta' ])

      values.add('nonsequitor', 2)
      select.children().length.should.equal(5)
      checkText(select, [ 'alpha', 'bravo', 'nonsequitor', 'charlie', 'delta' ])

    it 'removes option tags for removed values', ->
      values = new List([ 'alpha', 'bravo', 'charlie', 'delta' ])
      class TestAttribute extends attribute.Enum
        _values: -> values

      select = (new EnumAttributeEditView(new TestAttribute(new Model(), 'test'))).artifact()
      select.children().length.should.equal(4)

      values.remove('bravo')
      select.children().length.should.equal(3)
      checkText(select, [ 'alpha', 'charlie', 'delta' ])

      values.remove('alpha')
      select.children().length.should.equal(2)
      checkText(select, [ 'charlie', 'delta' ])

    it 'populates the select with the correct value initially', ->
      class TestAttribute extends attribute.Enum
        _values: -> new List([ 'alpha', 'bravo', 'charlie', 'delta' ])

      select = (new EnumAttributeEditView(new TestAttribute(new Model({ test: 'charlie' }), 'test'))).artifact()
      select.children(':selected').length.should.equal(1)
      select.children(':selected').text().should.equal('charlie')

    it 'updates the selected value if the model changes', ->
      class TestAttribute extends attribute.Enum
        _values: -> new List([ 'alpha', 'bravo', 'charlie', 'delta' ])

      m = new Model({ test: 'charlie' })
      view = new EnumAttributeEditView(new TestAttribute(m, 'test'))
      select = view.artifact()
      view.wireEvents()

      m.set('test', 'bravo')
      select.children(':selected').length.should.equal(1)
      select.children(':selected').text().should.equal('bravo')

    # originally this test also tried {}, but this doesn't work as when you
    # go to set the value it just thinks you want to set a bag of nothing.
    it 'knows how to set the value for fringe data types', ->
      mval = new Model()
      arrval = []
      class TestAttribute extends attribute.Enum
        _values: -> new List([ mval, arrval ])

      m = new Model()
      view = new EnumAttributeEditView(new TestAttribute(m, 'test'))
      select = view.artifact()
      view.wireEvents()

      select.val(select.children().eq(1).val())
      select.trigger('change')
      m.get_('test').should.equal(arrval)

      select.val(select.children().eq(0).val())
      select.trigger('change')
      m.get_('test').should.equal(mval)

    it 'updates the model if the selected value changes', ->
      class TestAttribute extends attribute.Enum
        _values: -> new List([ 'alpha', 'bravo', 'charlie', 'delta' ])

      m = new Model({ test: 'charlie' })
      view = new EnumAttributeEditView(new TestAttribute(m, 'test'))
      select = view.artifact()
      view.wireEvents()

      select.val('bravo')
      select.trigger('change')
      m.get_('test').should.equal('bravo')

      select.val('charlie')
      select.trigger('change')
      m.get_('test').should.equal('charlie')

    it 'sets the model value upon event wiring to the apparent value', ->
      class TestAttribute extends attribute.Enum
        _values: -> [ 'alpha', 'bravo', 'charlie', 'delta' ]

      m = new Model()
      view = new EnumAttributeEditView(new TestAttribute(m, 'test'))
      select = view.artifact()
      view.wireEvents()

      m.get_('test').should.equal('alpha')

    it 'inserts a blank placeholder if the field is declared nullable', ->
      class TestAttribute extends attribute.Enum
        _values: -> [ 'alpha', 'bravo', 'charlie' ]
        nullable: true

      select = (new EnumAttributeEditView(new TestAttribute(new Model(), 'test'))).artifact()
      select.children().length.should.equal(4)
      checkText(select, [ '', 'alpha', 'bravo', 'charlie' ])

    it 'deals well with a Varying values list ref changing wholesale', ->
      v = new Varying([ 'alpha', 'bravo', 'charlie' ])
      class TestAttribute extends attribute.Enum
        _values: -> v

      select = (new EnumAttributeEditView(new TestAttribute(new Model(), 'test'))).artifact()
      select.children().length.should.equal(3)
      checkText(select, [ 'alpha', 'bravo', 'charlie' ])

      v.set([ 'puppies', 'kittens', 'ducklings' ])
      select.children().length.should.equal(3)
      checkText(select, [ 'puppies', 'kittens', 'ducklings' ])

    it 'deals well with a from expression', ->
      class TestAttribute extends attribute.Enum
        _values: -> from('list')

      model = new Model({ list: new List([ 'xray', 'yankee', 'zulu' ]) })
      select = (new EnumAttributeEditView(new TestAttribute(model, 'test'))).artifact()
      select.children().length.should.equal(3)
      checkText(select, [ 'xray', 'yankee', 'zulu' ])

      model.get_('list').add('missingno')
      checkText(select, [ 'xray', 'yankee', 'zulu', 'missingno' ])

    it 'inserts a blank placeholder if the field is declared nullable', ->
      class TestAttribute extends attribute.Enum
        _values: -> [ 'alpha', 'bravo', 'charlie' ]
        nullable: true

      select = (new EnumAttributeEditView(new TestAttribute(new Model(), 'test'))).artifact()
      select.children().length.should.equal(4)
      checkText(select, [ '', 'alpha', 'bravo', 'charlie' ])

    describe 'attach', ->
      it 'should leave the initial markup alone', ->
        class TestAttribute extends attribute.Enum
          _values: -> [ 'alpha', 'bravo', 'charlie' ]

        dom = $('<select><option value="alpha">a</option><option value="bravo">b</option><option value="charlie">c</option></select>')
        (new EnumAttributeEditView(new TestAttribute(new Model(), 'test'))).attach(dom)
        dom.children().eq(0).text().should.equal('a')
        dom.children().eq(1).text().should.equal('b')
        dom.children().eq(2).text().should.equal('c')

      it 'should still set the correct model values on change', ->
        class TestAttribute extends attribute.Enum
          _values: -> [ 'alpha', 'bravo', 'charlie' ]

        select = $('<select><option value="alpha">a</option><option value="bravo">b</option><option value="charlie">c</option></select>')
        m = new Model()
        view = new EnumAttributeEditView(new TestAttribute(m, 'test'))
        view.attach(select)
        view.wireEvents()

        select.val('bravo')
        select.trigger('change')
        m.get_('test').should.equal('bravo')

      it 'should replace options correctly', ->
        l = new List([ 'alpha', 'bravo', 'charlie' ])
        class TestAttribute extends attribute.Enum
          _values: -> l

        select = $('<select><option value="alpha">a</option><option value="bravo">b</option><option value="charlie">c</option></select>')
        view = (new EnumAttributeEditView(new TestAttribute(new Model(), 'test')))
        view.attach(select)
        l.remove('bravo')
        select.children().length.should.equal(2)
        select.children().eq(1).attr('value').should.equal('charlie')
        select.children().eq(1).text().should.equal('c')

        l.add('delta')
        select.children().length.should.equal(3)
        select.children().eq(2).attr('value').should.equal('delta')
        select.children().eq(2).text().should.equal('delta')

      it 'should update label text on stringify change', ->
        l = new List([ 'alpha', 'bravo', 'charlie' ])
        class TestAttribute extends attribute.Enum
          _values: -> l

        select = $('<select><option value="alpha">a</option><option value="bravo">b</option><option value="charlie">c</option></select>')
        btext = new Varying('bravo')
        stringify = (x) -> if x is 'bravo' then btext else x
        view = (new EnumAttributeEditView(new TestAttribute(new Model(), 'test'), { stringify }))
        view.attach(select)

        btext.set('bueno')
        select.children().eq(1).text().should.equal('bueno')

      it 'should bind new options correctly', ->
        l = new List([ 'alpha', 'bravo', 'charlie' ])
        class TestAttribute extends attribute.Enum
          _values: -> l

        select = $('<select><option value="alpha">a</option><option value="bravo">b</option><option value="charlie">c</option></select>')
        dtext = new Varying('delta')
        stringify = (x) -> if x is 'delta' then dtext else x
        view = (new EnumAttributeEditView(new TestAttribute(new Model(), 'test'), { stringify }))
        view.attach(select)

        l.add('delta')
        dtext.set('delightful')
        select.children().eq(3).text().should.equal('delightful')

