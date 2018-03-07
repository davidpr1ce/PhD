PRO model_vs_ASK

;Routine to plot model intensities/ratios against those calculated by ask

restore, 'ASK_data_int.sav'    ;contains energy, flux, int1_cal, int3_cal, ratio arrays directly from ASK observations
restore, 'ASK_model_brightness.sav'	;contains ASK1_model and ASK3_model brightness

;removing warmup period

;ASK1_model = ASK1_model[30:-1]
;ASK3_model = ASK3_model[30:-1]

ASK1_model = ASK1[9:-1]
ASK3_model = ASK3[9:-1]

x = n_elements(int1_cal)
y = n_elements(ASK1_model)

z = x*y  ;easiest way to find a common multiple

int1_cal = rebin(int1_cal, z)
int3_cal = rebin(int3_cal, z)

ASK1_model = rebin(ASK1_model, z)
ASK3_model = rebin(ASK3_model, z)

;Ratio

model_ratio = ASK3_model / ASK1_model
ask_ratio = int3_cal / int1_cal


!P.MULTI = [3,1,3]
layout, 3, pos, cpos

loadct, 39

plot, int1_cal, TITLE='ASK1', YTITLE='Brightness (R)', POSITION=pos(*,0), charsize=2.0
oplot, ASK1_model, color=250


plot, int3_cal, TITLE='ASK3', YTITLE='Brightness (R)', POSITION=pos(*,1), charsize=2.0
oplot, ASK3_model, color=250


plot, ask_ratio, TITLE='ASK3 / ASK1 Ratio', YTITLE='Ratio', POSITION=pos(*,2), charsize=2.0
oplot, model_ratio, color=250

print, 'MODEL IS IN RED'

END

