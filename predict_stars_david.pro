pro predict_stars_david, mblock, stars, days
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This routine is a modified version from ASTROLIB
; This routine creates an index of stars within the ASK FOV, either for a single megablock, 
; or over a number of megablocks. In both cases, the mjs of the starting megablock should be defined.
; The spotted star data is stored in the output array, stars(), as explained below.
;
; INPUT
; mjs - the Julian seconds value of the time/date to be investigated
; mjsend - the Julian seconds value of the end time/date to be investigated
; mblock - an array of megablock names to investigate
; KEYWORD 'DAY' - set this keyword if you would like to list all Pulkovo stars over a 24hr period. This routine will work regardless of whether the corresponding megablocks have been loaded.
;		  The first element of the mblock array is used as the start time.
;
; OUTPUT
; stars - 8-element array of data: 0 is SAO number; 1 is right ascension; 2 is declination; 3 is mjs time of star spotted; 4 is Henry Draper (HD) number; 5 is the azimuth; 6 is the elevation; 7 is a flag for Pulkovo stars (1 if Pulkovo, 0 otherwise); 8 is the HR number; 9 is the corresponding index of the megablock in the mblock array; 10 is the magnitude of the star
;
; Pulkovo stars are flagged with a '1' in the 8th column of the stars array.
; Uses PRECESS and PREMAT from ASTROLIB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
common vs
common sao

;A star will appear in the ASK FOV for 30 minutes (Svalbard).
;An accurate mjs time for each star's appearance in the FOV needs to be obtained from this routine.
;The routine mjs_megablock that's run at the end of this script will give the user a breakdown of when the star appears and disappears
								;Both of these have been tested and output the correct mjs for the megablocks

if n_elements(sra_) lt 10 then read_sao				;Check whether the SAO catalogue has been read. If not, then read in.
epoch1=2000.0d0
cnt=0l
stars=dblarr(11, 400000)
openr,1, '/stp/raid2/ask/Pulkovocalibration/pulkovo_cat/stars_index_int.dat'			;Load the pulkovo HR and HD index file, which contains the HR number
index=fltarr(2,631)						;and corresponding HD number from the Pulkovo catalogue. CHANGED INDEX DIMENSION FROM 609 TO 631 
readf,1,index
close,1

;if keyword_set(day) then begin					;If the keyword day is set, then tell routine to look at mblock(0) and iterate up to 87000 seconds afterwards
;endmjs=87000L
;iterations=0
;out_message=". Checking over 24 hours, starting from this megablock."
;endif else begin
endmjs=87000 * days							;Otherwise, iterate over all megablock in mblock array, checking each one at the beg, middle and end.
iterations=n_elements(mblock)-1
out_message=". Checking start, middle and end. Please wait..."
;endelse
for f=0, iterations, 1 do begin
read_vs, filename=mblock(f), /quiet				;Read in megablock file
print, "Predicting stars in megablock: ", mblock(f) ,out_message
mjs=vmjs(vsel)
for g=mjs, mjs+endmjs, 600 do begin				;Check each megablock at three times: once at the beginning, once in the middle, and once at the end
mjs_tt, g, yr,mo,da,ho,mi,se,ms                               	;Converts megablock mjs to year, month, day, hour, minute, second and milli-second
tt_mjs, yr,1,1,0,0,0,0,mjs_                                     ;Finds mjs for yr/01/01 00:00:00 - this is then used to create epoch2 (e.g 2006.0027).
epoch2=1.0d0*yr+(g-mjs_)/3600./24./365.25			;Define epoch2
cnv=fltarr(8)							;Load cnv factors for megablock
cnv(*)=vcnv(vsel,*)
								;Define look direction
az0=vcnv(vsel,6)
el0=vcnv(vsel,7)
								;Define geographical coordinates of instrument position
lat=vlat(vsel)
lon=vlon(vsel)

scale=vcnv(vsel,2)*1d-3 					;Define how large an angle one pixel covers * 0.001
r1=dimx(vsel)*0.5*scale						;Calculate the angle covered by half the camera in the x direction
r2=dimy(vsel)*0.5*scale						;Calculate the angle covered by half the camera in the y direction
rmax=sqrt((r1*r1)+(r2*r2))					;Calculate the resultant (angle covered by diagonal line across one quarter of FOV)

								;0 is s_num, 1 is right ascension, 2 is declination, 3 is time (mjs), 4 is Henry Draper number, 5 is azimuth, 6 is elevation
								;7 is Pulkovo Flag, 8 is HR number (only for Pulkovo stars), 9 is the index of mblock, i.e. the megablock when the star is found,
								;10 is the magnitude of the star
								;Information on all stars that appear within the ASK FOV over this period will be saved into the stars() array
epoch2=1.0d0*yr+(g-mjs_)/3600./24./365.25			;Define epoch2 for each new mjs
					                   	;Iterates through time period
ae_rd,az0,el0,ra00,dec00,g,lat,lon, /rad                        ;Outputs right ascension and declination for mjs00 time.
nnn=n_elements(sra_)-1
for j=1l,nnn do begin                                           ;Loops through the SAO catalogue.
								
if (sph_dist(sra_(j),sdec_(j),ra00,dec00) lt rmax) then begin   ;If star number is within the ASK FOV (denoted by ra00 and dec00), then begin.
ra_=sra_(j-1)
dec_=sdec_(j-1)
precess, ra_,dec_,epoch1,epoch2, /radian                        ;Find the change in angle of the star between epoch1 and epoch2
								;Epoch1 is set at the top of the routine as 2000.0d - why? 
rd_ae, ra_,dec_,az,el,g,lat,lon,/rad				;Convert right ascension and declination to azimuth and elevation
conv_xy_ae,x,y,az,el,cnv,/back					;Convert azimuth and elevation into x and y pixels
if (x ge 4) and (x lt dimx(vsel)-4) and (y ge 4) and (y lt dimy(vsel)-4) then begin	;If star is in the ASK FOV, then begin
if cnt eq 0 then begin						;Save the details of the first star found in the ASK FOV
stars(0,cnt)=j
stars(1,cnt)=ra_
stars(2,cnt)=dec_
stars(3,cnt)=g
stars(4,cnt)=hd_(stars(0,cnt)-1)
stars(5,cnt)=az
stars(6,cnt)=el
stars(9,cnt)=f
stars(10,cnt)=mag_(stars(0,cnt)-1)
if (where(index(1,*) eq stars(4,cnt))) ne -1 then begin		;column of the corresponding stars() row as 1, to indicate that star is a pulkovo star
stars(7,cnt)=1
d=where(index(1,*) eq stars(4,cnt))
stars(8,cnt)=index(0,d)						;Store the HR number
endif
cnt=cnt+1
endif else begin					        ;Where epoch1 is 2000 and epoch2 is the year (to the decimal place) of the megablock date.
if where(stars(0,*) eq j) eq -1 then begin			;Check to make sure each star spotted doesn't already exist in the stars array.
stars(0,cnt)=j 							;Save sao number.
stars(1,cnt)=ra_				;Save right ascension of star.
stars(2,cnt)=dec_				;Save declination of star.
stars(3,cnt)=g  						;Save mjs time when star was spotted
stars(4,cnt)=hd_(stars(0,cnt)-1) 				;Save the Henry Draper number of the star.
stars(5,cnt)=az							;Save the azimuth
stars(6,cnt)=el							;Save the elevation angle
stars(9,cnt)=f							;Save the corresponding index of mblock for star sighting
stars(10,cnt)=mag_(stars(0,cnt)-1)				;Save the magnitude of the star
if (where(index(1,*) eq stars(4,cnt))) ne -1 then begin		;column of the corresponding stars() row as 1, to indicate that star is a pulkovo star
stars(7,cnt)=1
d=where(index(1,*) eq stars(4,cnt))				;Find the HR number
stars(8,cnt)=index(0,d)						;Store the HR number
                                                                ;pindex=where(stars(7,*) eq 1)
                                                                ;print, "Index of pulkovo stars in stars() array: ", strtrim(pindex,2)
                                                                ;print, "Index of pulkovo stars in stars() array: ", cnt
mjs_tt, stars(3,cnt) ,yr, mo, da, ho, mi, se, ms
time=strtrim(mo,2)+":"+strtrim(da,2)+":"+strtrim(ho,2)+":"+strtrim(mi,2)+":"+strtrim(se,2)
sao=strtrim(stars(0, cnt),1)
if keyword_set(day) then begin
print, "Pulkovo star(SAO: "+sao+") spotted at "+time+". Stellar mag: "+strtrim(stars(10,cnt),2)
endif else begin
print, "Pulkovo star(SAO: "+sao+") spotted at "+time+" within the following megablock: "+ mblock(f)+". Stellar mag: "+strtrim(stars(10,cnt),2)
endelse
endif
cnt=cnt+1
endif
endelse
endif
endif
endfor
								;Print some information for the user
endfor
nepulk=where(stars(7,*) eq 1)
if n_elements(nepulk) eq 1 && nepulk(0) eq -1 then begin
print, "No Pulkovo stars appear in the FOV megablock ", mblock(f)
endif
endfor
stars=stars(*,0:cnt-1)

end
