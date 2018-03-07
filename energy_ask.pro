PRO ENERGY_ASK, megablock, frame1, Nframes, background, energy, ratio, flux, save=save

;A routine to produce energies from an inputted ASK megablock by calculating ratio of
;intensity between ASK1 and ASK3 (ASK3/ASK1) for the region corresponding to the radar
;beam at ESR
;!!!!!!!requires a model run prior to running itself (ie. get_ask_ems, ...)!!!!!!!
;Inputs:
;	megablock - string of the megablock label (w/o .txt)
;	frame1 - frame of the megablock to start on
;	Nframes - number of frames of which to run over
;	background - input background values for megablock (array), for now taken from get_askbackground 
;	save - set this keyword equal to the name of the file you want the arrays to be saved into
;	
;Outputs:
;	energy - energy calculated from ratio of emissions for each frame (array)
;	ratio - ratio calculated of emissions for each frame (array)
;	flux - calculated per frame via the model results
;


;read in the appropriate megablocks

read_vs, filename = [megablock[0]+'.txt',megablock[1]+'.txt'],/quiet
common vs

;get the intensity calibration
mjs0 = time_v(frame1,/full)   
cal_ask1 = get_ask_cal(mjs0,1)
cal_ask3 = get_ask_cal(mjs0,3)

print, 'Calibration numbers: ', cal_ask1, cal_ask3

;get model results from the common block
common flickering_model, energy_axis, tot6730, tot7774

;find the direction of the radar beam (ESR)
az=186.8*!dtor
el=81.6*!dtor
rr=0.45


;ASK1
;converting into pixel coordinates
v_select, 0
get_cnv, cnv1, scale1
conv_xy_ae, x1, y1, az, el, cnv1, /back
rad1 = rr/scale1

;defining the dimensions of the image frames
nx = dimx(vsel)
ny = dimy(vsel)

;generating the mask
roundmask, nx, ny, x1, y1, rad1, mask1, dummy1
nmask1 = n_elements(mask1)

;defining some variables and arrays for loops/storing data
count=0
oldpercent=0
time_start = time_v(frame1)
time=fltarr(Nframes)
int1=[]

;trying instead a square box around the zenith - I have commented out the lines that rely on this in the loops
;i prefer the mask method of defining the zenith

mjs_dy, mjs0, date

igrf_zenith, date, 78.15d, 16.03d, 0.0d, 100d, zaz, zel

conv_xy_ae, x1, y1, zaz, zel, cnv1, /back 

x1 = round(x1)
y1 = round(y1)

for i=0, Nframes - 1, 1 do begin
	percent =round( i/float(Nframes)*100.0)
	if (percent - oldpercent) ge 5 then begin
		print, string(percent, form='(f5.1, " % done")')
		oldpercent = percent
	endif
	time(count) = time_v(i) - time_start
	frame_curr = frame1+i
	read_v,frame_curr,im
	;int1 = [int1,mean(im[x1-5:x1+5,y1-5:y1+5])]
	;print, 'Mean counts: ', int1[i]
	int1 = [int1, mean(im[mask1])]
	 
count = count + 1
endfor


print, '---------------------'

;ASK3
v_select, 1
get_cnv, cnv3, scale3
conv_xy_ae, x3, y3, az, el, cnv3, /back
rad3 = rr/scale3

;generating the mask
roundmask, nx, ny, x3, y3, rad3, mask3, dummy3
nmask3 = n_elements(mask3)

;defining the variables anew
count=0
oldpercent=0
int3=[]

conv_xy_ae, x3, y3, zaz, zel, cnv3, /back

x3 = round(x3)
y3 = round(y3)

for i=0, Nframes-1, 1 do begin
	percent =round( i/float(Nframes)*100.0)
	if (percent - oldpercent) ge 5 then begin
		print, string(percent, form='(f5.1, "% done")')
		oldpercent = percent
	endif
	frame_curr = frame1+i
	read_v,frame_curr,im
	;int3 = [int3,mean(im[x3-5:x3+5,y3-5:y3+5])]
	int3 = [int3, mean(im[mask3])]

count = count + 1
endfor

help, int1
help, int3

print, 'Means: ', mean(int1), mean(int3)
;Removing background
int1 = int1 - background[0]
int3 = int3 - background[1]



print, 'Means: ', mean(int1), mean(int3)

;Applying calibration
int1_cal = (int1*cal_ask1)/vres(vsel) ;THIS IS WHAT WAS CAUSING DIFFERENCE IN FLUXES
int3_cal = (int3*cal_ask3)/vres(vsel)

;Calculating the ratio and corresponding energy
ratio = int3_cal/int1_cal
energy = ratio2energy(ratio)

flux = fltarr(Nframes)
;help, flux
;help, energy

;calculating the flux? this is taken from josh's get_askenergy procedure in hsoft.pro - not checked!
for j=0, n_elements(energy)-1 do begin
	brightness = INTERPOL(tot6730, energy_axis, energy[j])
 	flux[j] = int1_cal[j]/brightness
	;print, 'Brightness: ', brightness
	;print, 'Int1_cal: ', int1_cal[j]
	;print, 'Flux :', flux[j]
	
endfor

print, '---------------------'
print, 'Data can be saved as a .sav file if keyword /save is set!!'

if keyword_set(save) then begin
	save, energy, flux, ratio,int1_cal, int3_cal, file='ASK_data_int.sav'
	print, ' '
	print, "Saved energy, flux, ratio and int1/2_cal arrays into " + save + " file in the pwd. Can be restored in IDL via: restore, 'ASK_data.sav'"
endif

END


