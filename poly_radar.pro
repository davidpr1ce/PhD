PRO poly_radar, true=true
;Quick routine to recreate the plot_2d plots for radar data.
;Run in ~/Documents/DensityPlots

;save_2d, 'radar_2d.dat', mjs, time, alt, array, 'Electron Density','Altitude','Density'

;true keyword sets it to match the scale from icr_color

if keyword_set(true) then begin
	print, 'True'
	window,0
	loadct,39
	plot_2d, 'radar_2d.dat', [0.1,0.1,0.8,0.9], [0.85,0.1,0.9,0.9], range=[1.0e+11, 1.0e+14], yrange=[80,150], /log

	window,1

	icr, 'densities.dat'
	icr_color, 'e', h_range=[80,150]

endif

if not(keyword_set(true)) then begin
	print, 'False'
	window,0
	loadct,39
	plot_2d, 'radar_2d.dat', [0.1,0.1,0.8,0.9],[0.85,0.1,0.9,0.9], range=[1.0e+11, 1.0e+13], yrange=[80,150], /log
	
	window,1
	
	icr, 'densities.dat'
	icr_color, 'e', h_range=[80,150]
	
endif


END
