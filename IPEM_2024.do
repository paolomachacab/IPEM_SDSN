********************************************************************************
***** IPEM 2024 - ÍNDICE DE POBREZA ENERGÉTICA MULTIDIMENSIONAL
***** Metodología: Alkire-Foster | Corte: k = 0.30
***** Referencia: Nussbaumer et al. (2012), Bajpayee & Mohanty (2026),
*****             Koirala & Rahut (2024), SDSN Bolivia (2026)
********************************************************************************

********************************************************************************
* CONFIGURACIÓN
********************************************************************************
clear all
set more off
version 17.0

if ("`c(username)'" == "Paolo") {
    global path  "C:\Paolo\ipm_2012_sdsn"
    global in    "$path/_in"
    global out   "$path/_out"
    global code  "$path/_code"
    global tbl   "$path/_tbl"
    global graph "$path/_graph"
}

use "$out/persona_vivienda_censo_2024", clear

********************************************************************************
* FILTRAR VIVIENDAS PARTICULARES Y QUEDARSE CON UNA FILA POR VIVIENDA
********************************************************************************
keep if inrange(P01_TIPOVIV, 1, 5)
bys I_BC_VIV: keep if _n == 1

********************************************************************************
* ETIQUETA GENERAL
********************************************************************************
cap label define priv_label 0 "No privado" 1 "Privado"

********************************************************************************
* TRATAMIENTO DE MISSING EN 2024
********************************************************************************
/*
El valor 9 corresponde a "No respondió" y se trata como missing.
Esta categoría no existía en 2012.
*/

foreach var in v19a_radio v19b_tv v19c_compu v19d_celular ///
               v19e_inetfijo v19f_inetmovil v19h_telfijo {
    replace `var' = . if `var' == 9
}

********************************************************************************
* DIMENSIÓN 1: ENERGÍA BÁSICA
********************************************************************************

*---------------------------------------------------------------------------
* INDICADOR 1: COMBUSTIBLE PARA COCINAR
* Peso: 0.247
*---------------------------------------------------------------------------
/*
v10_combus – Principal combustible o energía para cocinar
    1 Gas en garrafa              → NO PRIVADO
    2 Gas por cañería (domicilio) → NO PRIVADO
    3 Leña                        → PRIVADO
    4 Guano, bosta o taquia       → PRIVADO
    5 Electricidad                → NO PRIVADO
    6 Energía solar               → NO PRIVADO
    7 Otro                        → PRIVADO
    8 No cocina                   → PRIVADO

ATENCIÓN: categorías distintas a 2012.
    2012: limpios={1,2,3,4} / 2024: limpios={1,2,5,6}
*/

cap drop dep_combustible
gen dep_combustible = .
replace dep_combustible = 0 if inlist(v10_combus, 1, 2, 5, 6)
replace dep_combustible = 1 if inlist(v10_combus, 3, 4, 7, 8)

label var dep_combustible "Privación: usa combustible no limpio (1=privado)"
label values dep_combustible priv_label
tab dep_combustible, missing

*---------------------------------------------------------------------------
* INDICADOR 2: CONTAMINACIÓN INTERIOR
* Peso: 0.127
*---------------------------------------------------------------------------
/*
v12_cocina – Tiene un cuarto sólo para cocinar
    1 Sí → NO PRIVADO
    2 No → PRIVADO

Nota: En 2012 la categoría 2 era "No pertenece". El código es idéntico.
*/

cap drop dep_indoor
gen dep_indoor = .
replace dep_indoor = 0 if v12_cocina == 1
replace dep_indoor = 1 if v12_cocina == 2

label var dep_indoor "Privación: no tiene cuarto exclusivo para cocinar (1=privado)"
label values dep_indoor priv_label
tab dep_indoor, missing

*---------------------------------------------------------------------------
* INDICADOR 3: ACCESO A ELECTRICIDAD
* Peso: 0.247
*---------------------------------------------------------------------------
/*
v09_energia – De dónde proviene la energía eléctrica
    1 Red de empresa eléctrica → NO PRIVADO
    2 Panel solar              → NO PRIVADO
    3 Generador/Turbina        → NO PRIVADO
    4 Otra fuente              → NO PRIVADO
    5 No tiene                 → PRIVADO
*/

cap drop dep_electricidad
gen dep_electricidad = .
replace dep_electricidad = 0 if inlist(v09_energia, 1, 2, 3, 4)
replace dep_electricidad = 1 if v09_energia == 5

label var dep_electricidad "Privación: no tiene acceso a electricidad (1=privado)"
label values dep_electricidad priv_label
tab dep_electricidad, missing

********************************************************************************
* DIMENSIÓN 2: EQUIPAMIENTO
********************************************************************************

*---------------------------------------------------------------------------
* INDICADOR 4: ACCESO A ENTRETENIMIENTO
* Peso: 0.147
*---------------------------------------------------------------------------
/*
v19a_radio – El hogar tiene radio     (1=Sí, 2=No, 9→.)
v19b_tv    – El hogar tiene televisor (1=Sí, 2=No, 9→.)

PRIVADO    si: no tiene TV ni radio
NO PRIVADO si: tiene al menos uno
*/

cap drop dep_entretenimiento
gen dep_entretenimiento = .
replace dep_entretenimiento = 0 if v19a_radio == 1 | v19b_tv == 1
replace dep_entretenimiento = 1 if v19a_radio == 2 & v19b_tv == 2
replace dep_entretenimiento = . if missing(v19a_radio) & missing(v19b_tv)

label var dep_entretenimiento "Privación: no tiene TV ni radio (1=privado)"
label values dep_entretenimiento priv_label
tab dep_entretenimiento, missing

********************************************************************************
* DIMENSIÓN 3: COMUNICACIÓN
********************************************************************************

*---------------------------------------------------------------------------
* INDICADOR 5: ACCESO A COMUNICACIÓN BÁSICA
* Peso: 0.147
*---------------------------------------------------------------------------
/*
v19d_celular – El hogar tiene celular       (1=Sí, 2=No, 9→.)
v19h_telfijo – El hogar tiene teléfono fijo (1=Sí, 2=No, 9→.)

En 2024 separadas. En 2012 era una sola: P17E_TELEF.
PRIVADO    si: no tiene celular ni teléfono fijo
NO PRIVADO si: tiene al menos uno
*/

cap drop dep_comunicacion
gen dep_comunicacion = .
replace dep_comunicacion = 0 if v19d_celular == 1 | v19h_telfijo == 1
replace dep_comunicacion = 1 if v19d_celular == 2 & v19h_telfijo == 2
replace dep_comunicacion = . if missing(v19d_celular) & missing(v19h_telfijo)

label var dep_comunicacion "Privación: no tiene celular ni teléfono (1=privado)"
label values dep_comunicacion priv_label
tab dep_comunicacion, missing

*---------------------------------------------------------------------------
* INDICADOR 6: ACCESO DIGITAL
* Peso: 0.085
*---------------------------------------------------------------------------
/*
v19c_compu     – El hogar tiene computadora    (1=Sí, 2=No, 9→.)
v19e_inetfijo  – El hogar tiene internet fijo  (1=Sí, 2=No, 9→.)
v19f_inetmovil – El hogar tiene internet móvil (1=Sí, 2=No, 9→.)

En 2024 el internet se desagrega en fijo y móvil. En 2012 era P17D_INTERNET.
El hogar tiene internet si tiene fijo OR móvil.
NO PRIVADO si: tiene computadora Y cualquier tipo de internet.
PRIVADO    si: no tiene computadora O no tiene internet de ningún tipo.
*/

cap drop tiene_internet dep_digital
gen tiene_internet = .
replace tiene_internet = 1 if v19e_inetfijo == 1 | v19f_inetmovil == 1
replace tiene_internet = 0 if v19e_inetfijo == 2 & v19f_inetmovil == 2
replace tiene_internet = . if missing(v19e_inetfijo) & missing(v19f_inetmovil)

gen dep_digital = .
replace dep_digital = 0 if v19c_compu == 1 & tiene_internet == 1
replace dep_digital = 1 if v19c_compu == 2 | tiene_internet == 0
replace dep_digital = . if missing(v19c_compu) | missing(tiene_internet)
drop tiene_internet

label var dep_digital "Privación: no tiene computadora con internet (1=privado)"
label values dep_digital priv_label
tab dep_digital, missing

********************************************************************************
* GUARDAR BASE A NIVEL VIVIENDA CON INDICADORES
********************************************************************************

rename I02_DEPTO dep_res_cod
rename I03_PROV  prov_cod
rename URBRUR    urbrur

order I_BC_VIV ID_INE_CENSO_MUN urbrur dep_res_cod prov_cod URBRUR_P ///
      dep_combustible dep_indoor dep_electricidad    ///
      dep_entretenimiento dep_comunicacion dep_digital

save "$out/base_vivienda_ipem_2024.dta", replace

********************************************************************************
* PESOS DEL IPEM (idénticos a 2012 para garantizar comparabilidad)
********************************************************************************

global w_combustible     = 0.247
global w_indoor          = 0.127
global w_electricidad    = 0.247
global w_entretenimiento = 0.147
global w_comunicacion    = 0.147
global w_digital         = 0.085

********************************************************************************
* PRIVACIONES PONDERADAS (g0)
********************************************************************************

foreach ind in combustible indoor electricidad ///
               entretenimiento comunicacion digital {
    cap drop g0_`ind'
    gen g0_`ind' = dep_`ind' * ${w_`ind'}
    label var g0_`ind' "Privación ponderada: `ind'"
}

********************************************************************************
* VECTOR DE CONTEO (c_i)
********************************************************************************

cap drop c_vector
egen c_vector = rowtotal(g0_combustible g0_indoor g0_electricidad ///
                          g0_entretenimiento g0_comunicacion g0_digital)
label var c_vector "Puntaje de privación ponderada (0-1)"
tab c_vector, missing

********************************************************************************
* IDENTIFICACIÓN DE POBRES ENERGÉTICOS: k = 0.30
********************************************************************************

cap drop _ipem_h _ipem_e _ipem_m0 _ipem_a

gen _ipem_h  = (c_vector >= 0.30) if !missing(c_vector)
gen _ipem_e  = (c_vector >= 0.70) if !missing(c_vector)
gen _ipem_m0 = c_vector * _ipem_h
gen _ipem_a  = c_vector if _ipem_h == 1

label var _ipem_h  "Hogar pobre energético (k=0.30)"
label var _ipem_e  "H"
