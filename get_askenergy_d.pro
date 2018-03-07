pro get_askenergy_d, megablock, frame1, Nframes, background, mjs, energy, ratio, filename=filename
;
; Routine to obtain ASK energies
;

; for each frame in meagablock from frame1:frame1+Nframes-1:
;	- load frame
;   - locate zenith
;   - determine mean intensity for box of 10x10 pixels around zenith (calibrate and remove background)
;   - get ratio ASK3/ASK1
;   - convert ratio into energy using ratio2energy
;   - get mjs of frame

; declare outputs
mjs = dblarr(Nframes)
energy = dblarr(Nframes)
ratio  = dblarr(Nframes)
flux  = dblarr(Nframes)

; read in ASK1 and 3 megablocks
read_vs, file=[megablock+'r1.txt',megablock+'r3.txt'],/quiet

; get intensity calibration
mjs0 = time_v(frame1,/full)
cal_ask1 = get_ask_cal(mjs0,1)
cal_ask3 = get_ask_cal(mjs0,3)

print, 'Calibration numbers: ', cal_ask1, cal_ask3

; get model results common block
common flickering_model, energy_axis,tot6730,tot7774

; Make directory for output files
dir = strmid(systime(),20,4)+strmid(systime(),4,3)+strtrim(strmid(systime(),8,2),1)+'_'+strmid(systime(),11,2)+strmid(systime(),14,2)+strmid(systime(),17,2)
dir = '$WKDIR/results_from_get_askenergy/'+dir
spawn, 'mkdir '+dir

; Create filename based on current date and time if a file name has not been provided
if not(keyword_set(filename)) then begin
	mjs_tt,mjs0,yr,mo,dd,hh,mm,ss,ms
	; convert to strings
	dd2str = string(dd,format='(I2.2)')
	mo2str = string(mo,format='(I2.2)')
	yr2str = strtrim(yr,1)
	hh2str = string(hh,format='(I2.2)')
	mm2str = string(mm,format='(I2.2)')
	ss2str = string(ss,format='(I2.2)')
	filename = dir+'/res_get_askenergy_start'+yr2str+mo2str+dd2str+hh2str+mm2str+ss2str+'.dat'
endif else filename = dir+'/'+filename

; Write header of output data file
openw,lun,filename,width=200,/get_lun
printf,lun,'Results from get_askenergy, run started at '+systime()+', with following parameters:'
printf,lun,'Megablock: '+strtrim(megablock,1)
printf,lun,'Frames: ',strtrim(frame1,1),' to ',strtrim(frame1+Nframes-1,1)
printf,lun,'Background values for ASK1,3: ',background
printf,lun,'--------------------------------'
printf,lun,'  mjs                ratio     	energy             flux         ASK1           ASK3'
free_lun,lun

; loop over image frames
for idx_frame = frame1,frame1+Nframes-1 do begin
	print, string(13b), 'Processing frame #'+strtrim(string(idx_frame-frame1+1),1)+'/'+strtrim(string(Nframes),1), format='(A,35A,$)'
	mjs[idx_frame-frame1] = time_v(idx_frame,/full) ; mjs of current frame
	mjs_dy, mjs[idx_frame-frame1], date

	; find location of zenith
	igrf_zenith, date, 78.15d, 16.03d, 0.0d, 100d, zaz, zel
	get_cnv,cnv,scale
	conv_xy_ae, x, y, zaz, zel, cnv,/back

	; determine mean intensity in 11x11 pixel box centred on the zenith
	xi = round(x) ; round to nearest integer pixel number
 	yi = round(y)
 	; determine ASK1 intensity
 	v_select,0,/quiet
	read_v,idx_frame,im 
	intensity_ask1 = mean(im[xi-5:xi+5,yi-5:yi+5])
	print, 'Mean counts: ', intensity_ask1
	intensity_ask1 -= background[0]
	intensity_ask1 *= cal_ask1
	; determine ASK3 intensity
 	v_select,1,/quiet
	read_v,idx_frame,im 
	intensity_ask3 = mean(im[xi-5:xi+5,yi-5:yi+5])
	intensity_ask3 -= background[1]
	intensity_ask3 *= cal_ask3

	; get energy
	ratio[idx_frame-frame1] = intensity_ask3/intensity_ask1
	energy[idx_frame-frame1] = ratio2energy(ratio[idx_frame-frame1])

	; get flux
	brightness = INTERPOL(tot6730, energy_axis, energy[idx_frame-frame1]) ; conversion mW/m2 to R
	
	flux[idx_frame-frame1] = intensity_ask1/brightness


	; Write to file
	openu,lun,filename,width=200,/get_lun,/append
	printf,lun,mjs[idx_frame-frame1],ratio[idx_frame-frame1],energy[idx_frame-frame1],flux[idx_frame-frame1],intensity_ask1,intensity_ask3,format='(F17.4,2X,F7.3,2X,F13.3,2X,F13.3,2X,F13.3,2X,F13.3)'
	free_lun,lun
endfor

end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
