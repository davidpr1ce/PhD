PRO READ_GAE, filename, mjs, ratio, energy, flux, ask1, ask3, time, minutes, seconds, msecs

data = READ_ASCII(filename, TEMPLATE=ASCII_TEMPLATE(filename))

mjs = data.FIELD1
ratio = data.FIELD2
energy = data.FIELD3
flux = data.FIELD4
ask1 = data.FIELD5
ask3 = data.FIELD6
seconds = fltarr(n_elements(mjs))
minutes = fltarr(n_elements(mjs))
msecs = fltarr(n_elements(mjs))
time = fltarr(n_elements(mjs))

FOREACH element, mjs, index DO BEGIN
mjs_tt, element, year, month, day, hour, minute, second, ms
minutes[index] = minute
seconds[index] = second
msecs[index] = ms
time[index] = minute + ((second + (ms/1000))/60.0)
ENDFOREACH

END
