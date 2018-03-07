PRO save_radar, array, step

;Routine to save the radar data into 2D arrays with timestep in x and altitude in y
;Uses radar_data.sav which is created using radar_ascii routine - the input file of which is output from Josh's MATLAB
;This code is not very general as it stands and should be modified to account for different input radar data



low = 0
high = 29

;Data can be saved using radar_ascii routine in Documents/IDL. If you want errors or other variables run it again and change ;below!

restore, 'radar_data.sav'
;radar_ascii, 'eiscatascii_2.txt', hour, min, sec, alt, n_e, t_i, ratio

;Data from restore is simply in arrays of X length (atm 180) of data values corresponding to each of the names given above
;The time array is a constant fixed value for Y number of points (eg. the number of different altitudes each variable is 
;measured at) then it progresses one time step (5s) and lists the next set of data points for each variable at each alt.


;Determining the total number of timesteps in the radar data - count.
count= 0
old =0

for i=0, n_elements(sec)-1 do begin
	new = sec[i]
	if new ne old then begin
		count = count+1
		old = new 
	endif
endfor

print, count
;The above code determines how many times the time variable changes in the array - eg. the number of time steps in the data 
;ie for a 30s radar run, with an integration time of 5s, there will be a total of 6 'timesteps'.

;Now we create the array that will contains the data and be saved (format shown below)
;format is set this way for 'historical reasons'..... Since altitude is plotted as y it made sense to me to have it last

;array = [time,number of data points (alt. points),variable]
;Currently:
; array(t,*,0) = n_e (at each altitude)
; array(t,*,1) = altitude

array = fltarr(count,30,2)


for i=0, count-1 do begin
	print, i
	array[i,*,0] = n_e[low:high]
	array[i,*,1] = alt[low:high]
	low = low + 30
	high = high + 30

endfor



;array(timestep,values, n_e(0)/alt(1))
;s = scatterplot(array(step,*,0),array(step,*,1))

save, array, file='radar_2D.sav' 





;X = findgen(6) * 6
;Y = findgen(30) * 16

;XF = findgen(n_elements(array[*,0])) * 6

;if keyword_set(full) then begin
	;print, 'Full!'
	;s = CONTOUR(array,XF,Y,/fill,XTITLE='Seconds since 20:50:40UT.', YTITLE='Altitude (km)', TITLE='Electron Density measured at ESR on 27/01/2017', 			;DIM=[1000,500],YRANGE=[ylow,yhigh], POSITION=[0.1,0.1,0.75,0.9])

;endif else s = CONTOUR(array[0:5,*],X,Y,/fill,XTITLE='Seconds since 20:50:40UT.', YTITLE='Altitude (km)', TITLE='Electron Density measured at ESR on 27/01/2017', ;DIM=[1000,500],YRANGE=[ylow,yhigh], POSITION=[0.1,0.1,0.75,0.9])


;cb = colorbar(TARGET=s, orientation=1, POSITION=[0.85,0.15,0.9,0.9], TICKNAME=['1.25E+11','2.50E+11','3.76E+11','5.00E+11','6.26E+11','7.51E+11','8.76E+11','1.00E+12','1.13E+12'], ;/border)

END
