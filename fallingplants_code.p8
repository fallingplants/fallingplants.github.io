intro=true
introwipe=20

minx=8
maxx=136

rain=false
wet=false

carbon=0
carbonremoved=0
function updateintro()
    if intro and btnp(5) then
        intro=false
        carbon=0
    end
    if not intro and introwipe>0 then
        introwipe-=1
    end
end


grass={}
function hitgrass(mx,my,m)
    local grasstime=6
    for g in all(grass) do
     if g.x==mx and g.y==my then
            g.t=grasstime
            return
        end
    end
   
    if not fget(m,1) then
        return
    end
   
    local g={}
    g.x=mx
    g.y=my
    g.o=m
    g.t=grasstime
    mset(mx,my,49)
    add(grass, g)
end

function hitworld(x,y)
    local mx=flr(x/8)
    local my=flr(y/8)
    local m=mget(mx,my)
   
    hitgrass(mx,my,m)
end


function animworld()
    for g in all(grass) do
        g.t-=1
        if g.t<=0 then
            mset(g.x,g.y,g.o)
            del(grass,g)
        end
    end
   
    for p in all(puffs) do
        p.t+=1
        if p.t>=8 then
            del(puffs,p)
        end
    end
end

function newgrrl()
 local g={}
 g.x=64 g.y=73
 g.vx=0
 g.ax=0.35 g.acx=-0.5
 g.maxvx=4
    g.flipx=false
 g.s0=6
 g.srs=7 g.sre=9 g.srt=2
 g.s=g.s0 g.st=0
 g.laststp=g.x
    g.skid=false
    g.held=nil
 return g
end

function movegrrl(g)
    local wacs=1
    local wbs=1
    local waxs=1
    if wet then
        wacs=0
        wbs=1.1
        waxs=0.5
    end
   
    if btn(0) then
        if (g.vx>0) g.vx+=g.acx*wacs
        g.vx-=g.ax*waxs
    elseif btn(1) then
        if (g.vx<0) g.vx-=g.acx*wacs
        g.vx+=g.ax*waxs
    else
        g.vx*=0.85*wbs
        if (abs(g.vx)<0.5) g.vx=0
    end
   
    g.vx=clmp(g.vx,-g.maxvx,g.maxvx)
   
    g.x+=g.vx
    if g.x<minx-2 then
        g.vx=0 g.x=minx-2
    elseif g.x>maxx-6 then
        g.vx=0 g.x=maxx-6
    end
end

function animgrrl(g)
    if g.vx==0 then
        g.s=g.s0
    elseif g.s==g.s0 then
        g.s=g.srs
        g.st=g.srt
    else --todo: distance-based
        g.st-=1
        if g.st<=0 then
            g.s+=1
            g.st=g.srt
            if g.s>g.sre then
                g.s=g.srs
            end
        end
    end
   
    if btn(1) then
        g.flipx=false
    elseif btn(0) then
        g.flipx=true
    end
   
    g.skid=false
    if ((g.flipx==true and g.vx>0) or
        (g.flipx==false and g.vx<0)) then
        g.skid=true
    end
end

function sfxgrrl(g)
    if abs(g.x-g.laststp)>4 then
        sfx(0,0)
        g.laststp=g.x
    end
    if g.skid then
     sfx(1,1)
     local c=6+flr(rnd(1)+0.7)
     if (wet) c=4
     startpuff(g.x+4*sgn(g.vx),g.y,not g.flipx,c)
    end
end

function updategrrl(g)
    if g.held != nil then
        plantgrrl(g)
    end

    movegrrl(g)
    animgrrl(g)
    sfxgrrl(g)
   
    if g.vx!=0 and g.vy!=0 then
        hitworld(g.x+4,g.y+9)
    end   
end

function drawgrrl(g)
    local s=g.s
    if (g.skid) s=10
    spr(s, g.x,g.y, 1,1, g.flipx)
end

jg=newgrrl()



tweet=100
wasmoist=false
function updateambience()
    local moist=rain
    if wasmoist and not moist then
        sfx(6,3)
    elseif moist and not wasmoist then
        sfx(7,3)
    end
    wasmoist=moist
         
    if not moist then
        tweet-=1
        if tweet<=0 then
            tweet=120+flr(rnd(200))
            local t=pick({8,9})
            sfx(t,3)  
        end
    end
end


function updatedebug()
    if btnp(4) then
        for p in all(plants) do
            p.sz=min(p.sz+1,max_sz)
        end
    end
    if btnp(5) then
        for p in all(plants) do
            p.sz=max(p.sz-1,0)
        end
    end
end 

tix = 0
function _update()
 carbon+=.35
 
    updateintro()

    updateweather()
   
    updategrrl(jg)
    animworld()
    updatepots()
    catchpots(jg)
    updatecam(cam)
   
    updateclouds()
    updatebirds()
    updateambience()
    updatedrips()
   
    --updatedebug()
end


function _draw()
    local skyc=12
    if (rain or rainvsoon) skyc=1
    rectfill(0,0,144,144,skyc)

    camera(cam.x+cam.shx*0.5,
           cam.y+cam.shy*0.5)

    drawdrips()
    setcloudpal()
    map(22,0,-cloudx,0,cloudw,8,0x80)
    map(22,0,(cloudw*8)-cloudx,0,cloudw,8,0x80)
    drawbirds()
    setcloudpal()
    map(22,0,-cloudx,0,cloudw,8,0x40)
    map(22,0,(cloudw*8)-cloudx,0,cloudw,8,0x40)
    pal()
    map(24,9,-8,rcloudy-6,20,2)
   
    camera(cam.x+cam.shx,
           cam.y+cam.shy)
   
    if intro or introwipe>0 then
        map(24,14,-8,65,20,2)
        if not intro then
            local blankh=rmap(introwipe,20,0,0,16)
            rectfill(-8,65,140,65+blankh,12)
        end
    end
   
    -- plants behind world so they can shrink
    drawplants()
   
    map(0,0,0,0,20,20)
    foreach(puffs, drawpuff)

    drawgrrl(jg)
    drawpots()
    print(flr(carbon),12,8,8)
    print("carbon removed:"..carbonremoved,12,14,7)
   
    if intro or introwipe>0 then
        spr(83,50,30,6,4)
        map(24,20,45,86,8,3)
        spr(106,54,110)
        print("- plant",62,110,15)
        spr(107,54,117)
        print("- start",62,117,15)
       
        local wipey=rmap(introwipe,20,0,130,88)
        map(0,11,0,wipey,20,9)
    end
end



function pick(list)
    local i=flr(1+rnd(#list))
    return list[i]
end 
-->8
--camera stuff
function newcam()
    local c={}
    c.x=8 c.y=0
    c.shx=0 c.shy=0
    c.sht=-1
    c.shmaxt=8
    c.shspd=4
    c.shang=0 c.shstr=0
    return c
end
cam=newcam()

function updatecam(c)
    if (c.sht<0) return
   
    c.sht+=1
    if c.sht>=c.shmaxt then
        c.sht=-1
        c.shstr=0
        c.shx=0 c.shy=0
        return
    end
   
    local t=c.shspd*rmap(c.sht,0,c.shmaxt,1,0)
    local s=cos(t)
    c.shy=c.shstr*s
end

function shake(ang,str)
    cam.sht=0
    cam.shstr=str
    cam.shang=ang
end

function pull(x)
    cam.shx+=x
end

-->8
--drips
drips={}
lastdripx=40
function newdrip(x)
    local d={}
    d.x=x d.y=-8
    return d
end

function updatedrips()
    wet=false
    for d in all(drips) do
        d.x-=1 d.y+=2
        if d.y>=jg.y+11 then
            del(drips,d)
            wet=true
            -- todo: splash
        end
    end
   
    if rain then
        for i=0,1 do
            lastdripx=(lastdripx+10)%170
            add(drips,newdrip(lastdripx))
        end
    end
end

function drawdrips()
    for d in all(drips) do
        spr(22,d.x,d.y)
    end
end
-->8
-- puffs
puffs={}
function startpuff(x,y,flp,c)
    local p={}
    p.x=x p.y=y p.f=flp p.c=c
    p.t=0
    add(puffs,p)
end

function startdirtpuff(x,y)
    startpuff(x+1,y-2,false,4)
    startpuff(x-1,y-1,true,4)
end

function drawpuff(p)
    pal(7,p.c)
    spr(38+p.t/2, p.x,p.y, 1,1, p.f)
    pal()
end
-->8
--map stuff
function clmp(v,n,x)
    return max(min(v,x),n)
end

function rmap(v,on,ox,nn,nx)
    local orng=ox-on
    local nrng=nx-nn
    local nv=(((v-on)/orng)*nrng)+nn
    return clmp(nv,
                   min(nn,nx),
                   max(nn,nx))
end
-->8
--clouds and weather
function setcloudpal()
 if(not rain) return
 pal(7,13)
 pal(6,5)
end

cloudx=0
cloudw=44
rcloudy=-15
function updateclouds()
 cloudx+=0.125
 if cloudx>cloudw*8 then
  cloudx-=cloudw*8
 end
 
 if rain or rainsoon then
  rcloudy=min(2,rcloudy+0.4)
 else
  rcloudy=max(-15,rcloudy-0.5)
 end
end 


weathertime=1000+flr(rnd(500))
rainsoon=false
rainvsoon=false
function updateweather()
 if not intro and introwipe<=0 then
  weathertime-=1
 end
 
 rainsoon=false
 rainvsoon=false
 if weathertime<=0 then
  local mint=1000
  rain=not rain 
  if(rain) then
   weathertime =300+flr(rnd(450))
  else
   weathertime=1000+flr(rnd(500))
  end
 end
 
 if not rain then
  if weathertime<80 then
   rainsoon=true
  end
  if weathertime<30 then
   rainvsoon=true
  end  
 end
end
-->8
--birds
birds={}
function newbird()
    local b={}
    b.f=(rnd(1)>0.5)
    b.x=-3 b.y=8+flr(rnd(18))
    b.vx=0.4+rnd(0.4)
    if b.f then
        b.x=130
        b.vx = -b.vx
    end
   
    b.s=flr(rnd(1)+0.5)
    b.st=pick({3,4})
 b.t=b.st
    return b
end

ttnb=10
function updatebirds()
    for b in all(birds) do
        b.x+=b.vx
        if b.x>135 or b.x<-8 then
            del(birds,b)
        end
        b.t-=1
        if b.t<=0 then
            b.t=b.st
            b.s=1-b.s
        end
    end
   
    ttnb-=1
    if ttnb<=0 then
        ttnb=40+flr(rnd(80))
        add(birds,newbird())
    end
end

function drawbirds()
    palt(1,true)
    palt(0,false)
    if (rain) pal(13,0)
       
    for b in all(birds) do
        spr(51+b.s,b.x,b.y,1,1,b.f)
    end
    palt()
    pal()
end
-->8
--plants and pots
pots={}
plants={}
plant_type={12,73,89,125}
p_fall=0 p_dead=1 p_held=2
p_thrw=3 p_grow=4
p_cols= {7,8,10,2,13, 9,14}
p_hcols={9,5, 4,9, 7,10, 2}
p_hcols={9,5, 4,9, 7,10, 2}
max_sz=38
lastfast=0
spnum = 0

function pick_plant()
num=rnd(plant_type)
return num
end

function newpot()
    local p={}
    p.x=14+flr(rnd(54)+rnd(54))
    p.y=-4
    if rnd(25)<lastfast then
        p.vy=2
        lastfast=0
    else
        p.vy=1
        lastfast+=1
    end
    p.s=pick_plant()
    p.picked=p.s
    spnum=p.s
    if spnum == 12 then
                p.planted=44
    elseif spnum == 73 then
             p.planted=78
    elseif spnum == 89 then
             p.planted=94
    elseif spnum == 125 then
                p.planted=110
    end
    local d=rmap(#plants,0,45,1,#p_cols)
    local ic=1+flr(rnd(d))
    p.c=p_cols[ic]
    p.hc=p_hcols[ic]
    p.f=false
    p.sz=0
    if (rnd(2)>1) p.f=true
    p.stt=p_fall
    return p
end



function next_ttp()
    return 22+flr(rnd(60))
end

function onsmashed(p)
    sfx(5,2)
    shake(0,abs(p.vy)*0.8)
    startdirtpuff(p.x,p.y)
           
    p.y=jg.y
    p.vy=0
    p.stt=p_dead
    p.picked=28//+flr(rnd(1)+0.5)
   
    -- decay nearby smashed pots
    for n in all(pots) do
        if n.stt==p_dead and n!=p then
            if abs(n.x-p.x)<5 then
                n.s+=1
                if n.s>29 then
                    del(pots,n)
                end   
            end
        end
    end
   
    -- damage nearby plants
    for n in all(plants) do
        if abs(n.x-p.x)<5 then
            if wet then
                n.sz-=2
            else
                n.sz-=0.5
            end
            if n.sz<-2 then
                del(plants,n)
            end
        end
    end
end


ttp=next_ttp()
plantnum=0
function updatepots()
    if not intro and introwipe<=0 then
        ttp-=1
    end
    if ttp<0 then
        add(pots,newpot())
        ttp=next_ttp()
        if (rain) ttp+=15
    end
        plantnum = spnum
        for p in all(pots) do
            if p.stt==p_held then
             p.x=jg.x
             p.y=jg.y-3
             //picked = spnum
             //if plantnum % 100 == 70
             //p.s=plantnum
             //p.s=rnd(plant_type)
         elseif p.stt==p_fall then
                p.y+=p.vy
                //p.s=plantnum+flr(rnd(3))
                if p.y>=jg.y then
                    onsmashed(p)
                end
            end
        end

    if wet then
        for p in all(plants) do
            //if p.sz<max_sz then
                //p.sz+=rnd(0.003)
            //end
        end
    end
end

function findnearplant(p)
    for n in all(plants) do
        if n.c==p.c and
           n.sz<max_sz and
           abs(n.x-p.x)<3 then
         return n
        end
    end
   
    return nil
end

function overlaps_pg(p,g)
    if((p.y+8<g.y+1) or
             (p.y+1>g.y+8)) then
        return false
    end
             
    local mingx=g.x+1
    local maxgx=g.x+7
    if not wet then
        if g.skid then
            mingx-=3
            maxgx+=3
        elseif abs(g.vx>g.maxvx*0.75) then
            mingx-=2
            maxgx+=2
        end
    end
   
    if((p.x+7<mingx) or
             (p.x+1>maxgx)) then
        return false
    end
   
    return true
end

function catchpots(g)
    if g.held != nil then
        return
    end
     
    for p in all(pots) do
        if p.stt==p_fall and
                 overlaps_pg(p,g) then
            sfx(3,2)
            g.held=p
            p.stt=p_held
            break
        end
    end
end

function drawpots()
    for p in all(pots) do
     pal(7,p.c)
     pal(9,p.hc)
        spr(p.picked+flr(rnd(3)),p.x,p.y,1,1,p.f)
        --print(p.s) p.s
    end
    pal()
end

branchstrt=12

--function drawbranches(p,sz)
    --local bsz=p.sz-branchstrt
    --bsz=min(bsz,7)
    --local bs=flr(bsz/2)
    --local bx=3+(bsz%2)
    --local f=band(p.x,1)==0
    --if (f) bx=-bx
    --local by=(p.x%6)-sz
    --local bw=1
    --if (bs>3) bw=2
    --spr(bs+65,p.x+bx,p.y+by+4,bw,1,f)
--end

function need_pick()
    if plantnum <= 14 then
        return 1
    elseif plantnum <= 91 then
     return 2
    elseif plantnum<= 75 then
     return 3
    elseif plantnum<= 127 then
  return 4
 end
end

function drawplants()
 
    for p in all(plants) do
     pal(8,p.c)
     pal(9,p.hc)
     if p.sz<1 then
         spr(p.planted,p.x,p.y-p.sz,1,1,p.f)
        --else   
            --local sz=min(24,p.sz)
            --if (p.sz>branchstrt)    drawbranches(p,sz)
            --spr(15,p.x,p.y-sz+2,1,4,p.f)
        end
    end
    pal()
end

function plantgrrl(g)
    if (not btnp(3)) return
    --takes away carbon
    carbon-=20
    carbonremoved+=20
    sfx(4,1)
    local p=g.held
    g.held=nil
   
    g.vx*=0.3
   
    -- are we planting a new plant?
    local n=findnearplant(p)
    if n==nil then
        p.stt=p_grow
        p.s=44
        p.y=g.y+pick({-1,0,1})
        add(plants,p)
    else
        //n.sz+=1
    end
   
    del(pots,p)
end
