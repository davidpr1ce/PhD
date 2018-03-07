PRO quick_plot, energy=energy, flux=flux, ratio=ratio

;Plots the energy, flux or ratio for the full event I am studying quickly

restore, 'ASK_data.sav'

!p.position=[0.1,0.1,0.9,0.9]


if keyword_set(energy) then plot, energy
if keyword_set(flux) then plot, flux
if keyword_set(ratio) then plot, ratio


END
