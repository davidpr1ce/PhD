PRO read_agup_david, fname, mjs,time,h,nel,te,ti,vi,fit,pp_range,pp,range_pps,pps, nosave=nosave,noclean=noclean,silent=silent
;
; Reads in an ascii file as created by gup2ascii, and saves the results
; into preprocessed files (unless keyword nosave is set). Normally data
; for which the guisdap fit status is non-zero is removed (set to -1e30)
; but this can be overriden by setting the noclean keyword. The keyword
; silent prevents this routine from printing status info.
;
; Outputs:
;  mjs is the start time (mjs) of the data
;  time is an array of seconds since the start
;  h is an array of the heights of the data points
;  nel, te, ti, vi are the radar parameters produced by GUISDAP
;  fit is the fit status produced by GUISDAP (e.g. 0,1,2,3)
;  pp_range is an array of power profile ranges and pp is the power profiles
;   these can only be read from files created with gup2ascii v1.1 and above
; Need to add test to check if file exists...
if keyword_set(silent) then n_silent=0 else n_silent=1
openr, 23, fname
dummy=''
readf, 23, dummy ; to read the two header lines
readf, 23, dummy
ascii_ver=0.0
readf, 23, ascii_ver  ; This can be used to switch if necessary
gup_ver=0.0
site=''
expr=''
n_t=0L
n_h=0L
n_ppr=0L
readf, 23, gup_ver,n_t,n_h,n_ppr
readf, 23, site
readf, 23, expr
if n_silent then begin
 print, "GUISDAP version: "+strtrim(string(gup_ver),2)
 print, "Site: "+site
 print, "Experiment: "+expr
endif
time_az_el=dblarr(4,n_t)
readf,23,time_az_el
t_res=float(mean(time_az_el[1,*]-time_az_el[0,*]))
time=time_az_el[0,*]
mjs=min(time)
time=time-mjs
time=float(time)
if n_silent then begin
 print, "Start time:"
 print_dat,mjs
 print, "Dump length (secs): "+strtrim(string(t_res),2)
 print, "Reading data..."
endif
h=fltarr(n_h,n_t)
readf,23,h
h=transpose(h)
nel=fltarr(n_h,n_t)
readf,23,nel
nel=nel*1e10
nel=transpose(nel)
te=fltarr(n_h,n_t)
readf,23,te
te=transpose(te)
ti=fltarr(n_h,n_t)
readf,23,ti
ti=transpose(ti)
vi=fltarr(n_h,n_t)
readf,23,vi
vi=transpose(vi)
fit=intarr(n_h,n_t)
readf,23,fit
fit=transpose(fit)
if (ascii_ver ge 1.1) then begin ; pp's are only saved in v1.1+
 pp_range=fltarr(n_ppr,n_t)
 readf,23,pp_range
 pp_range=transpose(pp_range)
 pp=fltarr(n_ppr,n_t)
 readf,23,pp
 pp*=1e10
 pp=transpose(pp)
endif
close, 23
; clean data...
if not(keyword_set(noclean)) then begin
 if n_silent then print, "Removing unfitted data points..."
 bad=where(fit ne 0)
 nel[bad]=-1e30
 te[bad]=-1e30
 ti[bad]=-1e30
 vi[bad]=-1e30
endif
; do slicing...
print, 'ascii_ver: ', ascii_ver
if (ascii_ver ge 1.1) then begin
 slice_points=[0]
 for i=1,n_ppr-1 do if (pp_range[0,i] lt pp_range[0,i-1]) then slice_points=[slice_points,i]
 ; slice points are indexes to START of a slice 
 if n_elements(slice_points) gt 1 then begin ; power profiles are sliced
  print, '---'
  if n_silent then print, "Extracting slices from power profiles..."
  n_slices=n_elements(slice_points)
  slice_points=[slice_points,n_ppr] ; last point does not exist!
  slice_len=intarr(n_slices)
  for i=0,n_slices-1 do slice_len[i]=slice_points[i+1]-slice_points[i]
  if n_elements(uniq(slice_len)) ne 1 then pad=1 else pad=0
  if n_silent then print, strtrim(string(n_slices),2)+" slices per dump each with a length of "+strtrim(string(max(slice_len)),2)+" elements (ranges)."
  ;if pad then print, strtrim(string(n_elements(n_slices)-1),2)+" slices are short and will be padded with dummy values."
  if pad then begin
   print, "WARNING: "+strtrim(string(n_elements(n_slices)-1),2)+" slices are short and will be skipped."
   print, " 2d format preprocessed data cannot currently deal with varying range axes."
  endif
  t_res_pps=t_res/float(n_slices)
  if n_silent then print, "Assuming all slices have an equal time length of "+strtrim(string(t_res_pps),2)+" secs."
  time_pps=fltarr(n_t*n_slices)
  range_pps=fltarr(n_t*(n_slices+1-n_elements(uniq(slice_len))),max(slice_len))
  pps=fltarr(n_t*n_slices,max(slice_len))
  k=0L
  for i=0,n_t-1 do begin
   for j=0,n_slices-1 do begin
    time_pps[(i*n_slices)+j]=time[i]+(t_res_pps*j)
    if (slice_len[j] eq max(slice_len)) then begin
     range_pps[k,*]=pp_range[i,slice_points[j]:(slice_points[j+1]-1)]
     k+=1
     pps[(i*n_slices)+j,*]=pp[i,slice_points[j]:(slice_points[j+1]-1)]
    endif else pps[(i*n_slices)+j,*]=1e-30
   endfor
  endfor
  av_h_pps=fltarr(max(slice_len))
  for i=0,max(slice_len)-1 do av_h_pps[i]=mean(range_pps[*,i])
 endif else begin  ; if data is not sliced...
  pps=pp
  time_pps=time
  range_pps=pp_range
  av_h_pps=fltarr(n_ppr)
  for i=0,n_ppr-1 do av_h_pps[i]=mean(pp_range[*,i])
 endelse
endif
; save stuff with save_2d...
if not(keyword_set(nosave)) then begin
 print, "Saving data to 2d format files..."
 mjs_tt,mjs,yr,mo,da,hr,mi,se
 case site of
  'T': title='EISCAT Tromsö UHF'
  'L': title='EISCAT Svalbard Radar
  'V': title='EISCAT Tromsö VHF'
  'K': title='EISCAT Kiruna'
  'S': title='EISCAT Sodankylä'
  else: title='(unknown radar)'
 endcase
 title+=', '+expr
 title+=', '+string(yr,mo,da,form="(I4,2('/',I2))")
 title+=', g'+strtrim(string(gup_ver,form='(F10.2)'),2)
 ytitle='Altitude / km'
 av_h=fltarr(n_h)
 for i=0,n_h-1 do av_h[i]=mean(h[*,i]) 
 fbase=strmid(fname,0,strpos(fname,'.',/reverse_search))
 if (fbase eq '') then fbase=fname
 save_2D, fbase+'_nel.dat',mjs,time,av_h,nel,title,ytitle,'Electron Density / m^-3'
 if n_silent then print, fbase+"_nel.dat saved."
 save_2D, fbase+'_te.dat',mjs,time,av_h,te,title,ytitle,'Electron Temperature / K'
 if n_silent then print, fbase+"_te.dat saved."
 save_2D, fbase+'_ti.dat',mjs,time,av_h,ti,title,ytitle,'Ion Temperature / K'
 if n_silent then print, fbase+"_ti.dat saved."
 save_2D, fbase+'_vi.dat',mjs,time,av_h,vi,title,ytitle,'Ion Velocity / ms^-1'
 if n_silent then print, fbase+"_vi.dat saved."
 if (ascii_ver ge 1.1) then begin
  save_2D, fbase+'_pp.dat',mjs,time_pps,av_h_pps,pps,title,'Range / km','Raw Electron Density / m^-3'
  if n_silent then print, fbase+"_pp.dat saved."
 endif 
endif
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
