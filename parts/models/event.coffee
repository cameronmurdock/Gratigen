if Meteor.isClient
    Router.route '/event/:doc_id', (->
        @layout 'layout'
        @render 'event_view'
        ), name:'event_view'
        
                
if Meteor.isServer 
    Meteor.publish 'my_events_publication', ->
        user = Meteor.user()
        # authored
        Docs.find 
            model:'event'
            _author_id:Meteor.userId()



if Meteor.isClient
    # Router.route '/e/:doc_slug/', (->
    #     @layout 'layout'
    #     @render 'event_view'
    #     ), name:'event_view_by_slug'
        
    Template.registerHelper 'facilitator', () ->    
        Meteor.users.findOne @facilitator_id
    Template.registerHelper 'fac', () ->    
        Meteor.users.findOne @facilitator_id
   
    Template.registerHelper 'my_ticket', () ->    
        event = Docs.findOne @_id
        Docs.findOne
            model:'order'
            order_type:'ticket_purchase'
            event_id:@_id
            _author_id:Meteor.userId()
   
    Template.registerHelper 'event_room', () ->
        event = Docs.findOne @_id
        Docs.findOne 
            _id:event.room_id

    Template.registerHelper 'going', () ->
        event = Docs.findOne @_id
        event_tickets = 
            Docs.find(
                model:'order'
                order_type:'ticket_purchase'
                event_id: @_id
                ).fetch()
        going_user_ids = []
        for ticket in event_tickets
            going_user_ids.push ticket._author_id
        Meteor.users.find 
            _id:$in:going_user_ids
            
    Template.registerHelper 'maybe_going', () ->
        event = Docs.findOne @_id
        Meteor.users.find 
            _id:$in:event.maybe_user_ids
            
    Template.registerHelper 'user_maybe_events', () ->
        user = Meteor.users.findOne username:Router.current().params.username
        Docs.find
            model:"event"
            maybe_user_ids:user._id

if Meteor.isServer
    Meteor.publish 'user_maybe_events', (username) ->
        user = Meteor.users.findOne username:username
        Docs.find
            model:"event"
            maybe_user_ids:user._id

if Meteor.isClient
    Template.user_events.onCreated ->
        @autorun => @subscribe 'user_maybe_events', Router.current().params.username, ->
        
        

            
            
    Template.registerHelper 'not_going', () ->
        event = Docs.findOne @_id
        Meteor.users.find 
            _id:$in:event.not_user_ids

    Template.registerHelper 'event_tickets', () ->
        Docs.find 
            model:'order'
            order_type:'ticket_purchase'
            event_id: Router.current().params.doc_id


    Template.event_view.onCreated ->
    Template.event_view.events
        'click .buy_ticket': ->
            Docs.insert 
                model:'order'
                ticket:true
                event_id:@_id
                ticket_price: @point_price
        
    Template.event_view.helpers
        event_ticket_docs: ->
            Docs.find
                model:'order'
                ticket:true
                event_id:@_id
                ticket_price: @point_price
        
    
        can_add_event: ->
            facilitator_badge = 
                Docs.findOne    
                    model:'badge'
                    slug:'facilitator'
            if facilitator_badge
                Meteor.userId() in facilitator_badge.badger_ids
            
    
    

if Meteor.isServer
    Meteor.publish 'future_events', ()->
        console.log moment().subtract(1,'days').format("YYYY-MM-DD")
        Docs.find {
            model:'event'
            published:true
            date:$gt:moment().subtract(1,'days').format("YYYY-MM-DD")
        }, 
            sort:date:1
    
    Meteor.publish 'events', (
        viewing_room_id
        viewing_past
        viewing_published
        )->
            
        match = {model:'event'}
        if viewing_room_id
            match.room_id = viewing_room_id
        if viewing_past
            match.date = $gt:moment().subtract(1,'days').format("YYYY-MM-DD")
            
        match.published = viewing_published    
            
        console.log moment().subtract(1,'days').format("YYYY-MM-DD")
        Docs.find match, 
            sort:date:1
    

    # Meteor.publish 'doc_by_slug', (slug)->
    #     Docs.find
    #         slug:slug
            
    # Meteor.publish 'author_by_doc_id', (doc_id)->
    #     doc_by_id =
    #         Docs.findOne doc_id
    #     doc_by_slug =
    #         Docs.findOne slug:doc_id
    #     if doc_by_id
    #         Meteor.users.findOne 
    #             _id:doc_by_id._author_id
    #     else
    #         Meteor.users.findOne 
    #             _id:doc_by_slug._author_id
            
            
    # Meteor.publish 'author_by_doc_slug', (slug)->
    #     doc = 
    #         Docs.findOne
    #             slug:slug
    #     Meteor.users.findOne 
    #         _id:doc._author_id


#     Meteor.methods
        # send_event: (event_id)->
        #     event = Docs.findOne event_id
        #     target = Meteor.users.findOne event.recipient_id
        #     gifter = Meteor.users.findOne event._author_id
        #
        #     console.log 'sending event', event
        #     Meteor.users.update target._id,
        #         $inc:
        #             points: event.amount
        #     Meteor.users.update gifter._id,
        #         $inc:
        #             points: -event.amount
        #     Docs.update event_id,
        #         $set:
        #             submitted:true
        #             submitted_timestamp:Date.now()
        #
        #
        #
        #     Docs.update Router.current().params.doc_id,
        #         $set:
        #             submitted:true


 if Meteor.isClient
    Template.registerHelper 'ticket_event', () ->
        Docs.findOne @event_id



    Template.ticket_view.onCreated ->
        @autorun => Meteor.subscribe 'event_from_ticket_id', Router.current().params.doc_id
        @autorun => Meteor.subscribe 'author_from_doc_id', Router.current().params.doc_id
        @autorun => Meteor.subscribe 'doc', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'all_users'
        
    Template.ticket_view.onRendered ->

    Template.ticket_view.events
        'click .cancel_reservation': ->
            event = @
            # Swal.fire({
            #     title: "cancel reservation?"
            #     # text: "cannot be undone"
            #     icon: 'question'
            #     confirmButtonText: 'confirm cancelation'
            #     confirmButtonColor: 'red'
            #     showCancelButton: true
            #     cancelButtonText: 'return'
            #     reverseButtons: true
            # }).then((result)=>
            #     if result.value
            #         console.log @
            #             Meteor.call 'remove_reservation', @_id, =>
            #                 Swal.fire(
            #                     position: 'top-end',
            #                     icon: 'success',
            #                     title: 'reservation removed',
            #                     showConfirmButton: false,
            #                     timer: 1500
            #                 )
            #                 Router.go "/event/#{event}/view"
            #         )
            # )_



if Meteor.isServer
    Meteor.publish 'event_from_ticket_id', (ticket_id)->
        ticket = Docs.findOne ticket_id
        Docs.find 
            _id:ticket.event_id
            
            
    Meteor.methods
        remove_reservation: (doc_id)->
            Docs.remove doc_id
            
            
            
if Meteor.isClient
    Router.route '/event/:doc_id/edit', (->
        @layout 'layout'
        @render 'event_edit'
        ), name:'event_edit'

    Template.eft_view_item.events 
        'click .pick_eft':->
            Meteor.users.update Meteor.userId(),
                $set:'eft_filter':[@title]
            Router.go '/'
    Template.eft_view_item.helpers 
        in_list: ()->
            if Template.parentData() and Template.parentData().efts
                # cd = Docs.findOne Router.current().params.doc_id 
                @label in Template.parentData().efts
            # @label in cd.efts
    Template.eft_view_item_small.onRendered ->
        Meteor.setTimeout ->
            $('.icon')
                .popup()
        , 2000
    Template.eft_view_item_small.helpers 
        in_list: ()->
            if Template.parentData() and Template.parentData().efts
                # cd = Docs.findOne Router.current().params.doc_id 
                @label in Template.parentData().efts
                # @label in cd.efts
    Template.eft_picker.events 
        'click .toggle_eft': ->
            current_doc = Docs.findOne Router.current().params.doc_id 
            if current_doc.efts
                if @label in current_doc.efts 
                    Docs.update current_doc._id,
                        $pull:
                            efts:@label
                else 
                    Docs.update current_doc._id,
                        $addToSet:
                            efts:@label
            else 
                Docs.update current_doc._id,
                    $addToSet:
                        efts:@label
    Template.eft_picker.helpers 
        toggled: -> 
            current_doc = Docs.findOne Router.current().params.doc_id 
            if current_doc.efts
                @label in current_doc.efts
            else 
                false
        eft_picker_class: ->
            current_doc = Docs.findOne Router.current().params.doc_id 
            if current_doc and current_doc.efts
                if @label in current_doc.efts
                    'basic'
                else
                    'tertiary'
            else 
                'tertiary'


    Template.event_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'model_docs', 'room_reservation', ->
        @autorun => Meteor.subscribe 'model_docs', 'room', ->
    Template.event_edit.onRendered ->
    Template.event_edit.helpers
        rooms: ->
            Docs.find   
                model:'room'


    Template.event_edit.events
        'click .delete_item': ->
            if confirm 'delete item?'
                Docs.remove @_id

        'click .select_room': ->
            reservation_exists = 
                Docs.findOne
                    model:'room_reservation'
                    room_id:event.room_id 
                    date:event.date
            console.log reservation_exists
            unless reservation_exists            
                Docs.update Router.current().params.doc_id,
                    $set:
                        room_id:@_id
                        room_title:@title

        'click .submit': ->
            Docs.update Router.current().params.doc_id,
                $set:published:true
            if confirm 'confirm?'
                Meteor.call 'send_event', @_id, =>
                    Router.go "/event/#{@_id}"


    Template.event_edit.helpers
        reservation_exists: ->
            event = Docs.findOne Router.current().params.doc_id
            Docs.findOne
                model:'room_reservation'
                # room_id:event.room_id 
                date:event.date
        room_button_class: ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
            reservation_exists = 
                Docs.findOne
                    model:'room_reservation'
                    # room_id:event.room_id 
                    date:event.date
            res = ''
            if event.room_id is @_id
                res += 'blue'
            else 
                res += 'basic'
            if reservation_exists
                # console.log 'res exists'
                res += ' disabled'
            else
                console.log 'no res'
            res
    
        room_reservations: ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
            Docs.find 
                model:'room_reservation'
                room_id:event.room_id 
                date:event.date
                
    Template.reserve_button.helpers
        event_room: ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
        slot_res: ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
            Docs.findOne
                model:'room_reservation'
                room_id:event.room_id
                date:event.date
                slot:@slot
    
    
    Template.reserve_button.events
        'click .cancel_res': ->
            Swal.fire({
                title: "confirm delete reservation?"
                text: ""
                icon: 'question'
                showCancelButton: true,
                confirmButtonText: 'confirm'
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Docs.remove @_id
            )
        'click .reserve_slot': ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
            Docs.insert 
                model:'room_reservation'
                room_id:event.room_id
                date:event.date
                slot:@slot
                payment:'points'

if Meteor.isServer
    Meteor.methods
        send_event: (event_id)->
            event = Docs.findOne event_id
            target = Meteor.users.findOne event.recipient_id
            gifter = Meteor.users.findOne event._author_id

            console.log 'sending event', event
            Meteor.users.update target._id,
                $inc:
                    points: event.amount
            Meteor.users.update gifter._id,
                $inc:
                    points: -event.amount
            Docs.update event_id,
                $set:
                    submitted:true
                    submitted_timestamp:Date.now()



            Docs.update Router.current().params.doc_id,
                $set:
                    submitted:true



if Meteor.isClient
    Template.event_view.onCreated ->
        @autorun => Meteor.subscribe 'doc', Router.current().params.doc_id
        @autorun => Meteor.subscribe 'doc_by_slug', Router.current().params.doc_slug
        @autorun => Meteor.subscribe 'author_by_doc_id', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'author_by_doc_slug', Router.current().params.doc_slug

        @autorun => Meteor.subscribe 'event_tickets', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'event_orders', Router.current().params.doc_id, ->
        # @autorun => Meteor.subscribe 'model_docs', 'room'
        
        # if Meteor.isDevelopment
        #     pub_key = Meteor.settings.public.stripe_test_publishable
        # else if Meteor.isProduction
        #     pub_key = Meteor.settings.public.stripe_live_publishable
        # Template.instance().checkout = StripeCheckout.configure(
        #     key: pub_key
        #     image: 'https://res.cloudinary.com/facet/image/upload/v1585357133/one_logo.png'
        #     locale: 'auto'
        #     zipCode: true
        #     token: (token) =>
        #         # amount = parseInt(Session.get('topup_amount'))
        #         event = Docs.findOne Router.current().params.doc_id
        #         charge =
        #             amount: event.price_usd*100
        #             event_id:event._id
        #             currency: 'usd'
        #             source: token.id
        #             input:'number'
        #             # description: token.description
        #             description: "gratigen event ticket purchase"
        #             event_title:event.title
        #             # receipt_email: token.email
        #         Meteor.call 'buy_ticket', charge, (err,res)=>
        #             if err then alert err.reason, 'danger'
        #             else
        #                 console.log 'res', res
        #                 Swal.fire(
        #                     'ticket purchased',
        #                     ''
        #                     'success'
        #                 # Meteor.users.update Meteor.userId(),
        #                 #     $inc: points:500
        #                 )
        # )
    
    Template.event_view.onRendered ->
        Docs.update Router.current().params.doc_id, 
            $inc: views: 1

    Template.event_view.helpers 
        can_buy: ->
            now = Date.now()
            

    Template.event_view.events
        'click .buy_for_points': (e,t)->
            val = parseInt $('.point_input').val()
            Session.set('point_paying',val)
            # $('.ui.modal').modal('show')
            Swal.fire({
                title: "buy ticket for #{Session.get('point_paying')}pts?"
                text: "#{@title}"
                icon: 'question'
                # input:'number'
                confirmButtonText: 'purchase'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Docs.insert 
                        model:'order'
                        order_type:'ticket_purchase'
                        payment_type:'points'
                        is_points:true
                        point_amount:Session.get('point_paying')
                        event_id:@_id
                    Meteor.users.update Meteor.userId(),
                        $inc:points:-Session.get('point_paying')
                    Meteor.users.update @_author_id, 
                        $inc:points:Session.get('point_paying')
                    Swal.fire(
                        position: 'top-end',
                        icon: 'success',
                        title: 'ticket purchased',
                        showConfirmButton: false,
                        timer: 1500
                    )
            )
        
        'click .return': (e,t)->
            # val = parseInt $('.point_input').val()
            # Session.set('point_paying',val)
            # $('.ui.modal').modal('show')
            Swal.fire({
                title: "return ticket?"
                # text: "#{Template.parentData().title}"
                icon: 'question'
                # input:'number'
                confirmButtonText: 'return'
                confirmButtonColor: 'orange'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Docs.remove @_id
                    Swal.fire(
                        position: 'top-end',
                        icon: 'success',
                        title: 'ticket returned',
                        showConfirmButton: false,
                        timer: 1500
                    )
            )
    
        'click .buy_for_usd': (e,t)->
            console.log Template.instance()
            val = parseInt t.$('.usd_input').val()
            Session.set('usd_paying',val)

            instance = Template.instance()
            event = 
                Docs.findOne Router.current().params.doc_id
            console.log event
            if event.price_usd
                Swal.fire({
                    # title: "buy ticket for $#{@usd_price} or more!"
                    title: "buy ticket for $#{event.price_usd}?"
                    text: "for #{@title}"
                    icon: 'question'
                    showCancelButton: true,
                    confirmButtonText: 'purchase'
                    # input:'number'
                    confirmButtonColor: 'green'
                    showCancelButton: true
                    cancelButtonText: 'cancel'
                    reverseButtons: true
                }).then((result)=>
                    if result.value
                        # Session.set('topup_amount',5)
                        # Template.instance().checkout.open
                        instance.checkout.open
                            name: 'gratigen'
                            # email:Meteor.user().emails[0].address
                            description: "#{@title} ticket purchase"
                            amount: event.price_usd*100
                
                        Meteor.users.update @_author_id,
                            $inc:credit:@order_price
                        Swal.fire(
                            'topup initiated',
                            ''
                            'success'
                        )
                )




    
    Template.attendance.events
        'click .mark_maybe': ->
            event = Docs.findOne Router.current().params.doc_id
            Meteor.call 'mark_maybe', Router.current().params.doc_id, ->
    
        'click .mark_not': ->
            event = Docs.findOne Router.current().params.doc_id
            Meteor.call 'mark_not', Router.current().params.doc_id, ->

    Template.event_card.events
        'click .mark_maybe': ->
            Meteor.call 'mark_maybe', @_id, ->
    
        'click .mark_not': ->
            Meteor.call 'mark_not', @_id, ->
    Template.event_view.helpers
        tickets_left: ->
            ticket_count = 
                Docs.find({ 
                    model:'order'
                    # order_type:'ticket_purchase'
                    event_id: Router.current().params.doc_id
                }).count()
            @max_attendees-ticket_count
        event_orders: ->
            Docs.find 
                model:'order'
                


# if Meteor.isServer
#     Meteor.publish 'event_tickets', (event_id)->
#         Docs.find
#             model:'order'
#             order_type:'ticket_purchase'
#             event_id:event_id


Meteor.methods
    'mark_not': (event_id)->
        event = Docs.findOne event_id
        if Meteor.userId() in event.not_user_ids
            Docs.update event_id,
                $pull:
                    not_user_ids: Meteor.userId()
        else
            Docs.update event_id,
                $addToSet:
                    not_user_ids: Meteor.userId()
                $pull:
                    going_user_ids: Meteor.userId()
                    maybe_user_ids: Meteor.userId()

        
    'mark_maybe': (event_id)->
        event = Docs.findOne event_id
        if Meteor.userId() in event.maybe_user_ids
            Docs.update event_id,
                $pull:
                    maybe_user_ids: Meteor.userId()
        else
            Docs.update event_id,
                $addToSet:
                    maybe_user_ids: Meteor.userId()
                $pull:
                    going_user_ids: Meteor.userId()
                    not_user_ids: Meteor.userId()
                    
                    
if Meteor.isServer
    Meteor.publish 'event_tickets', (event_id)->
        event = Docs.findOne event_id 
        if event 
            Docs.find 
                model:'order'
                event_id:event_id
                
    Meteor.publish 'event_orders', (event_id)->
        event = Docs.findOne event_id 
        if event 
            Docs.find 
                model:'order'
                event_id:event_id
                
                
                
if Meteor.isClient
    Template.event_crud.onCreated ->
        @autorun => @subscribe 'event_search_results', Session.get('event_search'), ->
        @autorun => @subscribe 'model_docs', 'event', ->
    Template.event_crud.helpers
        event_results: ->
            if Session.get('event_search') and Session.get('event_search').length > 1
                Docs.find 
                    model:'event'
                    title: {$regex:"#{Session.get('event_search')}",$options:'i'}
                
        picked_events: ->
            ref_doc = Docs.findOne Router.current().params.doc_id
            Docs.find 
                # model:'event'
                _id:$in:ref_doc.event_ids
        event_search_value: ->
            Session.get('event_search')
        assigned_to: ->
            Meteor.users.findOne
                _id: $in: @assigned_to_user_ids
        is_assigning: ->
            Session.equals 'assigning_docid',@_id
            
        has_taken: ->
            @taken_by_user_id and Meteor.userId() is @taken_by_user_id
            # ref_doc = Docs.findOne Router.current().params.doc_id
            # if ref_doc and ref_doc.taken_by_user_id
            #     if Meteor.userId() and Meteor.userId() is ref_doc.taken_by_user_id
            #         true
            #     else 
            #         false
            # else 
            #     false
        is_taken: ->
            @taken_by_user_id
            # ref_doc = Docs.findOne Router.current().params.doc_id
            # if ref_doc and ref_doc.taken_by_user_id
            #     true
        can_take: ->
            if @taken_by_user_id then false else true
            
            # ref_doc = Docs.findOne Router.current().params.doc_id
            # if ref_doc and @taken_by_user_id
            #     false
            # else true
            #     if Meteor.userId() and Meteor.userId() is ref_doc.taken_by_user_id
            #         true
            #     else 
            #         false
            # eles 
            #     false
        taken_user: ->
            ref_doc = Docs.findOne @_id
            Meteor.users.findOne _id:ref_doc.taken_by_user_id
            
            
    Template.event_crud.events
        'click .toggle_assign': ->
            Session.set('assigning_docid',@_id)
        'click .clear_search': (e,t)->
            Session.set('event_search', null)
            t.$('.event_search').val('')

        'click .take_event': ->
            console.log @
            Docs.update @_id,
                $set:taken_by_user_id:Meteor.userId()
            $('body').toast({
                title: "#{@title} taken"
                message: 'yeay'
                class : 'success'
                showIcon:'shield'
                showProgress:'bottom'
                position:'bottom right'
            })

        'click .release_event': ->
            console.log @
            Docs.update @_id,
                $unset:taken_by_user_id:1
            $('body').toast({
                title: "event released: #{@title}"
                message: 'yeay'
                class : 'info'
                showIcon:'shield'
                showProgress:'bottom'
                position:'bottom right'
            })

            
        'click .remove_event': (e,t)->
            if confirm "remove #{@title} event?"
                Docs.update Router.current().params.doc_id,
                    $pull:
                        event_ids:@_id
                        event_titles:@title
                $(e.currentTarget).closest('.card').transition('fly right', 500)

        'click .pick_event': (e,t)->
            Docs.update Router.current().params.doc_id,
                $addToSet:
                    event_ids:@_id
                    event_titles:@title
            Session.set('event_search',null)
            t.$('.event_search').val('')
                    
        'keyup .event_search': (e,t)->
            # if e.which is '13'
            val = t.$('.event_search').val()
            console.log val
            Session.set('event_search', val)
            if e.which is '13'
                new_id = 
                    Docs.insert 
                        model:'event'
                        title:Session.get('event_search')
                Docs.update Router.current().params.doc_id,
                    $addToSet:
                        event_ids:new_id
                        event_titles:Session.get('event_search')
                $('body').toast({
                    title: "added #{Session.get('event_search')}"
                    message: 'yeay'
                    class : 'success'
                    showIcon:'shield'
                    showProgress:'bottom'
                    position:'bottom right'
                })

        'click .create_event': ->
            parent = Docs.findOne Router.current().params.doc_id
            new_id = 
                Docs.insert 
                    model:'event'
                    title:Session.get('event_search')
                    parent_id:parent._id
                    parent_model:parent.model
            Docs.update Router.current().params.doc_id,
                $addToSet:
                    event_ids:new_id
                    event_titles:Session.get('event_search')
            $('body').toast({
                title: "added #{Session.get('event_search')}"
                message: 'yeay'
                class : 'success'
                showIcon:'shield'
                showProgress:'bottom'
                position:'bottom right'
            })
                    
            Session.set('event_search',null)
        
            # Docs.update
            # Router.go "/event/#{new_id}/edit"


if Meteor.isServer 
    Meteor.publish 'event_search_results', (title_query)->
        Docs.find 
            model:'event'
            title: {$regex:"#{title_query}",$options:'i'}