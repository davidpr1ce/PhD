pro pulkovo3, mblock, stars, day=day

;Test routine for bug hunting predict_stars_pulkovo3


common vs
common sao           						   ;calling variables from two common blocks defined elsewhere in hsoft

count = 0	;setting a count equal to zero for later - just to print if no pulkovo stars are found

if n_elements(sra_) lt 10 then read_sao                            ;reading in star catalogue	
print, 'test'		        
epoch1 = 2000.0d0                                                  ;defining a start point for star precession (used later)
cnt=0                                                          ;starting a count
stars = dblarr(11, 400000)                                         ;creating an array for stars data to be stored in once found (later)
openr, int, '/home/djp3g13/pulkovo_cat/stars_index_int.dat', /get_lun          ;opening pulkovo files for HR and HD numbers from pulkovo catalogue?
index = fltarr(2, 631)
readf, int, index
close, int

if keyword_set(day) then begin					;If the keyword day is set, then tell routine to look at mblock(0) and iterate up to 87000 seconds afterwards
endmjs=87000L
iterations=0
out_message=". Checking over 24 hours, starting from this megablock."
endif else begin
endmjs=1200L							;Otherwise, iterate over all megablock in mblock array, checking each one at the beg, middle and end.
iterations=n_elements(mblock)-1
out_message=". Checking start, middle and end. Please wait..."
endelse
for f=0, iterations, 1 do begin
read_vs, filename=mblock(f), /quiet				;Read in megablock file
print, "Predicting stars in megablock: ", mblock(f) ,out_message
mjs=vmjs(vsel)



for g=mjs, mjs+endmjs, 600 do begin                                ;loops over the range of mjs in steps of 600 (10 mins)
mjs_tt, g, yr, mo, da, hr, mi, se, ms                              ;converts given mjs (g) into gregorian calender 
tt_mjs, yr, 1, 1, 0, 0, 0, 0, mjs_e                                ;converts Jan 1st of year into mjs_e to define epoch2 (used for precession)
epoch2=1.0d0*yr+(g-mjs_e)/3600./24./365.25			   ;calculates epoch2
cnv = fltarr(8)
cnv(*) = vcnv(vsel,*)                                              ;reads out cnv (direction its pointing) values from ask.lut (read in via read_vs routine)
;print, 'CNV values used:', cnv

az0 = vcnv(vsel,6)                                                 ;read out the azimuth, elevation, latitude and longitude of ASK
el0 = vcnv(vsel,7)

lat = vlat(vsel)
lon = vlon(vsel)
                                                                   ;checked all these numbers manually, seem to recover expected 6 deg by 6 deg window
scale = vcnv(vsel,2)*1d-3                                          ;defining how large an angle 1 pixel covers * 0.001 
r1 = dimx(vsel)*0.5*scale                                          ;Calculate the angle covered by half the camera in the x-direction
r2 = dimy(vsel)*0.5*scale                                          ;Calculate the angle covered by half the camera in the y-direction
rmax = sqrt((r1*r1)+(r2*r2))                                       ;Calculate the distance to corner (angle covered by diagonal line across 1 quarter of FOV)
ae_rd, az0, el0, ra00, dec00, g, lat, lon, /rad                    ;Outputs right ascension (ra00) and declination (dec00) for mjs00 time (g)

star_no = n_elements(sra_)                                         ;Counts the number of stars in the sao catalogue to loop through
for j=0, star_no -1, 1 do begin                                   ;starts a loop through the stars in sao catalogue


if (sph_dist(sra_(j),sdec_(j),ra00,dec00) lt rmax) then begin      ;checks if angular distance between centre of ASK FOV and any stars in the catalogue is less than FOV max ang. rad.
ra_ = sra_(j)
dec_ = sdec_(j)
;print,'j: ',j, ' sra_(j): ', sra_(j), ' sra_(j-1): ', sra_(j-1)
;print, ra_, dec_
precess, ra_, dec_, epoch1, epoch2, /radian                        ;locate the star at the current time period (epoch2) by progressing it since its epoch1(1/1/2000) pos.(found in sao)
rd_ae, ra_, dec_, az, el, g, lat, lon, /rad                        ;convert the right ascension and declination into azimuth and elavation
conv_xy_ae, x, y, az, el, cnv, /back                               ;convert these az. and el. into x and y pixel coordinates

if (x ge 4) and (x lt dimx(vsel)-4) and (y ge 4) and (y lt dimy(vsel)-4) then begin           ;checks whether star is in the ASK FOV
if where(stars(0,*) eq j) eq -1 then begin                         ;checks to make sure each spotted star doesnt already exist in the stars array (if where finds no matches it returns
                                                                   ; -1)
stars(0,cnt)=j                                                     ;Save sao star number
stars(1,cnt)=ra_                                                   ;Save right ascension of star
stars(2,cnt)=dec_                                                  ;Save declination of star
stars(3,cnt)=g                                                     ;Save mjs time when star was spotted
stars(4,cnt)=hd_(stars(0,cnt)-1)                                   ;Save the Henry Draper number of the star
stars(5,cnt)=az                                                    ;Save the azimuth
stars(6,cnt)=el                                                    ;Save the elevation
stars(9,cnt)=f                                                     ;Save the megablock index
stars(10,cnt)=mag_(stars(0,cnt)-1)                                 ;Save the magnitude of the star

if (where(index(1,*) eq stars(4,cnt))) ne -1 then begin            ;Check HD number of star and compare to the pulkovo catalogue HD numbers, if there is a match ie not equal -1 then
stars(7,cnt)=1.0                                                   ;Flag the star as pulkovo ----------- In index (0,*) is HR numbers, (1,*) is HD numbers.
d=where(index(1,*) eq stars(4,cnt))                                ;Defining a variable d which stores the index in the array corresponding to pulkovo star
stars(8,cnt) = index(0,d)                                          ;Save the HR number

mjs_tt, stars(3,cnt) ,yr, mo, da, ho, mi, se, ms                   ;Convert the mjs at which pulkovo star was found into gregorian calender
time = strtrim(mo,2)+":"+strtrim(da,2)+":"+strtrim(ho,2)+":"+strtrim(mi,2)+":"+strtrim(se,2)           ;Define some strings for outputting the time star was spotted at
sao = strtrim(stars(0,cnt),1)                                      ;Output star number (of pulkovo star)



if keyword_set(day) then begin
print, "Pulkovo star(SAO: "+sao+") spotted at "+time+". Stellar mag: "+strtrim(stars(10,cnt),2)
count = count + 1
endif else begin
count = count + 1
print, "Pulkovo star(SAO: "+sao+") spotted at "+time+" within the following megablock: "+ mblock(f)+". Stellar mag: "+strtrim(stars(10,cnt),2)
print, 'x / y: ', x, y, ' SAO: ', stars(0,cnt)
print, 'az / el: ', az, el 
endelse
endif
cnt = cnt + 1
endif
endif
endif



endfor
endfor
endfor


if count eq 0 then begin
	print, 'No Pulkovo stars found for the period selected'
endif

stars=stars(*,0:cnt-1)

END 
