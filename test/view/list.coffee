should = require('should')

{ Varying, DomView, template, find, from, List, Set, App, Library } = require('janus')
{ ListView, SetView } = require('../../lib/view/list')

$ = require('janus-dollar')

# register LiteralView for our tests to make our lives easier.
testLibrary = new Library()
require('../../lib/view/literal').registerWith(testLibrary)
testApp = new App( views: testLibrary )

checkLiteral = (dom, expectedText) ->
  dom.is('span').should.equal(true)
  dom.hasClass('janus-literal').should.equal(true)
  dom.text().should.equal(expectedText.toString())

describe 'view', ->
  describe 'list', ->
    describe 'render', ->
      it 'should render an unordered list element of the appropriate class', ->
        dom = (new ListView(new List())).artifact()
        dom.is('ul').should.equal(true)
        dom.hasClass('janus-list').should.equal(true)

      it 'should initially display the appropriate elements', ->
        dom = (new ListView(new List([ 1, 2, 3 ]), { app: testApp })).artifact()
        dom.children().length.should.equal(3)

        for i in [0..2]
          child = dom.children().eq(i)
          child.is('li').should.equal(true)
          child.children().length.should.equal(1)

          checkLiteral(child.children(':first-child'), i + 1)

      it 'should correctly add new elements', ->
        l = new List([ 1, 2, 3 ])
        dom = (new ListView(l, { app: testApp })).artifact()

        l.add(4)
        dom.children().length.should.equal(4)
        itemDom = dom.children('li:last-child')
        itemDom.children().length.should.equal(1)
        checkLiteral(itemDom.children(':first-child'), 4)

        l.add(5, 1)
        dom.children().length.should.equal(5)
        itemDom = dom.children(':nth-child(2)') # nth-child is 1-indexed
        itemDom.children().length.should.equal(1)
        checkLiteral(itemDom.children(':first-child'), 5)

      it 'should correctly remove elements', ->
        l = new List([ 1, 2, 3, 4, 5 ])
        dom = (new ListView(l, { app: testApp })).artifact()

        l.remove(3)
        dom.children().length.should.equal(4)
        for label, idx in [ 1, 2, 4, 5 ]
          itemDom = dom.children().eq(idx)
          itemDom.is('li').should.equal(true)
          itemDom.children().length.should.equal(1)
          checkLiteral(itemDom.children(':first-child'), label)

      it 'should destroy views related to removed elements', ->
        l = new List([ 1, 2, 3, 4, 5 ])
        view = new ListView(l, { app: testApp })
        dom = view.artifact()
        view.wireEvents()

        destroyed = false
        victimView = dom.children().eq(2).children().data('view')
        victimView.on('destroying', -> destroyed = true)

        l.remove(3)
        destroyed.should.equal(true)

      it 'should unbind the render mutator related to removed elements', ->
        l = new List([ 1, 2, 3, 4, 5 ])
        view = new ListView(l, { app: testApp })
        dom = view.artifact()

        unbound = false
        victimMutator = view._mappedBindings.list[2]
        victimMutator.stop = -> unbound = true

        l.remove(3)
        unbound.should.equal(true)

      it 'should react appropriately when a Varying item changes', ->
        l = new List([ 1, new Varying(2), 3 ])
        dom = (new ListView(l, { app: testApp })).artifact()

        l.at_(1).set('test')
        dom.children().length.should.equal(3)
        itemDom = dom.children().eq(1)
        itemDom.is('li').should.equal(true)
        itemDom.children().length.should.equal(1)
        checkLiteral(itemDom.children(':first-child'), 'test')

    describe 'attaching', ->
      checkChild = (dom, idx, text) ->
        checkLiteral(dom.children().eq(idx).children(), text)

      # we don't test every nook and cranny, only the things that differ from
      # the render path above. the two share a lot of machinery code.
      it 'should leave the initial dom be', ->
        l = new List([ 1, 2, 3 ])
        dom = $('<ul><li><span class="janus-literal">one</span></li><li><span class="janus-literal">two</span></li><li><span class="janus-literal">three</span></li></ul>')
        (new ListView(l, { app: testApp })).attach(dom)
        checkChild(dom, 0, 'one')
        checkChild(dom, 1, 'two')
        checkChild(dom, 2, 'three')

      it 'should update the correct nodes when they change', ->
        l = new List([ 1, 2, 3 ])
        dom = $('<ul><li><span class="janus-literal">one</span></li><li><span class="janus-literal">two</span></li><li><span class="janus-literal">three</span></li></ul>')
        (new ListView(l, { app: testApp })).attach(dom)

        l.removeAt(0)
        dom.children().length.should.equal(2)
        checkChild(dom, 0, 'two')
        checkChild(dom, 1, 'three')

        l.set(0, 4)
        dom.children().length.should.equal(2)
        checkChild(dom, 0, '4')
        checkChild(dom, 1, 'three')

        l.add(5)
        dom.children().length.should.equal(3)
        checkChild(dom, 0, '4')
        checkChild(dom, 1, 'three')
        checkChild(dom, 2, '5')

      it 'should handle changed flattened varying values correctly', ->
        v = new Varying(2)
        l = new List([ 1, v, 3 ])
        dom = $('<ul><li><span class="janus-literal">one</span></li><li><span class="janus-literal">two</span></li><li><span class="janus-literal">three</span></li></ul>')
        (new ListView(l, { app: testApp })).attach(dom)

        v.set(7)
        dom.children().length.should.equal(3)
        checkChild(dom, 0, 'one')
        checkChild(dom, 1, '7')
        checkChild(dom, 2, 'three')

    it 'should allow chaining on its render mutator', ->
      l = new List([ 1, 2, 3 ])
      renderItem = (render) -> render.context('test')

      library = new Library()
      library.register(Number, require('../../lib/view/literal').LiteralView, context: 'test')
      app = new App( views: library )

      dom = (new ListView(l, { app, renderItem })).artifact()

      dom.children().length.should.equal(3)
      for i in [0..2]
        child = dom.children().eq(i)
        child.is('li').should.equal(true)
        child.children().length.should.equal(1)

        checkLiteral(child.children(':first-child'), i + 1)

    it 'should wire events on extant children upon request', ->
      view = new ListView(new List([ 1, 2, 3 ]), { app: testApp })
      dom = view.artifact()
      view.wireEvents()

      dom.children().eq(0).children().data('view')._wired.should.equal(true)
      dom.children().eq(1).children().data('view')._wired.should.equal(true)
      dom.children().eq(2).children().data('view')._wired.should.equal(true)

    it 'should wire events on new children when added', ->
      l = new List([ 1 ])
      view = new ListView(l, { app: testApp })
      dom = view.artifact()
      view.wireEvents()

      dom.children().eq(0).children().data('view')._wired.should.equal(true)
      l.add(2)
      dom.children().eq(1).children().data('view')._wired.should.equal(true)
      l.add(3)
      dom.children().eq(2).children().data('view')._wired.should.equal(true)

    it 'should wire events on changing flattened varying children when added', ->
      v = new Varying(1)
      l = new List([ v ])
      view = new ListView(l, { app: testApp })
      dom = view.artifact()
      view.wireEvents()

      dom.children().eq(0).children().data('view')._wired.should.equal(true)
      v.set(2)
      dom.children().eq(0).children().data('view')._wired.should.equal(true)

    it 'should destroy all child views when destroyed', ->
      l = new List([ 1, 2, 3 ])
      view = new ListView(l, { app: testApp })
      dom = view.artifact()
      view.wireEvents() # we do this just so we have easy access to the subviews via .data('view'):

      subviews = dom.children().children().map(-> $(this).data('view')).toArray()
      destroyed = 0
      (subview._destroy = -> destroyed += 1) for subview in subviews

      view.destroy()
      destroyed.should.equal(3)

  describe 'set', ->
    # this is all really just a plumbing check; the SetView renders entirely
    # using the captive List within the Set, which is canonical.
    it 'should render with the internal set list', ->
      dom = (new SetView(new Set([ 1, 2, 3 ]), { app: testApp })).artifact()
      dom.children().length.should.equal(3)

      for i in [0..2]
        child = dom.children().eq(i)
        child.is('li').should.equal(true)
        child.children().length.should.equal(1)

        checkLiteral(child.children(':first-child'), i + 1)

