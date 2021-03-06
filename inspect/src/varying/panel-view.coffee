{ Varying, Model, attribute, bind, DomView, template, find, from } = require('janus')
{ InspectorView } = require('../common/inspector')
$ = require('../dollar')
{ DateTime } = require('luxon')

{ exists } = require('../util')
{ valuate } = require('../common/valuate')
{ WrappedFunction } = require('../function/inspector')
{ WrappedVarying, Reaction } = require('./inspector')
{ reference } = require('../common/types')
{ inspect } = require('../inspect')


################################################################################
# REACTION VIEW (list)

ReactionVM = Model.build(
  bind('target-inspector', from('view').map((v) -> v.closest_(WrappedVarying).subject))
  bind('snapshot', from('target-inspector').get('id').and.subject()
    .all.flatMap((id, rxn) -> rxn.get("tree.#{id}")))
  bind('changed', from('snapshot').get('changed'))
)

class ReactionView extends DomView.build(ReactionVM, 
  $('<div class="reaction highlights"><span class="rxn-value"/></div>'),
  template(
    find('.reaction')
      .classed('target-changed', from.vm('changed'))
      .classed('target-unchanged', from.vm('changed').map((x) -> !x))
      .classed('internal', from('caller').map((c) -> c is false))
    find('.rxn-value')
      .render(from.vm('snapshot').flatMap(((vi) -> vi?.get('new_value').map(inspect))))
))
  highlight: -> this.subject

################################################################################
# VARYING DELTA ("x -> y") VIEW

VaryingDeltaView = DomView.build($('
    <span class="varying-delta">
      <span class="value"/>
      <span class="delta">
        <span class="separator"/>
        <span class="new-value"/>
      </span>
    </span>
  '), template(

    find('.value').render(from('value').map(inspect))
      .options(from.self().and('changed').all.map((view, changed) ->
        if changed is true then null
        # TODO: should be NodeView but because we're cheating it's TreeView for now.
        else { __source: view.closest_(VaryingTreeView), __ref: reference.varyingValue() }
      ))
    find('.new-value').render(from('new_value').map(inspect))

    find('.varying-delta').classed('has-delta', from('changed'))

    find('.value')
      .attr('title', from('derived').and('changed')
        .all.map((d, c) -> 'Double-click to edit' unless d or c))
      .on('dblclick', (event, subject, view) ->
        # don't try to valuate if we are displaying a delta. we don't have to block
        # on derived varyings here because valuate() will do it for us.
        return if subject.get_('changed') is true
        event.preventDefault() if valuate(subject, view)
      )
  )
)

################################################################################
# VARYING NODE VIEW
# TODO: feels like there should be a lighter weight approach.

VaryingNodeView = InspectorView.build($('
  <div class="varying-node highlights">
    <div class="inner-marker"/>
    <div class="value-marker"/>
  </div>
'), template())

################################################################################
# VARYING TREE VIEW

VaryingTreeView = DomView.build($('
    <div class="varying-tree">
      <div class="main">
        <div class="node"/>
        <div class="valueBlock"/>
      </div>
      <div class="aux">
        <div class="varying-tree-inner varying-tree-innerNew"/>
        <div class="varying-tree-inner varying-tree-innerMain"/>
        <div class="mapping"><span>λ</span></div>
      </div>
      <div class="varying-tree-nexts"/>
    </div>
  '), template(

    find('.varying-tree')
      .classed('derived', from('derived'))
      .classed('flattened', from('flattened'))
      .classed('mapped', from('mapped'))
      .classed('reducing', from('reducing'))

      .classed('hasObservations', from('observations').flatMap((os) -> os.nonEmpty()))
      .classed('hasValue', from('value').map(exists))
      .classed('hasInner', from('inner').and('new_inner').all.map((x, y) -> x? or y?))

    # TODO: ehhh on these context names?
    find('.node').render(from.subject()).context('node')
    find('.valueBlock').render(from.subject()).context('delta')

    find('.mapping').on('mouseenter', (event, wrapped, view) ->
      args = []
      for a in wrapped.get_('applicants').list
        wa = WrappedVarying.hijack(a)
        args.push(wa.get_('new_value') ? wa.get_('value'))
      wf = new WrappedFunction(wrapped.varying._f, args)
      view.options.app.flyout?($(event.target), wf, context: 'panel')
    )

    find('.varying-tree-innerNew')
      .classed('hasNewInner', from('new_inner').map(exists))
      .render(from('new_inner').map((v) -> WrappedVarying.hijack(v) if v?)).context('tree')
    find('.varying-tree-innerMain')
      .classed('hasMainInner', from('inner').map(exists))
      .render(from('inner').map((v) -> WrappedVarying.hijack(v) if v?)).context('tree')
    find('.varying-tree-nexts')
      .render(from('applicants').map((xs) -> xs?.map(WrappedVarying.hijack)))
        .context('linked').options( itemContext: 'tree' )
  )
)


################################################################################
# VARYING PANEL

downtree = (o) -> o.__downtree ?= new Varying()

class VaryingPanel extends Model.build(
  attribute('selected-rxn', class extends attribute.Enum
    nullable: true
    _values: -> from.subject('reactions')
    initial: -> null
  )
  bind('active-rxn', from('hovered-rxn').and('selected-rxn').all.map((h, s) -> h ? s))
  bind('active-rxn-caller', from('active-rxn').get('caller'))
)

VaryingView = InspectorView.build(VaryingPanel, $('
    <div class="janus-inspect-panel janus-inspect-varying highlights">
      <div class="panel-title">
        <span class="varying-title"/> #<span class="varying-id"/>
        <button class="janus-inspect-pin" title="Pin"/>
      </div>
      <div class="panel-derivation">
        Given by <span class="varying-owner"/>
        via .<span class="derivation-method"/><span class="derivation-arg"/>
      </div>
      <div class="panel-content">
        <div class="varying-bar varying-observation-bar">
          <label>Observations</label>
          <span class="varying-observations"/>
          <span class="varying-inert">
            Inert (no observers).
            <button class="varying-observe">Observe now</button>
          </span>
        </div>
        <div class="varying-bar varying-reaction-bar">
          <label>Reactions</label>
          <div class="varying-reactions"/>
          <span class="varying-reactions-none">(none tracked)</span>
        </div>
        <div class="varying-snapshot">
          Change snapshot at <span class="varying-snapshot-time"/>
          <div class="snapshot-initiation">
            Initiated via <span class="snapshot-caller"/>
          </div>
          <button class="varying-snapshot-close" title="Close Snapshot"/>
        </div>
        <div class="varying-tree"/>
      </div>
    </div>
  '), template(
    find('.janus-inspect-varying').classed('selected-rxn', from.vm('selected-rxn').map(exists))
    find('.varying-title').text(from('title'))
    find('.varying-id').text(from('id'))

    find('.panel-derivation').classed('hide', from('owner').map((x) -> !x?))
    find('.varying-owner').render(from('owner').map(inspect))
    find('.derivation-method').text(from('derivation').get('method'))
    find('.derivation-arg')
      .classed('has-arg', from('derivation').get('arg').map(exists))
      .render(from('derivation').get('arg').map(inspect))

    find('.varying-observations').render(from('observations').map((os) ->
      os.flatMap((o) -> downtree(o).map((dt) -> inspect(dt ? o.f_)))))
    find('.varying-inert').classed('hide', from('observations').flatMap((obs) -> obs?.nonEmpty()))
    find('.varying-observe').on('click', (event, subject) ->
      event.preventDefault()
      subject.varying.react()
    )

    find('.varying-reactions')
      .classed('has-reactions', from('reactions').flatMap((rs) -> rs.nonEmpty()))
      .render(from.vm().attribute('selected-rxn'))
        .context('edit').criteria( style: 'list' )
      .on('mouseover', '.reaction', (event, s, { viewModel }) ->
        viewModel.set('hovered-rxn', $(event.currentTarget).view().subject))
      .on('mouseleave', (event, s, { viewModel }) -> viewModel.unset('hovered-rxn'))

    find('.varying-snapshot-time').text(from.vm('active-rxn').get('at').map((t) ->
      DateTime.fromJSDate(t).toFormat("HH:mm:ss.SSS")))
    find('.varying-snapshot-close').on('click', (e, s, { vm }) -> vm.unset('selected-rxn'))
    find('.snapshot-initiation')
      .classed('hide', from.vm('active-rxn-caller').map((c) -> !c? or c is false))
    find('.snapshot-caller').render(from.vm('active-rxn-caller').map(inspect))

    find('.varying-tree').render(from.subject().and.vm('active-rxn').all.flatMap((wv, ar) ->
      if ar? then wv.get('id').flatMap((id) -> ar.get("tree.#{id}")) else wv
    )).context('tree')
  )
)

module.exports = {
  VaryingDeltaView
  VaryingTreeView
  VaryingView
  ReactionView

  registerWith: (library) ->
    library.register(WrappedVarying, VaryingDeltaView, context: 'delta')
    library.register(WrappedVarying, VaryingNodeView, context: 'node')
    library.register(WrappedVarying, VaryingTreeView, context: 'tree')
    library.register(WrappedVarying, VaryingView, context: 'panel')
    library.register(Reaction, ReactionView)
}

