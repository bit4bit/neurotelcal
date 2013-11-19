# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
#
#inicializa el IVR
#oculta la zona de escritura y
#muestra el IVR
#El IVR utiliza *jquery-ui* especialmente
#el *widget* *Menu* para mostrar el IVR.
#Este IVR tiene un Menu que es una lista
#de acciones.ej
#IVR
#sin accion [agregar] -> al agregar se puede escoger

class Action
        constructor: (@ivr) ->

        assignAction: (item) ->
                $.data(item[0], 'action', @)
                return item
                
        #Data para presentar
        # al mostrar listado de seleccion
        guiItem: ->
                item = $('<li>')
                item.text('nada guiItem')
                @assignAction(item)
        #Data para presentar al configurar
        #Usualmente muestra dialog model
        guiConfig: ->
                item = $('<li>')
                item.text('nada guiConfig')
                @assignAction(item)
                
        #Item para para el menu en el ivr
        # esto debe ser <li>..</li>
        gui: ->
                item = $('<li>')
                item.text('nada ')
                item.action = @
                @assignAction(item)

        #Retorna string de cadena en lenguage ivr neurotelcal
        toNeurotelcal: ->
                ''
        #Retorna string de al cual responde
        #en el parseo
        parseWord: ->
                ''


#Esta accion
#se encarga de ser una accion parar agregar
#otras acciones.
class AddAction extends Action
        cbAddAction: ->
                self = @
                dialog = $('<div>')
                menu = $('<ul>')

                for action in @ivr.actions
                        item = action.guiItem()
                        item.click ->
                                sel_action = $.data(this, 'action')
                                sel_action.ivr.addAction(sel_action)

                                dialog.remove()
                        menu.append(item)
                        
                dialog.append(menu)
                dialog.dialog({modal:true})

        #Data para presentar
        # al mostrar listado de seleccion
        guiItem: ->
                item = $('<li>')
                item.text('nada guiItem')
                
        #Data para presentar al configurar
        #Usualmente muestra dialog model
        guiConfig: ->
                item = $('<li>')
                item.text('nada guiConfig')
                
        #Item para para el menu en el ivr
        # esto debe ser <li>..</li>
        gui: ->
                self = @
                @item = $('<li>')
                @item.text('sin accion ')
                @add_action = $('<a>',{href:'#'})
                @add_action.text('agregar')

                @add_action.click ->
                        self.cbAddAction()
                        undefined
                        
                @item.append([
                        @add_action
                ])
        #Retorna string de al cual responde
        #en el parseo
        parseWord: ->
                ''
        

class HangupAction extends Action
        commandName: 'Colgar'
        timeElapsed: 0
        
        guiItem: ->
                item = $('<li>')
                a = $('<a>',{href:'#'})
                a.html('<b>'+@commandName+':</b> Hangup call')
                item.append(a)
                @assignAction(item)

        guiLabel: ->
                '<b>'+@commandName+' .seg ' + @timeElapsed + '</b> '
                
        configure: ->
                self = @
                dialog = $('<div>')
                label = $('<label>',{for:"time_elapsed"})
                dialog.append(label)
                input = $('<select>')
                input.change ->
                        self.timeElapsed = parseInt($(this).val())
                        self.label.html(self.guiLabel())

                for time in [0..10]
                        input.append($('<option>').text(time))
                dialog.append(input)
                dialog.dialog({modal:true})
        gui: ->
                self = @
                item = $('<li>')
                @label = $('<span>')
                @label.html(@guiLabel())
                item.append(@label)
                config = $('<a>', {href:'#'})
                config.html(' configurar ')
                config.click ->
                        self.configure()
                item.append(config)

class PlaybackAction extends Action
        @resource: undefined
        
        parseWord: ->
                'Reproducir'

        guiItem: ->
                item = $('<li>')
                a = $('<a>',{href:'#'})
                a.html('<b>Playback audio: </b> this option allow playback audio')
                item.append(a)
                @assignAction(a)
                
        guiConfig:(item) ->
                self = @
                dialog = $('<div>',{title:'Playback Config'})
                resources = []
                $('#resources div').each (index, value) ->
                        resources.push($(value).html())
                select = $('<select>')
                for resource in resources
                        if resource == self.resource
                                select.append($('<option selected>').text(resource))
                        else
                                select.append($('<option>').text(resource))
                select.change ->
                        if $(this).val() == ''
                                self.resource = undefined
                        self.resource = $(this).val()
                        item.html('<b>Reproducir:</b> ' + self.resource)
                dialog.append(select)
                dialog.dialog({modal:true})
                
        gui: ->
                self = @
                item = $('<li>')
                a = $('<a>',{href:'#'})
                a.html('<b>Reproducir:</b> sin archivo seleccionado')
                a.click ->
                        self.guiConfig($(this))
                item.append(a)
                @assignAction(item)


class SurveyIVR extends Action
        @uuid: 0
        commandName: 'SurveyIVR'
        digits: []
        duration: undefined
        tries: undefined
        
        configure: ->
                self = @
                dialog = $('<div>')

                label = $('<label>', {for:'digit'})
                label.text('Digitos')
                dialog.append(label)
                sel_digit = $('<select>',{name:"digit", multiple:'multiple'})
                sel_digit.change ->
                        self.digits = $(this).val()

                digits = ['0','1', '2', '3', '4', '5', '6', '7', '8', '9', '#']
                for digit in digits
                        if $.inArray(digit, self.digits) >= 0
                                sel_digit.append($('<option selected="selected">').text(digit))
                        else
                                sel_digit.append($('<option>').text(digit))
                dialog.append(sel_digit)

                label = $('<label>', {for:'duration'})
                label.text('Duracion')
                dialog.append(label)
                sel_duration = $('<select>',{name:"duration"})
                sel_duration.change ->
                        self.duration = parseInt($(this).val())
                durations = [5..15]

                for duration in durations
                        if parseInt(self.duration) == parseInt(duration)
                                sel_duration.append($('<option selected="selected">').text(duration))
                        else
                                sel_duration.append($('<option>').text(duration))
                dialog.append(sel_duration)

                label = $('<label>', {for:'tries'})
                label.text('Intentos')
                dialog.append(label)
                sel_tries = $('<select>',{name:"tries"})
                sel_tries.change ->
                        self.tries = parseInt($(this).val())
                tries = [1..5]
                for trie in tries
                        if parseInt(self.tries) == parseInt(trie)
                                sel_tries.append($('<option selected="selected">').text(trie))
                        else
                                sel_tries.append($('<option>').text(trie))
                dialog.append(sel_tries)
                dialog.dialog({modal:true})
                
        guiItem: ->
                item = $('<li>')
                a = $('<a>',{href:'#'})
                a.html('<b>SurveyIVR:</b>Do surveys')
                item.append(a)
                @assignAction(item)

        gui: ->
                SurveyIVR.uuid += 1
                self = @
                item = $('<li>')
                a = $('<span>')
                a.html('<b>'+@commandName+':</b>')
                item.append(a)
                
                a_config = $('<a>', {href:'#'})
                a_config.html(' configurar ')
                a_config.click ->
                        self.configure()
                item.append(a_config)

                #agrupa [ Si Hacer | No Hacer ]
                block = $('<table>')
                row = $('<tr>')
                col_yes = $('<td>')
                col_yes.html('<b>Si Hacer</b>')
                col_no = $('<td>')
                col_no.html('<b>No Hacer</b>')
                row.append(col_yes)
                row.append(col_no)
                block.append(row)
                item.append(block)
                
                ivr_yes = $('<div>')
                @ivr_yes = new IVR()
                @ivr_yes.initializeBranch(ivr_yes, 'ivr-yes' + SurveyIVR.uuid)
                col_yes.append(ivr_yes)

                
                ivr_no = $('<div>')
                @ivr_no = new IVR()
                @ivr_no.initializeBranch(ivr_no, 'ivr-no' + SurveyIVR.uuid)
                col_no.append(ivr_no)

                @assignAction(item)
                
class IVR
        constructor: () ->
                @actions = [
                        new PlaybackAction(@)
                        new SurveyIVR(@)
                        new HangupAction(@)
                        ]
                
        initializeRoot: ->
                @uid = 'ivr-root'
                #el campo donde se escribe el mensaje actualmente
                description_field = $('#message_description').parent()
                #ivr donde se pone el recuadro
                @ivr = $('#ivr')

                @ivr.css("width", "100%")
                @ivr.css("min-height", "100%")
                @ivr.css("height", description_field.css("height"))
                @ivr.css("border", "1px solid black")
                @ivr.css("background-color", "#FFFFFF")

                description_field.css('display', 'none')

                @initialize()

        initializeBranch: (root, uid) ->
                @ivr = root
                @ivr.css("width","100%")
                @uid = uid
                @root = $('<ul>',{id:'ivr-menu' + @uid, class: "ui-widget ui-widget-content ui-corner-all"})
                @createLastAction().appendTo(@root)
                @ivr.append(@root)
                

                
        initialize: ->
                @root = $('<ul>',{id:'ivr-menu' + @uid})
                @root.menu()
                @createLastAction().appendTo(@root)
                @ivr.append(@root)
                
        createLastAction: ->
                action = new AddAction(@)
                gui = action.gui()
                gui.attr('id', 'last-action-ivr-menu' + @uid)
                
        deleteLastAction: ->
                action = $('#last-action-ivr-menu' + @uid)
                action.remove()
                return action
                
        addAction: (action) ->
                @deleteLastAction()
                gui = action.gui()
                close = $('<a>',{href:'#'})
                close.html(' <b>X</b> ')
                close.attr('title','Delete')
                close.click ->
                        gui.remove()
                close.appendTo(gui)

                
                gui.appendTo(@root)
                @createLastAction().appendTo(@root)
                
$ ->
        $.ivr = new IVR
        $.ivr.initializeRoot()

