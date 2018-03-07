pro star_check

tt_mjs, 2017, 01, 27, 05, 39, 38, 00, mjs_start
tt_mjs, 2017, 01, 27, 05, 59, 38, 00, mjs_end

for mjs=mjs_start, mjs_end, 10 do begin
	predict_stars2, mjs, s_num, s_az, s_el
	check = where(s_num eq 8207, count)
	if count gt 0 then begin
		mjs_tt, mjs, yr, mn, da, hr, min, sec, ms
		print, hr, min, sec
	endif
endfor

END
	
