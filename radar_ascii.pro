pro radar_ascii,filename, hour, min, sec, alt, n_e, t_i, ratio


;Process to read radar data ASCII .txt files generated via josh's MATLAB script
;filename should be a string name of the .txt file

data = READ_ASCII(filename, TEMPLATE=ASCII_TEMPLATE(filename))

hour = data.FIELD04
min = data.FIELD05
sec = data.FIELD06
alt = data.FIELD07
n_e = data.FIELD08
t_i = data.FIELD09
ratio = data.FIELD10

save, hour, min, sec, alt, n_e, t_i, ratio, file='radar_data.sav'


end
