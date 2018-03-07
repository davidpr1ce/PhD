PRO dec_band, filename, stars

;Ideally modify this to take a gregorian date as input, look up the CNV values for that date and pull the variables without having
;to have loaded the megablock - allowing pulkovo hunting without needing to read tapes or load data.

;Procedure to get the band of declination values in the sky that correspond to ASK FOV
;Input:
;	filename = megablock in question eg. '20170127204239r1.txt'


;load the common blocks
common vs
common sao

;read the description file
read_vs, file=filename, /quiet

;pull some important variables for the megablock in question
mjs = vmjs(vsel)
get_cnv, cnv
az0 = vcnv(vsel,6)
el0 = vcnv(vsel,7)
lat = vlat(vsel)
lon = vlon(vsel)

;ADD SECTION THAT READS CAMERA#.LUT AND READS IN THE TIME PERIODS TO GET CNV VALUES RATHER THAN GIVING IT A MEGABLOCK - CHANGE INPUT TO REFLECT THIS
dec_check = []
ra_check =[]

;Trying to calculate the ra/dec or az/el range of the ASK fov by looping through every pixel and filling arrays with these values to find maximum

max_ = 0
min_ = 256
for i=0, 256-1 do begin
	for j=0, 256-1 do begin
		conv_xy_ae, i, j, _az, _el, cnv
		ae_rd, _az, _el, _ra, _dec,mjs, 78.1530, 16.0290, /rad
		if _dec gt max_ then max_= _dec
		if _dec lt min_ then min_=_dec
		dec_check = [dec_check, _dec]
		ra_check = [ra_check, _ra]
	endfor
endfor

high = max(dec_check) 
low = min(dec_check)
diff = (high - low)


print, '--'
print, min_, max_
print, '--'


conv_xy_ae, 156, 255, azz, ell, cnv
conv_xy_ae, 0, 0, aaz, eel, cnv
ae_rd, azz, ell, raa, decc, mjs, lat, lon, /rad
ae_rd, aaz, eel, rra, ddec, mjs, lat, lon, /rad

print, 'Dec (high): ' , decc, ' Pixel Coordinates (x/y): ', 156, 255
print, 'Dec (low): ', ddec, ' Pixel Coordinates (x/y): ' , 0, 0
 

;Adding an 'adjustment factor' that removes stars that are too close to top/bottom of the FOV and will likely not appear for very long.
adjust = diff * 0.0

high = high - adjust
low = low + adjust

rd_ae, _ra, high, azh, elh, mjs, lat, lon, /rad
rd_ae, _ra, low, azl, ell, mjs, lat, lon, /rad

conv_xy_ae, xh, yh, azh, elh, cnv, /back
conv_xy_ae, xl, yl, azl, ell, cnv, /back

print,'Dec converted into y: ', yl, yh


;Defining some attributes to describe the ASK FOV

scale = vcnv(vsel,2)*1d-3	;define how large an angle one pixel covers
r1 = dimx(vsel)*0.5*scale	;calculate the angle covered by 1/2 the camera in the x direction 
r2 = dimy(vsel)*0.5*scale	;calculate the angle covered by 1/2 the camera in the y direction
rmax = sqrt((r1*r1)+(r2*r2))*0.8	;calculate the angle covered by a diagonal line across a quarter of the FOV
	

print, 'High: ', high, ' Low: ', low, ' Diff: ', diff, ' Adjust: ', adjust


mjs_tt, mjs, yr,mo,da,ho,mi,se,ms	;calculates the gregorian date corresponding to mjs of megablock                          	
tt_mjs, yr,1,1,0,0,0,0,mjs_	;calculates mjs for the start of the year (Jan 1st)

epoch1 = 2000.0d0	;sets the initial epoch from which to precess stars from the sao catalogue from
epoch2 =1.0d0*yr+(mjs-mjs_)/3600./24./365.25	;sets the final epoch corresponding to time period of megablock to precess stars to

read_sao; 	reads in the sao catalogue

openr, 1, '/stp/raid2/ask/Pulkovocalibration/pulkovo_cat/stars_index_int.dat'	;reads in the pulkovo catalogue
index=fltarr(2,631)
readf,1,index
close,1


nn = n_elements(sra_)-1
stars=dblarr(6,n_elements(sra_))	;create an array to store data about stars in



;a loop to go through the sao catalogue

foreach element, sra_, i do begin	
	stars(0,i) = i						;Saves the SAO number
	stars(1,i) = hd_(stars(0,i)-1)				;Saves the Henry Draper Number (HD)
	if (where(index(1,*) eq stars(1,i))) ne -1 then begin   ;Compares the HD number from SAO to that of pulkovo catalogue
		stars(3,i) = 1					;If there is a match flags the star as pulkovo (ie. stars(3,#) =1)
		stars(5,i)= mag_(stars(0,i)-1)			;Stores the magnitude of the star
	endif
	
endforeach

pulkovo_i = where(stars(3,*) eq 1.0)	;defines the index's in stars that correspond to pulkovo stars


print, 'Pulkovo stars that should theoretically appear in the ASK FOV for the time period corresponding to the chosen megablock: '
print, ' '

count = 0

foreach element, pulkovo_i, j do begin			;loops through the pulkovo stars
	ra_ = sra_(element)				;defines the right ascension of the star
	dec_ = sdec_(element)				;defines the declination of the star
	precess, ra_, dec_, epoch1, epoch2, /radian	;precesses the star to the date of interest and changes the values of ra_ and dec_
	if (dec_ gt low) AND (dec_ lt high) then begin	;checks wether the star now appears in the region/band of interest in the sky
		count = count + 1
		rd_ae, ra_, dec_, az_, el_, mjs, lat, lon, /rad
		conv_xy_ae, x_, y_, az_, el_, cnv, /back
		if (y_ gt 0) and (y_ lt 255) then begin
			print, 'SAO number: ', strtrim(element),'|', ' Magnitude: ', strtrim(stars(5,element)),'|', ' Declination: ', dec_
	  	endif
	endif

	
endforeach

print, 'Count: ', count

END
