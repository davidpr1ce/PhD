pro icr_color, spec, h_range=h_range, v_range=v_range, t_range=t_range, file=file,$
             pos=pos,cpos=cpos, ctitle=ctitle
;
;  Plots altitude profile of (multiple) species output in the ionchem code.
;  The output file should first be read using icr.pro.
;
; Inputs:
;  spec - A string array of species names, as appearing in the model output.
;         If not set then all species are plotted.
; Keywords:
;  h_range - A two element array setting the height range in km.
;  t_range - A two element array setting the time range in secs.
;  v_range - A two element array setting the data scale, in log(10)
;            e.g [7,12] will use a scale of 10^7 to 10^12.
;  file    - A string filename in which to put postscript output.
;            If not set then plotting is done in the default plotting location.
;            (e.g. a window)
;  pos     - Used to specify plotting position. If not set 'layout' is used to get pos.
;  cpos    - As pos but for colour bar. If pos is used cpos must also be used.
;  ctitle  - Used to set the title on the colour bar.


common icr, time,dat, dat2, n_points, n_times, name_specs, reaction_n, s_out, s_bal,n_d_n,prodloss
; dat(species,            time_step, altitude_grid)
; dat2(species, reaction, time_step, altitude_grid)
; dat  - the array containing the densities of the species as the function 
;        of altitude and time
; dat2 - balances

if (n_elements(spec) lt 1) then spec=name_specs[s_out]

ddd=intarr(1)
count2=0
for i=0,n_elements(spec)-1 do begin
 ddd2=where(strtrim(name_specs[s_out],2) eq strtrim(spec[i],2), count)
 count2+=count
 if (count eq 1) then ddd=[ddd,ddd2]
 if (count eq 0) then print, spec[i]+": No species with that name found!"
endfor
if (count2 eq 0) then begin
 print, "Nothing to do!"
 goto, end_label
endif else ddd=ddd[1:count2]

h_ax=dat(0,0,*)/1e5

if keyword_set(h_range) then begin
 h_min=h_range[0]
 h_max=h_range[1]
endif else begin
 h_min=min(h_ax)
 h_max=max(h_ax)
endelse

if keyword_set(t_range) then begin
 t_min=t_range[0]
 t_max=t_range[1]
endif else begin
 t_min=0
 t_max=time(n_times-1)
endelse

if keyword_set(file) then begin
 set_plot, 'ps'
 pg_ht=(7*n_elements(ddd))
 device, /color, bits=8, xsi=20, ysi=pg_ht, file=file,/encap
endif ;else begin
; set_plot, 'x'
; erase
;endelse
loadct,39

if not(keyword_set(pos)) then layout, n_elements(ddd), pos, cpos
if keyword_set(file) then begin
 addb=(1.75-(min(pos[1,*])*pg_ht))/pg_ht
 h=(pos[3,*]-pos[1,*])*(1.0-addb-((2.5-((1.0-max(pos[3,*]))*pg_ht))/pg_ht))
 pos[1,*]=((pos[1,*]-0.5)*(1.0-addb))+addb+0.5
 pos[3,*]=pos[1,*]+h
 cpos[1,*]=pos[1,*]
 cpos[3,*]=pos[3,*]
endif

for k=0,n_elements(ddd)-1 do begin

 !p.position=pos[*,k]

 plot, time,h_ax,xran=[t_min,t_max],yran=[h_min,h_max],xsty=5,ysty=5, $
 /nodata,/noerase

 print, 'Species #: '+string(ddd[k],form='(i0)')+',  '+spec[k]
 
 t_con=where((time[0:n_times-1] ge t_min) and (time[0:n_times-1] le t_max))
 h_con=where((h_ax ge h_min) and (h_ax le h_max))
 z_data=reform(dat[ddd[k]+1,t_con,h_con])
 col=alog(z_data+1.0)/alog(10)

 if keyword_Set(v_range) then begin
  x_min=v_range[0]
  x_max=v_range[1]
 endif else begin
  x_min=floor(max(col)-(stddev(col,/nan)*0.6))
  x_max=ceil(max(col))
 endelse

 col=255*(col-x_min)/(x_max-x_min)
 dummy=where(col lt 0, count)
 if (count gt 0) then col[dummy]=0
 dummy=where(col gt 255, count)
 if (count gt 0) then col[dummy]=255

 xx=time[t_con]
 yy=h_ax[h_con]
 
 for i=0,n_elements(xx)-2 do begin
  for j=0,n_elements(yy)-2 do begin
   polyfill, [xx[i],xx[i+1],xx[i+1],xx[i]],[yy[j+1],yy[j+1],yy[j],yy[j]],color=col[i,j]
  endfor
 endfor

 ytitle='Height, km'
 if (k eq (n_elements(ddd)-1)) then xtitle='Time, s' else xtitle=''
 if (k eq 0) then begin
  title='Model density profile'
  if (n_elements(ddd) gt 1) then title+='s'
 endif else title=''
 if (keyword_set(ctitle)) then ztitle=ctitle else ztitle=name_specs[s_out[ddd[k]]]

 plot, time,h_ax,xran=[t_min,t_max],yran=[h_min,h_max],/xsty,/ysty, $
 /nodata,ytitle=ytitle,xtitle=xtitle,title=title,/noerase

 !p.position=cpos[*,k]
 cbar, range=[10.^x_min, 10.^x_max], /log, title=ztitle

endfor

if keyword_set(file) then begin
 device, /close
 set_plot,'x'
endif

end_label:;
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
