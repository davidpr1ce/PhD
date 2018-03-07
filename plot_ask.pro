PRO plot_ask, smooth=smooth, time=time

restore, 'ASK_data.sav'




loadct, 39
!p.position=[0.1,0.1,0.9,0.9]


if keyword_set(time) then begin
	energy = energy[0:32*time]
	flux = flux[0:32*time]
endif

if keyword_set(smooth) then begin
	energy = SMOOTH(energy, smooth)
	flux = SMOOTH(flux, smooth)
endif



len = n_elements(energy)
X = findgen(len) /32.0

plot, X, energy/1000., ystyle=8, XTITLE='Seconds since 20:42:39UT.', YTITLE = 'Energy (keV)'
axis, YAXIS=1, YRANGE=[0,500], YTITLE= 'Flux (mW/m^2)', color=250
oplot,X, flux/25., color=250


 
END
