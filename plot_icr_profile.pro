PRO plot_icr_profile, t_index



;
;Routine to plot the electron density profiles for a given time step
;Hope to improve this to include the model density profile for comparison


;if keyword_set(save) then begin
;
;	icr, 'densities.dat'
;	common icr
;	save, dat, file='model_data_mono.sav'
;endif


;Extracting the data - has to be saved first using the above method
restore, '~/Documents/Model_vs_Radar/model_data_mono.sav'
mono_dat = dat
restore, '~/Documents/Model_vs_Radar/model_data_max.sav'
max_dat = dat
restore, 'model_data_final.sav'
final_dat = dat
restore, '~/Documents/Model_vs_Radar/InputSpectra/Old/maxwellian_ascending_spectrum.sav'
max_asc = dat
restore, '~/Documents/Model_vs_Radar/InputSpectra/Old/monoenergetic_ascending_spectrum.sav'
mono_asc = dat



restore, 'radar_data_halfsec.sav' 

;checking the mono and max data has been restored correctly
;stop, mean(mono_dat), mean(max_dat)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MODEL;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;print, 'Total number of time steps for this data set (model) = ', n_elements(dat(1,*,0))
h_ax = reform(dat(0,0,*))/1e5 ;model height axis



;;;;;;;;;;;  ;;;;;;;;;;;;;;;;;;;;;;RADAR;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

radar_data = data ;redifining radar data for clarity

;radar_data = arr[60,442] ; 60 time steps (0.5s) for 30s over 442 altitudes
;yaxis = altitudes axis
;mjs = start time 
;time = arr[seconds since starting mjs]





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MODEL AVERAGING;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;REMEMBER TO REMOVE THE WARMUP PERIOD DATA POINTS!
; dat(0,223,*) should be zeros I think, it comes from an empty line on the end of the script file. 


help, radar_data


asc_max = max_asc(1,*,*)
asc_mono = mono_asc(1,*,*)


asc_max = reform(asc_max)
asc_mono = reform(asc_mono)

nn = n_elements(asc_max(*,0))

mono = mono_dat(1,10:-2,*)
max = max_dat(1,10:-2,*)
final = final_dat(1,20:-2,*)

mono = reform(mono)
max_ = reform(max)
final = reform(final)

help, mono
help, max_
help, final

; mono/max/final are now (t,h) coordinates



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;PLOTTING;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;PLOTTING THE MODEL
loadct, 39
print, ' '
print, '-----------------------'

print, 'Maxwellian is white, Mono-energetic is red and the radar is diamonds.'

;!p.position=[0.05,0.15,0.95,0.95]

help, mono_dat
help, max_dat

plots = n_elements(radar_data(*,0)) ;defining the number of plots
pos = 0 ;defining the initial position (ie. which plot to plot first)
window,1, xsi=800, ysi=800

WHILE pos lt plots AND pos ge 0 DO BEGIN
	;mono energetic plot
	print, 'Spectrum # : ', pos + 21, ' Time: ',(pos)*0.5
	erase
	
 	;Fit plot - adjusted by eye
	plot, final(pos, *), h_ax,$
	 TITLE='Electron Density vs. Altitude', YTITLE='Altitude (km)',$
	  XTITLE = 'Electron Number Density (n/m^3)', SUBTITLE="Mono = red ; Max = Green; Radar = Diamond ; Fit = White", $
	   YRANGE=[80,200], /ysty, XRANGE=[5e9, 5e12], /xlog, /xsty
	 
	;mono plot
	oplot, mono(pos, *), h_ax, color=250
	
	;radar data plot
	oplot, radar_data(pos,*), yaxis, PSYM=4
	
	;max plot
	oplot, max_(pos, *), h_ax, color = 125
	
	;overplotting a range of energies for reference
	for j=0, nn-1 DO BEGIN
		oplot, asc_max(j,*), h_ax, LINESTYLE=1
		oplot, asc_mono(j,*), h_ax, LINESTYLE=2, color=250
	endfor

	cursor, x, y, /DEVICE, WAIT=4, /up
	if x gt 400 then begin
		pos = pos + 1
	endif
	if x lt 400 then begin
		pos = pos -1
	endif

ENDWHILE






END
