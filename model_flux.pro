PRO model_flux,t_range=t_range, file=file, OI_7774D, OI_7774, N2_6730
;
; Routine to plot the emission integrated brightnesses
;
;

common emissions, em, br, alt, times, name_ems

if (n_elements(spec) lt 1) then spec=name_ems

ddd=intarr(1)
count2=0
for i=0,n_elements(spec)-1 do begin
 ddd2=where(strtrim(name_ems,2) eq strtrim(spec[i],2), count)
 count2+=count
 if (count eq 1) then ddd=[ddd,ddd2]
 if (count eq 0) then print, spec[i]+": No emission with that name found!"
endfor
if (count2 eq 0) then begin
 print, "Nothing to do!"
 goto, end_label
endif else ddd=ddd[1:count2]

if keyword_set(t_range) then begin
 t_min=t_range[0]
 t_max=t_range[1]
endif else begin
 t_min=0
 t_max=times(n_elements(times)-1)
endelse

if keyword_set(file) then begin
 set_plot, 'ps'
 pg_ht=(5*n_elements(ddd))
 device, /color, bits=8, xsi=20, ysi=pg_ht, file=file
endif else begin
 set_plot, 'x'
 erase
endelse

layout, n_elements(ddd), pos, cpos
pos[2,*]=cpos[2,*]+0.05 ; remove colourbar position
if keyword_set(file) then begin
; addb=(5.5/pg_ht)-min(pos[1,*])
; addt=(5.5/pg_ht)-(1-max(pos[3,*]))
; h=(pos[3,*]-pos[1,*])*(1.0-addb-addt);-((1.75-((1.0-max(pos[3,*]))*pg_ht))/pg_ht))
; pos[1,*]=((pos[1,*]-0.5)*(1.0-addb))+addb+0.5
; pos[3,*]=pos[1,*]+h
; cpos[1,*]=pos[1,*]
; cpos[3,*]=pos[3,*]
 pos[0,*]+=0.05
endif


;the three emissions I am interested in for now
OI_7774D = []
OI_7774 = []
N2_6730 = []

for k=0,n_elements(ddd)-1 do begin

 !p.position=pos[*,k]

 print, 'Emission #: '+string(ddd[k],form='(i0)')+',  '+spec[k]

 t_con=where((times ge t_min) and (times le t_max))
 z_data=reform(br[t_con,ddd[k]])
 data = fltarr(n_elements(z_data))
 
 ytitle='Emission brightness'
 if (k eq (n_elements(ddd)-1)) then xtitle='Time, s' else xtitle=''
 if (k eq 0) then begin
  title='Model emission'
  if (n_elements(ddd) gt 1) then title+='s'
 endif else title=''
 ztitle=name_ems[ddd[k]]

 if k eq 1 then OI_7774D = z_data
 if k eq 2 then OI_7774 = z_data
 if k eq 3 then N2_6730 = z_data
 
  
 plot, times[t_con], z_data, xran=[t_min,t_max],xsty=1, $
 /noerase, title=title,xtitle=xtitle,ytitle=ztitle;ytitle+', '+ztitle
 
 
endfor



if keyword_set(file) then begin
 device, /close
 set_plot,'x'
endif

end_label:;
end
