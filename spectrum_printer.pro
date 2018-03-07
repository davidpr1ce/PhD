PRO spectrum_printer, filename, Fstart, Fstep, range, sflux, senergy, max=max, warmup=warmup, save=save, josh=josh

;A procedure to print the flux and energys from the energy_ask process into a text file in a format that makes it easy to copy into sp_files for model runs.
;Need to add an option to average data in energy arrays over a period of time - ideally given as an argument in the function, then print that average value (eg, flux and energy) next to the timestep given.

;NOTE: IDL enviroment needs to be in a model run directory in order to get the energy and flux's from ratio.

;Inputs:
;	filename= string of what you want the file which the spectrum is printed into
;	Fstep= number of frames for which to average over, allowing you to set the time resolution of the energy and flux data
;	Fstart=start frame of region of interest
;	range= total number of frames for which to print the data for - note it is helpful if this is a multiple of Fstep
;	sflux = scaling factor to be applied to flux (eg. 0.8 for 80% flux input)
;	senergy = scaling factor to be applied to energies (eg. 0.7 for 70% energy input) 	
;	max= set this keyword if you want a maxwellian spectrum instead of the default gaussian (mono energetic)
;	warmup = set this keyword if you want to include a [x second] (array) warmup period in which energies are warmed up to the first input energy

;Gets the model results for the ASK wavelengths
get_ask_ems, efile='emissions.dat', sfile='spec_trans.dat', /justcam, /ask

;Runs the procedure energy_ask to get the energy, ratio and flux data from the event in question - entered here.
energy_ask, ['20170127204239r1','20170127204239r3'], Fstart, range, [11.9537, 4.02771], energy, ratio, flux

if keyword_set(save) then begin
	save, energy, ratio, flux, 'Spectrum_data.sav'
endif

if keyword_set(josh) then begin
	restore, 'data_josh.sav'
endif

;Defining empty arrays to fill with average data
energy_av = []
flux_av = []

;Defining the first energy and flux term for use with warmup
energy_i = energy[0]
flux_i = flux[0]


print, n_elements(energy)

;Loops over the full energy/flux arrays and takes a trailing average over Fstep number of elements - appending the values to energy_av and flux_av arrays.

for j=Fstep, range +1 , Fstep DO begin
	print, 'j-1: ', j-1, ' j-Fstep: ', (j-Fstep)
	energy_av = [energy_av, mean(energy[j-Fstep:j-1])]
	flux_av = [flux_av, mean(flux[j-Fstep:j-1])]
 
endfor


;Opens and prints to the file in the format needed for Model input spectra

openw, 1, filename

;Define the number of elements to print, depends on the Fstep chose
nn = n_elements(energy_av)
;Defining what to print as the timestep
timestep = round((0.03125 * Fstep)*100.0)/100.0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MAXWELLIAN;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if keyword_set(max) AND keyword_set(warmup) then begin
print, 'Printing a maxwellian spectrum /w warmup to the ', filename, ' file.'

warmup_step = round(warmup[0]/timestep)    ;how many timesteps it will take to get to the 5s warmup mark
energy_step = energy_i / warmup_step ;how much to increase the energy by per warmup step to reach initial energy levels
warmup_energy = energy_step ;variable which will be printed as energy in the warmup section

print, 'Warmup time: ', warmup_step*timestep
print, 'Total time: ', (warmup_step*timestep) + (timestep*nn)
print, 'Timestep: ', timestep

FOR w=0, warmup_step -1 , 1 DO begin
	printf,1,FORMAT='(3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4)'$
	,timestep,'e+00',0.0,'e+02',1.0,'e+02',(flux_i*sflux)/100.0,'e+02',(warmup_energy*senergy)/10000.0,'e+04',0.0,'e+02'
	warmup_energy = warmup_energy + energy_step
endfor

FOR i=0, nn-1 DO begin
	printf,1,FORMAT='(3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4)'$
	,timestep,'e+00',0.0,'e+02',1.0,'e+02',(flux_av[i]*sflux)/100.0,'e+02',(energy_av[i]*senergy)/10000.0,'e+04',0.0,'e+02'

endfor
endif else if keyword_set(warmup) then begin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MONOENERGETIC;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print, 'Printing a monoenergetic (guassian) spectrum /w warmup to the ', filename, ' file.'

warmup_step = round(warmup[0]/timestep)    ;how many timesteps it will take to get to the 5s warmup mark
energy_step = energy_i / warmup_step ;how much to increase the energy by per warmup step to reach initial energy levels
warmup_energy = energy_step ;variable which will be printed as energy in the warmup section

print, 'Warmup time: ', warmup_step*timestep
print, 'Total time: ', (warmup_step*timestep) + (timestep*nn)
print, 'Timestep: ', timestep

FOR w=0, warmup_step -1, 1 DO begin
	printf,1,FORMAT='(3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4)'$
	,timestep,'e+00',(flux_i*sflux)/100.0,'e+02',(warmup_energy*senergy)/10000.0,'e+04',0.0,'e+02',1.0,'e+02',0.0,'e+02'
	warmup_energy = warmup_energy + energy_step
endfor


FOR i=0, nn-1 DO begin
	printf,1, FORMAT='(3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4,3X,F9.7,A4)'$
	,timestep,'e+00',(flux_av[i]*sflux)/100.0,'e+02',(energy_av[i]*senergy)/10000.0,'e+04',0.0,'e+02',1.0,'e+02',0.0,'e+02'
	
ENDFOR
endif

close,1


close, /all
END
