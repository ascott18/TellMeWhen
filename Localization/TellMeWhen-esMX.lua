
local L = LibStub("AceLocale-3.0"):NewLocale("TellMeWhen", "esMX", false)
if not L then return end











L["CHOOSENAME_DIALOG"] = [=[Introduzca el nombre o la identificación de los hechizos / Capacidad / artículo / Buff / Debuff desea que este icono de la pantalla. Usted puede agregar múltiples Buffs / Debuffs separándolas con';'.
HABILIDADES PET debe utilizar SpellIDs.]=] -- Needs review
L["CHOOSENAME_DIALOG_DDDEFAULT"] = "Conjuntos predefinidos Hechizo" -- Needs review
L["CHOOSENAME_EQUIVS_TOOLTIP"] = "Usted puede seleccionar un conjunto predefinido de aficionados / desventajas de este menú."
L["CMD_OPTIONS"] = "Opciones" -- Needs review
L["CONDITIONPANEL_AND"] = "Y"
L["CONDITIONPANEL_ANDOR"] = "Y / O"
L["CONDITIONPANEL_ECLIPSE_DESC"] = [=[Eclipse tiene un rango de -100 (un eclipse lunar) a 100 (un eclipse solar) 
Percentages trabajo de la misma manera:. 
Input -80 si desea que el icono de trabajar con un valor de 80 energía lunar. ]=] -- Needs review
L["CONDITIONPANEL_EQUALS"] = "iguales" -- Needs review
L["CONDITIONPANEL_GREATER"] = "mayor que" -- Needs review
L["CONDITIONPANEL_GREATEREQUAL"] = "Mayor o igual a" -- Needs review
L["CONDITIONPANEL_LESS"] = "menor que"
L["CONDITIONPANEL_LESSEQUAL"] = "Menor o igual a"
L["CONDITIONPANEL_NOTEQUAL"] = "No es igual a" -- Needs review
L["CONDITIONPANEL_OPERATOR"] = "operador" -- Needs review
L["CONDITIONPANEL_OR"] = "O"
L["CONDITIONPANEL_POWER_DESC"] = [=[buscará la energía si la unidad es un druida en forma de gato, 
rage si la unidad es un guerrero, etc]=] -- Needs review
L["CONDITIONPANEL_TITLE"] = "TellMeWhen Editor de Estado" -- Needs review
L["CONDITIONPANEL_TYPE"] = "Tipo" -- Needs review
L["CONDITIONPANEL_UNIT"] = "Unidad"
L["CONDITIONPANEL_VALUE"] = "Porcentaje" -- Needs review
L["ICONMENU_ABSENT"] = "|cFFFF0000Ausente|r" -- Needs review
L["ICONMENU_ALPHA"] = "Alfa" -- Needs review
L["ICONMENU_ALWAYS"] = "Siempre"
L["ICONMENU_BARS"] = "pubs"
L["ICONMENU_BUFF"] = "Buff"
L["ICONMENU_BUFFDEBUFF"] = "Buff / Debuff"
L["ICONMENU_BUFFTYPE"] = "Buff o desventaja?"
L["ICONMENU_CHOOSENAME"] = "Elige hechizo / artículo / beige / etc."
L["ICONMENU_CLEAR"] = "Borrar los valores"
L["ICONMENU_COOLDOWN"] = "Tiempo de reutilización"
L["ICONMENU_COOLDOWNTYPE"] = "tipo de tiempo de reutilización"
L["ICONMENU_DEBUFF"] = "Desventaja"
L["ICONMENU_EITHER"] = "Todas las unidades" -- Needs review
L["ICONMENU_ENABLE"] = "Habilitar el icono" -- Needs review
L["ICONMENU_FOCUSTARGET"] = "Focus' target" -- Needs review
L["ICONMENU_FRIEND"] = "|cFF00FF00Unidades Amigas|r"
L["ICONMENU_HOSTILE"] = "|cFF00FF00Unidades Hostiles|r"
L["ICONMENU_INVERTBARS"] = "Llene barras de arriba" -- Needs review
L["ICONMENU_ITEM"] = "elemento" -- Needs review
L["ICONMENU_MANACHECK"] = "Comprobar poder?" -- Needs review
L["ICONMENU_ONLYMINE"] = "Mostrar sólo si se emiten por sí mismo" -- Needs review
L["ICONMENU_PETTARGET"] = "objetivo de mascotas" -- Needs review
L["ICONMENU_PRESENT"] = "|cFF00FF00Present|r"
L["ICONMENU_RANGECHECK"] = "Comprobar Gama?" -- Needs review
L["ICONMENU_REACT"] = "Reacción del Unidad" -- Needs review
L["ICONMENU_REACTIVE"] = "hechizo reactiva o la capacidad" -- Needs review
L["ICONMENU_SHOWCBAR"] = "Mostrar el tiempo de reutilización / barra de temporizador" -- Needs review
L["ICONMENU_SHOWPBAR"] = "Mostrar barra de poder" -- Needs review
L["ICONMENU_SHOWTIMER"] = "Mostrar reloj" -- Needs review
L["ICONMENU_SHOWWHEN"] = "Mostrar icono cuando" -- Needs review
L["ICONMENU_SPELL"] = "hechizo o habilidad" -- Needs review
L["ICONMENU_STACKS_MAX_DESC"] = "Cantidad máxima de las pilas del aura es necesario para mostrar el icono" -- Needs review
L["ICONMENU_STACKS_MIN_DESC"] = "Número mínimo de las pilas del aura es necesario para mostrar el icono" -- Needs review
L["ICONMENU_TARGETTARGET"] = "El objectivo del objectivo"
L["ICONMENU_TOTEM"] = "Totem / Ghoul no MoG" -- Needs review
L["ICONMENU_TYPE"] = "Icono de tipo" -- Needs review
L["ICONMENU_UNUSABLE"] = "|cFFFF0000Inutilizable|r" -- Needs review
L["ICONMENU_USABLE"] = "|cFF00FF00útil|r"
L["ICONMENU_WPNENCHANT"] = "temporal encantar arma"
L["ICONMENU_WPNENCHANTTYPE"] = "ranura de armas para controlar" -- Needs review
L["ICON_TOOLTIP1"] = "TellMeWhen" -- Needs review
L["RESIZE"] = "tamaño" -- Needs review
L["RESIZE_TOOLTIP"] = "Haz clic y arrastra para cambiar el tamaño" -- Needs review
L["UIPANEL_ALLRESET"] = "Restablecer todos los iconos" -- Needs review
L["UIPANEL_BARTEXTURE"] = "Barra de textura" -- Needs review
L["UIPANEL_COLOR"] = "Tiempo de reutilización / Barras de Color Duración" -- Needs review
L["UIPANEL_COLOR_COMPLETE"] = "CD / Duración completa"
L["UIPANEL_COLOR_COMPLETE_DESC"] = "color de la barra cuando el tiempo de reutilización / duración es completo" -- Needs review
L["UIPANEL_COLOR_OOM"] = "De color de poder" -- Needs review
L["UIPANEL_COLOR_OOM_DESC"] = "Matiz y alfa del icono cuando te falta el mana / ira / energía / enfoque / runicpower para lanzar el hechizo" -- Needs review
L["UIPANEL_COLOR_OOR"] = "Fuera de la gama de colores" -- Needs review
L["UIPANEL_COLOR_OOR_DESC"] = "Matiz y alfa del icono cuando no están en el rango de la meta de lanzar el hechizo" -- Needs review
L["UIPANEL_COLOR_STARTED"] = "CD / Duración de comenzar" -- Needs review
L["UIPANEL_COLOR_STARTED_DESC"] = "color de la barra cuando el tiempo de reutilización / duración ha hecho más que empezar" -- Needs review
L["UIPANEL_COLUMNS"] = "Columnas"
L["UIPANEL_DRAWEDGE"] = "Resaltar borde temporizador" -- Needs review
L["UIPANEL_DRAWEDGE_DESC"] = "Destaca el borde del temporizador de tiempo de reutilización (la animación del reloj) para aumentar la visibilidad" -- Needs review
L["UIPANEL_ENABLEGROUP"] = "Habilitar el Grupo"
L["UIPANEL_GROUPRESET"] = "Posición Inicial"
L["UIPANEL_ICONGROUP"] = "Grupo de Iconos" -- Needs review
L["UIPANEL_LOCK"] = "AddOn bloqueo" -- Needs review
L["UIPANEL_LOCKUNLOCK"] = "Bloqueo / Desbloqueo AddOn" -- Needs review
L["UIPANEL_ONLYINCOMBAT"] = "Mostrar sólo en combate" -- Needs review
L["UIPANEL_PRIMARYSPEC"] = "Spec primaria" -- Needs review
L["UIPANEL_ROWS"] = "Filas" -- Needs review
L["UIPANEL_SECONDARYSPEC"] = "Spec Secundaria" -- Needs review
L["UIPANEL_STANCE"] = "Mostrar mientras que en:" -- Needs review
L["UIPANEL_SUBTEXT2"] = "Iconos de trabajo una vez cerradas Cuando desbloqueado, puede mover o grupos icono de tamaño y haga clic derecho en los iconos individuales para más opciones de configuración También puede escribir '/tellmewhen' o '/tmw' para bloquear o desbloquear." -- Needs review
L["UIPANEL_TOOLTIP_ALLRESET"] = "restablecer los datos y la posición de todos los iconos" -- Needs review
L["UIPANEL_TOOLTIP_COLUMNS"] = "Establecer el número de columnas de iconos en este grupo"
L["UIPANEL_TOOLTIP_ENABLEGROUP"] = "Mostrar y permitir que este grupo de iconos" -- Needs review
L["UIPANEL_TOOLTIP_GROUPRESET"] = "Restablecer la posición de este grupo" -- Needs review
L["UIPANEL_TOOLTIP_ONLYINCOMBAT"] = "Comprobar para mostrar sólo este grupo de iconos en combate" -- Needs review
L["UIPANEL_TOOLTIP_PRIMARYSPEC"] = "Comprobar para mostrar el resultado de este grupo de iconos, mientras que su especificación primaria está activa" -- Needs review
L["UIPANEL_TOOLTIP_ROWS"] = "Establecer el número de filas en el icono de este grupo" -- Needs review
L["UIPANEL_TOOLTIP_SECONDARYSPEC"] = "Comprobar para mostrar el resultado de este grupo de iconos, mientras que su especificación secundaria está activo" -- Needs review
L["UIPANEL_TOOLTIP_UPDATEINTERVAL"] = "Establece la frecuencia (en segundos) que los iconos son revisados para mostrar / ocultar, alfa, condiciones, etc, no afecta demasiado bares. Cero es tan rápido como sea posible. Los valores más bajos pueden tener un impacto significativo en la tasa de fotogramas de gama baja computadoras " -- Needs review
L["UIPANEL_UPDATEINTERVAL"] = "Intervalo de actualización" -- Needs review
