-- Original native Sentry beetle and first Survivors kit.
-- Drawn with Aseprite Lua pixel primitives. No raster art import or Pillow art.
local out=app.params['out']
assert(out,'Supply --script-param out=...')
local palette={outline='#14161f',foot='#282e3e',footLight='#465062',redDark='#722938',red='#b63c49',redLight='#f06c58',pink='#f7a37b',lime='#aec05a',limeLight='#d6f26c',cream='#ffebba',ground='#26312b',ground2='#2a352e',ground3='#303a31'}
local function px(c) local v=Color{r=tonumber(c:sub(2,3),16),g=tonumber(c:sub(4,5),16),b=tonumber(c:sub(6,7),16),a=255};return app.pixelColor.rgba(v.red,v.green,v.blue,255) end
local colors={} for k,v in pairs(palette)do colors[k]=px(v)end
local function rect(im,x,y,w,h,c)for yy=y,y+h-1 do for xx=x,x+w-1 do im:drawPixel(xx,yy,colors[c])end end end
local function line(im,x1,y1,x2,y2,c)
 local dx=math.abs(x2-x1);local sx=x1<x2 and 1 or -1;local dy=-math.abs(y2-y1);local sy=y1<y2 and 1 or -1;local err=dx+dy
 while true do if x1>=0 and y1>=0 and x1<im.width and y1<im.height then im:drawPixel(x1,y1,colors[c])end;if x1==x2 and y1==y2 then break end;local e=2*err;if e>=dy then err=err+dy;x1=x1+sx end;if e<=dx then err=err+dx;y1=y1+sy end end
end
local function rounded(im,x,y,w,h,c)
 rect(im,x+3,y,w-6,h,c);rect(im,x+1,y+2,w-2,h-4,c);rect(im,x,y+4,w,h-8,c)
end
local function newSprite(w,h,names)
 local s=Sprite(w,h,ColorMode.RGB);s.layers[1].name=names[1];local layers={s.layers[1]};for i=2,#names do local l=s:newLayer();l.name=names[i];layers[i]=l end;return s,layers
end
local function cel(s,l,f,im)s:newCel(l,f,im,Point(0,0))end
local function tag(s,n,a,b)local t=s:newTag(a,b);t.name=n;t.aniDir=AniDir.FORWARD;t.color=Color{r=174,g=192,b=90};return t end
local s,l=newSprite(64,64,{'Feet and claws','Shell and outline','Eyes and antenna'})
for f=1,4 do
 if f>1 then s:newEmptyFrame()end;s.frames[f].duration=.240
 local feet=Image(64,64,ColorMode.RGB)
 local shell=Image(64,64,ColorMode.RGB)
 local face=Image(64,64,ColorMode.RGB)
 local rise=({0,-1,0,-1})[f]
 local left=({-2,-1,2,1})[f];local right=-left
 -- A foot's planted sole stays at y=59. Passing foot rises two pixels.
 local liftL= f==3 and 2 or 0;local liftR=f==1 and 2 or 0
 rounded(feet,17+left,48-liftL,11,12,'outline');rounded(feet,36+right,48-liftR,11,12,'outline')
 rect(feet,19+left,50-liftL,7,8,'foot');rect(feet,38+right,50-liftR,7,8,'foot')
 rect(feet,18+left,56-liftL,8,2,'footLight');rect(feet,38+right,56-liftR,8,2,'footLight')
 line(feet,13,43+rise,8,48+rise,'outline');line(feet,8,48+rise,11,51+rise,'outline')
 line(feet,50,43+rise,55,48+rise,'outline');line(feet,55,48+rise,52,51+rise,'outline')
 -- Shell stays centered at x=31.5. All four frames retain the same body design.
 rounded(shell,12,24+rise,40,31,'outline')
 rounded(shell,14,26+rise,36,27,'redDark')
 rounded(shell,14,26+rise,36,21,'red')
 rect(shell,17,27+rise,24,3,'redLight');rect(shell,15,31+rise,5,8,'redLight')
 rect(shell,19,28+rise,12,1,'pink')
 rect(shell,31,28+rise,2,24,'redDark')
 rect(shell,17,48+rise,12,3,'redDark');rect(shell,35,48+rise,12,3,'redDark')
 rect(shell,18,51+rise,28,1,'outline')
 -- One antenna. Two lime eyes. No face or original hero pixels are sampled.
 rect(face,31,18+rise,2,7,'outline');rect(face,29,16+rise,6,3,'outline');rect(face,30,17+rise,4,1,'lime')
 rounded(face,19,34+rise,10,10,'outline');rounded(face,35,34+rise,10,10,'outline')
 rect(face,21,36+rise,6,6,'lime');rect(face,37,36+rise,6,6,'lime')
 rect(face,21,36+rise,4,2,'limeLight');rect(face,37,36+rise,4,2,'limeLight')
 rect(face,24,39+rise,2,3,'outline');rect(face,38,39+rise,2,3,'outline')
 cel(s,l[1],f,feet);cel(s,l[2],f,shell);cel(s,l[3],f,face)
end
tag(s,'walk_front',1,4);s:saveAs(out..'/sentry-beetle.aseprite')
-- Ground stays low contrast. Edge pixels use the same base color for tiling.
local g,gl=newSprite(64,64,{'Quiet ground base','Sparse ground marks'});local base=Image(64,64,ColorMode.RGB);rect(base,0,0,64,64,'ground');cel(g,gl[1],1,base)
local marks=Image(64,64,ColorMode.RGB)
for _,p in ipairs({{7,12,5},{39,9,4},{20,34,6},{49,43,4},{10,51,3},{37,55,5}})do rect(marks,p[1],p[2],p[3],1,'ground2');rect(marks,p[1]+1,p[2]+1,p[3]-2,1,'ground3')end
cel(g,gl[2],1,marks);tag(g,'ground',1,1);g:saveAs(out..'/ground.aseprite')
-- Five independent 32 px icons. Each icon has its own frame and tag.
local ic,il=newSprite(32,32,{'Icon outline','Icon fill and highlight'})
local function diamond(im,x,y,r,c)for yy=-r,r do local w=r-math.abs(yy);rect(im,x-w,y+yy,2*w+1,1,c)end end
for f=1,5 do
 if f>1 then ic:newEmptyFrame()end;ic.frames[f].duration=.240
 local a=Image(32,32,ColorMode.RGB);local b=Image(32,32,ColorMode.RGB)
 if f==1 then -- projectile travels right
  rounded(a,6,12,20,8,'outline');rect(b,8,14,15,4,'lime');rect(b,11,14,13,2,'cream');rect(b,5,15,3,2,'limeLight')
 elseif f==2 then
  diamond(a,16,16,9,'outline');diamond(b,16,16,7,'lime');line(b,16,10,12,16,'limeLight');line(b,12,16,16,22,'limeLight');line(b,18,14,18,19,'cream')
 elseif f==3 then -- power / energy bolt
  for _,seg in ipairs({{17,5,10,16},{10,16,17,16},{17,16,12,27},{12,27,23,13},{23,13,17,13},{17,13,20,5}})do line(a,seg[1],seg[2],seg[3],seg[4],'outline')end
  for y=7,14 do rect(b,15-math.floor((y-7)/2),y,5,1,'redLight')end
  for y=15,23 do rect(b,15,y,5-math.floor((y-15)/3),1,'red');end
  line(b,18,8,14,15,'cream')
 elseif f==4 then -- reach / target
  rounded(a,5,5,22,22,'outline');rounded(b,7,7,18,18,'footLight');rounded(b,9,9,14,14,'outline');diamond(b,16,16,4,'limeLight');rect(b,15,2,2,8,'cream');rect(b,15,22,2,8,'cream');rect(b,2,15,8,2,'cream');rect(b,22,15,8,2,'cream')
 else -- speed / two chevrons
  for _,x in ipairs({7,15})do for y=6,25 do local off=math.floor(math.min(y-6,25-y)/2);rect(a,x+off,y,6,1,'outline');rect(b,x+off+1,y,3,1,'limeLight')end end
 end
 cel(ic,il[1],f,a);cel(ic,il[2],f,b)
end
for f,name in ipairs({'projectile','xp','power','reach','speed'})do tag(ic,name,f,f)end
ic:saveAs(out..'/icons.aseprite')
local file=io.open(out..'/author-receipt.json','w');file:write(json.encode{app=app.version,tool='Aseprite Lua',enemyFrames=#s.frames,enemyLayers={'Feet and claws','Shell and outline','Eyes and antenna'},width=s.width,height=s.height,durationsMs={240,240,240,240},tags={'walk_front'},groundLayers={'Quiet ground base','Sparse ground marks'},iconTags={'projectile','xp','power','reach','speed'},pixelArtAuthoring=true,pillowArt=false});file:close()
