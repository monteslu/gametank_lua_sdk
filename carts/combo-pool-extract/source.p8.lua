--combo pool
--by nusan

skipmenu = false
menuselect = 2
maxallowed = 0
names = {"endless","easy","normal","hard"}

function toggledisplaynumber(b)
	if(b&32 > 0)	displaynumber=not displaynumber
	menuitem(1,"numbers: "..(displaynumber and "visible" or "hidden"),toggledisplaynumber)
end
displaynumber = false
toggledisplaynumber(0)

function newball(xx,yy,cc)
	local b = {x=xx,y=yy,vx=0,vy=0,c=cc,idx=ballidx,dead=false,mult=1,lastmult=0}
	add(balls, b)
	ballidx += 1
	return b
end

function newpart(xx,yy,time,cc)
	local b = {x=xx,y=yy,vx=0,vy=0,c=cc,t=time}
	add(parts, b)
	return b
end

function newtext(xx,yy,cc,intext)
	local b = {x=xx,y=yy,vx=0,vy=0,c=cc,t=1,text=intext}
	add(parts, b)
	return b
end

function reset()

	balls={}
	ballidx = 0

	parts = {}

	grid = {}

	time = 0
	menutime = 0

	launch_vrot = 0
	launch_rot = 0.25
	launch_px = 66
	launch_py = 64
	launch_vx = 0
	launch_vy = 0
	launch_x = 64
	launch_y = 120
	launch_dx = 0
	launch_dy = 1
	launch_str = 6

	launch_press = false
	launch_duration = 0
	avoid_nextlaunch = true

	launch_next = 1

	shouldrun = true

	score = 0
	ballscore = 0
	maxballscore = 0
	ballmult = 1
	maxmult = 1
	oldscore = 0
	newscoretimer = 0
	newballtimer = 0
	newballappear = 0
	oldballscore = 0
	newballscoretimer = 0
	newmaxtimer = 0
	newmaxappear = 0

	mainmenu = not skipmenu
	intromenu = false
	lastselect = 30

	death = false
	suddendeath = false
	suddendeathduration = 120
	victory = false
	finish = false
	finishtimer = 0

	pstam = 100
	astam = 0.5
	lstam = pstam

	plife = 1
	llife = plife

	for i=1,8 do
		grid[i]={}
		for j=1,8 do
			grid[i][j] = {}
		end
	end

	local ballcount = 0
	for i=0,2 do
		for j=0,1 do
			local typ = flr(rnd(3))
			ballcount += 2^typ
			newball(16 + j * 64 + rnd(32),8 + i*32 + rnd(16),typ+1)
		end
	end

	ballidx = ballcount

	rectfill(0,0,128,128,5)
	copyprevframe()

	music(-1,0,1)
end

function _init()
	poke(0x5f2d, 1)
	use_mouse,pmx,pmy,pmb1=false,stat(32),stat(33),false

	reset()

	bpal={1,13,6,9,10,8,14}
	bpal2={13,6,7,15,7,14,15}
	bpal3={0,1,13,4,9,2,2}

	mulint = 100 -- (2^15)
	ballvalue={1,2,3,5,10,20,100}
	ballcost={4,3.5,3,2,1.5,1,0}
	
end

function updategrid()
	for i=1,8 do
		for j=1,8 do
			grid[i][j] = {}
		end
	end

	for b in all(balls) do
		if b.dead then
			del(balls, b)
		else
			local gx = max(0,min(15,flr(b.x/16))) + 1
			local gy = max(0,min(15,flr(b.y/16))) + 1
			local gg1 = grid[gx]
			if gg1 then
				local gg = gg1[gy]
				if(gg) add(gg, b)
			end
		end
	end
end

function reflect(vx,vy,nx,ny)
	local dot = vx*nx+vy*ny
	vx = dot*nx*2.0 - vx
	vy = dot*ny*2.0 - vy
	return vx,vy
end

function dotpart(vx,vy,nx,ny)
	local dot = vx*nx+vy*ny
	vx = vx - dot*nx
	vy = vy - dot*ny
	return vx,vy
end

function lensqr(x,y)
	return x*x + y*y
end

function bomb(x,y,rad,str)

	for b in all(balls) do
		if not b.dead then

			local dx = (b.x-x)
			local dy = (b.y-y)
			local dist = sqrt(lensqr(dx,dy)+0.01)
			if dist<rad then
				dx = dx * str / dist
				dy = dy * str / dist

				b.vx += dx
				b.vy += dy
			end

		end
	end

end

function docoll(b1,b2)
	local dx = b1.x-b2.x
	local dy = b1.y-b2.y
	local sqrdist = lensqr(dx,dy)
	if sqrdist < 64 and not b1.dead and not b2.dead then

		if b1.c == b2.c then

			b1.x = (b1.x + b2.x)*0.5
			b1.y = (b1.y + b2.y)*0.5

			b1.vx = b1.vx+b2.vx
			b1.vy = b1.vy+b2.vy
		
			local dist = sqrt(sqrdist+0.01)
			local nx = dy/dist
			local ny = -dx/dist

			if b1.c<7 then
				b1.c += 1
				local sound = (b1.c>3) and 12 or 13
				if(b1.c>5) sound = 14
				sfx(sound)
			else
				bomb(b1.x,b1.y,80,5)
				b1.dead = true

				for pp=0,19 do
					local p = newpart(b1.x,b1.y,0.5,3)
					p.vx = b1.vx * 0.5 + (rnd()-0.5)*3
					p.vy = b1.vy * 0.5 + (rnd()-0.5)*3
					p.rnd = flr(pp*3/20)
				end

				if not death and maxallowed>0 then
					if not victory then
						finishtimer = 0
						music(-1,100)
					end
					victory = true
					finish = true
				end

				sfx(15)
			end

			b2.dead = true

			ballmult += b1.mult * b2.mult
			local addscore = ballmult*ballvalue[b1.c]
			ballscore += addscore/mulint
			score += addscore/mulint

			
			if ny>0 then
				ny = -ny
				nx = -nx
			end
			local p = newtext(b1.x,b1.y,b1.c,addscore.."0")
			p.vx = nx * 1
			p.vy = ny * 1

			b1.mult = min(b1.mult*2,8)
			b1.lastmult = 60

		else
			if sqrdist > 0 then
				local dist = sqrt(sqrdist)
				local nx = dy/dist
				local ny = -dx/dist

				local dd1x,dd1y=dotpart(b1.vx,b1.vy,nx,ny)
				local dd2x,dd2y=dotpart(b2.vx,b2.vy,nx,ny)

				local push = max(0,9-dist)*0.5/dist
				b1.x += dx*push
				b1.y += dy*push
				b2.x -= dx*push
				b2.y -= dy*push

				b1.vx = b1.vx - dd1x + dd2x
				b1.vy = b1.vy - dd1y + dd2y
				b2.vx = b2.vx - dd2x + dd1x
				b2.vy = b2.vy - dd2y + dd1y

				local iscombo = false
				if b1.lastmult <= 55 then
					b1.mult = min(b1.mult*2,8)
					b1.lastmult = 60
					iscombo = true
				end
				if b2.lastmult <= 55 then
					b2.mult = min(b2.mult*2,8)
					b2.lastmult = 60
					iscombo = true
				end

				if iscombo then
					local bestmult = max(b1.mult,b2.mult)
					b1.mult = bestmult
					b2.mult = bestmult
					local p = newpart((b1.x+b2.x)*0.5,(b1.y+b2.y)*0.5,0.25,2)
					p.vx = (b1.vx+b2.vx)*0.5
					p.vy = (b1.vy+b2.vy)*0.5

					sfx(11)
				end
			end
	
		end
	end
end

function colgrid(b1,gx,gy)
	if gx>0 and gx<=8 and gy>0 and gy<=8 then
		for b2 in all(grid[gx][gy]) do
			if(b1.idx>b2.idx) docoll(b1,b2)
		end
	end
end

function colballs()

	for b in all(balls) do
		local gx = max(0,min(15,flr(b.x/16 + 0.5))) + 1
		local gy = max(0,min(15,flr(b.y/16 + 0.5))) + 1

		colgrid(b,gx,gy)
		colgrid(b,gx-1,gy)
		colgrid(b,gx,gy-1)
		colgrid(b,gx-1,gy-1)

	end

end

function _update()

	pmb1=mb1
	mmx,mmy,mb1=stat(32),stat(33),stat(34)%2==1
	if(btnp()>0) use_mouse=false
	if mmx!=pmx or mmy!=pmy or mb1!=pmb1 then
		pmx,pmy=mmx,mmy
		if time>0 then
			use_mouse=true
		end
	end
	mouse_press=(mb1 and not pmb1)

	if not shouldrun then
		return
	end

	if mainmenu then

		if btnp(2) then
			menuselect -=1
			lastselect = 30
		end
		if btnp(3) then
			menuselect +=1
			lastselect = 30
		end
		
		local mouse_over_button=false
		if use_mouse then
			newselect=menuselect
			if abs(38+25-mmx)<28 then
				for i=1,4 do
					if abs(i*10+78-mmy)<5 then
						newselect=i-1
						mouse_over_button=true
					end
				end
			end
			
			if mouse_over_button then
				if newselect!=menuselect then
					menuselect=newselect
					lastselect=30
				end
			else
				menuselect=-1
				lastselect=31
			end
		else
			local menunumb=4
			menuselect = ((menuselect%menunumb)+menunumb)%4
		end

		if(lastselect>0) lastselect-=1

		if btnp(4) or btnp(5) or (mouse_press and mouse_over_button) then
			intromenu = true
			mainmenu = false
			music(-1,0,1)
			sfx(12)
			avoid_nextlaunch = true
		end

		if time == 0 then
			sfx(13)
		end

		time += 1
		menutime += 1/30

		if mainmenu then
			return
		end
	end

	if intromenu then

		if (btnp(4) or btnp(5) or mouse_press) and not avoid_nextlaunch then
			local lifes = {0,50,40,34}
			maxallowed = lifes[menuselect+1]
			sfx(14)
			reset()
			music(-1,0,1)
			mainmenu = false
			intromenu = false
		else
			avoid_nextlaunch = false
		end

		time += 1

		if intromenu then
			return
		end
	end

	if (death or victory) and finishtimer>60 then
		if btnp(4) or btnp(5) or mouse_press then
			reset()
		end
	end

	local dt = 1/30

	for b in all(parts) do
		b.x += b.vx
		b.y += b.vy
		b.vx *= 0.95
		b.vy *= 0.95
		b.t -= dt
		if(b.t<=0) del(parts,b)
	end

	updategrid()

	local curpress = btn(4) or mb1
	local resetmult = false

	if not finish then

		if use_mouse then

			launch_px = min(124,max(4,mmx))
			launch_py = min(112,max(4,mmy))

			local launch_len = 1/sqrt(lensqr(launch_px-launch_x,launch_py-launch_y) + 0.01)

			launch_dx = (launch_px-launch_x)*launch_len
			launch_dy = (launch_py-launch_y)*launch_len
			launch_rot = atan2(launch_dx,launch_dy)
		else --keyboard
		
			local vrot = curpress and 0.003 or 0.002

			if(btn(0)) launch_vrot += vrot
			if(btn(1)) launch_vrot -= vrot

			launch_rot = min(max(0.005,launch_rot+launch_vrot),0.495)
			launch_dx = cos(launch_rot)
			launch_dy = sin(launch_rot)

			launch_vrot *= (curpress and 0 or 0.8)

		end

		-- and a slight offset if there is no horizontal motion
		-- so you cannot play in 1d
		if launch_dx == 0 then
			launch_dx += 0.01
			launch_dy += 0.01
		end

		local canrelease = pstam>0 and not avoid_nextlaunch

		if curpress and not launch_press and canrelease then
			sfx(9)
		end

		if not curpress and launch_press and canrelease then
			local nb = newball(launch_x,launch_y,launch_next)
			nb.vx = launch_dx * launch_str
			nb.vy = launch_dy * launch_str

			launch_next = 1 -- flr(rnd(7))+1
			ballscore = 0
			ballmult = 1
			resetmult = true
			pstam -= 40
			astam = 0.5

			sfx(10)
		end
	else
		finishtimer += 1
	end

	launch_press = curpress
	if not curpress then
		avoid_nextlaunch = false
	end


	local drag = 0.98

	local substeps = 5
	local invsub = 1.0/substeps
	for i=1,substeps do
		for b in all(balls) do
			b.x += b.vx*invsub
			b.y += b.vy*invsub

			local hurt = false

			if b.x>124 or b.x<4 then
				hurt = true
				b.vx = -b.vx
				b.x += b.vx
				if(b.x>124) b.x=124
				if(b.x<4) b.x=4
			end
			local colboty = b.y>112 and b.vy>0.1
			if colboty or b.y<4 then
				hurt = true
				b.vy = -b.vy
				b.y += b.vy
				if(b.y>112) b.y=112
				if(b.y<4) b.y=4
			end

			if hurt then
				if b.lastmult <= 55 then
					b.mult = min(b.mult*2,8)
					b.lastmult = 60

					newpart(b.x,b.y,0.25,2)
					--newtext(b.x,b.y,b.c,"+")

					sfx(11)
				end
			end

			if resetmult then -- or b.lastmult <= 0 then
				b.mult = 1
			end

			if b.lastmult > 0 then
				b.lastmult -= 1
			end
		end

		colballs()
	end

	lifecost = 0

	for b in all(balls) do
		b.vx *= drag
		b.vy *= drag

		lifecost += ballcost[b.c]
	end
	maxlifecost = max(maxlifecost,lifecost)

	if maxballscore<ballscore then
		newmaxtimer = 60
	end
	if newmaxtimer>0 then
		newmaxtimer -= 1
		newmaxappear = min(60,newmaxappear+1)
	else
		newmaxappear = max(0,newmaxappear-1)
	end
	maxballscore = max(maxballscore,ballscore)

	newballscoretimer = max(0,newballscoretimer-1)
	if ballscore!=oldballscore then
		newballscoretimer = 32
		oldballscore = ballscore
	end

	newscoretimer = max(0,newscoretimer-1)
	if score!=oldscore then
		newscoretimer = 4
		oldscore = score
	end

	maxmult = max(ballmult,maxmult)

	newballtimer = (ballscore>0) and 10 or 0
	newballappear += max(-1,min(1,(newballtimer-newballappear)))
	
	if pstam<100 then
		pstam = min(100,pstam+astam)
		astam *= 1.1
	end
	lstam += max(-1,min(1,(pstam-lstam)))

	if finish and victory then
		if finishtimer == 30 then
			sfx(17)
		end
	end

	if maxallowed>0 and not death and not victory then
		plife = 100-100*(lifecost/maxallowed)^3
		if plife<0 then
			if not suddendeath then
				music(10,100,1)
			end
			suddendeath = true
			finish = true
			if finishtimer>=suddendeathduration then
				if suddendeath then
					music(5,100,1)
				end
				suddendeath = false
				finishtimer = 0
				death = true
			end
		else
			if finishtimer<suddendeathduration then
				if suddendeath then
					music(-1,0,1)
				end
				suddendeath = false
				finish = false
				finishtimer = 0
			else
				death = true
				finish = true
			end
		end
		llife += max(-1,min(1,(plife-llife)))	
	end

	time += 1
end

function drawball(x,y,c)
	circfill(x,y,4, bpal3[c])
	circfill(x+0.66,y-0.66,3,bpal[c])
	circfill(x+1.33,y-1.33,1,bpal2[c])
	if displaynumber then
		bprint(c,x-1,y-2,0,bpal[c])
	end
end


frame_chunk_0 = 0x1000
frame_chunk_1 = 0x4300

function copyprevframe()
	memcpy(frame_chunk_0,0x6000,0x1000)
	memcpy(frame_chunk_1,0x7000,0x1000)
end

function pasteprevframe()
	memcpy(0x6000,frame_chunk_0,0x1000)
	memcpy(0x7000,frame_chunk_1,0x1000)
end

function boldline(x1,y1,x2,y2,c)
	line(x1,y1,x2,y2,c)
	line(x1+1,y1,x2+1,y2,c)
	line(x1-1,y1,x2-1,y2,c)
	line(x1,y1+1,x2,y2+1,c)
	line(x1,y1-1,x2,y2-1,c)
end

function bprint(text,x,y,c,d)
	print(text,x-1,y,d)
	print(text,x+1,y,d)
	print(text,x,y-1,d)
	print(text,x,y+1,d)
	print(text,x,y,c)
end

function cprint(text,x,y,c,d)
	bprint(text,x - #text*2,y,c,d)
end

function rprint(text,x,y,c,d)
	bprint(text,x - #text*4,y,c,d)
end

function dbar(px,py,v,m,c,c2,c3)
	local pe = px+v*0.3
	local pe2 = px+m*0.3
	--rectfill(px-1,py-1,px+30,py+3,c3)
	if(c3) rectfill(px,py,px+28,py+2,c3)
	rectfill(px,py,pe,py+2,c2)
	rectfill(px,py,max(px,pe-1),py+1,c)
	if(m>v) rectfill(pe+1,py,pe2,py+2,6)
end

function panel(x,y,sx,sy)
	--rectfill(x+8,y+8,x+sx-9,y+sy-9,0)
	spr(66,x,y)
	spr(67,x+sx-8,y)
	spr(82,x,y+sy-8)
	spr(83,x+sx-8,y+sy-8)
	sspr(24,32,4,8,x+8,y,sx-16,8)
	sspr(24,40,4,8,x+8,y+sy-8,sx-16,8)
	sspr(16,36,8,4,x,y+8,8,sy-16)
	sspr(24,36,8,4,x+sx-8,y+8,8,sy-16)
end

function getscoretext(value)
	local fracscore = flr((value%1)*mulint+0.5)
	local textscore = (fracscore%mulint)..""
	local floorscore = flr(value) + flr(fracscore/mulint)
	if floorscore > 0 then
		if(#textscore<2) textscore = "0"..textscore
		textscore = floorscore..textscore
	end
	if(textscore!="0") textscore=textscore.."0"
	return textscore
end

function rainbow()
	for pp=8,14 do
		pal(pp,8+(pp+(time/4))%7)
	end
end

function setpal(v)
	for pp=8,14 do
		pal(pp,v)
	end
end

function setpallist(l,v)
	for b in all(l) do
		pal(b,v)
	end
end

function menuballdisplace(i)
	local animtime = max(0,menutime-1.5)
	local avance = (animtime*10 + sin(animtime*0.4+i/13)*5 + i * 136/14 - 4)%136 - 4
	return avance - 136 + 136*(1-((1-min(menutime,2)/2)^2))
end

function _draw()

	cls()

	if mainmenu then

		local mx = 40
		local my = 37


		rectfill(0,0,128,128,1)

		map(0,0,0,1,16,16)

		local delay = 2

		local animtime = min(delay,menutime)/delay
		local titlex = (animtime^10)
		local titleb = 32-64+64*titlex
		local titley = my + (sin(menutime+0.3)*5)/(menutime^2)

		if time == 60 then
			sfx(14,3)
			music(0,2000,1)
		end

		pal()
		setpal(1)
		spr(5,titleb,my+3,4,2)
		spr(5,titleb,my+2,4,2)
		spr(5,titleb,my+1,4,2)
		pal(1,0)
		if menutime<(delay+0.2) then
			setpal((menutime>delay) and 7 or 5)
		else
			rainbow()
		end
		spr(5,titleb,titley,4,2)

		local title2x = 64+70-70*titlex
		local title2y = my + (sin(menutime)*10)/menutime

		local palist={2,8,14}
		setpallist(palist,1)
		spr(37,title2x,my+3,4,2)
		spr(37,title2x,my+2,4,2)
		spr(37,title2x,my+1,4,2)
		setpallist(palist,0)
		spr(37,title2x-1,title2y,4,2)
		spr(37,title2x+1,title2y,4,2)
		spr(37,title2x,title2y-1,4,2)
		spr(37,title2x,title2y+1,4,2)
		pal()
		if menutime<(delay+0.2) then
			setpallist(palist,(menutime>delay) and 7 or 5)
		end
		spr(37,title2x,title2y,4,2)

		pal()

		my = 66

		--time = 7
		
		local second = 50

		rectfill(0,my+3,128,128,0)
		rectfill(0,0,128,my-second+2,0)
		rect(0,my+3,128,my-second+2,1)

		bprint("nusan - p8jam2", mx,1,6,5)
		print("v4",116,122,1)
		
		for i=0,13 do
			local bx = menuballdisplace(i)
			local bid = i%7+1
			circfill(bx,my+2,5,1)
			circfill(128-bx,my+2-second,5,1)
		end

		for i=0,13 do
			local bx = menuballdisplace(i)
			local bid = i%7+1
			circfill(bx,my,5,0)
			drawball(bx,my,bid)
			circfill(128-bx,my-second,5,0)
			drawball(128-bx,my-second,bid)
		end

		my = 77

		panel(mx-7,my+3,61,48)

		for i=1,#names do
			if i == menuselect+1 then
				rectfill(mx-2,my+i*10-2,mx-2+50*(1-(lastselect/30)^3),my+i*10+6,1)
				bprint(names[i],mx,my+i*10,7,0)
			else
				bprint(names[i],mx,my+i*10,13,1)
			end
		end
		
		if(use_mouse) circ(mmx,mmy,4,6)

		return
	end

	if intromenu then

		local mx = 2
		local my = menuselect==0 and 24 or 1
		cprint("goal", 64,my,7,1)
		my += 10
		bprint("merge two balls of same color", mx,my,6,1)
		bprint("to transform them to next color", mx,my+7,6,1)

		my += 24
		rectfill(0,my-10,128,my+18,1)

		for i=1,7 do
			local bx = i*16 - 9

			spr(50,bx+4,my+1)
			
			circfill(bx,my,5,0)
			circfill(bx,my+9,5,0)

			drawball(bx,my,i)
			drawball(bx,my+9,i)
		end
		
		bprint("?",119,my+2,6,0)

		if menuselect>0 then
			my += 26
			
			bprint("avoid keeping too much balls", mx,my,6,1)
			bprint("or your life will end soon", mx,my+7,6,1)
			
			my += 17
	
			rectfill(25,my-2,105,my+13,1)
	
			dbar(28+1,my+2,60,60,8,2,0)
	
			spr(50,60,my+1)
	
			local flagx = 70
			pal(7,9 + (time/3)%2)
			rainbow()
			spr(12,flagx,my,4,2)
			dbar(flagx+1,my+2,15,15,8,2,7)
			pal()
		end
		
		my += 21
		bprint("hold the launch button", mx,my,6,1)
		bprint("to use precise rotations", mx,my+7,6,1)

		spr((flr(time/4)%6==0) and 51 or 52,104,my+4)
		
		cprint("press to start",64,my+20,(flr(time/8)%2==0) and 7 or 5,1)

		if(use_mouse) circ(mmx,mmy,4,6)

		return
	end

	if false then
		rectfill(0,0,128,128,5)
	else
		pasteprevframe()

		for b in all(balls) do
			--pset(b.x+rnd(7)-3.5,b.y+rnd(7)-3.5,bpal[b.c])
			circfill(b.x,b.y,3,bpal[b.c])
		end

		for i=0,10 do
			local fillcol = suddendeath and 2 or 5
			circfill(rnd(128),rnd(128),2,fillcol)
		end
		for i=0,70 do
			local fillcol = suddendeath and 2 or 5
			pset(rnd(128),rnd(128),fillcol)
		end


		copyprevframe()
	end

	if not finish then
		local llen = 130
		boldline(launch_x,launch_y,launch_x+launch_dx*llen,launch_y+launch_dy*llen,1)
	end

	--rectfill(0,0,128,128,5)
	palt(0,false)
	palt(5,true)
	map(0,0,0,0,16,16)
	pal()

	if use_mouse then
		local lgoal = 5
		--line(launch_px-lgoal,launch_py,launch_px+lgoal,launch_py,6)
		--line(launch_px,launch_py-lgoal,launch_px,launch_py+lgoal,6)
		circfill(launch_px,launch_py,lgoal,1)
	end
	
	for b in all(balls) do
		local blink = (b.c == 7 or (b.mult>=8 and b.lastmult>30)) and flr(time/8)%2==0
		circfill(b.x,b.y+2,5,1)
		circfill(b.x,b.y,5,blink and 8 or 0)
	end
	
	for b in all(balls) do
		drawball(b.x,b.y,b.c)
	end

	rectfill(0,119,128,128,0)

	if not finish then

		if use_mouse then
			pset(launch_px,launch_py,6)
		end

		panel(0,112,55,16)

		local maxballscorecol = (newmaxtimer>0 and (flr(newmaxtimer/4)%2==0)) and 7 or 13		
		bprint(getscoretext(maxballscore),5,115,maxballscorecol,1)
		local newscorecol = (newscoretimer>0 and (flr(newscoretimer/4)%2==0)) and 7 or 13
		bprint(getscoretext(score),5,121,newscorecol,1)

		local ballmenuy = 130-((newballappear/10)^2) * 12

		local ballscorecol = (newballscoretimer>0 and (flr(newballscoretimer/4)%2==0)) and 7 or 13
		bprint("+"..getscoretext(ballscore),80,ballmenuy,ballscorecol,1)
		rprint("x"..ballmult,124,ballmenuy,ballscorecol,1)

		panel(74,112,54,16)

		if newmaxappear>0 then
			pal(1,0)
			rainbow()
			spr(44,2-((1-newmaxappear/60)^2) * 33,103,4,2)
			pal()
		end

		if not suddendeath then

			local launch_color = 13
			local llen = 20
			line(launch_x,launch_y,launch_x+launch_dx*llen,launch_y+launch_dy*llen,launch_color)

			circ(launch_x,launch_y,6,launch_color)
			circfill(launch_x,launch_y,5,0)

			drawball(launch_x,launch_y,launch_next)

			dbar(50,124,max(0,pstam),lstam,13,5,1)
			if maxallowed>0 then

				local warn = lifecost+4>maxallowed
				--warn = true
				if warn then
					pal(7,9 + (time/3)%2)
					rainbow()
					spr(12,49,0,4,2)
				end

				dbar(50,2,max(0,plife),llife,8,2,warn and 7 or 0)

				pal()
			end
		end
	end

	for b in all(parts) do
		if b.text then
			bprint(b.text,b.x,b.y,7,0) -- bpal[b.c])
		else
			if b.c == 3 then
				circfill(b.x,b.y,10-b.t*20,8+b.rnd)
			elseif b.c == 2 then
				circ(b.x,b.y,7-b.t*24,7)
			else
				--circ(b.x,b.y,7-b.t*12,)
			end
		end
	end

	if finish then		
		local gx = 16
		local gy = 128 - min(96,finishtimer)

		if suddendeath then
			bprint("sudden death : "..(suddendeathduration-finishtimer),64-4*8,120,8,1)
		else
			rectfill(gx+3,gy+3,gx + 94,gy+61,0)
			--rect(gx,gy,gx + 96,gy+64,0)
			pal(13,6)
			pal(5,13)
			panel(gx,gy,97,64)
			pal()
			cprint((death and"game over : " or "victory : ")..names[menuselect+1],64,gy+6,7,1)
			bprint("final score: "..getscoretext(score),gx+5,gy+18,6,1)
			bprint("max ball: "..getscoretext(maxballscore),gx+5,gy+24,6,1)
			bprint("last ball: "..getscoretext(ballscore),gx+5,gy+30,6,1)
			bprint("max multiplyer: "..maxmult.."x",gx+5,gy+36,6,1)
			bprint("ball count: "..ballidx,gx+5,gy+42,6,1)
		end

		if (death or victory) and finishtimer>60 then
			cprint("press to restart",64,gy+53,(flr(time/8)%2==0) and 7 or 5,1)
		end
	end

	if false then
		print("cpu "..flr(stat(1)*100),96,0,7)
		print("b "..#balls,96,8,7)
	end

end
