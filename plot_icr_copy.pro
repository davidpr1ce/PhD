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
restore, 'model_data_mono.sav'
mono_dat = dat
restore, 'model_data_max.sav'
max_dat = dat
restore, 'radar_data_halfsec.sav' 

;checking the mono and max data has been restored correctly
stop, mean(mono_dat), mean(max_dat)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MODEL;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;print, 'Total number of time steps for this data set (model) = ', n_elements(dat(1,*,0))
h_ax = reform(dat(0,0,*))/1e5 ;model height axis



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;RADAR;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Just some numbers for how many data points in altitude there are per time step- manual for now.
low = 0
high = 29

;Determining the total number of timesteps in the data data - count.
count=0
old=0

for i=0, n_elements(sec)-1 do begin
	new = sec[i]
	if new ne old then begin
		count = count + 1
		old = new
	endif
endfor

;Count = number of individual time steps in the radar data

;the 30 comes from the number of altitude points of data per time step (eg. same as 'high' including 0)
array = fltarr(count, 30, 2)

for i=0, count-1 do begin
	array[i,*,0] = n_e[low:high]
	array[i,*,1] = alt[low:high]
	low = low + 30
	high = high + 30

endfor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MODEL AVERAGING;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;REMEMBER TO REMOVE THE WARMUP PERIOD DATA POINTS!
; dat(0,223,*) should be zeros I think, it comes from an empty line on the end of the script file. 


x= mono_dat(1,31:222,*)
a= max_dat(1,31:222,*)
x=reform(x)
a=reform(a)
; x/a are now (t,h) coordinates

;31 time steps in the model with resolution (0.16s) equates to 4.96 seconds, eg ~ 5s averaging
low = 0
high = 30

;Round 2 - simplified

;print, 'Count: ', count
;Making the arrays to store the averaged model results in
av_mono = fltarr(count,201)
av_max = fltarr(count,201)

;loops through the radar data in 5s chunks (6 total - eg. 30s)
for j=0, count-1 do begin
	y = x(low:high,*)
	b = a(low:high,*)                ;selects a 5s chunk of the data (31 steps equals 4.96 seconds)
	for k=0, 200 do begin		 ;loops through each data point - 201 total densities recorded over the altitude range at each time step
		av_mono(j,k) = mean(y(*,k))   ;averages the densities at each individual alt. over 5s and stores this value in the av array
		av_max(j,k) = mean(b(*,k))
	endfor
	
	av_mono = reform(av_mono)                  ;removes un-needed leading indexes in array
	av_max = reform(av_max)
	
	low = low + 31                   ;progress forward 5 seconds in the time indexes
	high = high + 31
endfor


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;PLOTTING;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;PLOTTING THE MODEL
loadct, 39
print, ' '
print, '-----------------------'

print, 'Mono-energetic is white, Maxwellian is red and the radar is diamonds.'

!p.position=[0.05,0.1,0.95,0.95]
plot, av_mono(t_index,*), h_ax, TITLE='Electron Density vs. Altitude for a number of models', YTITLE='Altitude (km)', XTITLE='Number Density (n/m^3)', SUBTITLE='Mono = White ; Max = Red ; Radar = Diamond', YRANGE=[80,200], /ysty, XRANGE=[5e9, 5e12], /xlog, /xsty
oplot, av_max(t_index,*), h_ax, color=250



;I think the radar data integrates the PREVIOUS 5 seconds? So the first set of data contains no aurora? not sure
;PLOTTING THE RADAR DATA
oplot, array(t_index,*,0), array(t_index,*,1), PSYM=4



END
