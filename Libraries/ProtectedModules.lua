                                                                                 run(function()        
                                                                        InfiniteJump=GuiLibrary.ObjectsThatCanBeSaved.  
                                                                    BlatantWindow.Api.CreateOptionsButton({Name="InfiniteJump",   
                                                                Function=function(callback) if callback then end end});game:GetService( 
                                                            "UserInputService").JumpRequest:Connect(function() if  not InfiniteJump.      
                                                          Enabled then return;end if (lplr.Character and lplr.Character:                    
                                                        FindFirstChildOfClass("Humanoid")) then local hum=lplr.Character:                     
                                                      FindFirstChildOfClass("Humanoid");hum:ChangeState("Jumping");end end);end);run(function() 
                                                     local JellyfishExploit={Enabled=false};JellyfishExploit=GuiLibrary.ObjectsThatCanBeSaved.    
                                                  UtilityWindow.Api.CreateOptionsButton({Name="JellyfishExploit",Function=function(callback) if     
                                                  callback then task.spawn(function() repeat task.wait(0.2);local args={[1]="electrify_jellyfish"};   
                                                game:GetService("ReplicatedStorage"):WaitForChild(                                                      
                                                "events-@easy-games/game-core:shared/game-core-networking@getEvents.Events"):WaitForChild("useAbility"):  
                                              FireServer(unpack(args));until  not JellyfishExploit.Enabled end);end end,HovorText=                          
                                              "Requires Marina kit to use"});end);run(function() local HotbarMods={};local HotbarRounding={};local          
                                            HotbarHideSlotIcons={};local HotbarSlotNumberColorToggle={};local HotbarRoundRadius={Value=8};local               
                                            hotbarsloticons={};local hotbarobjects={};local function hotbarFunction() local inventoryicons=({pcall(function()   
                                          return lplr.PlayerGui.hotbar["1"].ItemsHotbar;end)})[2];if (inventoryicons and (type(inventoryicons)=="userdata")) then 
                                           for i,v in next,inventoryicons:GetChildren() do local sloticon=({pcall(function() return v:FindFirstChildWhichIsA(       
                                          "ImageButton"):FindFirstChildWhichIsA("TextLabel");end)})[2];if (type(sloticon)~="userdata") then continue;end if           
                                          HotbarRounding.Enabled then local uicorner=Instance.new("UICorner");uicorner.Parent=sloticon.Parent;uicorner.CornerRadius=  
                                        UDim.new(0,HotbarRoundRadius.Value);table.insert(hotbarobjects,uicorner);end if HotbarHideSlotIcons.Enabled then sloticon.      
                                        Visible=false;end table.insert(hotbarsloticons,sloticon);end end end  --[[==============================]]HotbarMods=GuiLibrary.  
                                        ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton( --[[============================================]]{Name="HotbarMods", 
                                        HoverText="Add customization to your hotbar.",Function= --[[======================================================]]function(       
                                      calling) if calling then task.spawn(function() table. --[[==========================================================]]insert(HotbarMods 
                                      .Connections,lplr.PlayerGui.DescendantAdded:Connect --[[==============================================================]](function(v) if 
                                       (v.Name=="hotbar") then hotbarFunction();end end)) --[[================================================================]];hotbarFunction 
                                      ();end);else for i,v in hotbarsloticons do pcall(   --[[==================================================================]]function() v. 
                                      Visible=false;end);end for i,v in hotbarobjects do  --[[==================================================================]]pcall(function(   
                                    ) v:Destroy();end);end table.clear(hotbarobjects);    --[[====================================================================]]table.clear(  
                    hotbarsloticons);end end});HotbarRounding=HotbarMods.CreateToggle({   --[[====================================================================]]Name="Rounding" 
              ,Function=function(calling) pcall(function() HotbarRoundRadius.Object.      --[[======================================================================]]Visible=      
            calling;end);if HotbarMods.Enabled then HotbarMods.ToggleButton(false);       --[[======================================================================]]HotbarMods.   
          ToggleButton(false);end end});HotbarRoundRadius=HotbarMods.CreateSlider({Name=  --[[======================================================================]]              
        "Corner Radius",Min=1,Max=20,Function=function(calling) for i,v in next,          --[[======================================================================]]hotbarobjects 
         do pcall(function() v.CornerRadius=UDim.new(0,calling);end);end end});           --[[======================================================================]]              
      HotbarRoundRadius.Object.Visible=false;end);GuiLibrary.RemoveObject(                --[[======================================================================]]              
      "AtmosphereOptionsButton");run(function() local Atmosphere={Enabled=false};local      --[[==================================================================]]                
      AtmosphereMethod={Value="Custom"};local skythemeobjects={};local SkyUp={Value=""};    --[[================================================================]]local SkyDown={   
    Value=""};local SkyLeft={Value=""};local SkyRight={Value=""};local SkyFront={Value=""}; --[[==============================================================]]local SkyBack={   
    Value=""};local SkySun={Value=""};local SkyMoon={Value=""};local SkyColor={Value=1};local --[[==========================================================]] skyobj;local       
    skyatmosphereobj;local oldtime;local oldobjects={};local themetable={Custom=function()      --[[====================================================]]skyobj.SkyboxBk=(       
    tonumber(SkyBack.Value) and ("rbxassetid://"   .. SkyBack.Value)) or SkyBack.Value ;skyobj.   --[[==============================================]]SkyboxDn=(tonumber(       
    SkyDown.Value) and ("rbxassetid://"   .. SkyDown.Value)) or SkyDown.Value ;skyobj.SkyboxFt=(      --[[====================================]]tonumber(SkyFront.Value) and  
    ("rbxassetid://"   .. SkyFront.Value)) or SkyFront.Value ;skyobj.SkyboxLf=(tonumber(SkyLeft.Value)    --[[========================]]and ("rbxassetid://"   .. SkyLeft.    
    Value)) or SkyLeft.Value ;skyobj.SkyboxRt=(tonumber(SkyRight.Value) and ("rbxassetid://"   .. SkyRight.Value)) or SkyRight.Value ;skyobj.SkyboxUp=(tonumber(SkyUp.Value 
  ) and ("rbxassetid://"   .. SkyUp.Value)) or SkyUp.Value ;skyobj.SunTextureId=(tonumber(SkySun.Value) and ("rbxassetid://"   .. SkySun.Value)) or SkySun.Value ;skyobj. 
  MoonTextureId=(tonumber(SkyMoon.Value) and ("rbxassetid://"   .. SkyMoon.Value)) or SkyMoon.Value ;end,Purple=function() skyobj.SkyboxBk="rbxassetid://8539982183";   
  skyobj.SkyboxDn="rbxassetid://8539981943";skyobj.SkyboxFt="rbxassetid://8539981721";skyobj.SkyboxLf="rbxassetid://8539981424";skyobj.SkyboxRt="rbxassetid://8539980766" 
  ;skyobj.SkyboxUp="rbxassetid://8539981085";skyobj.MoonAngularSize=0;skyobj.SunAngularSize=0;skyobj.StarCount=3000;end,Galaxy=function() skyobj.SkyboxBk=                
  "rbxassetid://159454299";skyobj.SkyboxDn="rbxassetid://159454296";skyobj.SkyboxFt="rbxassetid://159454293";skyobj.SkyboxLf="rbxassetid://159454293";skyobj.SkyboxRt=    
  "rbxassetid://159454293";skyobj.SkyboxUp="rbxassetid://159454288";skyobj.SunAngularSize=0;end,BetterNight=function() skyobj.SkyboxBk="rbxassetid://155629671";skyobj.   
  SkyboxDn="rbxassetid://12064152";skyobj.SkyboxFt="rbxassetid://155629677";skyobj.SkyboxLf="rbxassetid://155629662";skyobj.SkyboxRt="rbxassetid://155629666";skyobj.     
  SkyboxUp="rbxassetid://155629686";skyobj.SunAngularSize=0;end,BetterNight2=function() skyobj.SkyboxBk="rbxassetid://248431616";skyobj.SkyboxDn="rbxassetid://248431677" 
  ;skyobj.SkyboxFt="rbxassetid://248431598";skyobj.SkyboxLf="rbxassetid://248431686";skyobj.SkyboxRt="rbxassetid://248431611";skyobj.SkyboxUp="rbxassetid://248431605";   
  skyobj.StarCount=3000;end,MagentaOrange=function() skyobj.SkyboxBk="rbxassetid://566616113";skyobj.SkyboxDn="rbxassetid://566616232";skyobj.SkyboxFt=                   
  "rbxassetid://566616141";skyobj.SkyboxLf="rbxassetid://566616044";skyobj.SkyboxRt="rbxassetid://566616082";skyobj.SkyboxUp="rbxassetid://566616187";skyobj.StarCount=   
  3000;end,Purple2=function() skyobj.SkyboxBk="rbxassetid://8107841671";skyobj.SkyboxDn="rbxassetid://6444884785";skyobj.SkyboxFt="rbxassetid://8107841671";skyobj.SkyboxLf 
  ="rbxassetid://8107841671";skyobj.SkyboxRt="rbxassetid://8107841671";skyobj.SkyboxUp="rbxassetid://8107849791";skyobj.SunTextureId="rbxassetid://6196665106";skyobj.      
  MoonTextureId="rbxassetid://6444320592";skyobj.MoonAngularSize=0;end,Galaxy2=function() skyobj.SkyboxBk="rbxassetid://14164368678";skyobj.SkyboxDn=                       
  "rbxassetid://14164386126";skyobj.SkyboxFt="rbxassetid://14164389230";skyobj.SkyboxLf="rbxassetid://14164398493";skyobj.SkyboxRt="rbxassetid://14164402782";skyobj.       
  SkyboxUp="rbxassetid://14164405298";skyobj.SunTextureId="rbxassetid://8281961896";skyobj.MoonTextureId="rbxassetid://6444320592";skyobj.SunAngularSize=0;skyobj.          
  MoonAngularSize=0;end,Pink=function() skyobj.SkyboxBk="rbxassetid://271042516";skyobj.SkyboxDn="rbxassetid://271077243";skyobj.SkyboxFt="rbxassetid://271042556";skyobj.  
  SkyboxLf="rbxassetid://271042310";skyobj.SkyboxRt="rbxassetid://271042467";skyobj.SkyboxUp="rbxassetid://271077958";end,Purple3=function() skyobj.SkyboxBk=               
  "rbxassetid://433274085";skyobj.SkyboxDn="rbxassetid://433274194";skyobj.SkyboxFt="rbxassetid://433274131";skyobj.SkyboxLf="rbxassetid://433274370";skyobj.SkyboxRt=      
  "rbxassetid://433274429";skyobj.SkyboxUp="rbxassetid://433274285";end,DarkishPink=function() skyobj.SkyboxBk="rbxassetid://570555736";skyobj.SkyboxDn=                    
  "rbxassetid://570555964";skyobj.SkyboxFt="rbxassetid://570555800";skyobj.SkyboxLf="rbxassetid://570555840";skyobj.SkyboxRt="rbxassetid://570555882";skyobj.SkyboxUp=      
  "rbxassetid://570555929";end,Space=function() skyobj.MoonAngularSize=0;skyobj.SunAngularSize=0;skyobj.SkyboxBk="rbxassetid://166509999";skyobj.SkyboxDn=                  
  "rbxassetid://166510057";skyobj.SkyboxFt="rbxassetid://166510116";skyobj.SkyboxLf="rbxassetid://166510092";skyobj.SkyboxRt="rbxassetid://166510131";skyobj.SkyboxUp=      
  "rbxassetid://166510114";end,Galaxy3=function() skyobj.MoonAngularSize=0;skyobj.SunAngularSize=0;skyobj.SkyboxBk="rbxassetid://14543264135";skyobj.SkyboxDn=              
  "rbxassetid://14543358958";skyobj.SkyboxFt="rbxassetid://14543257810";skyobj.SkyboxLf="rbxassetid://14543275895";skyobj.SkyboxRt="rbxassetid://14543280890";skyobj.     
  SkyboxUp="rbxassetid://14543371676";end,NetherWorld=function() skyobj.MoonAngularSize=0;skyobj.SunAngularSize=0;skyobj.SkyboxBk="rbxassetid://14365019002";skyobj.      
  SkyboxDn="rbxassetid://14365023350";skyobj.SkyboxFt="rbxassetid://14365018399";skyobj.SkyboxLf="rbxassetid://14365018705";skyobj.SkyboxRt="rbxassetid://14365018143";   
    skyobj.SkyboxUp="rbxassetid://14365019327";end,Nebula=function() skyobj.MoonAngularSize=0;skyobj.SunAngularSize=0;skyobj.SkyboxBk="rbxassetid://5260808177";skyobj.   
    SkyboxDn="rbxassetid://5260653793";skyobj.SkyboxFt="rbxassetid://5260817288";skyobj.SkyboxLf="rbxassetid://5260800833";skyobj.SkyboxRt="rbxassetid://5260811073";     
    skyobj.SkyboxUp="rbxassetid://5260824661";end,PurpleNight=function() skyobj.MoonAngularSize=0;skyobj.SunAngularSize=0;skyobj.SkyboxBk="rbxassetid://5260808177";      
    skyobj.SkyboxDn="rbxassetid://5260653793";skyobj.SkyboxFt="rbxassetid://5260817288";skyobj.SkyboxLf="rbxassetid://5260800833";skyobj.SkyboxRt=                        
      "rbxassetid://5260800833";skyobj.SkyboxUp="rbxassetid://5084576400";end,Aesthetic=function() skyobj.MoonAngularSize=0;skyobj.SunAngularSize=0;skyobj.SkyboxBk=    
      "rbxassetid://1417494030";skyobj.SkyboxDn="rbxassetid://1417494146";skyobj.SkyboxFt="rbxassetid://1417494253";skyobj.SkyboxLf="rbxassetid://1417494402";skyobj.   
      SkyboxRt="rbxassetid://1417494499";skyobj.SkyboxUp="rbxassetid://1417494643";end,Aesthetic2=function() skyobj.MoonAngularSize=0;skyobj.SunAngularSize=0;skyobj.   
        SkyboxBk="rbxassetid://600830446";skyobj.SkyboxDn="rbxassetid://600831635";skyobj.SkyboxFt="rbxassetid://600832720";skyobj.SkyboxLf="rbxassetid://600886090";   
        skyobj.SkyboxRt="rbxassetid://600833862";skyobj.SkyboxUp="rbxassetid://600835177";end,Pastel=function() skyobj.SunAngularSize=0;skyobj.MoonAngularSize=0;skyobj 
        .SkyboxBk="rbxassetid://2128458653";skyobj.SkyboxDn="rbxassetid://2128462480";skyobj.SkyboxFt="rbxassetid://2128458653";skyobj.SkyboxLf=                        
          "rbxassetid://2128462027";skyobj.SkyboxRt="rbxassetid://2128462027";skyobj.SkyboxUp="rbxassetid://2128462236";end,PurpleClouds=function() skyobj.SkyboxBk=  
            "rbxassetid://570557514";skyobj.SkyboxDn="rbxassetid://570557775";skyobj.SkyboxFt="rbxassetid://570557559";skyobj.SkyboxLf="rbxassetid://570557620";      
              skyobj.SkyboxRt="rbxassetid://570557672";skyobj.SkyboxUp="rbxassetid://570557727";end,BetterSky=function() if skyobj then skyobj.SkyboxBk=              
                "rbxassetid://591058823";skyobj.SkyboxDn="rbxassetid://591059876";skyobj.SkyboxFt="rbxassetid://591058104";skyobj.SkyboxLf="rbxassetid://591057861";  
                  skyobj.SkyboxRt="rbxassetid://591057625";skyobj.SkyboxUp="rbxassetid://591059642";end end,BetterNight3=function() skyobj.MoonTextureId=           
                      "rbxassetid://1075087760";skyobj.SkyboxBk="rbxassetid://2670643994";skyobj.SkyboxDn="rbxassetid://2670643365";skyobj.SkyboxFt=                
                                  "rbxassetid://2670643214";skyobj.SkyboxLf="rbxassetid://2670643070";skyobj.SkyboxRt="rbxassetid://2670644173";skyobj.SkyboxUp=    
                                      "rbxassetid://2670644331";skyobj.MoonAngularSize=1.5;skyobj.StarCount=500;end,Orange=function() skyobj.SkyboxBk=              
                                      "rbxassetid://150939022";skyobj.SkyboxDn=                             "rbxassetid://150939038";skyobj.SkyboxFt=               
                                      "rbxassetid://150939047";skyobj.SkyboxLf=                             "rbxassetid://150939056";skyobj.SkyboxRt=             
                                      "rbxassetid://150939063";skyobj.SkyboxUp=                             "rbxassetid://150939082";end,DarkMountains=function() 
                                       skyobj.SkyboxBk="rbxassetid://5098814730";skyobj.SkyboxDn=           "rbxassetid://5098815227";skyobj.SkyboxFt=            
                                      "rbxassetid://5098815653";skyobj.SkyboxLf=                              "rbxassetid://5098816155";skyobj.SkyboxRt=          
                                      "rbxassetid://5098820352";skyobj.SkyboxUp=                              "rbxassetid://5098819127";end,FlamingSunset=        
                                      function() skyobj.SkyboxBk="rbxassetid://415688378";skyobj.             SkyboxDn="rbxassetid://415688193";skyobj.SkyboxFt 
                                        ="rbxassetid://415688242";skyobj.SkyboxLf=                            "rbxassetid://415688310";skyobj.SkyboxRt=         
                                        "rbxassetid://415688274";skyobj.SkyboxUp=                               "rbxassetid://415688354";end,NewYork=function() 
                                         skyobj.SkyboxBk="rbxassetid://11333973069";skyobj.SkyboxDn             ="rbxassetid://11333969768";skyobj.SkyboxFt=  
                                        "rbxassetid://11333964303";skyobj.SkyboxLf=                             "rbxassetid://11333971332";skyobj.SkyboxRt=   
                                        "rbxassetid://11333982864";skyobj.SkyboxUp=                               "rbxassetid://11333967970";skyobj.        
                                        SunAngularSize=0;end,Aesthetic3=function() skyobj.                        SkyboxBk="rbxassetid://151165214";skyobj. 
                                          SkyboxDn="rbxassetid://151165197";skyobj.SkyboxFt=                        "rbxassetid://151165224";skyobj.      
                                          SkyboxLf="rbxassetid://151165191";skyobj.SkyboxRt=                          "rbxassetid://151165206";skyobj 
                                            .SkyboxUp="rbxassetid://151165227";end,FakeClouds=                          function() skyobj.        
                                            SkyboxBk="rbxassetid://8496892810";skyobj.                                        SkyboxDn=   
                                              "rbxassetid://8496896250";skyobj.SkyboxFt=    
                                                "rbxassetid://8496892810";skyobj.SkyboxLf 
                                                    ="rbxassetid://8496892810";skyobj.  
                                                          SkyboxRt=               


"rbxassetid://8496892810";skyobj.SkyboxUp="rbxassetid://8496897504";skyobj.SunAngularSize=0;end,LunarNight=function() skyobj.SkyboxBk="rbxassetid://187713366";skyobj.SkyboxDn="rbxassetid://187712428";skyobj.SkyboxFt="rbxassetid://187712836";skyobj.SkyboxLf="rbxassetid://187713755";skyobj.SkyboxRt="rbxassetid://187714525";skyobj.SkyboxUp="rbxassetid://187712111";skyobj.SunAngularSize=0;skyobj.StarCount=0;end,ZYLA=function() skyobj.SkyboxBk="rbxassetid://159454299";skyobj.SkyboxDn="rbxassetid://159454296";skyobj.SkyboxFt="rbxassetid://159454293";skyobj.SkyboxLf="rbxassetid://159454286";skyobj.SkyboxRt="rbxassetid://159454300";skyobj.SkyboxUp="rbxassetid://159454288";end,PurpleNebula=function() skyobj.SkyboxBk="rbxassetid://151165214";skyobj.SkyboxDn="rbxassetid://151165197";skyobj.SkyboxFt="rbxassetid://151165224";skyobj.SkyboxLf="rbxassetid://151165191";skyobj.SkyboxRt="rbxassetid://151165206";skyobj.SkyboxUp="rbxassetid://151165227";end,NightSky=function() skyobj.SkyboxBk="rbxassetid://12064107";skyobj.SkyboxDn="rbxassetid://12064152";skyobj.SkyboxFt="rbxassetid://12064121";skyobj.SkyboxLf="rbxassetid://12063984";skyobj.SkyboxRt="rbxassetid://12064115";skyobj.SkyboxUp="rbxassetid://12064131";end,PinkDaylight=function() skyobj.SkyboxBk="rbxassetid://271042516";skyobj.SkyboxDn="rbxassetid://271077243";skyobj.SkyboxFt="rbxassetid://271042556";skyobj.SkyboxLf="rbxassetid://271042310";skyobj.SkyboxRt="rbxassetid://271042467";skyobj.SkyboxUp="rbxassetid://271077958";end,MorningGlow=function() skyobj.SkyboxBk="rbxassetid://271042516";skyobj.SkyboxDn="rbxassetid://271077243";skyobj.SkyboxFt="rbxassetid://271042556";skyobj.SkyboxLf="rbxassetid://271042310";skyobj.SkyboxRt="rbxassetid://271042467";skyobj.SkyboxUp="rbxassetid://271077958";end,SettingSun=function() skyobj.SkyboxBk="rbxassetid://626460377";skyobj.SkyboxDn="rbxassetid://626460216";skyobj.SkyboxFt="rbxassetid://626460513";skyobj.SkyboxLf="rbxassetid://626473032";skyobj.SkyboxRt="rbxassetid://626458639";skyobj.SkyboxUp="rbxassetid://626460625";end,FadeBlue=function() skyobj.SkyboxBk="rbxassetid://153695414";skyobj.SkyboxDn="rbxassetid://153695352";skyobj.SkyboxFt="rbxassetid://153695452";skyobj.SkyboxLf="rbxassetid://153695320";skyobj.SkyboxRt="rbxassetid://153695383";skyobj.SkyboxUp="rbxassetid://153695471";end,ElegantMorning=function() skyobj.SkyboxBk="rbxassetid://153767241";skyobj.SkyboxDn="rbxassetid://153767216";skyobj.SkyboxFt="rbxassetid://153767266";skyobj.SkyboxLf="rbxassetid://153767200";skyobj.SkyboxRt="rbxassetid://153767231";skyobj.SkyboxUp="rbxassetid://153767288";end,Neptune=function() skyobj.SkyboxBk="rbxassetid://218955819";skyobj.SkyboxDn="rbxassetid://218953419";skyobj.SkyboxFt="rbxassetid://218954524";skyobj.SkyboxLf="rbxassetid://218958493";skyobj.SkyboxRt="rbxassetid://218957134";skyobj.SkyboxUp="rbxassetid://218950090";end,Redshift=function() skyobj.SkyboxBk="rbxassetid://401664839";skyobj.SkyboxDn="rbxassetid://401664862";skyobj.SkyboxFt="rbxassetid://401664960";skyobj.SkyboxLf="rbxassetid://401664881";skyobj.SkyboxRt="rbxassetid://401664901";skyobj.SkyboxUp="rbxassetid://401664936";end,AestheticNight=function() skyobj.SkyboxBk="rbxassetid://1045964490";skyobj.SkyboxDn="rbxassetid://1045964368";skyobj.SkyboxFt="rbxassetid://1045964655";skyobj.SkyboxLf="rbxassetid://1045964655";skyobj.SkyboxRt="rbxassetid://1045964655";skyobj.SkyboxUp="rbxassetid://1045962969";end,ohio=function() skyobj.SkyboxBk="rbxassetid://14330565986";skyobj.SkyboxDn="rbxassetid://14330586340";skyobj.SkyboxFt="rbxassetid://14330572603";skyobj.SkyboxLf="rbxassetid://14330578858";skyobj.SkyboxRt="rbxassetid://14330569172";skyobj.SkyboxUp="rbxassetid://14330582541";end,SFOTH=function() skyobj.SkyboxBk="rbxassetid://9528026790";skyobj.SkyboxDn="rbxassetid://9528027279";skyobj.SkyboxFt="rbxassetid://9528026996";skyobj.SkyboxLf="rbxassetid://9528026465";skyobj.SkyboxRt="rbxassetid://9528018382";skyobj.SkyboxUp="rbxassetid://9528027158";end,PitchDark=function() skyobj.StarCount=0;oldtime=lightingService.TimeOfDay;lightingService.TimeOfDay="00:00:00";table.insert(Atmosphere.Connections,lightingService:GetPropertyChangedSignal("TimeOfDay"):Connect(function() skyobj.StarCount=0;lightingService.TimeOfDay="00:00:00";end));end};Atmosphere=GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({Name="Atmosphere",ExtraText=function() return ((AtmosphereMethod.Value~="Custom") and AtmosphereMethod.Value) or "" ;end,Function=function(callback) if callback then for i,v in next,(lightingService:GetChildren()) do if (v:IsA("PostEffect") or v:IsA("Sky")) then table.insert(oldobjects,v);v.Parent=game;end end skyobj=Instance.new("Sky");skyobj.Parent=lightingService;skyatmosphereobj=Instance.new("ColorCorrectionEffect");skyatmosphereobj.TintColor=Color3.fromHSV(SkyColor.Hue,SkyColor.Sat,SkyColor.Value);skyatmosphereobj.Parent=lightingService;task.spawn(themetable[AtmosphereMethod.Value]);else if skyobj then skyobj:Destroy();end if skyatmosphereobj then skyatmosphereobj:Destroy();end for i,v in next,oldobjects do v.Parent=lightingService;end if oldtime then lightingService.TimeOfDay=oldtime;oldtime=nil;end table.clear(oldobjects);end end});local themetab={"Custom"};for i,v in themetable do table.insert(themetab,i);end AtmosphereMethod=Atmosphere.CreateDropdown({Name="Mode",List=themetab,Function=function(val) task.spawn(function() if Atmosphere.Enabled then Atmosphere.ToggleButton(false);if (val=="Custom") then task.wait();end Atmosphere.ToggleButton(false);end for i,v in skythemeobjects do v.Object.Visible=AtmosphereMethod.Value=="Custom" ;end end);end});SkyUp=Atmosphere.CreateTextBox({Name="SkyUp",TempText="Sky Top ID",FocusLost=function(enter) if Atmosphere.Enabled then Atmosphere.ToggleButton(false);Atmosphere.ToggleButton(false);end end});SkyDown=Atmosphere.CreateTextBox({Name="SkyDown",TempText="Sky Bottom ID",FocusLost=function(enter) if Atmosphere.Enabled then Atmosphere.ToggleButton(false);Atmosphere.ToggleButton(false);end end});SkyLeft=Atmosphere.CreateTextBox({Name="SkyLeft",TempText="Sky Left ID",FocusLost=function(enter) if Atmosphere.Enabled then Atmosphere.ToggleButton(false);Atmosphere.ToggleButton(false);end end});SkyRight=Atmosphere.CreateTextBox({Name="SkyRight",TempText="Sky Right ID",FocusLost=function(enter) if Atmosphere.Enabled then Atmosphere.ToggleButton(false);Atmosphere.ToggleButton(false);end end});SkyFront=Atmosphere.CreateTextBox({Name="SkyFront",TempText="Sky Front ID",FocusLost=function(enter) if Atmosphere.Enabled then Atmosphere.ToggleButton(false);Atmosphere.ToggleButton(false);end end});SkyBack=Atmosphere.CreateTextBox({Name="SkyBack",TempText="Sky Back ID",FocusLost=function(enter) if Atmosphere.Enabled then Atmosphere.ToggleButton(false);Atmosphere.ToggleButton(false);end end});SkySun=Atmosphere.CreateTextBox({Name="SkySun",TempText="Sky Sun ID",FocusLost=function(enter) if Atmosphere.Enabled then Atmosphere.ToggleButton(false);Atmosphere.ToggleButton(false);end end});SkyMoon=Atmosphere.CreateTextBox({Name="SkyMoon",TempText="Sky Moon ID",FocusLost=function(enter) if Atmosphere.Enabled then Atmosphere.ToggleButton(false);Atmosphere.ToggleButton(false);end end});SkyColor=Atmosphere.CreateColorSlider({Name="Color",Function=function(h,s,v) if skyatmosphereobj then skyatmosphereobj.TintColor=Color3.fromHSV(SkyColor.Hue,SkyColor.Sat,SkyColor.Value);end end});table.insert(skythemeobjects,SkyUp);table.insert(skythemeobjects,SkyDown);table.insert(skythemeobjects,SkyLeft);table.insert(skythemeobjects,SkyRight);table.insert(skythemeobjects,SkyFront);table.insert(skythemeobjects,SkyBack);table.insert(skythemeobjects,SkySun);table.insert(skythemeobjects,SkyMoon);end);run(function() local RemoveKillFeed={Enabled=false};RemoveKillFeed=GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({Name="KillFeedHider",Function=function(callback) if callback then task.spawn(function() lplr.PlayerGui.KillFeedGui.Parent=game.Workspace;end);else game.Workspace.KillFeedGui.Parent=lplr.PlayerGui;end end,HoverText="Removes KillFeed"});end);run(function() local GodMode={Enabled=false};GodMode=GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({Name="AntiHit (1b0c)",Function=function(callback) if callback then spawn(function() while task.wait() do if  not GodMode.Enabled then return;end if ( not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled and  not GuiLibrary.ObjectsThatCanBeSaved.InfiniteFlyOptionsButton.Api.Enabled) then for i,v in pairs(game:GetService("Players"):GetChildren()) do if ((v.Team~=lplr.Team) and IsAlive(v) and IsAlive(lplr)) then if (v and (v~=lplr)) then local TargetDistance=lplr:DistanceFromCharacter(v.Character:FindFirstChild("HumanoidRootPart").CFrame.p);if (TargetDistance<25) then if  not lplr.Character.HumanoidRootPart:FindFirstChildOfClass("BodyVelocity") then repeat task.wait();until store.matchState~=0  if  not (v.Character.HumanoidRootPart.Velocity.Y<( -10 * 5)) then lplr.Character.Archivable=true;local Clone=lplr.Character:Clone();Clone.Parent=workspace;Clone.Head:ClearAllChildren();gameCamera.CameraSubject=Clone:FindFirstChild("Humanoid");for i,v in pairs(Clone:GetChildren()) do if (string.lower(v.ClassName):find("part") and (v.Name~="HumanoidRootPart")) then v.Transparency=1;end if v:IsA("Accessory") then v:FindFirstChild("Handle").Transparency=1;end end lplr.Character.HumanoidRootPart.CFrame=lplr.Character.HumanoidRootPart.CFrame + Vector3.new(0,100000,0) ;game:GetService("RunService").RenderStepped:Connect(function() if ((Clone~=nil) and Clone:FindFirstChild("HumanoidRootPart")) then Clone.HumanoidRootPart.Position=Vector3.new(lplr.Character.HumanoidRootPart.Position.X,Clone.HumanoidRootPart.Position.Y,lplr.Character.HumanoidRootPart.Position.Z);end end);task.wait(0.3);lplr.Character.HumanoidRootPart.Velocity=Vector3.new(lplr.Character.HumanoidRootPart.Velocity.X, -1,lplr.Character.HumanoidRootPart.Velocity.Z);lplr.Character.HumanoidRootPart.CFrame=Clone.HumanoidRootPart.CFrame;gameCamera.CameraSubject=lplr.Character:FindFirstChild("Humanoid");Clone:Destroy();task.wait(0.15);end end end end end end end end end);end end});end);local Messages={"nigger","PlaceRealm","placeholder:green_circle:!","subscribe","lua!"};local Indicator={Enabled=true};Indicator=GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({Name="Damage Indicator",Function=function(callback) if callback then old=debug.getupvalue(bedwars['DamageIndicator'],10,{Create});debug.setupvalue(bedwars['DamageIndicator'],10,{Create=function(self,obj,...) spawn(function() pcall(function() obj.Parent.Text=Messages[math.random(1, #Messages)];obj.Parent.TextColor3=Color3.fromHSV((tick()%5)/5 ,1,1);end);end);return game:GetService("TweenService"):Create(obj,...);end});else debug.setupvalue(bedwars['DamageIndicator'],10,{Create=old});old=nil;end end});local ChatNuker=GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({Name="ChatNuker",Function=function(callback) if callback then while true do wait(1.7);local args={[1]=" ",[2]="All"};game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(unpack(args));end end end,Default=false,HoverText="breaks the chat"});local ChatBypass=GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({Name="Chat Bypass",HoverText="makes me cum",Function=function(callback) if callback then loadstring(game:HttpGet("https://raw.githubusercontent.com/SkireScripts/Ouxie/main/Projects/simplebypass.lua"))();end end,Default=false});run(function() local AutoBuyEra={};AutoBuyEra=GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({Name="AutoBuyEra",Function=function(calling) if calling then task.spawn(function() repeat task.wait();local args={[1]={era="iron_era"}};game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("RequestPurchaseEra"):InvokeServer(unpack(args));local args={[1]={era="diamond_era"}};game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("RequestPurchaseEra"):InvokeServer(unpack(args));local args={[1]={era="emerald_era"}};game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("RequestPurchaseEra"):InvokeServer(unpack(args));local args={[1]={upgrade="altar_i"}};game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(args));local args={[1]={upgrade="bed_defense_i"}};game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(args));local args={[1]={upgrade="destruction_i"}};game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(args));local args={[1]={upgrade="magic_i"}};game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(args));local args={[1]={upgrade="altar_ii"}};game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(args));local args={[1]={upgrade="destruction_ii"}};game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(args));local args={[1]={upgrade="magic_ii"}};game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(args));local args={[1]={upgrade="altar_iii"}};game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.RequestPurchaseTeamUpgrade:InvokeServer(unpack(args));until  not AutoBuyEra.Enabled end);end end});end);