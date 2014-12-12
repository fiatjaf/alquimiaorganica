Firebase  = require 'firebase'
hg        = require 'mercury'
cuid      = require 'cuid'
xtend     = require 'xtend'
week      = require 'current-week-number'

parseMeta = require './parsemeta.coffee'

firebaseref = new Firebase('https://week.firebaseio.com/alquimia')
{div, form, label, textarea, input, button} = require 'virtual-elements'

# model and DOM handles
makeOrder = (data) ->
  orderObservables = {}
  for k, v of orderDefaults data
    orderObservables[k] = hg.value v
  hg.struct orderObservables

orderDefaults = (data) ->
  date: data.date or (new Date).toISOString()
  week: data.week or week()
  name: data.name or ''
  phone: data.phone or ''
  addr: data.addr or ''
  content: data.content or ''

theState = ->
  hg.state
    currentWeek: hg.value week()
    orders: hg.varhash {}, makeOrder
    creating_order: hg.value null
    handles:
      edit: (state, data) ->
        p = data.content.split('\n\n')
        meta = parseMeta p[0]
        if not meta
          meta = {}
          content = data.content
        else
          meta = meta
          content = p.slice(1).join('\n\n')
        orderData = xtend state.orders.get(data.key), meta
        orderData.content = content

        firebaseref.child(data.key).set(orderData)
      addNew: (state) -> state.creating_order.set true
      saveNew: (state, data) ->
        firebaseref.child(cuid.slug()).set orderDefaults(data), ->
          state.creating_order.set false

state = theState()

# modifications reacting to external events
firebaseref.orderByChild('week')
           .equalTo(state.currentWeek())
           .on 'child_added', (snap) -> state.orders.put snap.key(), snap.val()
firebaseref.on 'child_changed', (snap) -> state.orders.put snap.key(), snap.val()
firebaseref.on 'child_removed', (snap) -> state.orders.delete snap.key()

# html skeleton
vrenderMain = (state) ->
  (div {},
    (button
     className: 'btn btn-info add-new'
     'ev-click': state.handles.addNew
    , 'Fazer seu pedido') if not state.creating_order
    (div className: 'orders',
      (div
        className: 'order editing'
        (form
          className: 'form-horizontal'
          'ev-submit': hg.valueEvent(state.handles.saveNew)
        ,
          (div className: 'form-group',
            (label {className: 'col-sm-2 control-label', htmlFor: 'name'}, 'Nome:')
            (div className: 'col-sm-10',
              (input type: 'text', className: 'form-control', id: 'name', name: 'name')
            )
          )
          (div className: 'form-group',
            (label {className: 'col-sm-2 control-label', htmlFor: 'phone'}, 'Telefone:')
            (div className: 'col-sm-10',
              (input type: 'text', className: 'form-control', id: 'phone', name: 'phone')
            )
          )
          (div className: 'form-group',
            (label {className: 'col-sm-2 control-label', htmlFor: 'addr'}, 'Endereço:')
            (div className: 'col-sm-10',
              (input type: 'text', className: 'form-control', id: 'addr', name: 'addr')
            )
          )
          (textarea
            className: 'form-control'
            name: 'content'
            rows: 5
            placeholder: '1 penca de banana\nuns 10 tomates\n1 abobrinha'
          )
          (button {className: 'btn btn-primary'}, 'Enviar pedido')
        ) if state.creating_order
      ) if state.creating_order or state.editing
      hg.partial vrenderListedOrder, key, data, state.handles for key, data of state.orders
    )
  )

vrenderListedOrder = (key, data, parentHandles) ->
  content = data.content
  if data.confirmado
    content = 'confirmado\n' + content
  if data.date
    content = data.date + '\n' + content
  content = '\n\n' + content

  (div className: 'order',
    (textarea
      name: 'content'
      'ev-input': hg.valueEvent(parentHandles.edit, {key: key})
    , content)
  )

# run
hg.app document.getElementById('pedidos'), state, vrenderMain
