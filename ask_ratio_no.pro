PRO ask_ratio_no, filedatetime, numstart, length, filename, data1, data2, data3

; a procedure to retrieve ASK total intensity in the radar beam region for ASK1 and ASK3 and to take the ratio between
; the two (ASK3/ASK1) for precipitation energy considerations
;
;Input:
;    filedatetime - number refering to the megablock of interest eg. YEAR/MONTH/DAY/HOUR/MIN/SEC - 20170127204239
;    numstart - start image (frame) number for the chosen period of interest
;    length - number of frames to consider (length of data pool)
;    filename - name of output ps-file (test.ps is default)
;
;Output:
;    data(1/2/3) - 1D arrays containing the individual ASK(1/2/3) radar beam intensity data 
;    
;
;
datestr = STRING(filedatetime) ; converting input value into string to read data file
A1 =STRMID(datestr + 'r1.txt', 8, 23) ; removing blank spaces surrounding string plus creating unique string for each cam
A2 =STRMID(datestr + 'r2.txt', 8, 23)
A3 =STRMID(datestr + 'r3.txt', 8, 23)
;
;
;




read_vs, file = [A1,A2,A3] ; should read all 3 ask files for the desired event ready to have data extracted

; process (below) from hsoft to create 4 files, a .ps plot file called 'filename' and 3 line#.dat files with array data
; contained within them

filenamestr = STRING(filename)
add_int_radar, numstart, length, filename=filenamestr, /esr, range=[1,150000]

; process (below) to read the binary data into arrays called data1, data2 and data3
read_1d, 'line1.dat', mjs1, time1, data1, title1, ytitle1
read_1d, 'line2.dat', mjs2, time2, data2, title2, ytitle2
read_1d, 'line3.dat', mjs3, time3, data3, title3, ytitle3

;taking the ratio of each of the arrays to get the ASK3/ASK1 ratio in its own seperate 'ratio' array


data1= data1
data2= data2
data3= data3

ratio = data3/data1

print, '----------'
print, 'Mean Ratio:', mean(ratio)

$ rm line1.dat
$ rm line2.dat
$ rm line3.dat

name = filename + '.ps'

$ rm name

end



