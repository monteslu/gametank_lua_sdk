-- ==== GENERATED DATA BEGIN (tools/gen.js — do not edit by hand) ====
-- track A1 of Driftmania by maxbize (CC-BY-NC-SA 4.0), 30x30 chunks of
-- 3x3 tiles; layer-local chunk ids packed r|d<<5|p<<10; ckd 0=skip,
-- 1..15=solid color, 16+k=tile def k; masks: bit(x)=1 row bytes.
-- constants: DECB=23 PROPB=44 NCK=54 SPAWN=(312,264) dir=0.5 laps=3
local decb = 23
local propb = 44
local spawnx = 312
local spawny = 264
local spawndir = 0.5
local nlaps = 3
local mplat = 990
local mgold = 1080
local msilver = 1216
local mbronze = 1440
local ncp = 3
local cgrid = array(900)
local ckd = array(54, 16)
local ckt = array(54)
local ctiles = array(477)
local wallbit = array(540)
local tmi = array(128)
local tcls = array(12, 2)
local tmask = array(96)
local woff = array(264, -3)
local bbx = array(256, -3)
local bby = array(256, -1)
local carfr = array(32, 128)
local cpx = array(3, 300)
local cpy = array(3, 229)
local cpdx = array(3, 1)
local cpdy = array(3, 1)
local cpl = array(3, 72)
local div3 = array(96)
local mod3 = array(96)

function gd_1()
 cgrid[138]=1024
 for i=139,143 do cgrid[i]=2048 end
 cgrid[144]=3072
 cgrid[168]=4096
 cgrid[169]=1
 cgrid[170]=2
 cgrid[171]=2
 cgrid[172]=2
 cgrid[173]=3
 cgrid[174]=4096
 cgrid[198]=4096
 cgrid[199]=4
 cgrid[200]=5
 cgrid[201]=38
 cgrid[202]=5
 cgrid[203]=7
 cgrid[204]=4096
 cgrid[228]=4096
 cgrid[229]=68
 cgrid[230]=104
 cgrid[231]=5257
 cgrid[232]=170
 cgrid[233]=7
 cgrid[234]=4096
 cgrid[258]=4096
 cgrid[259]=68
 cgrid[260]=7
 cgrid[261]=4096
 cgrid[262]=68
 cgrid[263]=7
 cgrid[264]=4096
 cgrid[276]=1024
 for i=277,287 do cgrid[i]=2048 end
 cgrid[288]=6347
 cgrid[289]=236
 cgrid[290]=7
 cgrid[291]=4096
 cgrid[292]=68
 cgrid[293]=7
 cgrid[294]=4096
 cgrid[306]=4096
 cgrid[307]=1
 for i=308,312 do cgrid[i]=2 end
 cgrid[313]=258
 for i=314,317 do cgrid[i]=2 end
 cgrid[318]=301
 cgrid[319]=5
 cgrid[320]=7
 cgrid[321]=4096
 cgrid[322]=4
 cgrid[323]=7
 cgrid[324]=4096
 cgrid[336]=4096
 cgrid[337]=4
 cgrid[338]=5
 cgrid[339]=334
 cgrid[340]=367
 cgrid[341]=367
 cgrid[342]=15
 cgrid[343]=271
 for i=344,349 do cgrid[i]=15 end
 cgrid[350]=16
 cgrid[351]=4096
 cgrid[352]=4
 cgrid[353]=7
 cgrid[354]=4096
 cgrid[366]=4096
 cgrid[367]=4
 cgrid[368]=104
 cgrid[369]=1425
 for i=370,380 do cgrid[i]=2048 end
 cgrid[381]=6347
 cgrid[382]=236
 cgrid[383]=7
 cgrid[384]=4096
 cgrid[396]=4096
 cgrid[397]=4
 cgrid[398]=7
 cgrid[399]=4096
 cgrid[400]=1
 for i=401,408 do cgrid[i]=2 end
 cgrid[409]=418
 cgrid[410]=418
 cgrid[411]=301
 cgrid[412]=453
 cgrid[413]=7
 cgrid[414]=4096
 cgrid[426]=4096
 cgrid[427]=4
 cgrid[428]=7
 cgrid[429]=4096
 cgrid[430]=4
 cgrid[431]=5
 cgrid[432]=334
 for i=433,442 do cgrid[i]=15 end
 cgrid[443]=496
 cgrid[444]=4096
 cgrid[456]=4096
 cgrid[457]=4
 cgrid[458]=7
 cgrid[459]=4096
 cgrid[460]=4
 cgrid[461]=104
 cgrid[462]=7569
 for i=463,473 do cgrid[i]=2048 end
 cgrid[474]=6144
 cgrid[486]=4096
 cgrid[487]=4
 cgrid[488]=7
 cgrid[489]=4096
 cgrid[490]=4
 cgrid[491]=530
 cgrid[492]=8755
 for i=493,497 do cgrid[i]=2048 end
 cgrid[498]=3072
 cgrid[516]=4096
 cgrid[517]=4
 cgrid[518]=7
 cgrid[519]=4096
 cgrid[520]=4
 cgrid[521]=5
 cgrid[522]=596
 cgrid[523]=418
 cgrid[524]=418
 cgrid[525]=2
 cgrid[526]=2
 cgrid[527]=3
 cgrid[528]=4096
 cgrid[546]=4096
 cgrid[547]=4
 cgrid[548]=7
 cgrid[549]=4096
 cgrid[550]=21
 for i=551,554 do cgrid[i]=15 end
 cgrid[555]=630
 cgrid[556]=5
 cgrid[557]=7
 cgrid[558]=4096
 cgrid[576]=4096
 cgrid[577]=4
 cgrid[578]=647
 cgrid[579]=9216
 for i=580,584 do cgrid[i]=2048 end
 cgrid[585]=3767
 cgrid[586]=170
 cgrid[587]=7
 cgrid[588]=4096
 cgrid[606]=4096
 cgrid[607]=4
 cgrid[608]=647
 cgrid[609]=4096
 cgrid[615]=4096
 cgrid[616]=68
 cgrid[617]=7
 cgrid[618]=4096
 cgrid[636]=4096
 cgrid[637]=4
 cgrid[638]=530
 cgrid[639]=10803
 for i=640,644 do cgrid[i]=2048 end
 cgrid[645]=6347
 cgrid[646]=236
 cgrid[647]=7
 cgrid[648]=4096
 cgrid[666]=4096
 cgrid[667]=4
 cgrid[668]=5
 cgrid[669]=596
 cgrid[670]=2
 cgrid[671]=2
 cgrid[672]=2
 cgrid[673]=418
 cgrid[674]=418
 cgrid[675]=301
 cgrid[676]=453
 cgrid[677]=7
 cgrid[678]=4096
 cgrid[696]=4096
 cgrid[697]=21
 for i=698,706 do cgrid[i]=15 end
 cgrid[707]=496
 cgrid[708]=4096
 cgrid[726]=10240
 for i=727,737 do cgrid[i]=2048 end
 cgrid[738]=6144
 ckd[2]=17
 ckd[3]=18
 ckd[4]=19
 ckd[5]=5
 ckd[6]=20
 ckd[7]=21
 ckd[8]=22
 ckd[9]=23
 ckd[10]=24
 ckd[11]=25
 ckd[12]=26
 ckd[13]=27
 ckd[14]=28
 ckd[15]=29
 ckd[16]=30
end

function gd_2()
 ckd[17]=31
 ckd[18]=32
 ckd[19]=33
 ckd[20]=34
 ckd[21]=35
 ckd[22]=36
 ckd[23]=37
 ckd[24]=38
 ckd[25]=39
 ckd[26]=40
 ckd[27]=41
 ckd[28]=42
 ckd[29]=43
 ckd[30]=44
 ckd[31]=45
 ckd[32]=46
 ckd[33]=47
 ckd[34]=48
 ckd[35]=49
 ckd[36]=50
 ckd[37]=51
 ckd[38]=52
 ckd[39]=53
 ckd[40]=54
 ckd[41]=55
 ckd[42]=56
 ckd[43]=57
 ckd[44]=58
 ckd[45]=59
 ckd[46]=60
 ckd[47]=61
 ckd[48]=62
 ckd[49]=63
 ckd[50]=64
 ckd[51]=65
 ckd[52]=66
 ckd[53]=67
 ckd[54]=68
 ckt[5]=1
 ctiles[1]=8
 ctiles[2]=2
 ctiles[3]=2
 ctiles[4]=4
 ctiles[5]=1
 ctiles[6]=1
 ctiles[7]=4
 ctiles[8]=1
 ctiles[9]=1
 ctiles[10]=2
 ctiles[11]=2
 ctiles[12]=2
 for i=13,18 do ctiles[i]=1 end
 ctiles[19]=2
 ctiles[20]=2
 ctiles[21]=7
 ctiles[22]=1
 ctiles[23]=1
 ctiles[24]=5
 ctiles[25]=1
 ctiles[26]=1
 ctiles[27]=5
 ctiles[28]=4
 ctiles[29]=1
 ctiles[30]=1
 ctiles[31]=4
 ctiles[32]=1
 ctiles[33]=1
 ctiles[34]=4
 for i=35,43 do ctiles[i]=1 end
 ctiles[44]=3
 ctiles[45]=1
 ctiles[46]=1
 ctiles[47]=1
 ctiles[48]=5
 ctiles[49]=1
 ctiles[50]=1
 ctiles[51]=5
 ctiles[52]=1
 ctiles[53]=1
 ctiles[54]=5
 for i=55,59 do ctiles[i]=1 end
 ctiles[60]=5
 ctiles[61]=1
 ctiles[62]=1
 ctiles[63]=5
 ctiles[64]=9
 ctiles[66]=6
 ctiles[73]=1
 ctiles[74]=1
 ctiles[75]=1
 ctiles[76]=4
 ctiles[77]=1
 ctiles[78]=1
 ctiles[79]=4
 ctiles[80]=1
 ctiles[81]=1
 ctiles[90]=8
 ctiles[91]=4
 ctiles[92]=1
 ctiles[93]=1
 ctiles[94]=4
 for i=95,99 do ctiles[i]=1 end
 ctiles[100]=2
 ctiles[101]=2
 for i=102,115 do ctiles[i]=1 end
 ctiles[116]=3
 ctiles[117]=3
 for i=118,123 do ctiles[i]=1 end
 ctiles[124]=3
 ctiles[125]=3
 ctiles[126]=3
 ctiles[127]=1
 ctiles[128]=1
 ctiles[129]=5
 ctiles[130]=1
 ctiles[131]=1
 ctiles[132]=5
 ctiles[133]=3
 ctiles[134]=3
 ctiles[135]=9
 ctiles[136]=9
 ctiles[145]=1
 ctiles[146]=1
 ctiles[147]=5
 ctiles[148]=1
 ctiles[149]=1
 ctiles[150]=5
 ctiles[151]=1
 ctiles[152]=1
 ctiles[153]=1
 ctiles[160]=7
 ctiles[163]=1
 ctiles[164]=2
 ctiles[165]=2
 for i=166,171 do ctiles[i]=1 end
 ctiles[172]=4
 ctiles[173]=1
 ctiles[174]=1
 ctiles[175]=4
 ctiles[176]=1
 ctiles[177]=1
 ctiles[178]=6
 ctiles[179]=3
 ctiles[180]=3
 for i=181,186 do ctiles[i]=1 end
 ctiles[187]=3
 ctiles[188]=3
 ctiles[189]=1
 ctiles[192]=6
 ctiles[206]=115
 ctiles[208]=114
 ctiles[211]=114
 ctiles[214]=114
 ctiles[222]=117
 ctiles[225]=117
 ctiles[226]=99
 ctiles[228]=98
 ctiles[238]=114
 ctiles[241]=114
 ctiles[252]=99
 ctiles[253]=114
 ctiles[256]=114
 ctiles[263]=10
 ctiles[266]=10
 ctiles[269]=10
 ctiles[271]=116
 ctiles[272]=116
 ctiles[287]=115
 ctiles[288]=115
 ctiles[295]=115
 ctiles[296]=115
 ctiles[297]=115
 ctiles[298]=99
 ctiles[307]=116
 ctiles[308]=116
 ctiles[309]=116
 ctiles[316]=15
 ctiles[320]=15
 ctiles[324]=15
 ctiles[325]=15
 ctiles[329]=15
 ctiles[336]=117
 ctiles[339]=117
 ctiles[349]=98
 ctiles[353]=116
 ctiles[354]=116
 ctiles[367]=115
 ctiles[368]=115
 ctiles[372]=117
 ctiles[375]=117
 ctiles[378]=117
 ctiles[381]=98
 ctiles[393]=45
 ctiles[395]=45
 ctiles[396]=61
 ctiles[400]=60
 ctiles[401]=60
 ctiles[402]=60
 ctiles[409]=43
 ctiles[412]=59
end

function gd_3()
 ctiles[413]=43
 ctiles[416]=44
 ctiles[419]=44
 ctiles[422]=44
 ctiles[428]=44
 ctiles[431]=44
 ctiles[433]=45
 ctiles[434]=61
 ctiles[436]=61
 ctiles[446]=45
 ctiles[447]=60
 ctiles[449]=44
 ctiles[452]=44
 ctiles[455]=59
 ctiles[456]=60
 ctiles[461]=44
 ctiles[464]=46
 ctiles[465]=60
 ctiles[467]=44
 ctiles[470]=59
 ctiles[471]=43
 ctiles[474]=59
 wallbit[82]=-32
 wallbit[83]=63
 wallbit[88]=48
 wallbit[89]=96
 wallbit[94]=16
 wallbit[95]=64
 wallbit[100]=16
 wallbit[101]=64
 wallbit[106]=16
 wallbit[107]=64
 wallbit[112]=16
 wallbit[113]=64
 wallbit[118]=16
 wallbit[119]=64
 wallbit[124]=16
 wallbit[125]=64
 wallbit[130]=16
 wallbit[131]=64
 wallbit[136]=8208
 wallbit[137]=64
 wallbit[142]=8208
 wallbit[143]=64
 wallbit[148]=8208
 wallbit[149]=64
 wallbit[154]=8208
 wallbit[155]=64
 wallbit[160]=8208
 wallbit[161]=64
 wallbit[166]=8216
 wallbit[167]=64
 wallbit[170]=-2
 wallbit[171]=-1
 wallbit[172]=8207
 wallbit[173]=64
 wallbit[176]=3
 wallbit[178]=8192
 wallbit[179]=64
 wallbit[182]=1
 wallbit[184]=8192
 wallbit[185]=64
 wallbit[188]=1
 wallbit[190]=8192
 wallbit[191]=64
 wallbit[194]=1
 wallbit[196]=8192
 wallbit[197]=64
 wallbit[200]=1
 wallbit[202]=8192
 wallbit[203]=64
 wallbit[206]=1
 wallbit[208]=8192
 wallbit[209]=64
 wallbit[212]=1
 wallbit[214]=8192
 wallbit[215]=64
 wallbit[218]=1
 wallbit[220]=12288
 wallbit[221]=64
 wallbit[224]=-1023
 wallbit[225]=-1
 wallbit[226]=8191
 wallbit[227]=64
 wallbit[230]=1537
 wallbit[233]=64
 wallbit[236]=513
 wallbit[239]=64
 wallbit[242]=513
 wallbit[245]=64
 wallbit[248]=513
 wallbit[251]=64
 wallbit[254]=513
 wallbit[257]=64
 wallbit[260]=513
 wallbit[263]=64
 wallbit[266]=513
 wallbit[269]=64
 wallbit[272]=513
 wallbit[275]=96
 wallbit[278]=513
 wallbit[279]=-4
 wallbit[280]=-1
 wallbit[281]=63
 wallbit[284]=513
 wallbit[285]=4
 wallbit[290]=513
 wallbit[291]=4
 wallbit[296]=513
 wallbit[297]=-4
 wallbit[298]=15
 wallbit[302]=513
 wallbit[304]=24
 wallbit[308]=513
 wallbit[310]=16
 wallbit[314]=513
 wallbit[316]=16
 wallbit[320]=513
 wallbit[322]=16
 wallbit[326]=513
 wallbit[328]=16
 wallbit[332]=513
 wallbit[334]=16
 wallbit[338]=513
 wallbit[340]=16
 wallbit[344]=513
 wallbit[346]=16
 wallbit[350]=-511
 wallbit[351]=2047
 wallbit[352]=16
 wallbit[356]=513
 wallbit[357]=3072
 wallbit[358]=16
 wallbit[362]=513
 wallbit[363]=2048
 wallbit[364]=16
 wallbit[368]=513
 wallbit[369]=2048
 wallbit[370]=16
 wallbit[374]=513
 wallbit[375]=2048
 wallbit[376]=16
 wallbit[380]=1537
 wallbit[381]=3072
 wallbit[382]=16
 wallbit[386]=-1023
 wallbit[387]=2047
 wallbit[388]=16
 wallbit[392]=1
 wallbit[394]=16
 wallbit[398]=1
 wallbit[400]=16
 wallbit[404]=1
 wallbit[406]=16
 wallbit[410]=1
 wallbit[412]=16
 wallbit[416]=1
 wallbit[418]=16
 wallbit[422]=1
 wallbit[424]=16
 wallbit[428]=1
 wallbit[430]=16
 wallbit[434]=3
 wallbit[436]=24
 wallbit[440]=-2
 wallbit[441]=-1
 wallbit[442]=15
 tmi[1]=1
 tmi[7]=2
 tmi[8]=3
 tmi[9]=4
 tmi[10]=5
 tmi[44]=6
 tmi[45]=7
 tmi[46]=8
 tmi[47]=9
 tmi[60]=10
 tmi[61]=11
 tmi[62]=12
 for i=1,5 do tcls[i]=1 end
 for i=1,8 do tmask[i]=255 end
 tmask[10]=1
 tmask[11]=3
 tmask[12]=7
 tmask[13]=15
 tmask[14]=31
 tmask[15]=63
 tmask[16]=127
 tmask[17]=254
 tmask[18]=252
 tmask[19]=248
 tmask[20]=240
 tmask[21]=224
 tmask[22]=192
 tmask[23]=128
 tmask[25]=127
 tmask[26]=63
 tmask[27]=31
 tmask[28]=15
 tmask[29]=7
end

function gd_4()
 tmask[30]=3
 tmask[31]=1
 tmask[34]=128
 tmask[35]=192
 tmask[36]=224
 tmask[37]=240
 tmask[38]=248
 tmask[39]=252
 tmask[40]=254
 tmask[46]=1
 tmask[47]=3
 tmask[48]=6
 for i=49,56 do tmask[i]=36 end
 tmask[62]=128
 tmask[63]=192
 tmask[64]=96
 tmask[65]=36
 tmask[66]=36
 tmask[67]=4
 tmask[68]=4
 tmask[69]=228
 tmask[70]=228
 tmask[71]=36
 tmask[72]=36
 tmask[73]=12
 tmask[74]=24
 tmask[75]=48
 tmask[76]=96
 tmask[77]=192
 tmask[78]=128
 tmask[85]=255
 tmask[86]=255
 tmask[89]=48
 tmask[90]=24
 tmask[91]=12
 tmask[92]=6
 tmask[93]=3
 tmask[94]=1
 woff[1]=-4
 woff[3]=3
 woff[4]=2
 woff[5]=-4
 woff[6]=2
 woff[7]=3
 woff[9]=-5
 woff[10]=-2
 woff[11]=3
 woff[12]=2
 woff[13]=-4
 woff[14]=3
 woff[15]=2
 woff[17]=-5
 woff[18]=-1
 woff[19]=3
 woff[20]=1
 woff[22]=4
 woff[23]=1
 woff[25]=-5
 woff[26]=0
 woff[27]=4
 woff[28]=0
 woff[29]=-2
 woff[30]=4
 woff[31]=1
 woff[32]=-4
 woff[33]=-5
 woff[34]=1
 woff[35]=3
 woff[36]=0
 woff[37]=-1
 woff[38]=5
 woff[39]=0
 woff[41]=-4
 woff[42]=2
 woff[43]=4
 woff[44]=-1
 woff[45]=0
 woff[46]=5
 woff[47]=-1
 woff[49]=-4
 woff[50]=3
 woff[51]=3
 woff[52]=-2
 woff[53]=1
 woff[54]=5
 woff[55]=-1
 woff[58]=4
 woff[59]=3
 woff[60]=-2
 woff[61]=2
 woff[62]=5
 woff[63]=-2
 woff[66]=4
 woff[67]=2
 woff[69]=2
 woff[70]=4
 woff[73]=-2
 woff[74]=5
 woff[75]=2
 woff[77]=3
 woff[78]=4
 woff[80]=-2
 woff[81]=-1
 woff[82]=5
 woff[83]=1
 woff[85]=4
 woff[86]=3
 woff[88]=-2
 woff[89]=0
 woff[90]=5
 woff[91]=0
 woff[92]=-4
 woff[93]=4
 woff[94]=2
 woff[95]=-4
 woff[96]=-1
 woff[97]=1
 woff[98]=5
 woff[99]=0
 woff[101]=5
 woff[102]=1
 woff[104]=0
 woff[105]=2
 woff[106]=4
 woff[107]=-1
 woff[108]=-4
 woff[109]=5
 woff[110]=0
 woff[111]=-4
 woff[112]=0
 woff[113]=3
 woff[114]=4
 woff[115]=-1
 woff[117]=5
 woff[118]=-1
 woff[120]=2
 woff[121]=4
 woff[122]=3
 woff[123]=-2
 woff[125]=5
 woff[126]=-2
 woff[128]=2
 woff[129]=4
 woff[130]=3
 woff[132]=-2
 woff[133]=4
 woff[134]=-2
 woff[136]=3
 woff[137]=5
 woff[138]=2
 woff[140]=-2
 woff[141]=4
 woff[143]=-2
 woff[144]=3
 woff[145]=5
 woff[146]=1
 woff[148]=-1
 woff[149]=3
 woff[150]=-4
 woff[151]=-1
 woff[152]=3
 woff[153]=5
 woff[154]=0
 woff[155]=-4
 woff[156]=0
 woff[157]=2
 woff[158]=-4
 woff[159]=-1
 woff[160]=4
 woff[161]=5
 woff[162]=-1
 woff[164]=0
 woff[165]=1
 woff[166]=-5
 woff[167]=0
 woff[168]=3
 woff[169]=4
 woff[170]=-2
 woff[171]=-4
 woff[172]=1
 woff[173]=0
 woff[174]=-5
 woff[175]=0
 woff[176]=4
 woff[177]=4
 woff[180]=2
 woff[181]=-1
 woff[182]=-5
 woff[183]=1
 woff[184]=3
 woff[185]=3
 woff[186]=-4
 woff[188]=2
 woff[189]=-2
 woff[190]=-5
 woff[191]=2
 woff[192]=3
 woff[193]=3
 woff[194]=-4
 woff[195]=-2
end

function gd_5()
 woff[196]=3
 woff[197]=-2
 woff[198]=-4
 woff[199]=3
 woff[200]=3
 woff[201]=2
 woff[202]=-5
 woff[203]=-2
 woff[204]=3
 woff[206]=-4
 woff[207]=3
 woff[208]=2
 woff[209]=1
 woff[210]=-5
 woff[211]=-1
 woff[212]=3
 woff[213]=-4
 woff[215]=3
 woff[216]=2
 woff[217]=0
 woff[218]=-5
 woff[219]=0
 woff[220]=4
 woff[221]=-4
 woff[222]=-2
 woff[223]=4
 woff[224]=1
 woff[225]=-1
 woff[226]=-5
 woff[227]=0
 woff[228]=3
 woff[229]=-5
 woff[230]=-1
 woff[231]=3
 woff[232]=0
 woff[233]=-2
 woff[234]=-4
 woff[235]=1
 woff[236]=4
 woff[237]=-5
 woff[238]=0
 woff[239]=4
 woff[240]=0
 woff[242]=-4
 woff[243]=2
 woff[244]=3
 woff[245]=-5
 woff[246]=1
 woff[247]=3
 woff[248]=-1
 woff[249]=-4
 woff[251]=2
 woff[252]=3
 woff[253]=-5
 woff[254]=2
 woff[255]=3
 woff[256]=-2
 woff[257]=-4
 woff[259]=3
 woff[260]=2
 woff[261]=-4
 woff[262]=2
 woff[263]=3
 bbx[1]=-6
 bbx[2]=-5
 bbx[3]=-1
 bbx[4]=2
 bbx[5]=4
 bbx[6]=2
 bbx[7]=-2
 bbx[8]=-5
 bbx[9]=-6
 bbx[10]=-4
 bbx[11]=-1
 bbx[12]=2
 bbx[13]=4
 bbx[14]=1
 bbx[15]=-2
 bbx[16]=-5
 bbx[17]=-7
 bbx[18]=-4
 bbx[19]=0
 bbx[20]=3
 bbx[21]=4
 bbx[22]=1
 bbx[24]=-5
 bbx[25]=-5
 bbx[26]=-2
 bbx[27]=1
 bbx[28]=4
 bbx[29]=3
 bbx[30]=0
 bbx[32]=-5
 bbx[33]=-4
 bbx[34]=-2
 bbx[35]=2
 bbx[36]=4
 bbx[37]=2
 bbx[38]=-1
 bbx[40]=-5
 bbx[42]=-1
 bbx[43]=2
 bbx[44]=4
 bbx[45]=1
 bbx[46]=0
 bbx[48]=-6
 bbx[50]=-2
 bbx[51]=2
 bbx[52]=3
 bbx[53]=1
 bbx[54]=0
 bbx[56]=-5
 bbx[58]=-2
 bbx[59]=1
 bbx[60]=2
 bbx[61]=1
 bbx[62]=1
 bbx[63]=-2
 bbx[64]=-4
 bbx[67]=1
 bbx[68]=2
 bbx[69]=2
 bbx[70]=2
 bbx[71]=-2
 bbx[75]=0
 bbx[76]=2
 bbx[77]=3
 bbx[78]=2
 bbx[79]=-1
 bbx[80]=-2
 bbx[82]=-4
 bbx[83]=0
 bbx[84]=2
 bbx[85]=3
 bbx[86]=3
 bbx[87]=-1
 bbx[88]=-2
 bbx[89]=-4
 bbx[91]=0
 bbx[92]=1
 bbx[93]=4
 bbx[94]=4
 bbx[95]=1
 bbx[96]=-1
 bbx[97]=-5
 bbx[98]=-4
 bbx[99]=0
 bbx[100]=2
 bbx[101]=4
 bbx[102]=4
 bbx[103]=1
 bbx[104]=-1
 bbx[105]=-5
 bbx[107]=0
 bbx[108]=3
 bbx[109]=5
 bbx[110]=3
 bbx[111]=1
 bbx[112]=-2
 bbx[113]=-5
 bbx[114]=-4
 bbx[115]=0
 bbx[116]=3
 bbx[117]=5
 bbx[118]=4
 bbx[119]=1
 bbx[120]=-2
 bbx[121]=-5
 bbx[123]=0
 bbx[124]=3
 bbx[125]=5
 bbx[126]=4
 bbx[127]=1
 bbx[128]=-2
 bbx[129]=-5
 bbx[131]=1
 bbx[132]=4
 bbx[133]=5
 bbx[134]=4
 bbx[135]=0
 bbx[137]=-5
 bbx[138]=-2
 bbx[139]=1
 bbx[140]=4
 bbx[141]=5
 bbx[142]=3
 bbx[143]=0
 bbx[144]=-2
 bbx[145]=-5
 bbx[146]=-2
 bbx[147]=2
 bbx[148]=4
 bbx[149]=4
 bbx[150]=3
 bbx[151]=-1
 bbx[152]=-4
 bbx[153]=-5
 bbx[154]=-2
 bbx[155]=1
 bbx[156]=3
end

function gd_6()
 bbx[157]=5
 bbx[158]=4
 bbx[159]=0
 bbx[161]=-4
 bbx[162]=-2
 bbx[163]=1
 bbx[164]=3
 bbx[165]=4
 bbx[166]=3
 bbx[167]=-1
 bbx[170]=-1
 bbx[171]=1
 bbx[172]=4
 bbx[173]=4
 bbx[174]=1
 bbx[175]=0
 bbx[178]=-2
 bbx[179]=0
 bbx[180]=3
 bbx[181]=3
 bbx[182]=2
 bbx[183]=-1
 bbx[184]=-4
 bbx[186]=-2
 bbx[187]=-1
 bbx[188]=2
 bbx[189]=3
 bbx[190]=2
 bbx[191]=0
 bbx[195]=-1
 bbx[196]=2
 bbx[197]=2
 bbx[198]=2
 bbx[199]=0
 bbx[202]=-4
 bbx[203]=-2
 bbx[204]=1
 bbx[205]=2
 bbx[206]=2
 bbx[207]=1
 bbx[208]=-2
 bbx[210]=-5
 bbx[211]=-2
 bbx[212]=0
 bbx[213]=2
 bbx[214]=3
 bbx[215]=1
 bbx[216]=-2
 bbx[217]=-4
 bbx[218]=-6
 bbx[220]=0
 bbx[221]=1
 bbx[222]=4
 bbx[223]=2
 bbx[224]=-1
 bbx[225]=-5
 bbx[226]=-6
 bbx[228]=-1
 bbx[229]=2
 bbx[230]=3
 bbx[231]=2
 bbx[232]=-1
 bbx[233]=-6
 bbx[234]=-5
 bbx[236]=0
 bbx[237]=3
 bbx[238]=4
 bbx[239]=1
 bbx[240]=-2
 bbx[241]=-6
 bbx[242]=-5
 bbx[243]=-2
 bbx[244]=1
 bbx[245]=4
 bbx[246]=3
 bbx[247]=-1
 bbx[248]=-4
 bbx[249]=-6
 bbx[250]=-5
 bbx[251]=-2
 bbx[252]=1
 bbx[253]=4
 bbx[254]=2
 bbx[255]=-1
 bbx[256]=-4
 bby[2]=-3
 bby[3]=-3
 bby[4]=-3
 bby[5]=0
 bby[6]=2
 bby[7]=2
 bby[8]=2
 bby[10]=-2
 bby[11]=-3
 bby[12]=-4
 bby[13]=0
 bby[14]=2
 bby[15]=2
 bby[16]=3
 bby[18]=-2
 bby[19]=-3
 bby[20]=-4
 bby[21]=0
 bby[22]=2
 bby[23]=3
 bby[24]=3
 bby[26]=-2
 bby[27]=-5
 bby[28]=-3
 bby[29]=0
 bby[30]=2
 bby[31]=4
 bby[32]=3
 bby[34]=-3
 bby[35]=-5
 bby[36]=-3
 bby[37]=1
 bby[38]=4
 bby[39]=4
 bby[40]=2
 bby[42]=-4
 bby[43]=-5
 bby[44]=-2
 bby[45]=1
 bby[46]=4
 bby[47]=4
 bby[48]=3
 bby[50]=-4
 bby[51]=-4
 bby[52]=-2
 bby[53]=2
 bby[54]=5
 bby[55]=4
 bby[56]=3
 bby[58]=-4
 bby[59]=-5
 bby[60]=-2
 bby[61]=2
 bby[62]=5
 bby[63]=5
 bby[64]=3
 bby[66]=-4
 bby[67]=-5
 bby[68]=-2
 bby[69]=2
 bby[70]=5
 bby[71]=5
 bby[72]=3
 bby[74]=-5
 bby[75]=-5
 bby[76]=-2
 bby[77]=2
 bby[78]=5
 bby[79]=5
 bby[80]=3
 bby[82]=-4
 bby[83]=-5
 bby[84]=-2
 bby[85]=2
 bby[86]=4
 bby[87]=6
 bby[88]=3
 bby[90]=-4
 bby[91]=-5
 bby[92]=-2
 bby[93]=1
 bby[94]=3
 bby[95]=5
 bby[96]=3
 bby[98]=-3
 bby[99]=-4
 bby[100]=-2
 bby[101]=1
 bby[102]=3
 bby[103]=4
 bby[104]=2
 bby[105]=-2
 bby[106]=-4
 bby[107]=-3
 bby[109]=1
 bby[110]=4
 bby[111]=4
 bby[112]=1
 bby[114]=-4
 bby[115]=-3
 bby[116]=-2
 bby[117]=0
 bby[118]=3
 bby[119]=3
 bby[120]=2
 bby[122]=-4
 bby[123]=-3
 bby[124]=-2
 bby[125]=0
 bby[126]=3
 bby[127]=2
 bby[128]=2
 bby[130]=-3
 bby[131]=-3
 bby[132]=-3
end

function gd_7()
 bby[133]=0
 bby[134]=2
 bby[135]=2
 bby[136]=2
 bby[138]=-3
 bby[139]=-3
 bby[140]=-4
 bby[141]=0
 bby[142]=1
 bby[143]=2
 bby[144]=2
 bby[146]=-3
 bby[147]=-4
 bby[148]=-4
 bby[149]=0
 bby[150]=1
 bby[151]=2
 bby[152]=3
 bby[154]=-2
 bby[155]=-5
 bby[156]=-5
 bby[157]=-2
 bby[158]=0
 bby[159]=2
 bby[160]=3
 bby[162]=-3
 bby[163]=-5
 bby[164]=-5
 bby[165]=-2
 bby[166]=0
 bby[167]=4
 bby[168]=3
 bby[170]=-4
 bby[171]=-6
 bby[172]=-4
 bby[173]=-2
 bby[174]=1
 bby[175]=3
 bby[176]=3
 bby[178]=-4
 bby[179]=-6
 bby[180]=-5
 bby[181]=-2
 bby[182]=1
 bby[183]=4
 bby[184]=3
 bby[186]=-4
 bby[187]=-6
 bby[188]=-6
 bby[189]=-3
 bby[190]=1
 bby[191]=4
 bby[192]=4
 bby[194]=-4
 bby[195]=-6
 bby[196]=-6
 bby[197]=-2
 bby[198]=1
 bby[199]=4
 bby[200]=3
 bby[202]=-4
 bby[203]=-6
 bby[204]=-6
 bby[205]=-2
 bby[206]=1
 bby[207]=4
 bby[208]=3
 bby[210]=-4
 bby[211]=-6
 bby[212]=-6
 bby[213]=-2
 bby[214]=1
 bby[215]=4
 bby[216]=3
 bby[218]=-4
 bby[219]=-5
 bby[220]=-4
 bby[221]=-2
 bby[222]=1
 bby[223]=4
 bby[224]=3
 bby[226]=-3
 bby[227]=-5
 bby[228]=-5
 bby[229]=-2
 bby[230]=0
 bby[231]=4
 bby[232]=2
 bby[234]=-4
 bby[235]=-5
 bby[236]=-3
 bby[238]=2
 bby[239]=4
 bby[240]=1
 bby[242]=-4
 bby[243]=-4
 bby[244]=-3
 bby[245]=0
 bby[246]=3
 bby[247]=2
 bby[248]=1
 bby[250]=-4
 bby[251]=-3
 bby[252]=-3
 bby[253]=0
 bby[254]=3
 bby[255]=2
 bby[256]=1
 carfr[2]=130
 carfr[3]=132
 carfr[4]=134
 carfr[5]=136
 carfr[6]=138
 carfr[7]=140
 carfr[8]=142
 carfr[9]=160
 carfr[10]=162
 carfr[11]=164
 carfr[12]=166
 carfr[13]=168
 carfr[14]=170
 carfr[15]=172
 carfr[16]=174
 carfr[17]=192
 carfr[18]=194
 carfr[19]=196
 carfr[20]=198
 carfr[21]=200
 carfr[22]=202
 carfr[23]=204
 carfr[24]=206
 carfr[25]=224
 carfr[26]=226
 carfr[27]=228
 carfr[28]=230
 carfr[29]=232
 carfr[30]=234
 carfr[31]=236
 carfr[32]=238
 cpx[2]=486
 cpx[3]=342
 cpy[2]=294
 cpy[3]=510
 cpdx[1]=0
 cpl[1]=71
end

function gd_init()
 gd_1()
 gd_2()
 gd_3()
 gd_4()
 gd_5()
 gd_6()
 gd_7()
 for i = 0, 95 do
  div3[i + 1] = i \ 3
  mod3[i + 1] = i % 3
 end
end
-- ==== GENERATED DATA END ====

-- driftmania — gametank port (playable slice: track a1)
-- Adapted from "Driftmania" by Max Bize (maxbize)
-- https://github.com/maxbize/PICO-8 — licensed CC-BY-NC-SA 4.0.
-- This hand-port to gtlua (real physics, real track data, real car art)
-- is released under the same license: CC-BY-NC-SA 4.0.
-- See PORT_NOTES.md for every divergence from the original cart.
--
-- controls: ⬆️/🅾️ (GT A) accelerate, ⬇️ brake/reverse, ⬅️➡️ steer,
--           ❎ (GT B) drift handbrake, START restart race
--
-- build: node bin/gtlua.js build ports/driftmania/main.lua \
--          --sheet ports/driftmania/gfx.bin
--
-- The original runs its physics in _update60; this port runs _update()
-- (30 fps) with the cart's constants rescaled: per-frame velocity deltas
-- x4 (two 60fps steps at doubled px/frame units), velocities x2, turn
-- rates x2, the 0.94 over-limit decay becomes 0.94^2 = 0.88.

-- car state (positions are whole pixels + 16.16 remainders, like the cart)
local carx = 0
local cary = 0
local vx = 0.0
local vy = 0.0
local xrem = 0.0
local yrem = 0.0
local angf = 0.0          -- facing angle in turns
local ai = 0              -- facing snapped to 1/32s: frame + table index
local spd = 0.0
local drift = 0            -- 0/1 (gtlua stores no booleans)
local wallpen = 0         -- wall-hit penalty frames
local wallnear = 0        -- prop chunks near car this frame (cheap gate)
local gwheels = 0         -- wheels on grass this frame
local kph = 0

-- race state
local state = 0           -- 0 countdown, 1 racing, 2 finished
local anim = 0
local lap = 1
local frame = 0
local lapstart = 0
local lastlap = 0
local finfr = 0
local lappop = 0
local nextcp = 2
local cpc = array(8)      -- checkpoint-crossed flags

-- lap time store
local laptf = array(8)

-- hud timer (incremental: avoids divides every frame)
local tmm = 0
local tms = 0
local tcs = 0.0

-- camera (fixed-point target, int applied)
local camx = 0.0
local camy = 0.0
local camxi = 0
local camyi = 0

-- drift/dirt trail ring buffer (world-space pset marks)
local tlx = array(64)
local tly = array(64)
local tlc = array(64)
local tri = 1
local tstep = 0

-- props collected during the map pass, drawn above the car
local plx = array(49)
local ply = array(49)
local plk = array(49)
local pcount = 0

-- audio latches
local engp = 0.0
local englast = -1
local sklast = 0
local grlast = 0
local beept = 0

function sgn0(v)
  if (v > 0) return 1
  if (v < 0) return -1
  return 0
end

-- ---- map lookups ----------------------------------------------------------

function road_tile(tx, ty)
  local cg = cgrid[div3[ty + 1] * 30 + div3[tx + 1] + 1]
  local r = cg & 31
  if (r == 0) return 0
  local k = ckd[r]
  if (k < 16) return ckt[r]
  return ctiles[(k - 16) * 9 + mod3[ty + 1] * 3 + mod3[tx + 1] + 1]
end

function prop_tile(tx, ty)
  local cg = cgrid[div3[ty + 1] * 30 + div3[tx + 1] + 1]
  local p = cg >> 10
  if (p == 0) return 0
  local k = ckd[p + propb]
  if (k < 16) return ckt[p + propb]
  return ctiles[(k - 16) * 9 + mod3[ty + 1] * 3 + mod3[tx + 1] + 1]
end

function grass_at(px, py)
  if (px < 0 or px > 719 or py < 0 or py > 719) return 0
  local t = road_tile(px >> 3, py >> 3)
  local mi = tmi[t + 1]
  if (mi == 0) return 0
  if (tcls[mi] != 1) return 0
  return (tmask[(mi - 1) * 8 + (py & 7) + 1] >> (px & 7)) & 1
end

function wallmask(px, py, tx, ty)
  local t = prop_tile(tx, ty)
  local mi = tmi[t + 1]
  if (mi == 0) return 0
  if (tcls[mi] != 2) return 0
  return (tmask[(mi - 1) * 8 + (py & 7) + 1] >> (px & 7)) & 1
end

-- car-vs-wall: 8 outline points for the current facing (bbx/bby), a
-- bit-grid pretest per tile, pixel mask only when the tile has wall ink
function collides_at(x, y)
  local b = ai * 8
  for j = 1, 8 do
    local px = x + bbx[b + j]
    local py = y + bby[b + j]
    if (px < 2 or px > 717 or py < 2 or py > 717) return 1
    local tx = px >> 3
    local ty = py >> 3
    if ((wallbit[ty * 6 + (tx >> 4) + 1] >> (tx & 15)) & 1) != 0 then
      if (wallmask(px, py, tx, ty) != 0) return 1
    end
  end
  return 0
end

-- ---- checkpoints / laps -----------------------------------------------------

function on_cp(c)
  if c == 1 then
    if (nextcp != 1) return
    lastlap = frame - lapstart
    lapstart = frame
    laptf[lap] = lastlap
    lappop = 45
    for i = 1, ncp do cpc[i] = 0 end
    nextcp = 2
    if lap == nlaps then
      state = 2
      finfr = frame
      gt.note(3, 88, 70)
      beept = 12
    else
      lap += 1
      gt.note(3, 83, 60)
      beept = 6
    end
    return
  end
  if (cpc[c] != 0) return
  cpc[c] = 1
  nextcp = (nextcp % ncp) + 1
  gt.note(3, 76, 50)
  beept = 4
end

-- ---- movement ---------------------------------------------------------------

function add_trail(x, y, c)
  tlx[tri] = x
  tly[tri] = y
  tlc[tri] = c
  tri += 1
  if (tri > 64) tri = 1
end

-- per-pixel-step events: checkpoint lines (all 4 wheels, exact-pixel
-- crossings like the cart) + drift trail from alternating rear wheels
function step_events()
  local b = ai * 8
  for j = 0, 3 do
    local wx = carx + woff[b + j * 2 + 1]
    local wy = cary + woff[b + j * 2 + 2]
    for c = 1, ncp do
      local d1 = wx - cpx[c]
      local d2 = wy - cpy[c]
      if cpdx[c] == 0 then
        if (d1 == 0 and d2 >= 0 and d2 < cpl[c]) on_cp(c)
      elseif cpdy[c] == 0 then
        if (d2 == 0 and d1 >= 0 and d1 < cpl[c]) on_cp(c)
      else
        if (d1 == d2 and d1 >= 0 and d1 < cpl[c]) on_cp(c)
      end
    end
  end
  if drift != 0 then
    tstep = 1 - tstep
    local wj = tstep * 4
    add_trail(carx + woff[b + wj + 1], cary + woff[b + wj + 2], 0)
  end
end

function move_x()
  xrem += vx
  local mv = flr(xrem + 0.5)
  xrem -= mv
  if (mv == 0) return 0
  local sg = 1
  if (mv < 0) sg = -1
  while mv != 0 do
    if wallnear != 0 and collides_at(carx + sg, cary) != 0 then
      return 1
    end
    carx += sg
    mv -= sg
    step_events()
  end
  return 0
end

function move_y()
  yrem += vy
  local mv = flr(yrem + 0.5)
  yrem -= mv
  if (mv == 0) return 0
  local sg = 1
  if (mv < 0) sg = -1
  while mv != 0 do
    if wallnear != 0 and collides_at(carx, cary + sg) != 0 then
      return 1
    end
    cary += sg
    mv -= sg
    step_events()
  end
  return 0
end

-- ---- race lifecycle ---------------------------------------------------------

function reset()
  carx = spawnx
  cary = spawny
  angf = spawndir
  ai = flr(angf * 32 + 0.5) % 32
  vx = 0
  vy = 0
  xrem = 0
  yrem = 0
  spd = 0
  drift = 0
  wallpen = 0
  state = 0
  anim = 0
  lap = 1
  frame = 0
  lapstart = 0
  lastlap = 0
  finfr = 0
  lappop = 0
  nextcp = 2
  for i = 1, 8 do cpc[i] = 0 end
  for i = 1, 8 do laptf[i] = 0 end
  tmm = 0
  tms = 0
  tcs = 0
  camx = spawnx - 64
  camy = spawny - 64
  camxi = mid(0, spawnx - 64, 592)
  camyi = mid(0, spawny - 64, 592)
  for i = 1, 64 do tlc[i] = -1 end
  tri = 1
  tstep = 0
  engp = 0
  englast = -1
  sklast = 0
  grlast = 0
  beept = 0
  gt.noteoff(0)
  gt.noteoff(1)
  gt.noteoff(2)
  gt.noteoff(3)
end

function _init()
  gd_init()
  reset()
end

-- ---- update -----------------------------------------------------------------

function _update()
  if (btnp(7)) reset()

  if state == 0 then
    anim += 1
    if anim == 1 or anim == 23 or anim == 45 then
      gt.note(3, 64, 60)
      beept = 5
    end
    if anim == 67 then
      gt.note(3, 88, 70)
      beept = 10
      state = 1
    end
  elseif state == 1 then
    if (anim < 120) anim += 1
    frame += 1
    tcs += 3.3333
    if tcs >= 100 then
      tcs -= 100
      tms += 1
      if tms == 60 then
        tms = 0
        tmm += 1
      end
    end
  end
  if (lappop > 0) lappop -= 1
  if beept > 0 then
    beept -= 1
    if (beept == 0) gt.noteoff(3)
  end

  -- input (live only while racing; the cart also runs the car with no
  -- input during the countdown and the results screen)
  local mside = 0
  local mfwd = 0
  local dbrake = 0
  if state == 1 then
    if (btn(0)) mside += 1
    if (btn(1)) mside -= 1
    if (btn(4) or btn(2)) mfwd += 1
    if (btn(3)) mfwd -= 1
    if (btn(5)) dbrake = 1
  elseif state == 2 then
    if (btnp(4)) reset()
  end

  -- ---- _car_move (cart physics, 30fps-rescaled constants) ----
  local fwdx = cos(angf)
  local fwdy = sin(angf)
  spd = sqrt(vx * vx + vy * vy)
  local nx = 0
  local ny = 0
  if spd > 0 then
    nx = vx / spd
    ny = vy / spd
  end
  local vdotf = fwdx * nx + fwdy * ny

  -- wheel surface modifiers
  gwheels = 0
  local wb = ai * 8
  for j = 0, 3 do
    if (grass_at(carx + woff[wb + j * 2 + 1], cary + woff[wb + j * 2 + 2]) != 0) gwheels += 1
  end
  local modturn = 1
  local modcorr = 1
  local modaccel = 1
  local modbrake = 1
  local modmax = 1
  if gwheels >= 2 then
    modturn = 0.25
    modcorr = 0.25
    modaccel = 0.5
    modbrake = 0.25
  end
  if wallpen > 0 then
    wallpen -= 1
    modmax = 0.8
    modaccel = 0.2
  end

  -- reduced steering when slow (and no handbrake)
  if spd < 1 then
    mside *= spd
    dbrake = 0
  end

  -- facing rotation; snap to 1/32s when no steer input
  local tmul = 1
  if (dbrake != 0) tmul = 1.35
  angf = (angf + mside * 0.012 * tmul) % 1
  if mside == 0 then
    angf = (flr(angf * 32 + 0.5) / 32) % 1
  end
  ai = flr(angf * 32 + 0.5) % 32

  -- wall proximity gate: prop chunks within reach this frame?
  wallnear = 0
  local txa = (carx - 14) >> 3
  local txb = (carx + 14) >> 3
  local tya = (cary - 14) >> 3
  local tyb = (cary + 14) >> 3
  if ((cgrid[div3[tya + 1] * 30 + div3[txa + 1] + 1] >> 10) != 0) wallnear = 1
  if ((cgrid[div3[tya + 1] * 30 + div3[txb + 1] + 1] >> 10) != 0) wallnear = 1
  if ((cgrid[div3[tyb + 1] * 30 + div3[txa + 1] + 1] >> 10) != 0) wallnear = 1
  if ((cgrid[div3[tyb + 1] * 30 + div3[txb + 1] + 1] >> 10) != 0) wallnear = 1

  -- unstick nudge (the cart pushes away from the colliding point)
  if wallnear != 0 then
    local tries = 0
    while tries < 3 and collides_at(carx, cary) != 0 do
      local dxp = sgn0(-vx)
      local dyp = sgn0(-vy)
      if dxp == 0 and dyp == 0 then
        dxp = sgn0(-fwdx)
        dyp = sgn0(-fwdy)
      end
      carx += dxp
      cary += dyp
      tries += 1
    end
  end

  -- acceleration / friction / braking
  if dbrake != 0 then
    local fstop = 0.2 * modbrake
    if mfwd > 0 then
      fstop = 0.02
    elseif mfwd == 0 then
      fstop = 0.12
    end
    vx -= mid(nx * fstop, vx, -vx)
    vy -= mid(ny * fstop, vy, -vy)
  else
    if mfwd > 0 then
      vx += fwdx * 0.3 * modaccel
      vy += fwdy * 0.3 * modaccel
    elseif mfwd < 0 then
      vx -= fwdx * 0.2 * modbrake
      vy -= fwdy * 0.2 * modbrake
    else
      vx -= mid(nx * 0.08, vx, -vx)
      vy -= mid(ny * 0.08, vy, -vy)
    end
  end

  -- corrective side force (kills lateral slide unless drifting)
  local rxx = fwdy
  local ryy = -fwdx
  local vdotr = rxx * nx + ryy * ny
  drift = dbrake
  if dbrake == 0 then
    local cf = (1 - abs(vdotf)) * 0.4 * modcorr * sgn(vdotr)
    vx -= mid(cf * rxx, vx, -vx)
    vy -= mid(cf * ryy, vy, -vy)
  end

  -- speed limit
  local angv = atan2(vx, vy)
  spd = sqrt(vx * vx + vy * vy)
  local lim = 4.4 * modmax
  if (vdotf < -0.8) lim = 1.0 * modmax
  if spd > lim then
    spd = max(spd * 0.88, lim)
    vx = cos(angv) * spd
    vy = sin(angv) * spd
  end

  -- velocity vector rotates toward the facing (the drift feel)
  local vrot = 0.010 * abs(vdotr) * modturn
  if ((angf - angv) % 1 >= 0.5) vrot = -vrot
  angv += vrot
  vx = cos(angv) * spd
  vy = sin(angv) * spd

  -- pixel-stepped movement with wall blocking
  local xb = move_x()
  local yb = move_y()
  if xb != 0 then
    vx *= 0.25
    vy *= 0.90
  end
  if yb != 0 then
    vx *= 0.90
    vy *= 0.25
  end
  if xb != 0 or yb != 0 then
    wallpen = 10
    gt.note(3, 32, 70)
    beept = 3
  end

  spd = sqrt(vx * vx + vy * vy)
  kph = flr(spd * 32.28)

  -- dirt kicked up by a front wheel on grass (once per frame)
  if gwheels > 0 and spd > 1 then
    add_trail(carx + woff[wb + 3], cary + woff[wb + 4], 4)
  end

  -- camera: lead toward travel direction, hard-clamped to the world
  local lead = min(spd * 4.95, 30)
  local ctx = carx - 64 + flr(fwdx * lead)
  local cty = cary - 64 + flr(fwdy * lead)
  camx += (ctx - camx) * 0.75
  camy += (cty - camy) * 0.75
  camxi = mid(0, flr(camx), 592)
  camyi = mid(0, flr(camy), 592)

  -- ---- audio (gt.note approximations of the cart's sfx) ----
  local tp = spd * 4
  if mfwd < 0 then
    tp = spd * 2
  elseif dbrake != 0 or mfwd == 0 then
    tp = spd * 3
  end
  if (state == 2) tp = 0
  if engp != tp then
    engp += sgn(tp - engp) * 0.5
    if (engp < 0) engp = 0
  end
  local en = 24 + flr(engp)
  if en != englast then
    englast = en
    gt.note(0, en, 30)
  end

  if drift != 0 and spd > 1.6 then
    local sk = 52
    if ((frame & 4) != 0) sk = 49
    if sk != sklast then
      sklast = sk
      gt.note(1, sk, 22)
    end
  else
    if (sklast != 0) gt.noteoff(1)
    sklast = 0
  end

  if gwheels >= 2 and spd > 1 then
    if (grlast == 0) gt.note(2, 14, 30)
    grlast = 1
  else
    if (grlast != 0) gt.noteoff(2)
    grlast = 0
  end
end

-- ---- draw -------------------------------------------------------------------

function draw_tiles(k, wx, wy)
  local bidx = (k - 16) * 9
  for ty2 = 0, 2 do
    local wyy = wy + ty2 * 8
    for tx2 = 0, 2 do
      bidx += 1
      local t = ctiles[bidx]
      if (t != 0) spr(t, wx + tx2 * 8, wyy)
    end
  end
end

function pad2(v, x, y, c)
  if (v < 10) x = print(0, x, y, c)
  return print(v, x, y, c)
end

function fmt_time(fr, x, y, c)
  local s = fr \ 30
  local cs2 = (fr % 30) * 10 \ 3
  local m = s \ 60
  s = s % 60
  x = print(m, x, y, c)
  x = print(":", x, y, c)
  x = pad2(s, x, y, c)
  x = print(".", x, y, c)
  x = pad2(cs2, x, y, c)
  return x
end

function lights(x, y)
  local c = 1
  if anim > 67 then
    c = 11
  elseif anim > 45 then
    c = 9
  elseif anim > 22 then
    c = 8
  end
  rectfill(x - 1, y - 1, x + 47, y + 19, c)
  rectfill(x, y, x + 46, y + 18, 0)
  for i = 0, 2 do
    local col = 1
    if (anim > 22 * (i + 1)) col = c
    circfill(x + 9 + 14 * i, y + 9, 5, col)
    circ(x + 9 + 14 * i, y + 9, 5, 6)
  end
end

function hud()
  local hx = camxi
  local hy = camyi
  fmt_time(frame, hx + 2, hy + 2, 7)
  local rx = print("lap ", hx + 96, hy + 2, 7)
  rx = print(lap, rx, hy + 2, 7)
  rx = print("/", rx, hy + 2, 7)
  print(nlaps, rx, hy + 2, 7)
  rx = print(kph, hx + 100, hy + 121, 7)
  print(" kph", rx, hy + 121, 7)

  if (anim <= 90 and state != 2) lights(hx + 40, hy + 24)

  if (lappop > 0 and state == 1) fmt_time(lastlap, hx + 46, hy + 34, 7)

  if state == 2 then
    rectfill(hx + 10, hy + 28, hx + 117, hy + 88, 1)
    rect(hx + 9, hy + 27, hx + 118, hy + 89, 12)
    print("race complete", hx + 38, hy + 32, 7)
    local rx2 = print("time ", hx + 24, hy + 44, 7)
    fmt_time(finfr, rx2, hy + 44, 7)
    local bl = laptf[1]
    for i = 2, nlaps do
      if (laptf[i] < bl) bl = laptf[i]
    end
    rx2 = print("best lap ", hx + 24, hy + 52, 6)
    fmt_time(bl, rx2, hy + 52, 6)
    if finfr <= mplat then
      print("platinum medal", hx + 36, hy + 64, 7)
    elseif finfr <= mgold then
      print("gold medal", hx + 44, hy + 64, 10)
    elseif finfr <= msilver then
      print("silver medal", hx + 40, hy + 64, 6)
    elseif finfr <= mbronze then
      print("bronze medal", hx + 40, hy + 64, 9)
    else
      print("no medal", hx + 48, hy + 64, 5)
    end
    print("press a to retry", hx + 32, hy + 78, 7)
  end
end

function _draw()
  cls(3)
  camera(camxi, camyi)

  -- visible chunk window (24px chunks; div3 tables avoid runtime divides)
  local cx0 = div3[(camxi >> 3) + 1]
  local cx1 = div3[((camxi + 127) >> 3) + 1]
  local cy0 = div3[(camyi >> 3) + 1]
  local cy1 = div3[((camyi + 127) >> 3) + 1]
  pcount = 0
  for cy = cy0, cy1 do
    local rb = cy * 30
    local wy = cy * 24
    for cx = cx0, cx1 do
      local cg = cgrid[rb + cx + 1]
      if cg != 0 then
        local wx = cx * 24
        local r = cg & 31
        if r != 0 then
          local k = ckd[r]
          if k >= 16 then
            draw_tiles(k, wx, wy)
          else
            rectfill(wx, wy, wx + 23, wy + 23, k)
          end
        end
        local d = (cg >> 5) & 31
        if d != 0 then
          local k2 = ckd[d + decb]
          if k2 >= 16 then
            draw_tiles(k2, wx, wy)
          else
            rectfill(wx, wy, wx + 23, wy + 23, k2)
          end
        end
        local p = cg >> 10
        if p != 0 then
          pcount += 1
          plx[pcount] = wx
          ply[pcount] = wy
          plk[pcount] = ckd[p + propb]
        end
      end
    end
  end

  -- tire trails
  for i = 1, 64 do
    if (tlc[i] >= 0) pset(tlx[i], tly[i], tlc[i])
  end

  -- next-checkpoint hint (blinking line; the cart pal-flashes the decal)
  if state == 1 and (frame & 8) == 0 then
    local c = nextcp
    line(cpx[c], cpy[c], cpx[c] + cpdx[c] * (cpl[c] - 1),
         cpy[c] + cpdy[c] * (cpl[c] - 1), 7)
  end

  -- the car (pre-rotated 16x16 frames baked into sheet cells 128-255)
  spr(carfr[ai + 1], carx - 8, cary - 10, 2, 2)

  -- props above the car (trees, fences)
  for i = 1, pcount do
    local k = plk[i]
    if k >= 16 then
      draw_tiles(k, plx[i], ply[i])
    else
      rectfill(plx[i], ply[i], plx[i] + 23, ply[i] + 23, k)
    end
  end

  hud()
end
