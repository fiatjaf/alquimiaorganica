Firebase  = require 'firebase'
hg        = require 'mercury'
cuid      = require 'cuid'
week      = require 'current-week-number'

firebaseref = new Firebase('https://week.firebaseio.com/alquimia')
{div, textarea, input, button} = require 'virtual-elements'

# model
makeOrder = (data) ->
  hg.state
    key: hg.value data.key or cuid.slug()
    date: hg.value data.date or (new Date).toISOString()
    week: hg.value data.week or week()
    content: hg.value data.content or ''

theState = ->
  hg.state
    currentWeek: hg.value week()
    orders: hg.varhash({}, makeOrder)
    handles:
      edit: (state, data) ->
        firebaseref.child(data.key).child('content').set(data.content)

state = theState()

# modifications reacting to external events
firebaseref.orderByChild('week')
           .equalTo(state.currentWeek())
           .on('child_added', (snap) ->
  state.orders.put(snap.key(), snap.val())
)
firebaseref.on('child_changed', (snap) ->
  state.orders.put(snap.key(), snap.val())
)
firebaseref.on('child_removed', (snap) ->
  state.orders.delete(snap.key())
)

# html skeleton
vrenderMain = (state) ->
  (div 'className': 'orders',
    (div 'className': 'order',
      (textarea
        'name': 'content'
        'ev-input': hg.valueEvent(state.handles.edit, {key: key})
      , data.content)
    ) for key, data of state.orders
  )

# run
hg.app document.getElementById('pedidos'), state, vrenderMain
