PRO button_press

;Proof of concept for a click test to cycle through plots
;Works!


window,1,xsi=1000,ysi=800


plots = fltarr(10) ;number of plots I want to cycle through
;should be changed to the number of elements in the time axis of density plots

pos = 0

WHILE pos lt n_elements(plots) AND pos ge 0 DO BEGIN
	print, pos
	;plot, pos, 5
	cursor, x, y, /DEVICE, WAIT=4, /up   ;waits for mouse to be positioned and clicked
	if x gt 500 then begin
		pos = pos + 1
	endif
	if x le 500 then begin
		pos = pos - 1
	endif
ENDWHILE

END
	
	
	
