should = require('should')

Model = require('../../lib/model/model').Model
View = require('../../lib/view/view').View
from = require('../../lib/core/from')

describe 'View', ->
  describe 'core', ->
    it 'should call initialize on instantiation if it exists', ->
      called = false
      class TestView extends View
        _initialize: -> called = true

      new TestView()
      called.should.equal(true)

  describe 'ViewModel injection', ->
    it 'should use the subject directly if no ViewModel is defined', ->
      class NoViewModel extends View
      class MyModel extends Model

      model = new MyModel()
      view = new NoViewModel(model)

      view.subject.should.equal(model)

    it 'should store a ViewModel if a ViewModel is defined', ->
      class MyViewModel extends Model
      class WithViewModel extends View
        @viewModelClass: MyViewModel

      class MyModel extends Model

      model = new MyModel()
      view = new WithViewModel(model)

      view.subject.should.be.an.instanceof(MyModel)
      view.viewModel.should.be.an.instanceof(MyViewModel)
      view.viewModel.get_('subject').should.equal(model)

    it 'should provide the view and the options to the ViewModel', ->
      class MyViewModel extends Model
      class WithViewModel extends View
        @viewModelClass: MyViewModel

      class MyModel extends Model

      model = new MyModel()
      view = new WithViewModel(model, { test: 14 })

      view.viewModel.get_('view').should.equal(view)
      view.viewModel.get_('options.test').should.equal(14)

  describe 'artifact handling', ->
    it 'should get its artifact from _render', ->
      artifact = {}
      class TestView extends View
        _render: -> artifact

      (new TestView()).artifact().should.equal(artifact)

    it 'should only ever call _render once', ->
      called = 0
      artifact = {}
      class TestView extends View
        _render: ->
          called += 1
          artifact

      view = new TestView()
      view.artifact().should.equal(artifact)
      view.artifact().should.equal(artifact)
      called.should.equal(1)

  # @point is tested in DomView's tests, as the concrete implementation yields
  # an easier test harness.

  describe 'pointer', ->
    it 'should provide itself as the view instance', ->
      view = new View()
      from.self().all.point(view.pointer()).get().should.equal(view)

  describe 'reference resolution', ->
    { App } = require('../../lib/application/app')
    { attribute } = require('../../lib/model/schema')
    { Reference } = require('../../lib/model/attribute')
    { Varying } = require('../../lib/core/varying')
    types = require('../../lib/core/types')

    it 'should cause a reaction given an attribute', ->
      appResolved = false
      class X extends Model.build(
        attribute 'ref', class extends Reference
          request: {}
      )
      class TestApp extends App
        resolver: -> ->
          appResolved = true
          new Varying(types.result.success(42))
      app = new TestApp()
      app.views.register(X, View)
      x = new X()
      view = app.view(x)

      view.reference(x.attribute('ref'))
      appResolved.should.equal(true)
      x.get_('ref').should.equal(42)
      x.get('ref').refCount().get().should.equal(1)

    it 'should cause a reaction given an attribute name', ->
      class X extends Model.build(
        attribute 'ref', class extends Reference
          request: {}
      )
      class TestApp extends App
        resolver: -> -> new Varying(types.result.success(42))
      app = new TestApp()
      app.views.register(X, View)
      x = new X()
      view = app.view(x)

      view.reference('ref')
      x.get_('ref').should.equal(42)
      x.get('ref').refCount().get().should.equal(1)

    it 'should provide context and react for not-autoResolve attributes', ->
      class X extends Model.build(
        attribute 'ref', class extends Reference
          autoResolve: false
          request: {}
      )
      class TestApp extends App
        resolver: -> -> new Varying(types.result.success(42))
      app = new TestApp()
      app.views.register(X, View)
      x = new X()
      view = app.view(x)

      view.reference('ref')
      x.get_('ref').should.equal(42)
      x.get('ref').refCount().get().should.equal(1)

