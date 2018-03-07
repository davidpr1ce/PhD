pro check_cnv_david, megablock, frame, immin, immax

;Routine to check how accurate the currently saved CNV values are for a chosen megablock
;
;Inputs:
;	megablock - string of the megablock/time you wish to investigate ie. '20170127204239r1'
;	frame - the frame no. you want to check the CNV values for
;	immin/immax - values for scaling the camera image via btyscl function

;Read in the megablock
read_vs, filename=megablock+'.txt', /quiet
common vs

;get the time of the frame
mjs = time_v(frame,/full)

;produce the simulated star field
ssimulate_image, mjs, sim

;scale the simulated image
sim_scl = bytscl(sim, min=0, max=max(sim))

;get the actual image
read_v, frame, im

;scale the actual image
im_scl = bytscl(im, min=immin, max=immax)

;plot the images side by side for comparison
tv, sim_scl, [0]
tv, sim_scl, [4]
tv, im_scl, [1]
tv, im_scl, [3]


END
