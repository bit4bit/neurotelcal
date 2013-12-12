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
#
# Para crear una nueva action
#  * Heredar de *Action*
#  * implementar *guiConfig* *gui*
#  * agregar a IVR::actions
#

Array::unique_string = ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output

Array::inArray = (v)->
        output = {}
        output[@[key]] = @[key] for key in [0...@length]
        rt = value for key, value of output when v + '' == value + ''
        if rt
                true
        else
                false
        
translation =
        "configure_advance": "Cambia interfaz del IVR"
        "configure": "configurar"
        "add": "agregar"
        "delete": "Eliminar"
        "resource": "Recurso"
        "hangup_title": "Colgar"
        "hangup": "Colgar"
        "hangup a call": "Colgar llamada"
        "add_action_title": "Gestor de acciones"
        "playback_action": "Reproducir"
        "playback_err_select_resource": "Debe escoger recurso"
        "playback_action_desc": "reproduce archivo de audio"
        "playback_config_title": "Reproducir"
        "playback_action_without_resource": "sin recurso seleccionado"
        "playback_action_resource_upload": "Agregar Recurso"
        "surveyivr_action": "Encuestar"
        "surveyivr_action_desc": "Realize encuesta"
        "surveyivr_err_not_option": "(Debe escoger) una opcion esperada ser presionada por el cliente"
        "surveyivr_err_not_resource": "Debe escoger un audio"
        "surveyivr_choose_one": "Debe escoger"
        "surveyivr_digit": "Digitos"
        "surveyivr_duration": "Duracion"
        "surveyivr_tries": "Intentos"
        "surveyivr_only_conditional": "Solo bifuracion"
        "surveyivr_only_conditional_help": "Active si desea continuar el IVR superior, tomara el la respuesta del cliente del IVR superior"
        "surveyivr_digit_help":"Seleccion los digitos permitidos por el cliente, esto es usado para crear un IVR mas complejo. Usar creando mas Encuestas de solo bifurcacion"
$.i18n.setDictionary(translation)


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

        #Permite asignar valores de configuracion
        # a la accion
        set: ->
                
#Esta accion
#se encarga de ser una accion parar agregar
#otras acciones.
class AddAction extends Action
        copy: ->
                new AddAction(@ivr)
                
        cbAddAction: ->
                self = @
                dialog = $('<div>',{title:$.i18n._("add_action_title")})
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
        commandName: $.i18n._('hangup')
        timeElapsed: 0

        copy: ->
                new HangupAction(@ivr)
                
        guiItem: ->
                item = $('<li>')
                a = $('<a>',{href:'#'})
                a.html('<b>'+@commandName+':</b>' + $.i18n._('hangup a call'))
                item.append(a)
                @assignAction(item)

        guiLabel: ->
                '<b>'+@commandName+' .seg ' + @timeElapsed + '</b> '
                
        configure: ->
                self = @
                dialog = $('<div>',{title:$.i18n._('hangup_title')})
                label = $('<label>',{for:"time_elapsed"})
                label.html('<b>Seg.</b>')
                dialog.append(label)
                input = $('<select>')
                input.change ->
                        self.timeElapsed = parseInt($(this).val())
                        self.label.html(self.guiLabel())

                for time in [0..60] by 5
                        if self.timeElapsed == time
                                input.append($('<option selected="selected">').text(time))
                        else
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
                config.html(' ' + $.i18n._('configure') + ' ')
                config.click ->
                        self.configure()
                item.append(config)
                
        set: (sec) ->
                @timeElapsed  = sec
                @label.html(@guiLabel())
                
        toNeurotelcal: ->
                #@todo estado??
                if parseInt(@timeElapsed) > 0
                        return 'Colgar segundos=' + @timeElapsed + ' razon="normal"\n'
                else
                        return 'Colgar' + "\n"
                        
class PlaybackAction extends Action
        commandName: $.i18n._("playback_action")
        
        @resource: undefined

        validate: ->
                self = @
                if @resource == undefined || @resource == "" || @resource == '----'
                        ret = ->
                                self.guiConfig()
                        @ivr.showError(ret, $.i18n._("playback_err_select_resource"))
                        return false
                return true
                
        copy: ->
                new PlaybackAction(@ivr)
                
        parseWord: ->
                'Reproducir'

        guiItem: ->
                item = $('<li>')
                a = $('<a>',{href:'#'})
                a.html('<b>' + $.i18n._('playback_action') + ': </b> ' + $.i18n._('playback_action_desc'))
                item.append(a)
                @assignAction(a)
                
        _guiLabel: ->
                '<b>' + $.i18n._("playback_action") + ':</b> ' + @resource
                
        guiConfig:(item) ->
                self = @
                dialog = $('<div>',{title: $.i18n._('playback_config_title')})
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
                        if $(this).val() == '' || $(this).val() == '----'
                                self.resource = undefined
                        else
                                dialog.remove()
                                self.resource = $(this).val()
                                self.label.html(self._guiLabel())
                                self.ivr.update() #@bug despues de crear se necesita
                dialog.append(select)
                dialog.append('<br>')
                resource_upload = $('<a>', {href:'#'})
                resource_upload.html('<b>' + $.i18n._('playback_action_resource_upload') + '</b>')
                dialog.append(resource_upload)
                dialog.append('<br>')
                resource_upload.click ->
                        drl = $('#resource_upload')

                        drl.dialog
                                modal:true
                                close: ->
                                        dialog.remove()
                                        self.guiConfig()

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
                @label.html('<b>' + $.i18n._('playback_action') + ':</b>' + $.i18n._('playback_action_without_resource'))
                @label.click ->
                        self.guiConfig($(this))
                item.append(@label)
                @assignAction(item)
                
        set: (resource) ->
                @resource = resource
                @label.html(@_guiLabel())
                
        toNeurotelcal: ->
                'Reproducir "' + @resource + '"\n'
                
class SurveyIVR extends Action
        @uuid: 0
        commandName: $.i18n._("surveyivr_action")
        digits: []
        duration: 5
        tries: 1
        resource: ""
        option: undefined
        only_conditional: false
        
        validate: ->
                self = @

                ret = ->
                        self.guiConfig()
                        
                if @resource == undefined || @resource == ''  && !@only_conditional
                        @ivr.showError(ret, $.i18n._("surveyivr_err_not_resource"))
                if @option == undefined || @option == '' 
                        @ivr.showError(ret, $.i18n._("surveyivr_err_not_option"))
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
                label.html('<b>' + $.i18n._('resource') + '</b>')
                dialog.append(label)
                sel_resource = $('<select>', {name:'resource'})
                dialog.append(sel_resource)
                resources = ['']
                $('#resources div').each (index, value) ->
                        resources.push($(value).html())
                for resource in resources
                        if resource == self.resource
                                sel_resource.append($('<option selected>').text(resource))
                        else
                                sel_resource.append($('<option>').text(resource))
                sel_resource.click ->
                        self.resource = $(this).val()

                dialog.append($('<br>'))
                #SELECCION OPCION ESPERADA
                label = $('<label>', {for:'option'})
                label.html('<b>' + $.i18n._('surveyivr_choose_one') + '</b>')
                dialog.append(label)
                digits = ['', '0','1', '2', '3', '4', '5', '6', '7', '8', '9', '#']
                sel_option = $('<select>',{name:'option'})
                dialog.append(sel_option)
                sel_option.click ->
                        self.option = $(this).val()
                        self.digits = [self.option] #??

                for digit in digits
                        if parseInt(@option) == parseInt(digit)
                                sel_option.append($('<option selected="selected">').text(digit))
                        else
                                sel_option.append($('<option>').text(digit))

                dialog.append($('<br>'))
                #SELECCION DIGITO
                label = $('<label>', {for:'digit', title:$.i18n._('surveyivr_digit_help')})
                label.text($.i18n._("surveyivr_digit"))
                dialog.append(label)
                sel_digit = $('<select>',{name:"digit", multiple:'multiple'})
                sel_digit.change ->
                        self.digits = $(this).val().unique_string()

                digits = ['', '0','1', '2', '3', '4', '5', '6', '7', '8', '9', '#']

                for digit in digits
                        if self.digits.inArray(digit)
                                sel_digit.append($('<option selected="selected">').text(digit+''))
                        else
                                sel_digit.append($('<option>').text(digit))
                dialog.append(sel_digit)
                dialog.append($('<br>'))
                #SEL DURACION
                label = $('<label>', {for:'duration'})
                label.text($.i18n._('surveyivr_duration'))
                dialog.append(label)
                sel_duration = $('<select>',{name:"duration"})
                sel_duration.change ->
                        self.duration = parseInt($(this).val())
                durations = [5..60]

                for duration in durations

                        if parseInt(self.duration) == parseInt(duration)
                                sel_duration.append($('<option selected="selected">').text(self.duration))
                        else
                                sel_duration.append($('<option>').text(duration))
                dialog.append(sel_duration)

                label = $('<label>', {for:'tries'})
                label.text($.i18n._('surveyivr_tries'))
                dialog.append(label)
                sel_tries = $('<select>',{name:"tries"})
                sel_tries.change ->
                        self.tries = parseInt($(this).val())
                tries = [1..5]
                for trie in tries
                        if parseInt(self.tries) == parseInt(trie)
                                sel_tries.append($('<option selected="selected">').text(self.tries))
                        else
                                sel_tries.append($('<option>').text(trie))
                dialog.append(sel_tries)
                dialog.append($('<br>'))
                #DIGITOS VALIDOS
                
                #SOLO BIFURCACION
                label = $('<label>', {for:'only_conditional', title: $.i18n._('surveyivr_only_conditional_help')})
                label.text($.i18n._('surveyivr_only_conditional'))
                dialog.append(label)
                check_conditional = $('<input>', {type:"checkbox", name:'only_conditional'})
                check_conditional.attr('checked', @only_conditional)
                dialog.append(check_conditional)
                items_dialog = [sel_resource, sel_digit, sel_duration, sel_tries]
                for item_dialog in items_dialog
                        if @only_conditional
                                item_dialog.prop('disabled',true)
                                
                check_conditional.change ->
                        self.only_conditional = this.checked

                        for item_dialog in items_dialog 
                                if this.checked
                                        item_dialog.prop('disabled', true)
                                else
                                        item_dialog.prop('disabled', false)


                dialog.append('<br>')
                resource_upload = $('<a>', {href:'#'})
                resource_upload.html('<b>' + $.i18n._('playback_action_resource_upload') + '</b>')
                dialog.append(resource_upload)
                dialog.append('<br>')
                resource_upload.click ->
                        drl = $('#resource_upload')

                        drl.dialog
                                modal:true
                                close: ->
                                        dialog.remove()
                                        self.guiConfig()


                on_close = (event,ui) ->
                        self.ivr.update()
                        if !self.validate()
                                self.configure()
                        return true
                        
                dialog.dialog({modal:true, close: on_close })
                
        guiItem: ->
                item = $('<li>')
                a = $('<a>',{href:'#'})
                a.html('<b>' + @commandName + ':</b>' + $.i18n._('surveyivr_action_desc'))
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
                digitosValidos = ""
                if @digits.length > 0
                        digitosValidos = @digits.unique_string().join('')
                        @digits = @digits.unique_string()
                else
                        digitosValidos = @option
                cantidad = 0
                if @digits.length > 0
                        cantidad = 1

                out = ''
                out += 'Registrar digitos cantidad=' + cantidad + ' audio="' + @resource + '"' + ' duracion=' + @duration + ' intentos=' + @tries + ' digitosValidos="' + digitosValidos + '" \n' if !@only_conditional
                out = out.trim()
                out += '\n'

                ivr_yes_desc = @ivr_yes.toNeurotelcal()
                ivr_no_desc = @ivr_no.toNeurotelcal()
                if ivr_yes_desc.length > 0 or ivr_no_desc.length > 0
                        out += 'Si =' + @option + '\n' + @ivr_yes.toNeurotelcal() + '\n' + 'No' +' \n' + @ivr_no.toNeurotelcal() + '\n' + 'Fin\n'

                out = out.trim()
                out += '\n'
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
                close.attr('title', $.i18n._('delete'))
                close.css('color','red')
                close.click ->
                        self.actions.splice($.inArray(action, self.actions), 1)
                        gui.remove()
                        self.update()
                        
                #close.appendTo(gui.first())
                ($(gui.children()[0])).before(close)
                action.guiConfig()
                gui.appendTo(@root)
                @update()
                @createLastAction().appendTo(@root)
                #fix height
                ht =$.ivr.ivr.height()
                ht += gui.height()/2
                $.ivr.ivr.height(ht)

        update: ->
                description_field = $('#message_description')
                #@hack ya al creado
                description_field.text($.ivr.toNeurotelcal())
                
        toNeurotelcal: ->
                out = ''
                for action in @actions
                        out += action.toNeurotelcal()
                out



#Se encarga de construir el IVR
# apartir del comando,argumento,variables del lenguage
# Neurotelcal
class IVRBuilder
        ivrs: []
        constructor: (@ivr) ->
                @ivrs.push(@ivr)
                @on_yes = false
                @on_no = false
                @depth = 0 #aumenta si esta en Si
                
        build: (command, argument, vars) ->
                ivr_working = @ivrs[@depth]
                if @on_yes
                        ivr_working = @ivrs[@depth].ivr_yes
                else if @on_no
                        ivr_working = @ivrs[@depth].ivr_no
                switch command
                        when "Reproducir"
                                @buildPlayback(ivr_working, argument.replace(/\"/g,''))
                        when "Colgar"
                                @buildHangup(ivr_working, parseInt(vars["segundos"]))
                        when "Registrar"
                                @buildSurveyIVR(ivr_working, vars)
                        when "Si"
                                @depth += 1
                                @on_yes = true
                                @ivrs[@depth].option = parseInt(vars[""])
                                @ivrs[@depth].digits.push(parseInt(vars[""]))
                        when "No"
                                @on_yes = false
                                @on_no = true
                        when "Fin"
                                @on_no = false
                                @depth -= 1
        buildPlayback: (ivr, resource) ->
                resource = resource
                action = new PlaybackAction(ivr)
                config = action.guiConfig
                action.guiConfig = ->
                ivr.addAction(action)
                action.guiConfig = config
                action.set(resource)
                
        buildHangup: (ivr, seg) ->
                seg = parseInt(seg)
                seg = 0 if isNaN(seg)
                action = new HangupAction(ivr)
                ivr.addAction(action)
                action.set(parseInt(seg))

        buildSurveyIVR: (ivr, vars) ->
                tivr = new SurveyIVR(ivr)
                config = tivr.guiConfig
                tivr.guiConfig = ->
                ivr.addAction(tivr)
                tivr.guiConfig = config

                tivr.digits = (''+vars["digitosValidos"]).split("")

                tivr.tries = parseInt(vars["intentos"])
                tivr.duration = parseInt(vars["duracion"])
                tivr.resource = vars["audio"]
                @ivrs.push(tivr)

#IVRParse lee cadena de texto y actualiza ivr
# agregando las actions
class IVRParse
        constructor: (@ivr) ->
                @builder = new IVRBuilder(@ivr)
                
        parse: (text) ->
                for line in text.split('\n')
                        continue if line.replace(" ").length == 0

                        tokens = line.split(' ')

                        command = tokens.shift()
                        variables = {}
                        argument = ""

                        if tokens[0] != undefined && tokens[0].indexOf('=') == -1
                                argument = tokens.shift()
                                
                        for token in tokens
                                variable = token.split("=")
                                variables[variable[0]] = variable[1].replace(/\"/g,"")
                        @builder.build(command, argument, variables)

$ ->
        $.ivr = new IVR
        $.ivr.initializeRoot()
        p = $('#message_description').parent()
        advance = $('<a>', {href:'#'})
        advance.html('<b>' + $.i18n._('configure_advance') + '</b>')
        advance.click ->
                $('#message_description').toggle()
                $('#message_help').toggle()
                $.ivr.ivr.toggle()
        p.append($('<br>'))
        p.append(advance)
        $('#message_description').hide()
        $('#message_help').hide()
        if $('#message_description').text().length > 0
                parser = new IVRParse($.ivr)
                parser.parse($('#message_description').text())
                $.ivr.update()

        $('#resource_upload').hide()
        $('#resource_upload form').ajaxForm
                dataType: 'json'
                error: (xhr, status, error, form) ->
                        data = JSON.parse(xhr.responseText)
                        msg = ''
                        for k in Object.keys(data)
                                msg += '*' + k + ': ' + data[k] + '\n'
                        alert(msg)
                        form.clearForm()
                success: (data, status, xhr, form) ->
                        r = $('<div>')
                        r.text(data.name)
                        $('div#resources').append(r)
                        form.clearForm()
                        form.parent().dialog('close')

