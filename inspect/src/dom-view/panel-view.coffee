{ DomView, template, find, from } = require('janus')
{ InspectorView } = require('../common/inspector')
$ = require('../dollar')
{ Mutation, DomViewInspector } = require('./inspector')
{ reference } = require('../common/types')
{ inspect } = require('../inspect')
{ exists } = require('../util')


MutationView = DomView.build($('
  <div class="mutation">
    <div class="mutation-selector"/>
    <span class="mutation-type">
      <span class="mutation-operation"/><span class="mutation-param"/>
    </span>
    <div class="mutation-binding"/>
  </div>'), template(

  find('.mutation-selector')
    .text(from('selector'))
    .classed('repeated', from('repeated-selector'))
  find('.mutation-operation').text(from('operation'))
  find('.mutation-param')
    .text(from('param'))
    .classed('has-param', from('param').map(exists))
  find('.mutation-binding').render(from('binding').map(inspect))
    .options(from.self().and('selector').and('operation').and('param').and('binding')
      .all.map((view, selector, operation, param) ->
        { __source: view.closest_(DomViewPanelView), __ref: reference.mutator({ selector, operation, param }) }))
))

class DomViewPanelView extends InspectorView.build($('
    <div class="janus-inspect-panel janus-inspect-domview highlights">
      <div class="panel-title">
        DomView<span class="domview-subtype"/>
        <button class="domview-flash" title="Show"/>
        <button class="janus-inspect-pin" title="Pin"/>
      </div>
      <div class="panel-derivation">
        View of <span class="domview-subject"/>
        <span class="domview-vm">with viewmodel <span class="domview-vm-vm"/></span>
      </div>
      <div class="panel-content">
        <div class="domview-mutations"/>
        <div class="domview-display">
          <div class="domview-display-label">View Preview</div>
        </div>
      </div>
    </div>'), template(
    find('.domview-subject').render(from('target').map((view) -> inspect(view.subject)))
      .options(from.self().map((__source) -> { __source, __ref: reference.viewSubject() }))
    find('.domview-vm').classed('hide', from('target').map((view) -> !view.vm?))
    find('.domview-vm-vm').render(from('target').map((view) => inspect(view.vm)))
      .options(from.self().map((__source) -> { __source, __ref: reference.viewVm() }))
    find('.domview-subtype').text(from('subtype'))
    find('.domview-mutations').render(from('mutations'))
    find('.domview-display').classed('unwired', from('events-unwired'))

    find('.domview-flash').on('click', (e, subject, view) ->
      view.options.app.flash?(subject.get_('target')))
  ))

  _render: ->
    artifact = super()
    domview = this.subject.get_('target')
    target = domview.artifact()
    detached = !target[0].parentNode?
    if detached or (target.parent().hasClass('domview-display') and (target.closest('.flyout').length isnt 0))
      target.detach()
      artifact.find('.domview-display').append(target)
      this.subject.set('events-unwired', true) if detached and domview._wired is true
      domview.wireEvents()
    artifact

module.exports = {
  MutationView
  DomViewPanelView
  registerWith: (library) ->
    library.register(Mutation, MutationView)
    library.register(DomViewInspector, DomViewPanelView, context: 'panel', inspect: true)
}

