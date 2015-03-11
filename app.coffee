Firebase  = require 'firebase'
Baobab    = require 'baobab'
hg        = require 'mercury'
cuid      = require 'cuid'
week      = require 'current-week-number'

firebaseref = new Firebase('https://week.firebaseio.com/alquimia')
{div, form, label, textarea, input, button, label} = require 'virtual-elements'

# model and DOM handles
orderDefaults = (data) ->
  key: data.key or cuid.slug()
  created: data.created or (new Date).toISOString()
  modified: if data.created then (new Date).toISOString() else null
  week: data.week or week()
  customer: data.customer or ''
  phone: data.phone or ''
  addr: data.addr or ''
  content: data.content or ''

state = Baobab
    currentWeek: week()
    orders: {}
    editing: null
  ,
    clone: true
    autoCommit: false
    shiftReferences: true

handles =
  edit: (state, data) ->
    order = state.orders.get(data.key)
    state.set 'editing', order.key
    state.commit()
  addNew: (state) ->
    order = orderDefaults({})
    state.select('orders').set order.key, order
    state.set 'editing', order.key
    state.commit()
  save: (state, data) ->
    order = orderDefaults(data)
    firebaseref.child(data.key).set order, ->
      state.set 'editing', null
      state.commit()

# modifications reacting to external events
firebaseref.orderByChild('week')
           .equalTo(state.select('currentWeek').get())
           .on 'child_added', (fsnap) ->
  state.select('orders').set fsnap.key(), fsnap.val()
  state.commit()
firebaseref.on 'child_changed', (fsnap) ->
  state.select('orders').set fsnap.key(), fsnap.val()
  state.commit()
firebaseref.on 'child_removed', (fsnap) ->
  state.select('orders').unset fsnap.key()
  state.commit()

# html skeleton
vrenderMain = (snap, handles) ->
  orderBeingEdited = snap.orders[snap.editing] if snap.editing

  (div {},
    (button
     className: 'btn btn-info add-new'
     'ev-click': handles.addNew
    , 'Fazer seu pedido') if not snap.editing
    (div className: 'orders',
      (div
        className: 'order editing'
        (form
          className: 'form-horizontal'
          'ev-submit': hg.submitEvent(handles.save, orderBeingEdited)
        ,
          (input type: 'hidden', name: 'key', value: orderBeingEdited.key)
          (input type: 'hidden', name: 'created', value: orderBeingEdited.created)
          (div className: 'form-group',
            (label {className: 'col-sm-2 control-label', htmlFor: 'customer'}, 'Nome:')
            (div className: 'col-sm-10',
              (input
                type: 'text',
                className: 'form-control',
                id: 'customer',
                name: 'customer'
                value: orderBeingEdited.customer
              )
            )
          )
          (div className: 'form-group',
            (label {className: 'col-sm-2 control-label', htmlFor: 'phone'}, 'Telefone:')
            (div className: 'col-sm-10',
              (input
                type: 'text',
                className: 'form-control',
                id: 'phone',
                name: 'phone'
                value: orderBeingEdited.phone
              )
            )
          )
          (div className: 'form-group',
            (label {className: 'col-sm-2 control-label', htmlFor: 'addr'}, 'Endereço:')
            (div className: 'col-sm-10',
              (input
                type: 'text',
                className: 'form-control',
                id: 'addr',
                name: 'addr'
                value: orderBeingEdited.addr
              )
            )
          )
          (textarea
            className: 'form-control'
            name: 'content'
            value: orderBeingEdited.content
            rows: 5
            placeholder: '1 penca de banana\nuns 10 tomates\n1 abobrinha'
          )
          (button {className: 'btn btn-primary'}, 'Enviar pedido')
        )
      ) if snap.editing
      hg.partial(vrenderListedOrder, key, data, handles) for key, data of snap.orders when key != snap.editing
    )
  )

vrenderListedOrder = (key, data, parentHandles) ->
  (div className: 'order',
    (label {htmlFor: 'content',})
    (textarea
      id: 'content'
      disabled: true
      name: 'content'
      'ev-click': hg.clickEvent(parentHandles.edit, {key: key})
    , data.content)
  )

# channels transformer func
channels = (funcs, context) ->

  createHandle = (acc, name) ->
    handle = hg.Delegator.allocateHandle(funcs[name].bind(null, context))
    acc[name] = handle
    acc

  Object.keys(funcs).reduce createHandle, {}

# run
elem = document.getElementById('pedidos')
handles = channels handles, state
mainloop = (require './baobab-loop')(state.get(), vrenderMain, handles,
  diff: hg.diff
  create: hg.create
  patch: hg.patch
)
elem.appendChild mainloop.target
state.on 'update', (b) -> mainloop.update b.target.get()
