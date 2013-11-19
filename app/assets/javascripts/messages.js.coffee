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

        copy: ->
                new Action(@ivr)
                
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
        # al agregarse al ivr se muestra inmediatamente
        guiConfig: ->
                item = $('<li>')
                item.text('nada guiConfig')
                @ivr.update()
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

        #Retorna bool indicando si es valido
        # sino llama $.ivr.addError(this, 'mensaje') para
        # mostrar mensaje de error
        validate: ->
                true
                
#Esta accion
#se encarga de ser una accion parar agregar
#otras acciones.
class AddAction extends Action
        copy: ->
                new AddAction(@ivr)
                
        cbAddAction: ->
                self = @
                dialog = $('<div>')
                menu = $('<ul>')

                for action in @ivr.actionsAllowed
                        item = action.guiItem()
                        item.click ->
                                sel_action = $.data(this, 'action')
                                sel_action.ivr.addAction(sel_action.copy())

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
                @ivr.update()
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

        copy: ->
                new HangupAction(@ivr)
                
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
                label.html('<b>Seg.</b>')
                dialog.append(label)
                input = $('<select>')
                input.change ->
                        self.timeElapsed = parseInt($(this).val())
                        self.label.html(self.guiLabel())

                for time in [0..10]
                        input.append($('<option>').text(time))
                dialog.append(input)
                on_close = ->
                        self.ivr.update()
                dialog.dialog({modal:true, close: on_close})
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

        toNeurotelcal: ->
                #@todo estado??
                'Colgar segundos="' + @timeElapsed + '"\n'
                
class PlaybackAction extends Action
        @resource: undefined

        validate: ->
                self = @
                if @resource == undefined || @resource == "" || @resource == '----'
                        ret = ->
                                self.guiConfig()
                        @ivr.showError(ret, "Debe escoger el recurso")
                        return false
                return true
                
        copy: ->
                new PlaybackAction(@ivr)
                
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
                label = $('<label>',{for:'playback'})
                label.html('<b>Recurso</b>')
                dialog.append(label)
                resources = ['----']
                $('#resources div').each (index, value) ->
                        resources.push($(value).html())
                select = $('<select>', {name:'playback'})
                for resource in resources
                        if resource == self.resource
                                select.append($('<option selected>').text(resource))
                        else
                                select.append($('<option>').text(resource))
                select.change ->
                        if $(this).val() == ''
                                self.resource = undefined
                        self.resource = $(this).val()
                        self.label.html('<b>Reproducir:</b> ' + self.resource)
                dialog.append(select)
                on_close = ->
                        self.ivr.update()
                        if !self.validate()
                                self.guiConfig()
                        return undefined
                dialog.dialog({modal:true, close: on_close})
                
        gui: ->
                self = @
                item = $('<li>')
                @label = $('<a>',{href:'#'})
                @label.html('<b>Reproducir:</b> sin archivo seleccionado')
                @label.click ->
                        self.guiConfig($(this))
                item.append(@label)
                @assignAction(item)

        toNeurotelcal: ->
                'Reproducir "' + @resource + '"\n'
                
class SurveyIVR extends Action
        @uuid: 0
        commandName: 'SurveyIVR'
        digits: []
        duration: 5
        tries: 1
        resource: ""
        option: undefined

        validate: ->
                self = @
                if @option == undefined
                        ret = ->
                                self.guiConfig()
                        @ivr.showError(ret, "No hay opcion para el cliente presionar (Debe escoger) ")
                        return false
                return true
                
        copy: ->
                new SurveyIVR(@ivr)

        guiConfig: ->
                @configure()
                
        configure: ->
                self = @
                dialog = $('<div>')
                
                #SELECCION RECURSO
                label = $('<label>', {for:'resource'})
                label.html('<b>Recurso</b>')
                dialog.append(label)
                sel_resource = $('<select>', {name:'resource'})
                dialog.append(sel_resource)
                resources = []
                $('#resources div').each (index, value) ->
                        resources.push($(value).html())
                for resource in resources
                        if resource == self.resource
                                sel_resource.append($('<option selected>').text(resource))
                        else
                                sel_resource.append($('<option>').text(resource))
                sel_resource.click ->
                        self.resource = $(this).val()

                #SELECCION OPCION ESPERADA

                label = $('<label>', {for:'option'})
                label.html('<b>Debe Escoger</b>')
                dialog.append(label)
                digits = ['0','1', '2', '3', '4', '5', '6', '7', '8', '9', '#']
                sel_option = $('<select>',{name:'option'})
                dialog.append(sel_option)
                sel_option.click ->
                        self.option = $(this).val()
                        self.digits = [self.option] #??
                for digit in digits
                        if @option == digit
                                sel_option.append($('<option selected="selected">').text(digit))
                        else
                                sel_option.append($('<option>').text(digit))
                                   
                #SELECCION DIGITO
                # se omite se
                label = $('<label>', {for:'digit'})
                label.text('Digitos')
                #dialog.append(label)
                sel_digit = $('<select>',{name:"digit", multiple:'multiple'})
                sel_digit.change ->
                        self.digits = $(this).val()

                digits = ['0','1', '2', '3', '4', '5', '6', '7', '8', '9', '#']
                for digit in digits
                        if $.inArray(digit, self.digits) >= 0
                                sel_digit.append($('<option selected="selected">').text(digit))
                        else
                                sel_digit.append($('<option>').text(digit))
                #dialog.append(sel_digit)

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

                on_close = (event,ui) ->
                        self.ivr.update()
                        if !self.validate()
                                self.configure()
                        return true
                        
                dialog.dialog({modal:true, close: on_close })
                
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

        toNeurotelcal: ->
                out = ''
                out += 'Registrar digitos cantidad=' + @digits.length + ' audio="' + @resource + '"' + ' duracion=' + @duration + ' intentos=' + @tries + '\n'
                out += 'Si =' + @option + '\n' + @ivr_yes.toNeurotelcal() + '\n' + 'No' +' \n' + @ivr_no.toNeurotelcal() + '\n' + 'Fin\n'
                out
                
class IVR
        constructor: () ->
                @errors = []
                @actions = []
                @actionsAllowed = [
                        new PlaybackAction(@)
                        new SurveyIVR(@)
                        new HangupAction(@)
                        ]

        clearErrors: ->
                @errors = []
                
        showError: (ret, msg) ->
                #dialog = $('<div>')

                gerror = $('<span>')
                gerror.css('backgrund-color', 'red')
                gerror.html(msg)
                #dialog.append(gerror)
                alert(gerror.html())
                #dialog.dialog({modal:true, close: ret})

                

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

                #description_field.css('display', 'none')

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
                self = @
                @actions.push(action)
                @deleteLastAction()
                gui = action.gui()
                close = $('<a>',{href:'#'})
                close.html(' <b>X</b> ')
                close.attr('title','Delete')
                close.click ->
                        self.actions.splice($.inArray(action, self.actions), 1)
                        gui.remove()
                        self.update()
                close.appendTo(gui)
                action.guiConfig()
                
                gui.appendTo(@root)
                @update()
                @createLastAction().appendTo(@root)

        update: ->
                description_field = $('#message_description')
                #@hack ya al creado
                description_field.text($.ivr.toNeurotelcal())
                
        toNeurotelcal: ->
                out = ''
                for action in @actions
                        out += action.toNeurotelcal()
                out
$ ->
        $.ivr = new IVR
        $.ivr.initializeRoot()
