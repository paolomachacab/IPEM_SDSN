********************************************************************************
***** IPEM 2012 - ÍNDICE DE POBREZA ENERGÉTICA MULTIDIMENSIONAL
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

use "$out/persona_vivienda_censo_2012", clear

********************************************************************************
* FILTRAR VIVIENDAS PARTICULARES Y QUEDARSE CON UNA FILA POR VIVIENDA
********************************************************************************
/*
A diferencia del IPM, todos los indicadores del IPEM son a nivel
vivienda, no de persona. Por tanto no se necesita agregar variables
desde nivel persona. Se elimina el duplicado de personas por vivienda
manteniendo solo la primera observación de cada una.
*/

keep if inrange(P01_TIPOVIV, 1, 5)
bys I_BC_VIV: keep if _n == 1

********************************************************************************
* ETIQUETA GENERAL
********************************************************************************
cap label define priv_label 0 "No privado" 1 "Privado"

********************************************************************************
* DIMENSIÓN 1: ENERGÍA BÁSICA
********************************************************************************

*---------------------------------------------------------------------------
* INDICADOR 1: COMBUSTIBLE PARA COCINAR
* Peso: 0.247
*---------------------------------------------------------------------------
/*
P12_COMBUS – Principal combustible o energía para cocinar
    Limpios    → NO PRIVADO:
        1 Gas domiciliario (por cañería)
        2 Gas en garrafa
        3 Electricidad
        4 Energía solar
    No limpios → PRIVADO:
        5 Leña
        6 Guano, bosta o taquia
        7 Otro
        8 No cocina

Fuente: SDSN Bolivia (2026) y criterios OMS/ODS 7.
*/

cap drop dep_combustible
gen dep_combustible = .
replace dep_combustible = 0 if inlist(P12_COMBUS, 1, 2, 3, 4)
replace dep_combustible = 1 if inlist(P12_COMBUS, 5, 6, 7, 8)

label var dep_combustible "Privación: usa combustible no limpio (1=privado)"
label values dep_combustible priv_label
tab dep_combustible, missing

*---------------------------------------------------------------------------
* INDICADOR 2: CONTAMINACIÓN INTERIOR
* Peso: 0.127
*---------------------------------------------------------------------------
/*
P13_COCINA – Tiene un cuarto sólo para cocinar
    1 Sí           → NO PRIVADO
    2 No pertenece → PRIVADO

Nota: Proxy parcial de contaminación interior (Nussbaumer et al., 2012).
El peso se reduce de 0.20 a 0.127 por ausencia del tipo de estufa.
Correlación tetracórica con dep_combustible: ρ=0.174 (débil),
lo que justifica su inclusión simultánea en el índice.
*/

cap drop dep_indoor
gen dep_indoor = .
replace dep_indoor = 0 if P13_COCINA == 1
replace dep_indoor = 1 if P13_COCINA == 2

label var dep_indoor "Privación: no tiene cuarto exclusivo para cocinar (1=privado)"
label values dep_indoor priv_label
tab dep_indoor, missing

*---------------------------------------------------------------------------
* INDICADOR 3: ACCESO A ELECTRICIDAD
* Peso: 0.247
*---------------------------------------------------------------------------
/*
P11_ENERGIA – De dónde proviene la energía eléctrica
    1 Red de empresa eléctrica → NO PRIVADO
    2 Panel solar              → NO PRIVADO
    3 Generador/Turbina        → NO PRIVADO
    4 Otra fuente              → NO PRIVADO
    5 No tiene                 → PRIVADO
*/

cap drop dep_electricidad
gen dep_electricidad = .
replace dep_electricidad = 0 if inlist(P11_ENERGIA, 1, 2, 3, 4)
replace dep_electricidad = 1 if P11_ENERGIA == 5

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
P17A_RADIO – El hogar tiene radio     (1=Sí, 2=No)
P17B_TV    – El hogar tiene televisor (1=Sí, 2=No)

PRIVADO     si: no tiene TV ni radio
NO PRIVADO  si: tiene al menos uno de los dos
*/

cap drop dep_entretenimiento
gen dep_entretenimiento = .
replace dep_entretenimiento = 0 if P17A_RADIO == 1 | P17B_TV == 1
replace dep_entretenimiento = 1 if P17A_RADIO == 2 & P17B_TV == 2
replace dep_entretenimiento = . if missing(P17A_RADIO) & missing(P17B_TV)

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
P17E_TELEF – El hogar tiene telefonía fija o celular
    1 Sí → NO PRIVADO
    2 No → PRIVADO
*/

cap drop dep_comunicacion
gen dep_comunicacion = .
replace dep_comunicacion = 0 if P17E_TELEF == 1
replace dep_comunicacion = 1 if P17E_TELEF == 2

label var dep_comunicacion "Privación: no tiene celular ni teléfono (1=privado)"
label values dep_comunicacion priv_label
tab dep_comunicacion, missing

*---------------------------------------------------------------------------
* INDICADOR 6: ACCESO DIGITAL
* Peso: 0.085
*---------------------------------------------------------------------------
/*
P17C_COMPUT   – El hogar tiene computadora    (1=Sí, 2=No)
P17D_INTERNET – El hogar tiene internet       (1=Sí, 2=No)

NO PRIVADO si: tiene computadora Y internet simultáneamente
PRIVADO    si: le falta la computadora O el internet O ambos

Fuente: Bajpayee & Mohanty (2026) - acceso digital requiere
dispositivo con conectividad, no solo tenencia de aparato.
*/

cap drop dep_digital
gen dep_digital = .
replace dep_digital = 0 if P17C_COMPUT == 1 & P17D_INTERNET == 1
replace dep_digital = 1 if P17C_COMPUT == 2 | P17D_INTERNET == 2
replace dep_digital = . if missing(P17C_COMPUT) | missing(P17D_INTERNET)

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

save "$out/base_vivienda_ipem_2012.dta", replace

********************************************************************************
* PESOS DEL IPEM
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
/*
Ahmed & Gasparatos (2020) citado en Bajpayee & Mohanty (2026):
    IPEM < 0.30          → Pobreza energética BAJA
    0.30 ≤ IPEM < 0.70   → Pobreza energética MODERADA
    IPEM ≥ 0.70          → Pobreza energética AGUDA
*/

cap drop _ipem_h _ipem_e _ipem_m0 _ipem_a

gen _ipem_h  = (c_vector >= 0.30) if !missing(c_vector)
gen _ipem_e  = (c_vector >= 0.70) if !missing(c_vector)
gen _ipem_m0 = c_vector * _ipem_h
gen _ipem_a  = c_vector if _ipem_h == 1

label var _ipem_h  "Hogar pobre energético (k=0.30)"
label var _ipem_e  "Hogar pobre energético extremo (k=0.70)"
label var _ipem_m0 "Privación censurada (M0)"
label var _ipem_a  "Intensidad (A) - solo pobres"

********************************************************************************
* RESULTADOS NIVEL NACIONAL
********************************************************************************

count if _ipem_h == 1
local q = r(N)
count if !missing(c_vector)
local n = r(N)
local H  = (`q'  / `n') * 100

count if _ipem_e == 1
local qe = r(N)
local He = (`qe' / `n') * 100

summarize _ipem_a
local A    = r(mean) * 100
local IPEM = (`H' * `A') / 100

display "════════════════════════════════════════════"
display "  IPEM 2012 - NIVEL NACIONAL"
display "════════════════════════════════════════════"
display "  Incidencia  H  (k≥0.30): " %6.2f `H'   " %"
display "  Incidencia  He (k≥0.70): " %6.2f `He'  " %"
display "  Intensidad  A          : " %6.2f `A'   " %"
display "  IPEM = H × A           : " %6.3f `IPEM'
display "════════════════════════════════════════════"

********************************************************************************
* RESULTADOS POR ÁREA URBANO/RURAL
********************************************************************************

preserve
collapse ///
    (count) n_obs      = c_vector ///
    (sum)   sum_pobres = _ipem_h  ///
    (mean)  mean_a     = _ipem_a, ///
    by(urbrur)

gen H    = (sum_pobres / n_obs) * 100
gen A    = mean_a * 100
gen IPEM = (H * A) / 100

label define area 1 "Urbano" 2 "Rural"
label values urbrur area

display "════════════════════════════════════════════"
display "  IPEM 2012 - POR ÁREA"
display "════════════════════════════════════════════"
list urbrur H A IPEM, noobs clean
display "════════════════════════════════════════════"
restore

********************************************************************************
* RESULTADOS POR MUNICIPIO
********************************************************************************

preserve
gen uno = 1

collapse ///
    (mean)  H       = _ipem_h ///
    (mean)  A       = _ipem_a ///
    (count) hogares = uno,    ///
    by(ID_INE_CENSO_MUN)

gen IPEM = H * A

label var H       "Incidencia (H)"
label var A       "Intensidad (A)"
label var IPEM    "IPEM = H × A"
label var hogares "Número de hogares"

sort ID_INE_CENSO_MUN

save "$out/ipem_municipal_2012.dta", replace
export delimited using "$out/ipem_municipal_2012.csv", replace
export excel using "$out/ipem_municipal_2012.xlsx", replace firstrow(variables)

display "════════════════════════════════════════════"
display "  TOP 10 MUNICIPIOS MÁS POBRES"
display "════════════════════════════════════════════"
gsort -IPEM
list ID_INE_CENSO_MUN H A IPEM in 1/10, noobs clean
restore

********************************************************************************
* PROPORCIÓN DE PRIVACIÓN POR INDICADOR Y MUNICIPIO
********************************************************************************

foreach var in combustible indoor electricidad ///
               entretenimiento comunicacion digital {
    bys ID_INE_CENSO_MUN: egen total_dep_`var'  = total(dep_`var')
    bys ID_INE_CENSO_MUN: egen total_hog_`var'  = total(!missing(dep_`var'))
    gen prop_`var' = (total_dep_`var' / total_hog_`var') * 100
    label var prop_`var' "% hogares privados: `var'"
    drop total_dep_`var' total_hog_`var'
}

preserve
collapse (mean) prop_*, by(ID_INE_CENSO_MUN)
foreach var of varlist prop_* {
    replace `var' = round(`var', 0.01)
}
sort ID_INE_CENSO_MUN
save "$out/prop_ipem_municipal_2012.dta", replace
export delimited using "$out/prop_ipem_municipal_2012.csv", replace
restore

********************************************************************************
* CONTRIBUCIÓN DE CADA INDICADOR AL IPEM NACIONAL
********************************************************************************

summarize _ipem_m0
local M0_total = r(mean)

display "════════════════════════════════════════════"
display "  CONTRIBUCIÓN DE INDICADORES AL IPEM"
display "════════════════════════════════════════════"
foreach ind in combustible indoor electricidad ///
               entretenimiento comunicacion digital {
    gen _contrib_`ind' = g0_`ind' * _ipem_h
    summarize _contrib_`ind'
    local contrib = (r(mean) / `M0_total') * 100
    display "  `ind': " %5.1f `contrib' " %"
    drop _contrib_`ind'
}
display "════════════════════════════════════════════"

********************************************************************************
* GUARDAR BASE FINAL
********************************************************************************

save "$out/base_ipem_2012_final.dta", replace
display "✓ Código IPEM 2012 completado exitosamente"

sort ID_INE_CENSO_MUN
export excel using "$out/numero_carencias_mayor_igual_4_2012.xlsx", replace firstrow(variables)


