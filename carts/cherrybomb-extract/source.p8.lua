-- cherry bomb
-- by lazy devs

function _init()
 --this will clear the screen
 cls(0)
 
 cartdata("cherrybomb")
 highscore=dget(0)
 
 version="v1"
 
 startscreen()
 blinkt=1
 t=0
 lockout=0
 
 shake=0
 flash=0

 debug=""
 
 peekerx=64
 
 -- logo ani --
	fadetable={{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{1,1,129,129,129,129,129,129,129,129,0,0,0,0,0},{2,2,2,130,130,130,130,130,128,128,128,128,128,0,0},{3,3,3,131,131,131,131,129,129,129,129,129,0,0,0},{4,4,132,132,132,132,132,132,130,128,128,128,128,0,0},{5,5,133,133,133,133,130,130,128,128,128,128,128,0,0},{6,6,134,13,13,13,141,5,5,5,133,130,128,128,0},{7,6,6,6,134,134,134,134,5,5,5,133,130,128,0},{8,8,136,136,136,136,132,132,132,130,128,128,128,128,0},{9,9,9,4,4,4,4,132,132,132,128,128,128,128,0},{10,10,138,138,138,4,4,4,132,132,133,128,128,128,0},{11,139,139,139,139,3,3,3,3,129,129,129,0,0,0},{12,12,12,140,140,140,140,131,131,131,1,129,129,129,0},{13,13,141,141,5,5,5,133,133,130,129,129,128,128,0},{14,14,14,134,134,141,141,2,2,133,130,130,128,128,0},{15,143,143,134,134,134,134,5,5,5,133,133,128,128,0}}

 cls(12)
 spr(10,40,34,6,5)
 cprint("a lazy devs game", 64,80,7)
 cprint("by krystian majewski", 64,86,7)
 
 fadeperc=1
 
 repeat
  dofade()
  fadeperc-=0.07
  flip()
 until( fadeperc<=0 )
 
 fadeperc=0
 dofade()
 for i=0,30 do
  flip()
 end
 
 repeat
  dofade()
  fadeperc+=0.07
  flip()
 until( fadeperc>=1 )
 fadeperc=0
 cls()
 dofade()
 for i=0,10 do
  flip()
 end
 
end

function dofade()
 fadeperc=min(fadeperc,1)
 for c=0,15 do
  pal(c,fadetable[c+1][flr(fadeperc*16+1)],1)
 end
end

function _update() 
 t+=1
 
 blinkt+=1
 
 if mode=="game" then
  update_game()
 elseif mode=="start" then
  update_start()
 elseif mode=="wavetext" then
  update_wavetext()
 elseif mode=="over" then
  update_over()
 elseif mode=="win" then
  update_win()
 end
 
end

function _draw()
 doshake()
 
 if mode=="game" then
  draw_game()
 elseif mode=="start" then
  draw_start()
 elseif mode=="wavetext" then
  draw_wavetext()
 elseif mode=="over" then
  draw_over()
 elseif mode=="win" then
  draw_win()
 end
 
 camera()
 print(debug,2,9,7)

end

function startscreen()
 makestars()
 mode="start"
 music(7)
end

function startgame()
 t=0
 wave=0
 lastwave=9
 nextwave()
 
 ship=makespr()
 ship.x=60
 ship.y=90
 ship.sx=0
 ship.sy=0
 ship.spr=2
   
 flamespr=5
 
 bultimer=0
 
 muzzle=0
 
 score=0
 cher=0
 
 lives=4
 invul=0
 
 attacfreq=60
 firefreq=20
 nextfire=0
 
 makestars()
  
 buls={}
 ebuls={}
 
 enemies={}
 
 parts={}
 
 shwaves={}
 
 pickups={}
 
 floats={}
end

-->8
-- tools

function makestars()
 stars={} 
 for i=1,100 do
  local newstar={}
  newstar.x=flr(rnd(128))
  newstar.y=flr(rnd(128))
  newstar.spd=rnd(1.5)+0.5
  add(stars,newstar)
 end 
end

function starfield()
 
 for i=1,#stars do
  local mystar=stars[i]
  local scol=6
  
  if mystar.spd<1 then
   scol=1
  elseif mystar.spd<1.5 then
   scol=13
  end   
  
  pset(mystar.x,mystar.y,scol)
 end
end

function animatestars(spd)
 if spd==nil then
  spd=1
 end
 
 for i=1,#stars do
  local mystar=stars[i]
  mystar.y=mystar.y+mystar.spd*spd
  if mystar.y>128 then
   mystar.y=mystar.y-128
  end
 end

end

function blink()
 local banim={5,5,5,5,5,5,5,5,5,5,5,6,6,7,7,6,6,5}
 
 if blinkt>#banim then
  blinkt=1
 end

 return banim[blinkt]
end

function drwoutline(myspr)
 spr(myspr.spr,myspr.x+1,myspr.y,myspr.sprw,myspr.sprh)
 spr(myspr.spr,myspr.x-1,myspr.y,myspr.sprw,myspr.sprh)
 spr(myspr.spr,myspr.x,myspr.y+1,myspr.sprw,myspr.sprh)
 spr(myspr.spr,myspr.x,myspr.y-1,myspr.sprw,myspr.sprh)
end

function drwmyspr(myspr)
 local sprx=myspr.x
 local spry=myspr.y
 
 if myspr.shake>0 then
  myspr.shake-=1
  if t%4<2 then
   sprx+=1
  end
 end
 if myspr.bulmode then
  sprx-=2
  spry-=2
 end
 
 spr(myspr.spr,sprx,spry,myspr.sprw,myspr.sprh)
end

function col(a,b)
 if a.ghost or b.ghost then 
  return false
 end

 local a_left=a.x
 local a_top=a.y
 local a_right=a.x+a.colw-1
 local a_bottom=a.y+a.colh-1
 
 local b_left=b.x
 local b_top=b.y
 local b_right=b.x+b.colw-1
 local b_bottom=b.y+b.colh-1

 if a_top>b_bottom then return false end
 if b_top>a_bottom then return false end
 if a_left>b_right then return false end
 if b_left>a_right then return false end
 
 return true
end

function explode(expx,expy,isblue)
 
 local myp={}
 myp.x=expx
 myp.y=expy
 
 myp.sx=0
 myp.sy=0
 
 myp.age=0
 myp.size=10
 myp.maxage=0
 myp.blue=isblue
 
 add(parts,myp)
	  
 for i=1,30 do
	 local myp={}
	 myp.x=expx
	 myp.y=expy
	 
	 myp.sx=rnd()*6-3
	 myp.sy=rnd()*6-3
	 
	 myp.age=rnd(2)
	 myp.size=1+rnd(4)
	 myp.maxage=10+rnd(10)
	 myp.blue=isblue
	 
	 add(parts,myp)
 end
 
 for i=1,20 do
	 local myp={}
	 myp.x=expx
	 myp.y=expy
	 
	 myp.sx=(rnd()-0.5)*10
	 myp.sy=(rnd()-0.5)*10
	 
	 myp.age=rnd(2)
	 myp.size=1+rnd(4)
	 myp.maxage=10+rnd(10)
	 myp.blue=isblue
	 myp.spark=true
	 
	 add(parts,myp)
 end
 
 big_shwave(expx,expy)
 
end

function bigexplode(expx,expy)
 
 local myp={}
 myp.x=expx
 myp.y=expy
 
 myp.sx=0
 myp.sy=0
 
 myp.age=0
 myp.size=25
 myp.maxage=0
 
 add(parts,myp)
	  
 for i=1,60 do
	 local myp={}
	 myp.x=expx
	 myp.y=expy
	 
	 myp.sx=rnd()*12-6
	 myp.sy=rnd()*12-6
	 
	 myp.age=rnd(2)
	 myp.size=1+rnd(6)
	 myp.maxage=20+rnd(20)
	 
	 add(parts,myp)
 end
 
 for i=1,100 do
	 local myp={}
	 myp.x=expx
	 myp.y=expy
	 
	 myp.sx=(rnd()-0.5)*30
	 myp.sy=(rnd()-0.5)*30
	 
	 myp.age=rnd(2)
	 myp.size=1+rnd(4)
	 myp.maxage=20+rnd(20)
	 myp.spark=true
	 
	 add(parts,myp)
 end
 
 big_shwave(expx,expy)
 
end

function page_red(page)
 local col=7
 
 if page>5 then
  col=10
 end
 if page>7 then
  col=9
 end
 if page>10 then
  col=8
 end
 if page>12 then
  col=2
 end
 if page>15 then
  col=5
 end
 
 return col
end

function page_blue(page)
 local col=7
 
 if page>5 then
  col=6
 end
 if page>7 then
  col=12
 end
 if page>10 then
  col=13
 end
 if page>12 then
  col=1
 end
 if page>15 then
  col=1
 end
 
 return col
end

function smol_shwave(shx,shy,shcol)
 if shcol==nil then
  shcol=9
 end 
 local mysw={}
 mysw.x=shx
 mysw.y=shy
 mysw.r=3
 mysw.tr=6
 mysw.col=shcol
 mysw.speed=1
 add(shwaves,mysw)
end

function big_shwave(shx,shy)
 local mysw={}
 mysw.x=shx
 mysw.y=shy
 mysw.r=3
 mysw.tr=25
 mysw.col=7
 mysw.speed=3.5
 add(shwaves,mysw)
end

function smol_spark(sx,sy)
 --for i=1,2 do
 local myp={}
 myp.x=sx
 myp.y=sy
 
 myp.sx=(rnd()-0.5)*8
 myp.sy=(rnd()-1)*3
 
 myp.age=rnd(2)
 myp.size=1+rnd(4)
 myp.maxage=10+rnd(10)
 myp.blue=isblue
 myp.spark=true
 
 add(parts,myp)
 --end
end

function makespr()
 local myspr={}
 myspr.x=0
 myspr.y=0
 myspr.sx=0
 myspr.sy=0
 
 myspr.flash=0
 myspr.shake=0
 
 myspr.aniframe=1
 myspr.spr=0
 myspr.sprw=1
 myspr.sprh=1
 myspr.colw=8
 myspr.colh=8
 
 return myspr
end

function doshake()

 local shakex=rnd(shake)-(shake/2)
 local shakey=rnd(shake)-(shake/2)
 
 camera(shakex,shakey)
 
 if shake>10 then
  shake*=0.9
 else
  shake-=1
  if shake<1 then
   shake=0
  end
 end
end

function popfloat(fltxt,flx,fly)
 local fl={}
 fl.x=flx
 fl.y=fly
 fl.txt=fltxt
 fl.age=0
 add(floats,fl)
end

function cprint(txt,x,y,c)
 print(txt,x-#txt*2,y,c)
end


-->8
--update

function update_game()
 --controls
 ship.sx=0
 ship.sy=0
 ship.spr=2
 
 if btn(0) then
  ship.sx=-2
  ship.spr=1
 end
 if btn(1) then
  ship.sx=2
  ship.spr=3
 end
 if btn(2) then
  ship.sy=-2
 end
 if btn(3) then
  ship.sy=2
 end
  
 if btnp(4) then
  if cher>0 then
   cherbomb()
   cher=0
  else
   sfx(32)
  end
 end
 
 if btn(5) then
  if bultimer<=0 then
	  local newbul=makespr()
	  newbul.x=ship.x+1
	  newbul.y=ship.y-3
	  newbul.spr=16
	  newbul.colw=6
	  newbul.sy=-4
	  newbul.dmg=1
	  add(buls,newbul)
	  
	  sfx(0)
	  muzzle=5
	  bultimer=4
  end
 end
 bultimer-=1
 
 --moving the ship
 ship.x+=ship.sx
 ship.y+=ship.sy
 
 --checking if we hit the edge
 if ship.x>120 then
  ship.x=120
 end
 if ship.x<0 then
  ship.x=0
 end
 if ship.y<0 then
  ship.y=0
 end
 if ship.y>120 then
  ship.y=120
 end
 
 --move the bullets
 for mybul in all(buls) do
  move(mybul)
  if mybul.y<-8 then
   del(buls,mybul)
  end
 end
 
 --move the ebuls
 for myebul in all(ebuls) do
  move(myebul)
  animate(myebul)
  if myebul.y>128 or myebul.x<-8 or myebul.x>128 or myebul.y<-8 then
   del(ebuls,myebul)
  end
 end 
 
 --move the pickups
 for mypick in all(pickups) do
  move(mypick)
  if mypick.y>128 then
   del(pickups,mypick)
  end
 end 
 
 --moving enemies 
 for myen in all(enemies) do
  --enemy mission
  doenemy(myen)
  
  --enemy animation
  animate(myen)
    
  --enemy leaving screen
  if myen.mission!="flyin" then 
   if myen.y>128 or myen.x<-8 or myen.x>128 then
    del(enemies,myen)
   end
  end
 end
 
 --collision enemy x bullets
 for myen in all(enemies) do
  for mybul in all(buls) do
   if col(myen,mybul) then
    del(buls,mybul)
    smol_shwave(mybul.x+4,mybul.y+4)
    smol_spark(myen.x+4,myen.y+4)
    if myen.mission!="flyin" then
     myen.hp-=mybul.dmg
    end
    sfx(3)
    if myen.boss then
     myen.flash=5
    else
     myen.flash=2
    end
    if myen.hp<=0 then
     killen(myen)
    end
   end
  end
 end
 
 --collision ebuls x bullets
 for mybul in all(buls) do
  if mybul.spr==17 then
	  for myebul in all(ebuls) do
	   if col(myebul,mybul) then
	    del(ebuls,myebul)
	    score+=5
	    smol_shwave(ebuls.x,ebuls.y,8)
	   end
	  end
  end
 end
 
 --collision ship x enemies
 if invul<=0 then
	 for myen in all(enemies) do
	  if col(myen,ship) then
    explode(ship.x+4,ship.y+4,true)
	   lives-=1
	   sfx(1)
	   shake=12
	   invul=60
    ship.x=60
    ship.y=100
    flash=3
	  end
	 end
 else
  invul-=1
 end
 
 --collision ship x ebuls
 if invul<=0 then
	 for myebul in all(ebuls) do
	  if col(myebul,ship) then
    explode(ship.x+4,ship.y+4,true)
	   lives-=1
	   shake=12
	   sfx(1)
	   invul=60
    ship.x=60
    ship.y=100
    flash=3
	  end
	 end
 end
 
 --collision pickup x ship
 for mypick in all(pickups) do
  if col(mypick,ship) then
   del(pickups,mypick)
   plogic(mypick)
  end
 end
 
 
 if lives<=0 then
  mode="over"
  lockout=t+30
  music(6)
  return
 end
 
 --picking
 picktimer()
 
 --animate flame
 flamespr=flamespr+1
 if flamespr>9 then
  flamespr=5
 end
 
 --animate mullze flash
 if muzzle>0 then
  muzzle=muzzle-1
 end
  
 if mode=="wavetext" then
  animatestars(2)
 else
  animatestars()
 end
 
 --check if wave over
 if mode=="game" and #enemies==0 then
  ebuls={}
  nextwave()
 end
 
end

function update_start()
 animatestars(0.4)
 
 if btn(4)==false and btn(5)==false then
  btnreleased=true
 end

 if btnreleased then
  if btnp(4) or btnp(5) then
   startgame()
   btnreleased=false
  end
 end
end

function update_over()
 if t<lockout then
  return
 end
 
 if btn(4)==false and btn(5)==false then
  btnreleased=true
 end

 if btnreleased then
  if btnp(4) or btnp(5) then
   if score>highscore then
    highscore=score
    dset(0,score)
   end
   startscreen()
   btnreleased=false
  end
 end
end

function update_win()
 if t<lockout then
  return
 end
 
 if btn(4)==false and btn(5)==false then
  btnreleased=true
 end

 if btnreleased then
  if btnp(4) or btnp(5) then
   if score>highscore then
    highscore=score
    dset(0,score)
   end
   startscreen()
   btnreleased=false
  end
 end
end

function update_wavetext()
 update_game()
 wavetime-=1
 if wavetime<=0 then
  mode="game"
  spawnwave()
 end
end
-->8
-- draw

function draw_game()
 if flash>0 then
  flash-=1
  cls(2)
 else
  cls(0)
 end
 
 starfield()

 if lives>0 then
	 if invul<=0 then
	  drwmyspr(ship)
	  spr(flamespr,ship.x,ship.y+8)
	 else
	  --invul state
	  if sin(t/5)<0.1 then
	   drwmyspr(ship)
	   spr(flamespr,ship.x,ship.y+8)
	  end
	 end
 end
 
 --drawing pickups
 for mypick in all(pickups) do
  local mycol=7
  if t%4<2 then
   mycol=14
  end
  for i=1,15 do
   pal(i,mycol)
  end
  drwoutline(mypick)
  pal()
  drwmyspr(mypick)
 end
 
 --drawing enemies
 for myen in all(enemies) do
  if myen.flash>0 then
   if t%4<2 then
    pal(3,8)
    pal(11,14)
   end
   myen.flash-=1
   if myen.boss then
    myen.spr=80
   else
    for i=1,15 do
     pal(i,7)
    end
   end
  end
  drwmyspr(myen)
  pal()
 end
  
 --drawing bullets
 for mybul in all(buls) do
  drwmyspr(mybul)
 end
 
 if muzzle>0 then
  circfill(ship.x+3,ship.y-2,muzzle,7)
  circfill(ship.x+4,ship.y-2,muzzle,7)
 end
 
 --drawing shwaves
 for mysw in all(shwaves) do
  circ(mysw.x,mysw.y,mysw.r,mysw.col)
  mysw.r+=mysw.speed
  if mysw.r>mysw.tr then
   del(shwaves,mysw)
  end
 end
 
 --drawing particles
 for myp in all(parts) do
  local pc=7

  if myp.blue then
   pc=page_blue(myp.age)
  else
   pc=page_red(myp.age)
  end
  
  if myp.spark then
   pset(myp.x,myp.y,7)
  else
   circfill(myp.x,myp.y,myp.size,pc)
  end
  
  myp.x+=myp.sx
  myp.y+=myp.sy
  
  myp.sx=myp.sx*0.85
  myp.sy=myp.sy*0.85
  
  myp.age+=1
  
  if myp.age>myp.maxage then
   myp.size-=0.5
   if myp.size<0 then
    del(parts,myp)
   end
  end
 end
 
 --drawing ebuls
 for myebul in all(ebuls) do
  drwmyspr(myebul)
 end
 
 --floats
 for myfl in all(floats) do
  local mycol=7
  if t%4<2 then
   mycol=8
  end
  cprint(myfl.txt,myfl.x,myfl.y,mycol)
  myfl.y-=0.5
  myfl.age+=1
  if myfl.age>60 then
   del(floats,myfl)
  end
 end
 
 print("score:"..makescore(score),40,2,12)
 
 for i=1,4 do
  if lives>=i then
   spr(37,i*9-8,1)
  else
   spr(38,i*9-8,1)
  end 
 end

 spr(48,108,1)
 print(cher,118,2,14)
 
 --print(#buls,5,5,7)
end

function makescore(val)
 if val==0 then
  return "0"
 end
 return val.."00"
end

function draw_start()
 cls(0)
 starfield()
 print(version,1,1,1)

 spr(21,peekerx,28+sin(time()/3.5)*4 )
 if sin(time()/3.5)>0.5 then
  peekerx=30+rnd(60)
 end
   
 spr(212,17,30,12,2)
 cprint("short shwave shmup",64,45,6)
 
 if highscore>0 then
  cprint("highscore:",64,63,12)
  cprint(makescore(highscore),64,69,12)
 end

 cprint("press any key to start",64,90,blink())
 
 rectfill(0,115,128,128,1)
 cprint("learn how to make this game!",64,116,12)
 cprint("bit.ly/shmupme",64,122,12)
 
end

function draw_over()
 draw_game()
 cprint("game over",64,40,8) 
 
 cprint("score:"..makescore(score),64,60,12)
 if score>highscore then
  local c=7
  if t%4<2 then
   c=10
  end
  cprint("new highscore!",64,66,c) 
 end
 
 cprint("press any key to continue",64,90,blink())
end

function draw_win()
 draw_game()
 cprint("congratulations",64,40,12)
 cprint("score:"..makescore(score),64,60,12)

 if score>highscore then
  local c=7
  if t%4<2 then
   c=10
  end
  cprint("new highscore!",64,66,c) 
 end

 cprint("press any key to continue",64,90,blink())
end

function draw_wavetext()
 draw_game()
 if wave==lastwave then
  cprint("final wave!",64,40,blink())
 else
  cprint("wave "..wave.." of "..lastwave,64,40,blink())
 end
end
-->8
-- waves and enemies

function spawnwave()
 if wave<lastwave then
  sfx(28)
 else
  music(10)
 end
 
 if wave==1 then
  --space invaders
  attacfreq=60
  firefreq=20
  placens({
   {0,1,1,1,1,1,1,1,1,0},
   {0,1,1,1,1,1,1,1,1,0},
   {0,1,1,1,1,1,1,1,1,0},
   {0,1,1,1,1,1,1,1,1,0}
  })
 elseif wave==2 then
  --red tutorial
  attacfreq=60
  firefreq=20
  placens({
   {1,1,2,2,1,1,2,2,1,1},
   {1,1,2,2,1,1,2,2,1,1},
   {1,1,2,2,2,2,2,2,1,1},
   {1,1,2,2,2,2,2,2,1,1}
  })
 elseif wave==3 then
  --wall of red
  attacfreq=50
  firefreq=20
  placens({
   {1,1,2,2,1,1,2,2,1,1},
   {1,1,2,2,2,2,2,2,1,1},
   {2,2,2,2,2,2,2,2,2,2},
   {2,2,2,2,2,2,2,2,2,2}
  })
 elseif wave==4 then
  --spin tutorial
  attacfreq=50
  firefreq=15
  placens({
   {3,3,0,1,1,1,1,0,3,3},
   {3,3,0,1,1,1,1,0,3,3},
   {3,3,0,1,1,1,1,0,3,3},
   {3,3,0,1,1,1,1,0,3,3}
  })
 elseif wave==5 then
  --chess
  attacfreq=50
  firefreq=15
  placens({
   {3,1,3,1,2,2,1,3,1,3},
   {1,3,1,2,1,1,2,1,3,1},
   {3,1,3,1,2,2,1,3,1,3},
   {1,3,1,2,1,1,2,1,3,1}
  })
 elseif wave==6 then
  --yellow tutorial
  attacfreq=40
  firefreq=10
  placens({
   {2,2,2,0,4,0,0,2,2,2},
   {2,2,0,0,0,0,0,0,2,2},
   {1,1,0,1,1,1,1,0,1,1},
   {1,1,0,1,1,1,1,0,1,1}
  })
  
 elseif wave==7 then
  --double yellow
  attacfreq=40
  firefreq=10
  placens({
   {3,3,0,1,1,1,1,0,3,3},
   {4,0,0,2,2,2,2,0,4,0},
   {0,0,0,2,1,1,2,0,0,0},
   {1,1,0,1,1,1,1,0,1,1}
  })
 elseif wave==8 then
  --hell
  attacfreq=30
  firefreq=10
  placens({
   {0,0,1,1,1,1,1,1,0,0},
   {3,3,1,1,1,1,1,1,3,3},
   {3,3,2,2,2,2,2,2,3,3},
   {3,3,2,2,2,2,2,2,3,3}
  })
 elseif wave==9 then
  --boss
  attacfreq=60
  firefreq=20
  placens({
   {0,0,0,0,5,0,0,0,0,0},
   {0,0,0,0,0,0,0,0,0,0},
   {0,0,0,0,0,0,0,0,0,0},
   {0,0,0,0,0,0,0,0,0,0}
  })
 end  
end

function placens(lvl)

 for y=1,4 do
  local myline=lvl[y]
  for x=1,10 do
   if myline[x]!=0 then
    spawnen(myline[x],x*12-6,4+y*12,x*3)
   end
  end
 end
 
end

function nextwave()
 wave+=1
 
 if wave>lastwave then
  mode="win"
  lockout=t+30
  music(4)
 else
  if wave==1 then
   music(0)
  else
   music(3)  
  end
  
  mode="wavetext"
  wavetime=80
 end

end

function spawnen(entype,enx,eny,enwait)
 local myen=makespr()
 myen.x=enx*1.25-16
 myen.y=eny-66
 
 myen.posx=enx
 myen.posy=eny
 
 myen.type=entype
 
 myen.wait=enwait

 myen.anispd=0.4
 
 myen.mission="flyin"
 
 if entype==nil or entype==1 then
  -- green alien
  myen.spr=21
  myen.hp=3
  myen.ani={21,22,23,24}
  myen.score=1
 elseif entype==2 then
  -- red flame guy
  myen.spr=148
  myen.hp=2
  myen.ani={148,149}
  myen.score=2
 elseif entype==3 then
  -- spinning ship
  myen.spr=184
  myen.hp=4
  myen.ani={184,185,186,187}
  myen.score=3
 elseif entype==4 then
  -- yellow guy
  myen.spr=208
  myen.hp=20
  myen.ani={208,210}
  myen.sprw=2
  myen.sprh=2
  myen.colw=16
  myen.colh=16
  myen.score=5
 elseif entype==5 then
  myen.hp=130
  myen.spr=84
  myen.ani={84,88,92,88}
  myen.sprw=4
  myen.sprh=3
  myen.colw=32
  myen.colh=24
  
  myen.x=48
  myen.y=-24
  myen.posx=48
  myen.posy=25
  
  myen.boss=true
 end
  
 add(enemies,myen)
end
-->8
--behavior

function doenemy(myen)
 if myen.wait>0 then
  myen.wait-=1
  return
 end
 
 --debug=myen.hp
 
 if myen.mission=="flyin" then
  --flying in
  --basic easing function
  --x+=(targetx-x)/n
  
  local dx=(myen.posx-myen.x)/7
  local dy=(myen.posy-myen.y)/7
  
  if myen.boss then
   dy=min(dy,1)
  end
  myen.x+=dx
  myen.y+=dy
  
  if abs(myen.y-myen.posy)<0.7 then
   myen.y=myen.posy
   myen.x=myen.posx
   if myen.boss then
    sfx(50)
    myen.shake=20
    myen.wait=28
    myen.mission="boss1"
    myen.phbegin=t
   else
    myen.mission="protec"
   end
  end
  
 elseif myen.mission=="protec" then
  -- staying put
 elseif myen.mission=="boss1" then
  boss1(myen)
 elseif myen.mission=="boss2" then
  boss2(myen)
 elseif myen.mission=="boss3" then
  boss3(myen)
 elseif myen.mission=="boss4" then
  boss4(myen)
 elseif myen.mission=="boss5" then
  boss5(myen)
 elseif myen.mission=="attac" then  
  -- attac
  if myen.type==1 then
   --green guy
   myen.sy=1.7
   myen.sx=sin(t/45)
   
   -- just tweaks
   if myen.x<32 then
    myen.sx+=1-(myen.x/32)
   end
   if myen.x>88 then
    myen.sx-=(myen.x-88)/32
   end
  elseif myen.type==2 then
   --red guy
   myen.sy=2.5
   myen.sx=sin(t/20)
   
   -- just tweaks
   if myen.x<32 then
    myen.sx+=1-(myen.x/32)
   end
   if myen.x>88 then
    myen.sx-=(myen.x-88)/32
   end   
   
  elseif myen.type==3 then
   --spinny ship
   if myen.sx==0 then
    --flying down
    myen.sy=2
    if ship.y<=myen.y then
     myen.sy=0
     if ship.x<myen.x then
      myen.sx=-2
     else
      myen.sx=2
     end
    end
   end
   
  elseif myen.type==4 then
   --yellow ship
   myen.sy=0.35
   if myen.y>110 then
    myen.sy=1
   else
    
    if t%25==0 then
     firespread(myen,8,1.3,rnd())
    end
   end   
  end
  
  move(myen)
 end
  
end

function picktimer()
 if mode!="game" then
  return
 end

 if t>nextfire then
  pickfire()
  nextfire=t+firefreq+rnd(firefreq)
 end
 
 if t%attacfreq==0 then
  pickattac()
 end
end

function pickattac()
 local maxnum=min(10,#enemies)
 local myindex=flr(rnd(maxnum))
 
 myindex=#enemies-myindex
 local myen=enemies[myindex]
 if myen==nil then return end
 
 if myen.mission=="protec" then
  myen.mission="attac"
  myen.anispd*=3
  myen.wait=60
  myen.shake=60
 end
end

function pickfire()
 local maxnum=min(10,#enemies)
 local myindex=flr(rnd(maxnum))
 
 for myen in all(enemies) do
  if myen.type==4 and myen.mission=="protec" then
   if rnd()<0.5 then
    firespread(myen,12,1.3,rnd())
    return
   end
  end
 end
 
 myindex=#enemies-myindex
 local myen=enemies[myindex]
 if myen==nil then return end
 
 if myen.mission=="protec" then
  if myen.type==4 then
   --yellow guy
   firespread(myen,12,1.3,rnd())
  elseif myen.type==2 then
   --red guy
   aimedfire(myen,2)
  else
   fire(myen,0,2)
  end
 end
end


function move(obj)
 obj.x+=obj.sx
 obj.y+=obj.sy
end

function killen(myen)
 if myen.boss then
  myen.mission="boss5"
  myen.phbegin=t
  myen.ghost=true
  ebuls={}
  music(-1)
  sfx(51)
  return
 end

 del(enemies,myen)   
 sfx(2)
 

 explode(myen.x+4,myen.y+4)
 local cherchance=0.1
 local scoremult=1
 
 if myen.mission=="attac" then
  scoremult=2
  if rnd()<0.5 then
   pickattac()
  end
  cherchance=0.2
 end
 
 score+=myen.score*scoremult
 if scoremult!=1 then
  popfloat(makescore(myen.score*scoremult),myen.x+4,myen.y+4)
 end
 
 if rnd()<cherchance then
  dropickup(myen.x,myen.y)
 end
end

function dropickup(pix,piy)
 local mypick=makespr()
 mypick.x=pix
 mypick.y=piy
 mypick.sy=0.75
 mypick.spr=48
 add(pickups,mypick)
end

function plogic(mypick)
 cher+=1
 smol_shwave(mypick.x+4,mypick.y+4,14)
 if cher>=10 then
  --get a life
  if lives<4 then
   lives+=1
   sfx(31)
   cher=0
   popfloat("1up!",mypick.x+4,mypick.y+4)
  else
   --points
   score+=50
   popfloat(makescore(50),mypick.x+4,mypick.y+4)
   sfx(30)
   cher=0
  end
 else
  sfx(30)
 end
end

function animate(myen)
 myen.aniframe+=myen.anispd
 if flr(myen.aniframe) > #myen.ani then
  myen.aniframe=1
 end
 myen.spr=myen.ani[flr(myen.aniframe)]
end
-->8
--bullets

function fire(myen,ang,spd)
 local myebul=makespr()
 myebul.x=myen.x+3
 myebul.y=myen.y+6
 
 if myen.type==4 then
  myebul.x=myen.x+7
  myebul.y=myen.y+13
 elseif myen.boss then
  myebul.x=myen.x+15
  myebul.y=myen.y+23 
 end
 
 myebul.spr=32
 myebul.ani={32,33,34,33}
 myebul.anispd=0.5
 
 myebul.sx=sin(ang)*spd
 myebul.sy=cos(ang)*spd
 
 myebul.colw=2
 myebul.colh=2
 myebul.bulmode=true
 
 if myen.boss!=true then
  myen.flash=4
  sfx(29)
 else
  sfx(34)
 end
 
 add(ebuls,myebul)
 
 return myebul
end

function firespread(myen,num,spd,base)
 if base==nil then
  base=0
 end
 for i=1,num do
  fire(myen,1/num*i+base,spd)
 end
end

function aimedfire(myen,spd)
 local myebul=fire(myen,0,spd)
 
 local ang=atan2((ship.y+4)-myebul.y,(ship.x+4)-myebul.x)

 myebul.sx=sin(ang)*spd
 myebul.sy=cos(ang)*spd 
end

function cherbomb()
 local spc=0.25/(cher*2)
 
 for i=0,cher*2 do
  local ang=0.375+spc*i
  
  local newbul=makespr()
  newbul.x=ship.x
  newbul.y=ship.y-3
  newbul.spr=17
  newbul.dmg=3
  
  newbul.sx=sin(ang)*4
  newbul.sy=cos(ang)*4
 
  add(buls,newbul)
 end
 
 big_shwave(ship.x+3,ship.y+3)
 shake=5
 muzzle=5
 invul=30
 flash=3
 sfx(33)
 
end
-->8
--boss

function boss1(myen)
 -- movement
 local spd=2
 
 if myen.sx==0 or myen.x>=93 then
  myen.sx=-spd
 end
 if myen.x<=3 then
  myen.sx=spd
 end
 -- shooting
 if t%30>3 then
  if t%3==0 then
   fire(myen,0,2)
  end
 end
 
 -- transition
 if myen.phbegin+8*30<t then
  myen.mission="boss2"
  myen.phbegin=t
  myen.subphase=1
 end
 move(myen)
end

function boss2(myen)
 local spd=1.5
 
 -- movement
 if myen.subphase==1 then
  myen.sx=-spd
  if myen.x<=4 then
   myen.subphase=2
  end
 elseif myen.subphase==2 then
  myen.sx=0
  myen.sy=spd
  if myen.y>=100 then
   myen.subphase=3
  end 
 elseif myen.subphase==3 then
  myen.sx=spd
  myen.sy=0
  if myen.x>=91 then
   myen.subphase=4
  end  
 elseif myen.subphase==4 then
  myen.sx=0
  myen.sy=-spd
  if myen.y<=25 then
   -- transition
   myen.mission="boss3"
   myen.phbegin=t
   myen.sy=0
  end  
 end 
 -- shooting
 if t%15==0 then
  aimedfire(myen,spd)
 end

 move(myen)
end

function boss3(myen)
 -- movement
 local spd=0.5
 
 if myen.sx==0 or myen.x>=93 then
  myen.sx=-spd
 end
 if myen.x<=3 then
  myen.sx=spd
 end

 -- shooting
 if t%10==0 then
  firespread(myen,8,2,time()/2)
 end 
 
 -- transition
 if myen.phbegin+8*30<t then
  myen.mission="boss4"
  myen.subphase=1
  myen.phbegin=t
 end
 move(myen)
end

function boss4(myen)
 local spd=1.5
 
 -- movement
 if myen.subphase==1 then
  myen.sx=spd
  if myen.x>=91 then
   myen.subphase=2
  end
 elseif myen.subphase==2 then
  myen.sx=0
  myen.sy=spd
  if myen.y>=100 then
   myen.subphase=3
  end 
 elseif myen.subphase==3 then
  myen.sx=-spd
  myen.sy=0
  if myen.x<=4 then
   myen.subphase=4
  end  
 elseif myen.subphase==4 then
  myen.sx=0
  myen.sy=-spd
  if myen.y<=25 then
   -- transition
   myen.mission="boss1"
   myen.phbegin=t
   myen.sy=0
  end  
 end 

 -- shooting
 if t%12==0 then
  if myen.subphase==1 then
   fire(myen,0,2)
  elseif myen.subphase==2 then
   fire(myen,0.25,2)
  elseif myen.subphase==3 then
   fire(myen,0.5,2)
  elseif myen.subphase==4 then
   fire(myen,0.75,2)
  end
 end
 -- transition
 move(myen)
end

function boss5(myen)
 myen.shake=10
 myen.flash=10 
 
 if t%8==0 then
  explode(myen.x+rnd(32),myen.y+rnd(24))
  sfx(2)
  shake=2
 end

 if myen.phbegin+3*30<t then
	 if t%4==2 then
	  explode(myen.x+rnd(32),myen.y+rnd(24))
	  sfx(2)
   shake=2
	 end
 end

 if myen.phbegin+6*30<t then
  flash=3
  score+=100
  popfloat(makescore(100),myen.x+16,myen.y+6)
  bigexplode(myen.x+16,myen.y+12)
  shake=15
  enemies={}
  sfx(35)
 end
end