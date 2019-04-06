{ DomView, template, find, from } = require('janus')
$ = require('janus-dollar')
{ inspect } = require('../inspect')
{ WrappedCase } = require('./inspector')
{ exists } = require('../util')

CaseEntityView = DomView.build($('
  <span class="janus-inspect-entity janus-inspect-case no-panel">
    <span class="entity-title">Case<span class="entity-subtitle"/></span>
    <span class="entity-content">
      <span class="case-value"></span>
    </span>
  </span>'), template(

  find('.entity-subtitle')
    .classed('has-subtitle', from('name').map(exists))
    .text(from('name'))

  find('.case-value').render(from('target').map((kase) -> inspect(kase.get())))
))

module.exports = {
  CaseEntityView,
  registerWith: (library) ->
    library.register(WrappedCase, CaseEntityView)
}

