PRO dec_check, dec_, ra_

common vs

read_vs, filename = '20170127204239r1.txt'
read_v, 50, im
get_cnv, cnv
mjs = vmjs(vsel)
lat = vlat(vsel)
lon = vlon(vsel)



dec_ = []
ra_ =[]

for i=0, 256-1 do begin
	for j=0, 256-1 do begin
		conv_xy_ae, i, j, az, el, cnv
		ae_rd, az, el, ra, dec,mjs, 78.1530, 16.0290, /rad
		dec_ = [dec_, dec]
		ra_ = [ra_, ra]
	endfor
endfor

END
