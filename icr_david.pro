pro icr_david, filename, inttime=inttime, data
;
; Routine to read ionchem model output file into icr common block.
; inttime is a keyword which allows integration (averaging) over several
; time steps, to get data for comparison with slower data (e.g. from GUISDAP).
; Set inttime to an integration time in seconds. This should be an integer
; multiple of the time step in the model. If inttime is set then n_times
; and the time array in the icr common block are adjusted appropriately.
;
;

common icr, time,dat, dat2, n_points,n_times, name_specs, reaction_n, s_out, s_bal,n_d_n, prodloss
;
;   dat(species,            time_step, altitude_grid)
;   dat2(species, reaction, time_step, altitude_grid)
;   dat  - the array containing the densities of the species as the function 
;          of altitude and time
;   dat2 - balances
;

!p.thick=1.6
!p.charsize=1.1

openr, 1, filename
;
; reading the header first
;
;
n_tt=5000

time=fltarr(n_tt)
a=' '
b=' '
for i=1,3 do readf, 1, a
print, a
readf, 1, n_d, n_b
print, n_d, n_b
s_out=fltarr(n_d)
readf, 1, s_out

if (n_b ne 0) then begin
s_bal=fltarr(n_b)
readf, 1, s_bal
endif else readf, 1, a

readf, 1, a
readf, 1, zmin,zmax
readf, 1, a
readf, 1, n_points
readf, 1, a
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if (strmid(a,1,1) eq '#') then begin
print, 'Long header...'
;
; reading the long header
;
readf, 1, a
readf, 1, n_specs

name_specs=strarr(n_specs+1)
prodloss=strarr(n_specs+1,100)

for i=1,n_specs do begin
 readf, 1, a, form='(7x,a10)'
 name_specs(i)=a
endfor
;;;;;;; SPECIES
readf, 1, a
readf, 1, a
readf, 1, n_react
reaction_n=strarr(n_react+1)
for i=1,n_react do begin
 readf, 1, a, form='(7x,a40)'
 reaction_n(i)=a
endfor
;;;;;;; REACTIONS
readf, 1, a
readf, 1, a
n_s=intarr(n_specs+1)
n_l=intarr(n_specs+1)

for i=1,n_specs do begin
 readf, 1, a

 readf, 1, a
 n_s(i)=fix(strmid(a,10,10))
 readf, 1, a
 n_l(i)=fix(strmid(a,10,10))

 for j=1,n_s(i)+n_l(i) do begin
  readf, 1, a
  prodloss(i,j)=strcompress(a)
 endfor

endfor
;;;;;;; PRODUCTION/LOSS

endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if (strmid(a,0,1) eq '-') then begin
;
; reading the short header - to do !!!
;

endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readf, 1, a


dat=fltarr(n_d+1,n_tt,n_points)
i=0

if (n_b gt 0) then begin
 dat2=fltarr(n_b+1,32,n_tt,n_points)
 n_d_n=intarr(n_b)
endif

while not(eof(1)) do begin

 readf, 1, t
 time(i)=t
 readf, 1, a

 ; Reading densities
 d_=fltarr(n_d+1)
 a=''
 for j=0,n_points-1 do begin
  readf, 1, a
  reads, a, d_, form='(19e'+string(strlen(strtrim(a,0)+' ')/(n_d+1), form='(i0)')+')'
  dat(*,i,j)=d_(*)
 endfor

 ; Reading balances
 for k=1,n_b do begin
  readf, 1, a
  n_d_n(k-1)=n_l(s_bal(k-1))+n_s(s_bal(k-1))
  d_=fltarr(n_d_n(k-1)+1)
  for j=0,200 do begin
   readf, 1, d_;, form='(19e10.3)'
   dat2(k,0:n_d_n(k-1),i,j)=d_(*)
  endfor
 endfor

 i=i+1
endwhile

close, 1

n_times=i;+1
;time=[0,time]

print, 'Read ',i,' timesteps'
print, 'Density output for '
for i=0,n_d-1 do print, name_specs(s_out(i))

print, 'Production/loss balance for '
for i=0,n_b-1 do print, name_specs(s_bal(i))

if keyword_set(inttime) then begin
; Doing integration:
;
 tmp=time-shift(time,1)
 tstep=mean(tmp[1:n_times-2])
 tnum=fix(max([round(inttime/tstep),1]))
 print,'Integrating over '+string(tnum,form='(i0)')+' timesteps ('+strtrim(string(tstep*tnum,form='(f12.2)'),2)+'s)...'
 s1=0
 s2=tnum-1
 i=0
 tmp=size(dat2)
 tmp=tmp[2]
 while (s2 lt n_times) do begin
  time[i]=time[s2]
  for k=0,n_points-1 do begin
   for j=0,n_elements(s_out)-1 do dat[j+1,i,k]=mean(dat[j+1,s1:s2,k])
   for j=0,n_elements(s_bal)-1 do for h=0,tmp-1 do dat2[j+1,h,i,k]=mean(dat2[j+1,h,s1:s2,k])
  endfor
  i+=1
  s1+=tnum
  s2+=tnum
 endwhile
 n_times=i
endif
time=time[0:n_times-1]
dat=dat[*,0:n_times-1,*]
dat2=dat2[*,*,0:n_times-1,*]

;set_plot, 'ps'
;for k=1,n_d do begin
;contour, dat(k,0:n_times-1,*),time(0:n_times-1),dat(0,0,*), $
;nlevel=10., title=name_specs(s_out(k-1))
;endfor
;device, /close



end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
