--ufo swamp odyssey
--by paranoid cactus

palette={
-- screen pal
0,128,2,3,4,133,134,15,8,137,9,139,12,5,131,13, -- blue palette: 0,129,2,3,4,1,134,15,8,137,9,139,12,5,131,13,
-- swamp greens
30,14,14,3,3,14,11,7,3,11,7,11,11,3,14,3,
-- gun pals
16,1,1,3,4,5,6,7,5,5,13,11,12,13,14,15,
16,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
16,1,14,3,4,5,6,7,3,11,11,11,12,13,14,15,
16,1,14,3,4,5,6,7,15,12,12,11,12,13,14,15,
16,1,2,3,4,5,6,11,8,9,10,11,3,13,14,14}

title={126,0,127,126,124,125,126,124,127,126,0,127,126,125,0,126,0,127,123,124,125,123,0,0,123,124,125}
titlesprs={{88,40,4,5},{92,40,7,7},{99,40,6,7},{105,40,7,8},{88,48,5,9},{93,48,5,6},{98,48,5,6},{103,48,5,6},{108,48,4,5},{16,16,8},{24,16,5},{29,16,5},{34,16,6},{40,16,6},{24,8,6}}
titlelo={1,2,3,4,5,6,7,8,1,1,9,8}
titlehi={10,11,12,12,0,13,14,15,11}

psprs={
-- 1 player sprites
{x=0,y=0,w=12,h=6},{x=12,y=0,w=4,h=5},{x=16,y=0,w=3,h=2},{x=19,y=0,w=3,h=2},{x=22,y=0,w=2,h=2},{x=16,y=3,w=3,h=2},{x=16,y=2,w=3,h=3},{x=16,y=4,w=3,h=1},{x=16,y=5,w=4,h=3},{x=19,y=2,w=2,h=3},{x=21,y=2,w=3,h=4},
-- 12 friend sprites
{x=45,y=0,w=7,h=5},{x=48,y=5,w=9,h=5},{x=52,y=0,w=7,h=5},{x=59,y=0,w=7,h=5},{x=57,y=5,w=7,h=5},{x=64,y=5,w=7,h=5},
-- 18 eyeball sprites
{x=32,y=0,w=8,h=8},{x=40,y=0,w=5,h=5},
-- 20 coin
{x=24,y=0,w=4,h=4},{x=28,y=0,w=4,h=4},{x=24,y=4,w=2,h=4},
-- 23 canister, 24 laser bolt, 25 goop
{x=12,y=0,w=4,h=6},{x=0,y=8,w=8,h=2},{x=26,y=4,x=4,h=4},
-- 26 floor button
{x=0,y=14,w=8,h=6},
-- 27 green ball
{x=26,y=4,w=4,h=4},
-- 28 portal stand
{x=9,y=10,w=6,h=4},
-- 29 core
{x=48,y=10,w=6,h=4},{x=54,y=10,w=6,h=4},{x=60,y=10,w=6,h=4},{x=66,y=10,w=6,h=4},{x=66,y=0,w=6,h=4},
-- 34 zapper
{x=118,y=40,w=10,h=7},{x=116,y=41,w=2,h=4},{x=116,y=48,w=12,h=8}
}
panms={{
-- 1 player idle
{{s=1,x=-7,y=-8},{s=2,x=0,y=-13,p=1},{s=6,x=-4,y=-2},{s=6,x=0,y=-2},{s=-7,x=4,y=-3}}},
-- 2 player walk
{{{s=1,x=-7,y=-8},{s=2,x=0,y=-13,p=1},{s=3,x=-5,y=-2},{s=4,x=1,y=-2},{s=-7,x=2,y=-3}},
{{s=1,x=-7,y=-8},{s=2,x=0,y=-13,p=1},{s=6,x=-5,y=-2},{s=5,x=2,y=-2},{s=-7,x=2,y=-3}},
{{s=1,x=-7,y=-9},{s=2,x=0,y=-14,p=1},{s=7,x=-4,y=-3},{s=6,x=0,y=-3},{s=-7,x=3,y=-4}},
{{s=1,x=-7,y=-9},{s=2,x=0,y=-14,p=1},{s=7,x=-3,y=-3},{s=6,x=-1,y=-3},{s=-7,x=4,y=-4}},
{{s=1,x=-7,y=-8},{s=2,x=0,y=-13,p=1},{s=6,x=-1,y=-2},{s=8,x=-2,y=-2},{s=-7,x=4,y=-4}},
{{s=1,x=-7,y=-8},{s=2,x=0,y=-13,p=1},{s=6,x=-2,y=-2},{s=-7,x=4,y=-4}},
{{s=1,x=-7,y=-9},{s=2,x=0,y=-14,p=1},{s=6,x=-3,y=-3},{s=7,x=-1,y=-3},{s=-7,x=4,y=-4}},
{{s=1,x=-7,y=-9},{s=2,x=0,y=-14,p=1},{s=6,x=-4,y=-3},{s=7,x=0,y=-3},{s=-7,x=3,y=-4}}},
-- 3 player jump
{{{s=1,x=-7,y=-8},{s=2,x=0,y=-13,p=1},{s=6,x=-3,y=-2},{s=11,x=1,y=-2},{s=-7,x=4,y=-3}},
{{s=1,x=-7,y=-8},{s=2,x=0,y=-13,p=1},{s=3,x=-4,y=-2},{s=10,x=2,y=-2},{s=-7,x=4,y=-4}},
{{s=1,x=-7,y=-8},{s=2,x=0,y=-13,p=1},{s=9,x=-5,y=-2},{s=4,x=1,y=-2},{s=-7,x=4,y=-4}}},
-- 4 eyeball
{{{s=18,x=-4,y=-8}},{{s=18,x=-4,y=-8},{s=19,x=-4,y=-6}}},
-- 5 friend expressions 
{{{s=12,x=-4,y=-11},{s=14,x=-4,y=-7},{s=6,x=-4,y=-2,p=1},{s=6,x=0,y=-2,p=1}}},
{{{s=13,x=-5,y=-12},{s=15,x=-4,y=-7},{s=6,x=-4,y=-2,p=1},{s=6,x=0,y=-2,p=1}}},
{{{s=12,x=-4,y=-11},{s=16,x=-4,y=-7},{s=6,x=-4,y=-2,p=1},{s=6,x=0,y=-2,p=1}}},
{{{s=12,x=-4,y=-12},{s=17,x=-4,y=-7},{s=6,x=-4,y=-2,p=1},{s=6,x=0,y=-2,p=1}}},
-- 9 friend walk
{{{s=12,x=-4,y=-11},{s=14,x=-4,y=-7},{s=3,x=-5,y=-2,p=1},{s=4,x=1,y=-2,p=1}},
{{s=12,x=-4,y=-11},{s=14,x=-4,y=-7},{s=6,x=-5,y=-2,p=1},{s=5,x=2,y=-2,p=1}},
{{s=12,x=-4,y=-12},{s=14,x=-4,y=-8},{s=7,x=-4,y=-3,p=1},{s=6,x=0,y=-3,p=1}},
{{s=12,x=-4,y=-12},{s=14,x=-4,y=-8},{s=7,x=-3,y=-3,p=1},{s=6,x=-1,y=-3,p=1}},
{{s=12,x=-4,y=-11},{s=14,x=-4,y=-7},{s=6,x=-1,y=-2,p=1},{s=8,x=-2,y=-2,p=1}},
{{s=12,x=-4,y=-11},{s=14,x=-4,y=-7},{s=6,x=-2,y=-2,p=1}},
{{s=12,x=-4,y=-12},{s=14,x=-4,y=-8},{s=6,x=-3,y=-3,p=1},{s=7,x=-1,y=-3,p=1}},
{{s=12,x=-4,y=-12},{s=14,x=-4,y=-8},{s=6,x=-4,y=-3,p=1},{s=7,x=0,y=-3,p=1}}},
-- 10 coin
{{{s=20,x=-2,y=-4}},{{s=21,x=-2,y=-4,f=1}},{{s=22,x=-1,y=-4}},{{s=21,x=-2,y=-4}}},
-- 11 fuel canister
{{{s=23,x=-2,y=-6,p=1}}},
-- 12 button
{{{s=26,x=0,y=-6}}},
-- 13 green ball
{{{s=27,x=-2,y=-8}}},
-- 14 portal stand
{{{s=28,x=-3,y=-3}}},
-- 15 core
{{{s=29,x=-3,y=-6}},{{s=30,x=-3,y=-6}},{{s=31,x=-3,y=-6}},{{s=32,x=-3,y=-6}},{{s=33,x=-3,y=-6}}},
-- 16 zapper
{{{s=34,x=-5,y=-6,f=1},{s=35,x=-7,y=-5,f=1}},{{s=34,x=-5,y=-6,f=1},{s=35,x=-7,y=-4,f=1}}},{{{s=36,x=-4,y=-6,f=1}}}
}

bgstr="000b1811100a0000af18111a01b50000000a111a0019800011105b19800007111fed0000000079111800000a5100d1a600010a00000b51fe000d2111a501dfe0000f211110b50a00791e1116a198000000ab1116c01de0001111113fe00a001110000000000a0d11111100b5710a01c10a019800000f13000a00fde1b1b100a00000fd11100198000e21111571ee00000b5f1118e030000a1113d0e000a6c0111a00000000aa0011111100f101b50211a6c1dea000ab1e00a6c000b1f1f1a06a000000111113fe00a00d1111130000000f79111e00000005111e00000071e0111ca0000000b50a111efd0a01c1980fe171e1006c0079100b55e0a0f211a18018000a00111df00000a0a011113e000000000d1110a0000a071110000000021111106c000000f5b511100005a113de00a10211a01ea00d1c0f71a04a00d141113e0a06a0111000000b5aa0111de000000000a011106c00b5001110a000000fdf11198e000000a1f7111000a181de00a0b1a0e16c19800a1e0a016c6c0a0171ede006c16a11100000004b501110000000000b5011113e00f6a01119800a000000111dea00000071c011100071e1a0004af16c018e1fe0b51a06013e4e05b1010000079118111000000a4f6c111000000000af6c111fe0000180111d0a06c000001110a600000002111110a00211ca0b57914e02113000f716c1a1ea40a4f101000000e2111110a000045a79111a0000000b50601110000002111110a6c10a0000111046a0000000df111b5a0fe1e6cf79118a0fd1e0000018e181056c46c1130a00000f0d111aa000b5180e1116c000000f791c111000c000d2111071e1980000111a71ca00000000111f660a0113e00de1e6c001000a002111e1918e71e13e06a0000000111b5000071e60111800a000000d21111000e0000f11111113ee000011180198000000ab11101806c1d0000001b1e0a100b50afed101fee00211e0a1800000ab111f5a00002111111e0b50a00000f2111c00000000111113de000000111113fe00000b5f11113e91e10a000002110ab1a0f7b50a011300000fe100b1e0a00079111b180000f2111110af6a6c00000f111e00000000111dfe000000001113d00000000079111d00d211b5a000afd1b5f160a0f606c1de0a0000011113004a000d11113e000000ed11106c184e00000011100a0000a011100000000000111e0a00000000021110000fd1f66c0b500198018a6c07911100b5000a01dfde00680000111d00a0000000111050198000000b1110b5000b50111000000000a01110a6ca0000000f1110000001b18eaf6c01de01e71e00ede10af10007910000001ea0001110a050a0000a1111113de00000a0111a07000f1a11100000000b5a111071e6c000000011100000a113e0791e010a0111300000a107910a00e1000000"
fgstr="000003b77b30b300bb77777b0b3bbb77e7e70bbb3bb77b77b337bb3bbbbb00003bbe7373000003bb7b70000000000000000077b3000000077777b00000377e7e730003bb77b77b30b3b3bbbbbb3b003ee737b300000be7e730000000bbb30000"

story={
{{"scavengers got you too huh?",2},{"we're TRAPPED here!",1},{"it's that damned EMP CANNON",4},{"they snare space ships",1},{"then strip them for parts",1},{"they love anything mechanical",4},{"OH NO! you're mechanical!",2},{"they'll want YOUR parts too!",4},{"you're DOOMED!",2},{"unless...",4},{"you disable their EMP CANNON",1},{"HA HA! good luck with that",3}},
{{"ahoy there little robot",3},{"whatcha up to round here?",1},{"oh, tryna ESCAPE are ya?",2},{"i might be able to help",3},{"ya know that EMP CANNON?",4},{"ya gotta take out it's core",1},{"fight fire with fire",3},{"use this EMP FUEL",4},{"it's good against eyebots too",3,2}},
{{"whoa, i'm so CONFUSED",4},{"i went through some PORTALS",1},{"now i don't know where i am!",2},{"i need to rest for a bit",1},{"if you wanna get out...",4},{"you're gonna need this",3},{"it's GRAPPLE FUEL",4},{"just look out for BLUE HOOKS",1},{"time for some HIGH FLYIN' FUN",3,4}},
{{"ooh, someone finally came!",3},{"i've been stuck down here",2},{"there's a PORTAL right there",4},{"and i've got some PORTAL FUEL",3},{"but i can't use it",2},{"you've got that handy zapper",4},{"why don't you give it a go",3,3}},
{{"you did it!",2},{"CONGRATULATIONS!",3},{"i guess you'll be leaving now",4},{"if only you had a bigger ship",1},{"but maybe we'll meet again",4},{"farewell for now little robot",3,-1}}
}

ptypes={{a=10,pn="score",pv=10,snd=32},{a=11,pn="guns",pv=1,snd=36,msg="emp zapper",pali=1},{a=11,pn="guns",pv=1,snd=36,msg="portal zapper",pali=2},{a=11,pn="guns",pv=1,snd=36,msg="grapple zapper",pali=3}}

function _init()
	for i=1,#palette do
		poke(0x42ff+i,palette[i])
	end
	poke(0x5f2e,1)
	for i=1,#bgstr do
		local v=tonum("0x"..sub(bgstr,i,i))
		poke(0x4dff+i,v==0 and 0 or v+48)
	end
	for i=1,#fgstr,2 do
		poke(0xa3a+flr((i-1)/12)*64+flr(((i-1)%12)/2),tonum("0x"..sub(fgstr,i+1,i+1)..sub(fgstr,i,i)))
	end
	memcpy(0x5600,0x1800,2048)
	
	new_game()
	if peek(0x4371)==254 then
		poke(0x4371,0)
		conditionone=true
		music(11)
	else
		music(13)
	end
end

function new_game()
	gamemode=0
	enemies,friends,pickups,particles,hooks,buttons,portals,msglog,sndcue,sndtm,jbtn,sbtn,slvls,zapt,zapdest={},{},{},{},{},{},{},{},{},0,4,5,{228.5,364.5,484.8},0,nil
	pl,camx,camy,camyo,camyd,camtime,slvlo,slvld,slvlt,stm,msgofs,gtime,popup,chat,active,canmove,drawlist,flying,camxp1,camxp2,scrollm,ufoy,ufobob,cannonzapt=new_player(532,96),469,-120,-120,24,0,108.5,108.5,1,0,0,0,nil,nil,btn,btnp,{particles,buttons,enemies,friends,pickups,portals},0,0,0,1,0,0,0
	local storyi=1
	for y=0,63 do
		for x=0,127 do
			local m=mget(x,y)
			if fget(m,0) then
				if m==3 then
					add(pickups,{x=x*8+4,y=y*8+6,ptype=ptypes[1],t=((x%8)/4+(y%32)/16)%2,f=1,
					update=function(p)
						local fc=#panms[p.ptype.a]
						p.t=(p.t+0.02)%2
						p.f=min(flr((p.t%0.5)*2*fc)+1,fc)
					end,
					draw=function(p) draw_sp(p.ptype.a,p.f,p.x,p.y+flr(sin(p.t)*1.5),4,false,p.ptype.pali) end})
				elseif m==4 then
					add(enemies,new_eyeball(x*8+3,y*8+8))
				elseif m==6 then
					if storyi<5 then
						add(friends,new_friend(x*8+3,y*8+8,storyi,5,9))
						storyi+=1
					else
						add(friends,new_friend(x*8+3,y*8+8,storyi,17,16,true))
					end
				elseif m==32 then
					add(buttons,{x=x*8,y=y*8,l=del(slvls,slvls[1]),pt=0,pf=2,
						draw=function(b)
							draw_sp(12,1,b.x,b.y+4,10)
							if b.y+13<sy and b.pf<40 then
								b.pt=(b.pt+1)%b.pf
								if b.pt<1 then
									new_particle(b.x+16,b.y+12.5,rnd()*0.4,0,rnd()<0.5 and 3 or 14,60,0.04,true)
									if b.pf>2 then
										b.pf+=b.pf*0.75
									end
								end
							end
						end})
				elseif m==33 then
					powercore={x=x*8+4,y=y*8+8,f=1,t=0}
				elseif m>=49 and m<=63 then
					local v=m-48
					local px=mget(x-1,y)==20 and x-1 or x+1
					portals[v]={x=px*8+4,y=y*8+6,d=v+(v%2)*2-1,draw=function(p) draw_sp(13,1,p.x,p.y+sin(stm),4) end}
				elseif m==75 then
					add(hooks,{x=x*8+4,y=y*8+8})
				end
			end
		end
	end
end

function _update60()
	jbtnd,sbtnd,gtime,trigger,tpressed,grapple,drain=false,false,(gtime+0.025)%1,active(1,1),active(2,1),canmove(4,1),canmove(5,1)
	if btn(jbtn) then
		if not jbtnlock then
			jbtnd=true
		end
	else
		jbtnlock=false
	end
	if btn(sbtn) then
		if not sbtnlock then
			sbtnd=true
		end
	else
		sbtnlock=false
	end
	if chat then
		local advance=chati==0
		if jbtnd and not jbtnlock then
			jbtnd,jbtnlock,advance=false,true,true
		end
		if sbtnd and not sbtnlock then
			sbtnd,sbtnlock,advance=false,true,true
		end
		
		if advance then
			if chati>0 and chat[chati][3] then
				if chat[chati][3]==-1 then
					poke(0x4371,254)
					run()
				end
				pl:give({ptype=ptypes[chat[chati][3]]})
			end
			chati+=1
			if chati>#chat then
				chat=nil
			else
				local ei=chat[chati][2]
				chatf:setanim(ei)
				sfx(38+ei,3)
				if ei==2 then
					for i=0,4 do
						local sv=sin(i/8)*-2.5
						new_particle(chatf.x-4.5+i*2,chatf.y-12-sv,(i-2)*0.075,-0.2,12,15,0,false)
					end
				end
			end
		end
	end
	
	if popup then
		popup.t-=1
		if popup.t<=0 then
			popup=nil
		end
	end
	
	slvlt=min(slvlt+0.005,1)
	slvl=smoothlerp(slvlo,slvld,slvlt)
	stm=(stm+0.0075)%2
	sy=slvl+sin(stm)*2
	
	update_table(particles)
	
	if powercore then
		powercore.t=(powercore.t+0.04)%1
		powercore.f=flr(powercore.t*5)+1
	end
	
	if gamemode==0 then
		camxp1,camxp2=(camxp1-0.33*scrollm)%176,(camxp2-0.5*scrollm)%336
		
		if transtime then
			if transtime==300 then
				cannonzapt=14
			end
			if transtime==150 then
				music(10,0,3)
			end
			transtime-=1
			if transtime>99 then
				scrollm-=0.005
				if scrollm<0.1 then
					scrollm=0
				end
				ufoy-=(transtime-300)/100
			end
			if cannonzapt>0 and cannonzapt%2==0 then
				zapoffsets={{0,0}}
				for i=1,8 do
					add(zapoffsets,{rnd(8)-4,rnd(8)-4})
				end
				zapoffsets[10]={0,0}
			end
			cannonzapt=max(cannonzapt-1,0)
			if transtime==0 then
				gamemode=1
			end
		else
			ufobob=(ufobob+0.005)%2
			if jbtnd or sbtnd then
				transtime=300
				music(17)
				sfx(30,3)
				local uy=-60+ufoy+sin(ufobob)*3.5
				for i=0,32 do
					new_particle(camx+52,uy,rnd(2)-1,rnd(2)-1,8,90+flr(rnd(60)),0.01,true)
					new_particle(camx+52,uy,rnd()-0.5,rnd()-0.75,9,120+flr(rnd(90)),0.01,true)
				end
			end
		end
	elseif gamemode==1 then
		if trigger and tpressed then
			if grapple then
				pl.guns,pl.gun=3,3
			end
			if drain then
				for i=1,#buttons do
					local b=buttons[i]
					if b.pf==2 then
						slvlo,slvld,slvlt,b.y,b.pf=slvl,b.l,0,b.y+2,3
						sfx(43)
						break
					end
				end
			end
		end
		for m in all(msglog) do
			m.y-=0.25
			m.t-=1
			if m.t==0 then
				del(msglog,m)
			end
		end
		update_table(pickups)
		update_table(enemies)
		if camtime==1 then
			update_table(friends)
			pl:update()
		end
		sndtm=max(sndtm-1,0)
		if #sndcue>0 and sndtm==0 then
			local snd=del(sndcue,sndcue[1])
			sfx(snd.snd,3)
			if snd.msg then
				snd.msg.y=flr(snd.msg.y-msgofs*7)
				msgofs=(msgofs+1)%3
				add(msglog,snd.msg)
			end
			sndtm=8
		end
		if camtime<1 then
			camtime=min(camtime+0.0075,1)
			camy=smoothlerp(camyo,camyd,camtime)
		else
			camx,camy=mid(0,896,flr(pl.x-62.5)),flr(pl.y-71.5)
		end
	end
end

function update_table(list)
	for i in all(list) do
		i:update()
	end
end

function _draw()
	cls(5)
	camera(camx,camy)
	memcpy(0x1800,0x4e00,2048)
	local layerx,layery=flr(camx*0.66+0.5)+camxp1,flr(camy*0.75+0.5)
	for x=-1,2 do
		map(106,48,layerx+x*176,layery-128,22,16)
		map(84,48,layerx+x*176,layery,22,16)
		map(106,48,layerx+x*176,layery+128,22,16)
	end
	pal(1,0)
	layerx=camx/2+camxp2
	for x=-1,1 do
		for y=0,1 do
			map(42,48,layerx+336*x,camy/2-128+y*256,42,16)
			map(0,48,layerx+336*x,camy/2+y*256,42,16)
		end
	end
	pal()
	if zapt>0 and powercore and zapdest==powercore then
		if zapt<6 then
			circfill(powercore.x-1,powercore.y-5,6*zapt,8)
			circfill(powercore.x-1,powercore.y-5,5*zapt,9)
			circfill(powercore.x-1,powercore.y-5,4*zapt,10)
		else
			if zapt==7 then
				sfx(30)
			end
			local s=sin(zapt/14)
			circfill(powercore.x-1,powercore.y-5,4+s*4,8)
			circfill(powercore.x-1,powercore.y-5,3+s*3,9)
		end
	end
	memcpy(0x1800,0x5600,2048)
	map(0,0,0,0,128,64,30)
	memcpy(0x5f00,0x4310,16)
	rectfill(0,sy,1024,576,14)
	map(0,sy/8+1,0,flr(sy/8)*8+8,128,64,30)
	clip(0,sy-camy,128,8)
	map(0,sy/8,0,flr(sy/8)*8,128,1,30)
	clip()
	pal()
	for l in all(drawlist) do
		for i in all(l) do
			i:draw()
		end
	end
	pl:draw()
	if powercore then
		draw_sp(15,powercore.f,powercore.x,powercore.y,4)
	end
	for m in all(msglog) do
		printc(m.txt,m.x,m.y,10,0)
	end
	if transtime and transtime<150 and camtime<1 then
		local x=camx+25
		for i=1,#title do
			local y=-77+flr((i-1)/9)*8
			if title[i]~=0 then
				spr(title[i],x,y)
			end
			x+=8
			if i%9==0 then
				x=camx+25
			elseif i%3==0 then
				x+=2
			end
		end
		x=camx+26
		for i=1,#titlelo do
			local sp=titlesprs[titlelo[i]]
			sspr(sp[1],sp[2],sp[3],8,x,-49)
			x+=sp[4]
		end
	end
	camera()
	if popup then
		local l=#popup.txt*2+20
		rectfill(59-l,105,69+l,117,1)
		rectfill(58-l,106,70+l,116,1)
		draw_sp(popup.anm,1,65-l,114,8,false,popup.pali,true)
		print("you got",73-l,109,6)
		print(popup.txt,105-l,109,8)
	end
	if chat and chati~=0 then
		local str=chat[chati][1]
		local l=#str*2
		rectfill(59-l,33,68+l,49,7)
		rectfill(58-l,34,69+l,48,7)
		sspr(9,6,7,4,chatf.x-camx-4,50)
		for i=1,#str do
			local c=sub(str,i,i)
			local ordc,y,col=ord(c),39,0
			if ordc>64 and ordc<91 then
				c,y,col=chr(ordc+32),39.5+sin(gtime+i*0.125)*1.5,15
			end
			print(c,60-l+i*4,y,col)
		end
		sspr(0,6,9,7,59,47)
	end
	if gamemode==0 then
		local uy=ufoy+sin(ufobob)*3.5
		if cannonzapt>0 then
			if cannonzapt>9 then
				local s=cannonzapt-9
				circfill(52,67+uy,6*s,8)
				circfill(52,67+uy,5*s,9)
				circfill(52,67+uy,4*s,10)
			end
			draw_zap(-1,128,52,67+uy,zapoffsets,8,10)
		end
		sspr(104,0,16,8,55,46+uy)
		sspr(96,8,32,16,47,54+uy)
		sspr(4,0,6,6,60,51+uy,6,6,true)
		-- title screen
		if not transtime then
			if conditionone then
				local x=36
				for i=1,#titlehi do
					if titlehi[i]==0 then
						x+=4
					else
						local sp=titlesprs[titlehi[i]]
						sspr(sp[1],sp[2],sp[3],8,x,14)
						x+=sp[3]+1
					end
				end
			end		
			printc("press    to start",64,112,7,0)
			sspr(1,7,7,6,54,112)
		end
	else
		-- gun ui
		if pl.guns>1 and not (popup and popup.t>240 and popup.t%16>7) then
			for i=1,pl.guns do
				rectfill(1,123-i*8,8,130-i*8,pl.gun==i and 5 or 1)
				draw_sp(ptypes[i+1].a,1,5,130-i*8,4,false,ptypes[i+1].pali,true)
				sspr(40,8,8,4,1,119-i*8)
			end
			sspr(40,12,8,4,1,123)
		end
		-- score
		if pl.score>0 then
			printc(pl.score,64,120,12,1)
		end
	end
	-- screen pal
	memcpy(0x5f10,0x4300,16)
end

function printc(txt,x,y,c,olc)
	c,txt=c or 7,tostr(txt)
	if olc then
		for y=y-1,y+1 do
			for x=x-1,x+1 do
				print(txt,x-#txt*2,y,olc)
			end	
		end
	end
	print(txt,x-#txt*2,y,c)
end

function new_player(x,y)
	local jtm,anm,anmf,flp,onground,inwater,ft,nft,canjmp,btm,zap,zapg=0,1,1,true,false,false,4,4,true,0,nil,1
	return {
		sx=x,sy=y,x=x,y=y,vx=0,vy=0,score=0,guns=0,gun=0,
		update=function(p)
			if chat then
				anm,anmf,flp,p.vx,p.vy,zapt=1,1,p.x<chatf.x,0,0,0
				return
			end
			
			if powercore and zapdest==powercore then
				if zapt>8 and flr(sin(0.5+zapt/896)*224)%14==0 then
					sfx(37)
					for i=0,12 do
						new_particle(powercore.x,powercore.y-4,rnd()-0.5,rnd()-0.5,rnd(zapcols),10+flr(rnd(10)),0,true)
					end
				end
			else			
				if p.guns>0 then
					if btnp(3) then
						-- down
						p.gun=p.gun==1 and p.guns or p.gun-1
					elseif btnp(2) then
						-- up
						p.gun=p.gun%p.guns+1
					end
				end
				
				-- move
				if flying<=1 then
					if btn(0) then
						p.vx,flp=(p.vx<-1 and flying>0) and p.vx or max(p.vx-0.125,-1),false
					elseif btn(1) then
						p.vx,flp=(p.vx>1 and flying>0) and p.vx or min(p.vx+0.125,1),true
					elseif onground then
						p.vx*=0.75
						if abs(p.vx)<0.1 then
							p.vx=0
						end
					elseif flying==0 then
						p.vx*=0.95
					end
					p.vx=onground and mid(p.vx,-1,1) or p.vx
				end
				-- jump
				if jbtnd then
					if (onground or p.y>sy) and canjmp then
						-- jtm: counts down while player is holding jump for variable height jump
						-- canjmp: keeps track of whether the player has released the jump button
						jtm,canjmp=0,false
						if onground then
							p.vy-=1.35
							jtm=8
						else
							p.vy=-1.75
						end
						sfx(34)
					elseif jtm>0 then
						-- increase jump velocity while player holds jump
						p.vy-=0.1
					end
				else
					-- not pressing jump so kill jump time and allow jump
					jtm,canjmp=0,true
				end
			end
			
			if jtm==0 then
				-- only apply gravity when jump height isn't increasing
				if p.y<=sy+3 and flying<=1 then
					if abs(p.vy)<0.5 then
						p.vy+=0.075
					else
						p.vy+=0.1
					end
				end
			else
				-- reduce jump timer
				jtm-=1
			end
			-- cap fall speed
			p.vy=min(p.vy,2)
			
			if p.y>sy+3 then
				if p.vy>0 then
					p.vy*=0.95
				end
				p.vy-=0.05
			end
			-- collide with map
			local collided=false
			p.x,p.y,p.vx,p.vy,onground,collided=collideworld(p.x,p.y,p.vx,p.vy,3,12)
			flying=not collided and flying or 0
			p.x+=p.vx
			p.y+=p.vy
			
			if p.y>sy then
				if not inwater and p.vy>0.5 then
					for i=0,10 do
						new_particle(p.x-4+rnd(8),sy,rnd()*0.5-0.25+p.vx*0.5,-rnd(p.vy*0.75)-0.5,3,30,0.1)
					end
					sfx(35,3,p.vy>1.65 and 0 or p.vy>1 and 1 or 2)
				end
				inwater,flying=true,0
			else
				inwater=false
			end
			
			for b in all(buttons) do
				if p.y==b.y and p.x>b.x-3 and p.x<b.x+11 then
					slvlo,slvld,slvlt,b.y,b.pf=slvl,b.l,0,b.y+2,3
					sfx(43)
				end
			end
			
			if flying>0 then
				flying=max(flying-1,1)
			end
			
			-- set animation sequence and frame
			if not onground then
				-- not on ground so use jump sequence set frame to 1
				anm,anmf=3,1
				if p.vy>1.3 then
					-- if going down use frame 3
					anmf=3
				elseif p.vy>-1 then
					-- if near peak of jump use frame 2
					anmf=2
				end
			elseif abs(p.vx)>0.01 then
				-- if on ground and moving use run sequence
				-- set time til next frame based on velocity
				nft=max(1,flr(6-(abs(p.vx)*2)))
				-- set run sequence
				if anm~=2 then
					anm,anmf,ft=2,0,1
				end
				ft-=1
				-- if frame timer hits 0 increment frame
				if ft==0 then
					ft,anmf=nft,anmf%#panms[anm]+1
				end
			else
				-- standing still
				anm,anmf=1,1
			end
			
			-- shooting
			if sbtnd and not (powercore and zapdest==powercore) then
				if btm<0 and p.gun>0 then
					zapg,zapt,zapdest,btm,zapcols=p.gun,14,nil,15,{8,10}
					sfx(37)
					if p.gun==2 then
						zapcols={3,11}
					elseif p.gun==3 then
						zapcols={15,12}
					end
				end
			else
				btm=btm<=0 and -1 or btm
			end
			if btm>0 then
				btm=max(0,btm-1)
			end
			
			if zapt>0 then
				local zd=zapdest
				if not zapdest then
					local d=p.x+(flp and 47 or -47)
					if zapg==1 then
						if powercore and not flp and powercore.x>p.x-50 and powercore.x<p.x-6 and powercore.y<p.y+6 and powercore.y>p.y-12 then
							zapdest,zd,p.vx,p.vy,zapt=powercore,powercore,0,min(p.vy,0),224
							for i=0,12 do
								new_particle(powercore.x,powercore.y-4,rnd()-0.5,rnd()-0.5,rnd(zapcols),10+flr(rnd(10)),0,true)
							end
						else
							for e in all(enemies) do
								if e.hurttime==0 and ((e.x>p.x and e.x<d) or (e.x<p.x and e.x>d)) and e.y<p.y+8 and e.y>p.y-8 then
									zapdest,zd=e,e
									e:hurt()
									sfx(38)
									for i=0,6 do
										new_particle(e.x,e.y-4,rnd()*0.5-0.25,-rnd(),rnd(zapcols),60,0.15)
									end
									break
								end
							end
						end
					elseif zapt==14 then
						if zapg==2 then
							for h in all(portals) do
								if ((h.x>p.x and h.x<d) or (h.x<p.x and h.x>d)) and h.y<p.y+22 and h.y>p.y-25 then
									zapdest,zd=h,h
									sfx(31)
									break
								end
							end
						elseif zapg==3 then
							local hd=d+(flp and 12 or -12)
							for h in all(hooks) do
								if ((h.x>p.x and h.x<hd) or (h.x<p.x and h.x>hd)) and h.y<p.y+6 and h.y>p.y-25 then
									zapdest,zd,flying=h,h,abs((h.x-p.x)/3)+6
									p.vx=h.x>p.x and 3 or -3
									p.vy=min(h.y-p.y,-8)/16
									sfx(31)
									break
								end
							end
						end
					end
					if not zapdest then
						local inc=flp and 8 or -8
						--d-=inc*0.5
						for dx=flr(p.x+inc),flr(p.x+inc*6),inc do
							if is_solid(dx,p.y-4) then
								d=flr(dx/8)*8-min(inc,1)
								if zapt%3==0 then
									new_particle(d,p.y-4,rnd()-0.5,rnd()-0.75,rnd(zapcols),60,0.15)
								end
								break
							end
						end
						zd={x=d,y=p.y}
					end
				elseif zapg==2 and zapt==7 then
					local dest=portals[zd.d]
					zapdest,zd,p.x,p.y=dest,dest,dest.x,dest.y+2
				end
				
				if zapt%2==0 then
					zapoffsets={{0,0}}
					for i=1,8 do
						add(zapoffsets,{rnd(4)-2,rnd(4)-2})
					end
					zapoffsets[10]={0,0}
				end
				zap={p.x+(flp and 7 or -7),p.y-4.5,zd.x,zd.y-4.5}
				zapt=max(zapt-1,0)
				if zapt==0 then
					if powercore and zapdest==powercore then
						for i=0,32 do
							new_particle(powercore.x,powercore.y-4,rnd(2)-1,rnd(2)-1,rnd(zapcols),90+flr(rnd(60)),0.01,true)
							new_particle(powercore.x,powercore.y-4,rnd()-0.5,rnd()-0.75,rnd(zapcols),120+flr(rnd(90)),0.01,true)
						end
						friends[1].sx-=32
						friends[1].chat,friends[1].chatted=story[5],false
						powercore=nil
					end
					zapdest=nil
				end
			end
			
			-- check collision with pickups
			for pu in all(pickups) do
				if not (p.x+4<pu.x-3 or p.x-4>pu.x+3 or p.y<pu.y-5 or p.y-12>pu.y+1) then
					p:give(del(pickups,pu))
				end
			end
		end,
		give=function(p,pu)
			local ptype=pu.ptype
			-- increment property the pickup affects
			p[ptype.pn]+=ptype.pv
			if ptype.msg then
				popup={txt=ptype.msg,anm=ptype.a,pali=ptype.pali,t=360}
				sfx(ptype.snd)
				if ptype.pn=="guns" then
					p.guns=min(p.guns,3)
					p.gun=p.guns
				end
			else
				add(sndcue,{snd=ptype.snd,msg={x=pu.x,y=pu.y-16,t=90,txt="+"..ptype.pv}})
			end
		end,
 		draw=function(p)
			draw_sp(anm,anmf,p.x,p.y,14,flp,p.gun)
			
			if zapt>0 then
				draw_zap(zap[1],zap[2],zap[3],zap[4],zapoffsets,zapcols[1],zapcols[2])
			end
		end
	}
end

function draw_zap(x1,y1,x2,y2,offsets,c1,c2)
	local lx,ly1,ly2,steps=x1,y1,y1,mid(2,flr(abs(x2-x1)/4),9)
	for i=1,steps do
		local lxn,ly1n=lerp(x1,x2,i/steps),lerp(y1,y2,i/steps)
		local ly2n=ly1n+offsets[i+1][1]
		ly1n+=offsets[i+1][2]
		line(lx,ly1,lxn,ly1n,c1)
		line(lx,ly2,lxn,ly2n,c2)
		lx,ly1,ly2=lxn,ly1n,ly2n
	end
end

function new_eyeball(x,y)
	local flp,ax,ay,vx,vy=false,x,y-8,0,0
	return {x=x+12,y=y+10,hurttime=0,
		update=function(e)
			if e.hurttime>0 then
				vy,vx=min(vy+0.15,2),0
				e.hurttime-=1
				if e.hurttime==0 then
					vx,vy=flp and 0.5 or -0.5,-0.25
				end
			else
				local tx,ty,accel,maxspd=ax,ay+20,0.025,0.5
				if abs(ax-pl.x)<32 and pl.y>ay and pl.y<ay+26 then
					tx,ty,accel,maxspd=pl.x,pl.y,0.25,1.5
				end
				if e.x>tx then
					vx,flp=max(vx-accel,-maxspd),false
				end
				if e.x<tx then
					vx,flp=min(vx+accel,maxspd),true
				end
				if e.y>ty then
					vy=max(vy-accel,-maxspd)
				end
				if e.y<ty then
					vy=min(vy+accel,maxspd)
				end
				if abs(vx)<0.0125 then
					vx*=3
				end
				if abs(vy)<0.0125 then
					vy*=3
				end
				if abs(e.x+vx-ax)>20 then
					vx=-vx*0.75
				end
				if abs(e.y+vy-ay)>24 then
					vy=-vy*0.75
				end
			end
			local pvy=vy
			e.x,e.y,vx,vy=collideworld(e.x,e.y,vx,vy,3,8)
			e.x+=vx
			e.y+=vy
			if e.hurttime==0 then
				if e.x+4>pl.x-3 and e.x-4<pl.x+3 and pl.y>ay and pl.y<ay+26 then
					pl.vx,pl.vy,flying=pl.x>e.x and 3 or -3,pl.vy>-1 and -1 or pl.vy,0
					sfx(33)
				end
			else
				if pvy>0 and e.vy==0 then
					vy=pvy*-0.75
				end
			end
		end,
		hurt=function(e)
			e.hurttime,vy=300,-1.5
		end,
		draw=function(e)
			if ax<camx-32 or ax>camx+160 or ay<camy-32 or ay>camy+136 then
				return
			end
			local cx,cy,t,c=ax,ay,1-abs(e.x-ax)/20,ay>sy and 3 or 8
			local cpx,cpy=ax+(e.x-ax)*0.5,ay+t*t*(3-2*t)*18+10
			for i=0,8 do
				local nx,ny=lerp3(ax,ax,e.x,i/8),lerp3(ay,cpy,e.y-3,i/8)
				line(cx,cy,nx,ny,c)
				cx,cy=nx,ny
			end
			draw_sp(4,e.hurttime>0 and 2 or 1,e.x,e.y,8,flp)
			
			-- draw dizzy stars
			if e.hurttime>0 then
				local s=min(e.hurttime/30,1)
				for i=0,2 do
					local xs,y=e.hurttime/48+i*0.3,e.y-13+cos(e.hurttime/40+i*0.3)*1.5
					local x,c=e.x+sin(xs)*5,cos(xs)>0 and 10 or 9
					if s>0.5 and s<1 then
						rectfill(x,y,x+1,y+1,c)
					else
						circfill(x,y,s,c)
					end
				end
			end
		end
	}
end

function new_friend(x,y,storyi,ia,wa,chatted)
	local flp,dx,wait,anm,anmf,ft,wm,dm=false,x,60,5,1,0,chatted and 1 or 90,chatted and 32 or 12
	return {x=x,y=y,sx=x,chat=story[storyi],chatted=chatted,
		update=function(p)
			if not chat then
				if p.x>dx then
					p.x-=0.25
					flp,anm=false,wa
				elseif p.x<dx then
					p.x+=0.25
					flp,anm=true,wa
				elseif wait>0 then
					anm,anmf=ia,1
					wait-=1
				else
					wait=60+flr(rnd(wm))
					if dx>p.sx then
						dx=p.sx-flr(rnd(dm))-4
					else
						dx=p.sx+flr(rnd(dm))+4
					end
				end
			
				if not p.chatted and ((p.x>pl.x-24 and p.x<pl.x-9) or (p.x>pl.x+9 and p.x<pl.x+24)) and p.y==pl.y then
					chati,chat,p.chatted,flp,chatf=0,p.chat,true,p.x<pl.x,p
				end
			end
			if ft>0 then
				ft-=1
			else
				ft=3
				anmf=anmf%#panms[anm]+1
			end
		end,
		setanim=function(p,i)
			anm,anmf=4+i,1
		end,
		draw=function(p)
			draw_sp(anm,anmf,p.x,p.y,12,flp,4)
		end
	}
end

function new_particle(x,y,vx,vy,c,t,g,nonsolid)
	c,t,g=c or 8,t or 60,g or 0.2
	add(particles,{
	update=function(p)
			vy=min(vy+g,7)
			
			-- if particle is solid then bounce
			if not nonsolid then
				if (vx>0 or vx<0) and is_solid(x+vx,y) then
					vx=-vx*0.75
					vy*=0.9
				end
				if (vy>0 or vy<0) and is_solid(x,y+vy) then
					vy=-vy*0.75
					vx*=0.9
				end
			end
			
			x+=vx
			y+=vy
			
			-- delete when its timer expires
			t-=1
			if t==0 or y>=sy or y>camy+140 or y<camy-12 or x<camx-12 or x>camx+140 then
				del(particles,p)
			end
		end,
		draw=function(p)
			pset(x,y,c)
		end
	})
end

function draw_sp(anm,anmf,x,y,h,flp,pali,noswamp)
	if y-h<sy or noswamp then
		draw_spint(anm,anmf,x,y,flp,pali)
	end
	if y>sy and not noswamp then
		memcpy(0x5f00,0x4310,16)
		if y-h<sy then
			clip(x-8-camx,sy-camy,16,16)
		end
		draw_spint(anm,anmf,x,y,flp)
		clip()
	end
	pal()
end

function draw_spint(anm,anmf,x,y,flp,pali)
	for i=1,#panms[anm][anmf] do
		local af=panms[anm][anmf][i]
		local f=true
		if (flp and af.f) or (not flp and not af.f) then
			f=false
		end
		if af.s<1 then
			pset(x+(f and -af.x-1 or af.x)+0.5,y+af.y+0.5,-af.s)
		else
			local s=psprs[af.s]
			if af.p and pali then
				memcpy(0x5f00,0x4320+pali*16,16)
			end
			sspr(s.x,s.y,s.w,s.h,x+(f and -s.w-af.x or af.x)+0.5,y+af.y+0.5,s.w,s.h,f)
			if af.p and pali then
				pal()
			end
		end
	end
end

function collideworld(x,y,vx,vy,w,h)
	local topclip,onground,collided=h>8 and h-8 or h,false,false
	-- only check collision in direction we are moving
	if vx<0 and (is_solid(x+vx-w,y-1) or is_solid(x+vx-w,y-7) or is_solid(x+vx-w,y-h+1)) then
		x,vx,collided=flr((x+vx+w)/8)*8+w,0,true
	end
	if vx>0 and (is_solid(x+vx+w,y-1) or is_solid(x+vx+w,y-7) or is_solid(x+vx+w,y-h+1)) then
		x,vx,collided=flr((x+vx-w)/8)*8+8-w,0,true
	end
	if vy>0 and (is_solid(x-w+1,y+vy) or is_solid(x+w-1,y+vy)) then
		-- hit the floor so set onground to true
		y,vy,onground,collided=flr((y+vy)/8)*8,0,true,true
	end
	if vy<0 and (is_solid(x-w+1,y+vy-h) or is_solid(x+w-1,y+vy-h)) then
		y,vy=flr((y+vy)/8)*8+topclip,0
	end
	return x,y,vx,vy,onground,collided
end

function is_solid(x,y)
	return fget(mget(x/8,y/8),1)
end

function lerp(a,b,t)
	return a+(b-a)*t
end

function smoothlerp(a,b,t)
	return a+(b-a)*(t*t*(3-2*t))
end

function lerp3(a,b,c,t)
	return (1-t)*(1-t)*a+2*(1-t)*t*b+t*t*c
end
