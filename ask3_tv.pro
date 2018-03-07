PRO ask3_tv, filename, image

;Input:
;	filename- name of the file you want to investigate
;
;Output:
;	image- array of data

close, 1
data = fltarr(256,256)
openr, 1, filename
readu, 1, data

tvscl, data

image = data

END
