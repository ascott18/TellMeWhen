local Cache = {
	[1] = {71,100,355,772,845,871,1160,1464,1680,1715,1719,2565,3127,5246,5308,6343,6544,6552,6572,7384,12294,12323,12712,12950,12975,18499,20243,23881,23920,23922,29144,29838,34428,46917,46924,46953,46968,57755,76838,76856,76857,81099,84608,85288,86101,86110,86535,88163,97462,100130,103827,103828,107570,107574,115767,118000,118038,122509,123829,152277,152278,161608,161798,163201,167105,184361,184364,184367,184783,190411,190456,197690,198304,202095,202161,202163,202168,202224,202288,202296,202297,202316,202560,202561,202572,202593,202603,202612,202743,202751,202922,203177,203179,203201,203526,204488,205484,205546,205547,206312,206313,206315,206320,207982,208154,209694,215538,215550,215556,215568,215569,215571,215573,223657,223662},
	[2] = {498,633,642,853,1022,1044,4987,6940,7328,13819,19750,20066,20271,20473,23214,25780,26573,31821,31842,31850,31884,31935,32223,34767,34769,35395,53376,53385,53503,53563,53576,53592,53595,53600,62124,69820,69826,73629,73630,76671,76672,82242,82326,85043,85222,85256,86102,86103,86539,86659,96231,105424,105805,105809,114154,114158,114165,115675,115750,121183,123830,152261,152262,156910,161608,161800,183218,183415,183416,183425,183435,183778,183997,183998,184092,184132,184575,184662,190784,196923,196926,197446,197646,198034,198038,198054,200025,200654,202270,202271,202273,203316,203528,203538,203539,203776,203785,203791,203797,204013,204018,204019,204023,204035,204054,204074,204077,204139,204150,205191,205228,205656,210191,210220,212056,213313,213644,213652,213757,214202,215661,217020,218178,219562,223306,223817,224668},
	[3] = {136,781,883,982,1462,1494,1515,1543,2641,2643,5116,5384,6197,6991,19386,19434,19574,19577,19878,19879,19880,19882,19883,19884,19885,34026,34477,35110,53209,53238,53270,56315,61648,76657,83242,83243,83244,83245,87935,93321,93322,109215,109248,109304,115939,120360,120679,125050,127933,130392,131894,138430,147362,155228,157443,162488,164856,185358,185789,185855,185901,185987,186257,186265,186270,186289,186387,187650,187698,187707,187708,190925,190928,191241,191334,191384,191433,193265,193455,193468,193526,193530,193532,193533,194277,194291,194306,194386,194397,194407,194595,194599,194855,195645,198670,198783,199483,199518,199522,199523,199527,199528,199530,199532,199543,199921,200108,200163,201075,201078,201082,201430,202800,203413,204308,204315,205154,206505,206817,207097,209997,210000,212431,212436,212621,212658,213423,214579,217200},
	[4] = {53,408,703,921,1329,1725,1766,1776,1784,1804,1833,1856,1860,1943,1966,2094,2098,2823,2836,2983,3408,5171,5277,6770,8676,8679,13750,13877,14062,14117,14161,14190,14983,16511,31209,31223,31224,31230,32645,35551,36554,51667,51690,51723,56814,57934,58423,61329,76803,76806,76808,79008,79134,79140,79152,82245,84601,108208,108209,108211,108216,114014,114015,121471,131511,137619,152150,152152,154904,157442,185311,185313,185314,185438,185565,185763,185767,192760,193315,193316,193531,193537,193539,193546,193640,195452,195457,196819,196861,196864,196912,196922,196924,196937,196938,196951,196976,196979,197835,199736,199740,199743,199754,199804,200733,200758,200759,200778,200802,200806,206237,209783,209784,210108,212283,222062},
	[5] = {17,139,527,528,585,586,589,596,605,1706,2006,2050,2060,2061,2096,8092,8122,9484,10060,14914,15286,15407,15487,19236,20711,32375,32379,32546,33076,33206,34433,34861,34914,45243,47536,47540,47585,47788,48045,62618,63733,64129,64843,64901,73325,73510,77484,77485,77486,78203,81749,81782,88625,109142,109186,110744,120517,121536,123040,129250,132157,152118,155271,162452,185916,186263,186440,190719,193063,193134,193155,193157,193173,193195,193223,193225,194249,194509,196704,196707,196985,197031,197034,197045,197419,199849,199853,199855,200128,200153,200174,200183,200199,200209,200309,200347,200829,204065,204197,204263,204883,205351,205367,205369,205371,205385,205448,207948,212036,213634,214121,214621},
	[6] = {674,3714,42650,43265,45524,46584,47528,47541,47568,48263,48265,48707,48792,49020,49028,49143,49184,49206,49530,49576,49998,50842,50977,51128,51271,51462,51986,53343,53344,53428,55078,55090,55095,55233,56222,57330,59057,61999,62158,63560,77513,77514,77515,77575,81136,81229,82246,85948,86113,86524,86536,86537,108194,108199,111673,114556,127344,130736,152279,152280,161797,178819,190780,194662,194679,194844,194878,194909,194912,194913,194916,194917,194918,195182,195292,195621,195679,196770,197147,198943,205224,205723,205727,206930,206931,206940,206960,206967,206970,206974,206977,207057,207060,207061,207104,207126,207127,207142,207161,207167,207170,207188,207200,207230,207256,207264,207269,207272,207289,207305,207311,207313,207316,207317,207319,207321,207346,207349,211078,212552,212744,212763,212765,219779,219786,219809,221536,221562,221699},
	[7] = {370,403,421,546,556,1064,2008,2645,2825,5394,6196,8004,8042,16164,16196,17364,20608,32182,33757,51485,51490,51505,51514,51533,51564,51886,57994,58875,60103,60188,61295,61882,73920,77130,77223,77226,77472,77756,79206,86099,86100,86108,86529,86629,98008,108271,108280,108281,108283,114050,114051,114052,117013,117014,123099,157153,157154,157444,168534,170374,187837,187874,187880,188070,188089,188196,188389,188443,188838,190488,190493,190899,192058,192063,192077,192087,192088,192106,192222,192234,192235,192246,192249,193786,193796,195255,196834,196840,196884,196932,197210,197211,197214,197464,197467,197992,197995,198067,198103,198838,200071,200072,200076,201845,201897,201898,201900,201909,207399,207401,210643,210689,210707,210714,210727,210731,210853,210873,212048,215864,216965},
	[8] = {66,116,118,120,122,130,133,1449,1463,1953,2120,2139,2948,3561,3562,3563,3565,3566,3567,5143,6117,7302,10059,11366,11416,11417,11418,11419,11420,11426,11958,12042,12051,12472,12846,12982,28271,28272,30449,30451,30455,30482,31589,31661,31687,32266,32267,32271,32272,33690,33691,35715,35717,44425,44457,45438,49358,49359,49360,49361,53140,53142,55342,61305,61721,61780,76613,80353,84714,86949,88342,88344,88345,88346,108839,108853,110959,112948,112965,113724,114923,116011,117216,120145,120146,126819,131784,132620,132621,132626,132627,153561,153595,153626,155147,155148,155149,157642,157976,157980,157981,157997,161353,161354,161355,161372,176242,176244,176246,176248,190319,190336,190356,190427,190447,190740,193759,195283,195676,198923,198929,199786,205020,205021,205022,205023,205024,205025,205026,205027,205028,205029,205030,205032,205033,205035,205036,205037,205038,205039,210086,210726,211076,211088,212653,224869,224871},
	[9] = {126,172,348,603,686,688,689,691,697,698,710,712,755,980,1098,1122,1454,5484,5697,5740,5782,5784,6201,6789,17877,17962,18540,20707,23161,27243,29722,29893,30108,30146,30283,48018,48181,77215,77219,77220,80240,93375,104316,104773,105174,108370,108415,108416,108501,108503,111400,111771,116858,119898,152107,152108,157695,171975,187394,193396,193440,193541,196098,196102,196103,196104,196105,196226,196269,196270,196272,196277,196283,196406,196408,196410,196412,196447,196605,196657,198590,205145,205148,205178,205179,205180,205181,205183,205184,211715,215279,215941,219272},
	[10] = {100780,100784,101545,101546,101643,103985,107428,109132,113656,115008,115069,115072,115078,115080,115098,115151,115173,115176,115178,115181,115203,115288,115308,115310,115313,115315,115396,115399,115450,115546,115636,116092,116095,116645,116670,116680,116694,116705,116812,116841,116844,116847,116849,117906,117907,117952,119381,119582,119996,120224,120225,120227,121253,121817,122278,122470,122783,123904,123986,124081,124146,124502,124682,125883,126892,126895,128595,132578,137025,137384,137639,152173,152175,157361,157411,157445,161608,191837,193884,196607,196719,196721,196722,196725,196730,196736,196737,196738,196740,196743,197895,197900,197908,197915,197945,198664,198898,205414,205523,210802,210804,212051,216519,218164,220357,222029},
	[11] = {99,339,740,768,774,783,1079,1822,1850,2782,5176,5185,5211,5215,5217,5221,5225,5487,6795,6807,8921,8936,16864,16870,16931,16974,18562,18960,20484,22568,22570,22812,22842,24858,29166,33763,33873,33891,33917,48438,48484,48500,50769,52610,61336,77492,77493,77495,77758,78674,78675,80313,86093,86096,86097,86104,88423,93402,102280,102342,102351,102359,102401,102543,102558,102560,102793,106830,106832,106839,106898,106951,108238,108299,113043,114107,125972,127757,131768,132469,137010,137011,137012,137013,145108,145205,155577,155578,155580,155672,155675,155783,155835,157447,158476,158477,158478,161608,164815,164862,165962,190984,191034,192081,192083,193753,194153,194223,197061,197073,197488,197490,197491,197492,197524,197632,197692,197721,200383,200390,202021,202022,202028,202031,202032,202060,202155,202157,202342,202345,202347,202354,202359,202360,202425,202430,202768,202770,202771,203953,203962,203964,203965,203974,204012,204053,204066,205636,207383,207385,210053,210065,210706,210723,212040,213764,217615,219432},
	[12] = {131347,162243,162794,178740,178940,179057,183752,183782,185123,185164,185244,185245,186452,187827,188499,188501,189110,189926,191427,192939,193897,195072,196055,196555,196718,197125,197130,198013,198589,198793,201628,201789,202137,202138,203513,203550,203551,203555,203556,203720,203724,203747,203753,203782,203783,203798,204021,204157,204254,204596,204909,205411,206416,206473,206475,206476,206477,206478,206491,207197,207548,207550,207666,207684,207697,207739,207810,209258,209281,209400,209795,211048,211053,211511,211662,211881,212084,212611,212612,212613,213241,213410,214743,217832,217996,218256,218612,218640,218679,221351},
	["RACIAL"] = {[68992]=22,[7744]=5,[68996]=22,[121093]={11,512},[92680]=7,[143369]=26,[92682]=3,[59542]={11,2},[59543]={11,4},[59544]={11,16},[59545]={11,32},[59547]={11,64},[59548]={11,128},[87840]=22,[33697]={2,576},[6562]=11,[33702]={2,384},[69046]={9,2047},[20592]=7,[20551]=6,[20594]=3,[69041]=9,[69042]=9,[69044]=9,[69045]=9,[822]=10,[155145]={10,2},[26297]=8,[28730]={10,400},[69179]={10,1},[129597]={10,512},[58943]=8,[107072]=24,[107073]=24,[107074]=24,[28875]=11,[107076]=24,[20549]=6,[20550]=6,[107079]={24,8},[20552]=6,[20555]=8,[20557]=8,[69070]=9,[28877]=10,[28880]={11,1},[154744]={7,520},[20579]=5,[59221]=11,[25046]={10,8},[20585]=4,[59224]=3,[143368]=25,[20572]={2,45},[20573]=2,[202719]={10,2048},[20577]=5,[80483]={10,4},[20582]=4,[20583]=4,[59752]=1,[50613]={10,32},[5227]=5,[20589]=7,[20591]={7,978},[68976]=22,[58984]=4,[68978]=22,[68975]=22,[20596]=3,[131701]=24,[154742]=10,[154743]=6,[20593]=7,[154747]={7,32},[154746]={7,1},[20599]=1,[154748]=4,[94293]=22,[20598]=1
	},
	["PET"] = {[50433]=3,[30213]=9,[160007]=3,[160044]=3,[160011]=3,[91778]=6,[6360]=9,[35346]=3,[118297]=7,[57984]=7,[115232]=9,[54049]=9,[115746]=9,[3110]=9,[159788]=3,[49966]=3,[160049]=3,[126259]=3,[160057]=3,[160060]=3,[160063]=3,[118337]=7,[160067]=3,[137798]=3,[17735]=9,[118345]=7,[118347]=7,[134477]=9,[118350]=7,[7870]=9,[117588]=7,[62137]=6,[2649]=3,[119899]=9,[17767]=9,[16827]=3,[17253]=3,[126311]=3,[191336]=3,[24423]=3,[47468]=6,[160018]=3,[88680]=3,[157331]=7,[54644]=3,[36213]=7,[117225]=9,[47481]=6,[47482]=6,[19647]=9,[47484]=6,[91776]=6,[24450]=3,[3716]=9,[7814]=9,[160065]=3,[54680]=3,[94019]=3,[91797]=6,[89751]=9,[91800]=6,[65220]=3,[91802]=6,[126364]=3,[91809]=6,[157348]=7,[94022]=3,[89766]=9,[112042]=9,[159926]=3,[126393]=3,[159931]=3,[91837]=6,[91838]=6,[157375]=7,[89792]=9,[160452]=3,[157382]=7,[30151]=9,[30153]=9,[26064]=3,[159953]=3,[159956]=3,[6358]=9,[90361]=3,[90328]=3,[92380]=3,[115408]=9,[89808]=9,[90339]=3,[32233]=9,[90347]=3,[90355]=3,[159733]=3,[93433]=3
	}
}