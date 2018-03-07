PRO READ_ASCII_D, filename, time, counts

get_lun, in
openr, in, filename

data=fltarr(23, 116551)

time = [0]
counts = [0]
FOR j=0, 116550 DO BEGIN

line=' '
readf, in, line
split = strsplit(line, /extract)
one = split[0]
print, one
two  = split[5]

time = [time,one]
counts = [counts, two]
ENDFOR

END
