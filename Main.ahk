; Virage GAG Macro [FREE VERSION]

#SingleInstance, Force
#NoEnv
SetWorkingDir %A_ScriptDir%
#WinActivateForce
SetMouseDelay, -1 
SetWinDelay, -1
SetControlDelay, -1
SetBatchLines, -1   

; globals

global webhookURL
global privateServerLink
global discordUserID
global PingSelected
global reconnectingProcess

global windowIDS := []
global currentWindow := ""
global firstWindow := ""
global instanceNumber
global idDisplay := ""
global started := 0

global cycleCount := 0
global cycleFinished := 0
global toolTipText := ""

global currentItem := ""
global currentArray := ""
global currentSelectedArray := ""
global indexItem := ""
global indexArray := []

global currentHour
global currentMinute
global currentSecond

global midX
global midY

global msgBoxCooldown := 0

global gearAutoActive := 0
global seedAutoActive := 0
global eggAutoActive  := 0
global cosmeticAutoActive := 0
global honeyShopAutoActive := 0
global honeyDepositAutoActive := 0
global collectPollinatedAutoActive := 0

global GAME_PASS_ID  := 1244038348
global VERIFIED_KEY  := "VerifiedUser"

global actionQueue := []

settingsFile := A_ScriptDir "\settings.ini"

; unused

global currentShop := ""

global selectedResolution

global scrollCounts_1080p, scrollCounts_1440p_100, scrollCounts_1440p_125
scrollCounts_1080p :=       [2, 4, 6, 8, 9, 11, 13, 14, 16, 18, 20, 21, 23, 25, 26, 28, 29, 31]
scrollCounts_1440p_100 :=   [3, 5, 8, 10, 13, 15, 17, 20, 22, 24, 27, 30, 31, 34, 36, 38, 40, 42]
scrollCounts_1440p_125 :=   [3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 25, 27, 29, 30, 31, 32]

global gearScroll_1080p, toolScroll_1440p_100, toolScroll_1440p_125
gearScroll_1080p     := [1, 2, 4, 6, 8, 9, 11, 13]
gearScroll_1440p_100 := [2, 3, 6, 8, 10, 13, 15, 17]
gearScroll_1440p_125 := [1, 3, 4, 6, 8, 9, 12, 12]

; http functions

SendDiscordMessage(webhookURL, message) {

    FormatTime, messageTime, , hh:mm:ss tt
    fullMessage := "[" . messageTime . "] " . message

    json := "{""content"": """ . fullMessage . """}"
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")

    try {
        whr.Open("POST", webhookURL, false)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(json)
        whr.WaitForResponse()
        status := whr.Status

        if (status != 200 && status != 204) {
            return
        }
    } catch {
        return
    }

}

checkValidity(url, msg := 0, mode := "nil") {

    global webhookURL
    global privateServerLink
    global settingsFile

    isValid := 0

    if (mode = "webhook" && (url = "" || !(InStr(url, "discord.com/api") || InStr(url, "discordapp.com/api")))) {
        isValid := 0
        if (msg) {
            MsgBox, 0, Message, Invalid Webhook
            IniRead, savedWebhook, %settingsFile%, Main, UserWebhook,
            GuiControl,, webhookURL, %savedWebhook%
        }
        return false
    }

    if (mode = "privateserver" && (url = "" || !InStr(url, "roblox.com/share"))) {
        isValid := 0
        if (msg) {
            MsgBox, 0, Message, Invalid Private Server Link
            IniRead, savedServerLink, %settingsFile%, Main, PrivateServerLink,
            GuiControl,, privateServerLink, %savedServerLink%
        }
        return false
    }

    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, false)
        whr.Send()
        whr.WaitForResponse()
        status := whr.Status

        if (mode = "webhook" && (status = 200 || status = 204)) {
            isValid := 1
        } else if (mode = "privateserver" && (status >= 200 && status < 400)) {
            isValid := 1
        }
    } catch {
        isValid := 0
    }

    if (msg) {
        if (mode = "webhook") {
            if (isValid && webhookURL != "") {
                IniWrite, %webhookURL%, %settingsFile%, Main, UserWebhook
                MsgBox, 0, Message, Webhook Saved Successfully
            }
            else if (!isValid && webhookURL != "") {
                MsgBox, 0, Message, Invalid Webhook
                IniRead, savedWebhook, %settingsFile%, Main, UserWebhook,
                GuiControl,, webhookURL, %savedWebhook%
            }
        } else if (mode = "privateserver") {
            if (isValid && privateServerLink != "") {
                IniWrite, %privateServerLink%, %settingsFile%, Main, PrivateServerLink
                MsgBox, 0, Message, Private Server Link Saved Successfully
            }
            else if (!isValid && privateServerLink != "") {
                MsgBox, 0, Message, Invalid Private Server Link
                IniRead, savedServerLink, %settingsFile%, Main, PrivateServerLink,
                GuiControl,, privateServerLink, %savedServerLink%
            }
        }
    }

    return isValid

}


showPopupMessage(msgText := "nil", duration := 2000) {

    static popupID := 99

    ; get main GUI position and size
    WinGetPos, guiX, guiY, guiW, guiH, A

    innerX := 20
    innerY := 35
    innerW := 200
    innerH := 50
    winW := 200
    winH := 50
    x := guiX + (guiW - winW) // 2 - 40
    y := guiY + (guiH - winH) // 2

    if (!msgBoxCooldown) {
        msgBoxCooldown = 1
        Gui, %popupID%:Destroy
        Gui, %popupID%:+AlwaysOnTop -Caption +ToolWindow +Border
        Gui, %popupID%:Color, FFFFFF
        Gui, %popupID%:Font, s10 cBlack, Segoe UI
        Gui, %popupID%:Add, Text, x%innerX% y%innerY% w%innerW% h%innerH% BackgroundWhite Center cBlack, %msgText%
        Gui, %popupID%:Show, x%x% y%y% NoActivate
        SetTimer, HidePopupMessage, -%duration%
        Sleep, 2200
        msgBoxCooldown = 0
    }

}

DonateResponder(ctrlName) {

    MsgBox, 1, Disclaimer, 
    (
    Your browser will open with a link to a roblox gamepass once you press OK.
    - Feel free to check the code, there are no malicious links.
    )

    IfMsgBox, OK
        if (ctrlName = "Donate100")
            Run, https://www.roblox.com/game-pass/1197306369/100-Donation
        else if (ctrlName = "Donate500")
            Run, https://www.roblox.com/game-pass/1222540123/500-Donation
        else if (ctrlName = "Donate1000")
            Run, https://www.roblox.com/game-pass/1222262383/1000-Donation
        else if (ctrlName = "Donate2500")
            Run, https://www.roblox.com/game-pass/1222306189/2500-Donation
        else if (ctrlName = "Donate10000")
            Run, https://www.roblox.com/game-pass/1220930414/10-000-Donation
        else
            return

}

; mouse functions

SafeMoveRelative(xRatio, yRatio) {

    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe
        moveX := winX + Round(xRatio * winW)
        moveY := winY + Round(yRatio * winH)
        MouseMove, %moveX%, %moveY%
    }

}

SafeClickRelative(xRatio, yRatio) {

    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe
        clickX := winX + Round(xRatio * winW)
        clickY := winY + Round(yRatio * winH)
        Click, %clickX%, %clickY%
    }

}

getMouseCoord(axis) {

    WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe
        CoordMode, Mouse, Screen
        MouseGetPos, mouseX, mouseY

        relX := (mouseX - winX) / winW
        relY := (mouseY - winY) / winH

        if (axis = "x")
            return relX
        else if (axis = "y")
            return relY

    return ""  ; error

}

; directional sequence encoder/executor
; if you're going to modify the calls to this make sure you know what you're doing (ui navigation has some odd behaviours)
uiUniversal(order := 0, exitUi := 1, continuous := 0, spam := 0, spamCount := 30, delayTime := 50, mode := "universal", index := 0, dir := "nil", itemType := "nil") {

    global SavedSpeed
    global SavedKeybind

    global indexItem
    global currentArray

    If (!order && mode = "universal") {
        return
    }

    if (!continuous) {
        sendKeybind(SavedKeybind)
        Sleep, 50
    }

    ; right = 1, left = 2, up = 3, down = 4, enter = 0, manual delay = 5
    if (mode = "universal") {

        Loop, Parse, order 
        {
            if (A_LoopField = "1") {
                repeatKey("Right", 1)
            }
            else if (A_LoopField = "2") {
                repeatKey("Left", 1)
            }
            else if (A_LoopField = "3") {
                repeatKey("Up", 1)
            }        
            else if (A_LoopField = "4") {
                repeatKey("Down", 1)
            }  
            else if (A_LoopField = "0") {
                repeatKey("Enter", spam ? spamCount : 1, spam ? 10 : 0)
            }       
            else if (A_LoopField = "5") {
                Sleep, 100
            } 
            if (SavedSpeed = "Stable" && A_LoopField != "5") {
                Sleep, %delayTime%
            }
        }

    }
    else if (mode = "calculate") {

        previousIndex := findIndex(currentArray, indexItem)
        sendCount := index - previousIndex

        if (dir = "up") {
            repeatKey(dir)
            repeatKey("Enter")
            repeatKey(dir, sendCount)
        }
        else if (dir = "down") {
            if ((currentArray.Name = "honeyItems") && (previousIndex = 1 || previousIndex = 10 || previousIndex = 12)) {
                if (!(findIndex(indexArray, 1, "bool"))) {
                    sendCount++
                }
                sendCount--
            }
			if(currentArray.Name = "eggItems") {
				if(previousIndex = 1){
					sendCount *= 2
				}
				else{
					sendCount := (sendCount * 2) - 1
				}
			}
            repeatKey(dir, sendCount)
            repeatKey("Enter")
            repeatKey(dir)
            if (((currentArray.Name = "honeyItems") && (index = 1 || index = 10 || index = 12)) || (currentArray.Name = "eggItems")) {
                repeatKey(dir)
            }
        }

    }
    else if (mode = "close") {
		if(currentArray.Name = "eggItems"){
			index := index * 2
		}
        if (dir = "up") {
            repeatKey(dir)
            repeatKey("Enter")
            repeatKey(dir, index)
        }
        else if (dir = "down") {
            repeatKey(dir, index)
            repeatKey("Enter")
            repeatKey(dir)
        }
    }

    if (exitUi) {
        Sleep, 50
        sendKeybind(SavedKeybind)
    }

    return

}

; universal shop buyer

buyUniversal(itemType) {

    global currentArray
    global currentSelectedArray
    global indexItem := ""
    global indexArray := []

    indexArray := []
    lastIndex := 0
    
    ; name array
    arrayName := itemType . "Items"
    currentArray := %arrayName%
    currentArray.Name := arrayName

    ; get arrays
    StringUpper, itemType, itemType, T

    selectedArrayName := "selected" . itemtype . "Items"
    currentSelectedArray := %selectedArrayName%

    ; get item indexes
    for i, selectedItem in currentSelectedArray {
        indexArray.Push(findIndex(currentArray, selectedItem))
    }

    ; buy items
    for i, index in indexArray {
        currentItem := currentSelectedArray[i]
		Sleep, 50
        uiUniversal(, 0, 1, , , , "calculate", index, "down", itemType)
        indexItem := currentSelectedArray[i]
        sleepAmount(100, 200)
        quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8508)
        Sleep, 50
        lastIndex := index - 1
    }

    ; end
    Sleep, 100
    uiUniversal(, 0, 1,,,, "close", lastIndex, "up", itemType)
    Sleep, 100

}

; helper functions

repeatKey(key := "nil", count := 1, delay := 30) {

    global SavedSpeed

    if (key = "nil") {
        return
    }

    Loop, %count% {
        Send {%key%}
        Sleep, % (SavedSpeed = "Ultra" ? (delay - 25) : SavedSpeed = "Max" ? (delay - 30) : delay)
    }

}

sendKeybind(keybind) {
    if (keybind = "\") {
        Send, \
    } else {
        Send, {%keybind%} 
    }
}


sleepAmount(fastTime, slowTime) {

    global SavedSpeed

    Sleep, % (SavedSpeed != "Stable") ? fastTime : slowTime

}

findIndex(array := "", value := "", returnValue := "int") {

    for index, item in array {
        if (value = item) {
            if (returnValue = "int") {
                return index
            }
            else if (returnValue = "bool") {
                return true
            }
        }
    }

    if (returnValue = "int") {
        return 1
    }
    else if (returnValue = "bool") {
        return false
    }

}

searchItem(search := "nil") {

    if(search = "nil") {
        Return
    }

        uiUniversal("1011143333333333333333333311440", 0)
        Sleep, 50      
        typeString(search)
        Sleep, 50

        if (search = "recall") {
            uiUniversal("22211550554155055", 1, 1)
        }
        else if (search = "pollinated") {
            uiUniversal("22115505544444444444444444444441111111155055", 1, 1)
        }
        else if (search = "pollen") {
            uiUniversal("2211550554444444444111111155055", 1, 1)
        }

        uiUniversal(10)

}

typeString(string, enter := 1, clean := 1) {

    if (string = "") {
        Return
    }

    if (clean) {
        Send {BackSpace 20}
        Sleep, 100
    }

    Loop, Parse, string
    {
        Send, {%A_LoopField%}
        Sleep, 100
    }

    if (enter) {
        Send, {Enter}
    }

    Return

}

dialogueClick(shop) {

    Loop, 5 {
        Send, {WheelUp}
        Sleep, 20
    }

    Sleep, 500

    if (shop = "gear") {
        SafeClickRelative(midX + 0.4, midY - 0.1)
    }
    else if (shop = "honey") {
        SafeClickRelative(midX + 0.4, midY)
    }
    else if (shop = "egg") {
		SafeClickRelative(midX + 0.35, midY - 0.4)
    }

    Sleep, 500

    Loop, 5 {
    Send, {WheelDown}
        Sleep, 20
    }

    SafeClickRelative(midX, midY)

}

hotbarController(select := 0, unselect := 0, key := "nil") {

    if ((select = 1 && unselect = 1) || (select = 0 && unselect = 0) || key = "nil") {
        Return
    }

    if (unselect) {
        Send, {%key%}
        Sleep, 200
        Send, {%key%}
    }
    else if (select) {
        Send, {%key%}
    }

}

closeRobuxPrompt() {

    Loop, 4 {
        Send {Escape}
        Sleep, 100
    }

}

getWindowIDS(returnIndex := 0) {

    global windowIDS
    global idDisplay
    global firstWindow

    windowIDS := []
    idDisplay := ""
    firstWindow := ""

    WinGet, robloxWindows, List, ahk_exe RobloxPlayerBeta.exe

    Loop, %robloxWindows% {
        windowIDS.Push(robloxWindows%A_Index%)
        idDisplay .= windowIDS[A_Index] . ", "
    }

    firstWindow := % windowIDS[1]

    StringTrimRight, idDisplay, idDisplay, 2

    if (returnIndex) {
        Return windowIDS[returnIndex]
    }
    
}

closeShop(shop, success) {

    StringUpper, shop, shop, T

    if (success) {

        Sleep, 500
        if (shop = "Honey") {
			uiUniversal("43333311140320", 1, 1)
        }
		else if (shop = "egg"){
			uiUniversal("1110332211110", 1, 1)
		}
        else {
            uiUniversal("4330320", 1, 1)
        }

    }
    else {

        ToolTip, % "Error In Detecting " . shop
        SetTimer, HideTooltip, -1500
        SendDiscordMessage(webhookURL, "Failed To Detect " . shop . " Shop Opening [Error]" . (PingSelected ? " <@" . discordUserID . ">" : ""))
        ; failsafe
        uiUniversal("3332223111133322231111054105")

    }

}

walkDistance(order := 0, multiplier := 1) {

    ; later

}

sendMessages() {

    ; later

}

simpleDetect(colorInBGR, variation, x1Ratio := 0.0, y1Ratio := 0.0, x2Ratio := 1.0, y2Ratio := 1.0) {

    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    ; limit search to specified area
	WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe

    x1 := winX + Round(x1Ratio * winW)
    y1 := winY + Round(y1Ratio * winH)
    x2 := winX + Round(x2Ratio * winW)
    y2 := winY + Round(y2Ratio * winH)

    PixelSearch, FoundX, FoundY, x1, y1, x2, y2, colorInBGR, variation, Fast
    if (ErrorLevel = 0) {
        return true
    }

}

quickDetect(color1, color2, variation := 10, x1Ratio := 0.0, y1Ratio := 0.0, x2Ratio := 1.0, y2Ratio := 1.0, item := 1, egg := 0) {

    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    stock := 0
    eggDetected := 0

    global currentItem
    
    ; change to whatever you want to be pinged for
    pingItems := ["Bamboo Seed", "Coconut Seed", "Cactus Seed", "Dragon Fruit Seed", "Mango Seed", "Grape Seed", "Mushroom Seed", "Pepper Seed"
                , "Cacao Seed", "Beanstalk Seed"
                , "Basic Sprinkler", "Advanced Sprinkler", "Godly Sprinkler", "Lightning Rod", "Master Sprinkler"
                , "Rare Egg", "Legendary Egg", "Mythical Egg", "Bug Egg"
                , "Flower Seed Pack", "Nectarine Seed", "Hive Fruit Seed", "Honey Sprinkler"
                , "Bee Egg", "Bee Crate", "Honey Comb", "Bee Chair", "Honey Torch", "Honey Walkway"]

	ping := false

    if (PingSelected) {
        for i, pingitem in pingItems {
            if (pingitem = currentItem) {
                ping := true
                break
            }
        }
    }

    ; limit search to specified area
	WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe

    x1 := winX + Round(x1Ratio * winW)
    y1 := winY + Round(y1Ratio * winH)
    x2 := winX + Round(x2Ratio * winW)
    y2 := winY + Round(y2Ratio * winH)

    ; for seeds/gears checks if either color is there (buy button)
    if (item) {
        for index, color in [color1, color2] {
            PixelSearch, FoundX, FoundY, x1, y1, x2, y2, %color%, variation, Fast RGB
            if (ErrorLevel = 0) {
                stock := 1
                ToolTip, %currentItem% `nIn Stock
                SetTimer, HideTooltip, -1500  
				Sleep, 1000
                uiUniversal(50, 0, 1, 1)
                Sleep, 50
                if (ping)
                    SendDiscordMessage(webhookURL, "Bought " . currentItem . ". <@" . discordUserID . ">")
                else
                    SendDiscordMessage(webhookURL, "Bought " . currentItem . ".")
            }
        }
    }

    ; for eggs
	/*
    if (egg) {
        PixelSearch, FoundX, FoundY, x1, y1, x2, y2, color1, variation, Fast RGB
        if (ErrorLevel = 0) {
            stock := 1
            ToolTip, %currentItem% `nIn Stock
            SetTimer, HideTooltip, -1500  
            uiUniversal(500, 1, 1)
            Sleep, 50
            if (ping)
                SendDiscordMessage(webhookURL, "Bought " . currentItem . ". <@" . discordUserID . ">")
            else
                SendDiscordMessage(webhookURL, "Bought " . currentItem . ".")
        }
        if (!stock) {
            uiUniversal(1105, 1, 1)
            SendDiscordMessage(webhookURL, currentItem . " Not In Stock.")  
        }
    }
	*/
	
    Sleep, 100

    if (!stock) {
        ToolTip, %currentItem% `nNot In Stock
        SetTimer, HideTooltip, -1500
        ; SendDiscordMessage(webhookURL, currentItem . " Not In Stock.")  
    }

}

; item arrays

seedItems := ["Carrot Seed", "Strawberry Seed", "Blueberry Seed", "Orange Tulip"
             , "Tomato Seed", "Corn Seed", "Daffodil Seed", "Watermelon Seed"
             , "Pumpkin Seed", "Apple Seed", "Bamboo Seed", "Coconut Seed"
             , "Cactus Seed", "Dragon Fruit Seed", "Mango Seed", "Grape Seed"
             , "Mushroom Seed", "Pepper Seed", "Cacao Seed", "Beanstalk Seed"
			 , "Ember Lily Seed", "Sugar Apple", "Burning Bud", "Giant Pinecone Seed"]

gearItems := ["Watering Can", "Trowel", "Recall Wrench", "Basic Sprinkler", "Advanced Sprinkler", "Medium Toy", "Medium Treat"
             , "Godly Sprinkler", "Magnifying Glass", "Tanning Mirror", "Master Sprinkler", "Cleaning Spray", "Favorite Tool"
			 , "Harvest Tool", "Friendship pot", "Levelup Lollipop"]

eggItems := ["Common Egg", "Common Summer Egg", "Rare Summer Egg", "Mythical Egg", "Paradise Egg"
             , "Bug Egg"]

cosmeticItems := ["Cosmetic 1", "Cosmetic 2", "Cosmetic 3", "Cosmetic 4", "Cosmetic 5"
             , "Cosmetic 6",  "Cosmetic 7", "Cosmetic 8", "Cosmetic 9"]

; honeyItems := ["Flower Seed Pack", "placeHolder1", "Lavender Seed", "Nectarshade Seed", "Nectarine Seed", "Hive Fruit Seed", "Pollen Rader", "Nectar Staff"
;             , "Honey Sprinkler", "Bee Egg", "placeHolder2", "Bee Crate", "placeHolder3", "Honey Comb", "Bee Chair", "Honey Torch", "Honey Walkway"]

;realHoneyItems := ["Flower Seed Pack", "Lavender Seed", "Nectarshade Seed", "Nectarine Seed", "Hive Fruit Seed", "Pollen Rader", "Nectar Staff"
;            , "Honey Sprinkler", "Bee Egg", "Bee Crate", "Honey Comb", "Bee Chair", "Honey Torch", "Honey Walkway"]

global craftItems, craftItems2
craftItems := ["Crafters Seed Pack", "Manuka Flower", "Dandelion"
    , "Lumira", "Honeysuckle", "Bee Balm", "Nectar Thorn", "Suncoil"]
craftItems2 := ["Tropical Mist Sprinkler", "Berry Blusher Sprinkler"
    , "Spice Spritzer Sprinkler", "Sweet Soaker Sprinkler"
    , "Flower Freeze Sprinkler", "Stalk Sprout Sprinkler"
    , "Mutation Spray Choc", "Mutation Spray Pollinated"
    , "Mutation Spray Shocked", "Honey Crafters Crate"
    , "Anti Bee Egg", "Pack Bee"]

settingsFile := A_ScriptDir "\settings.ini"

/*
fff(username) {
    global GAME_PASS_ID
    username := Trim(username)

    reqBody := "{""usernames"":[""" username """],""excludeBannedUsers"":true}"
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("POST","https://users.roblox.com/v1/usernames/users",false)
    whr.SetRequestHeader("Content-Type","application/json")
    whr.Send(reqBody),  whr.WaitForResponse()
    if (whr.Status!=200 || !RegExMatch(whr.ResponseText,"""id"":\s*(\d+)",m))
        return 0
    userId := m1

    ownURL := "https://inventory.roblox.com/v1/users/" userId
           .  "/items/GamePass/" GAME_PASS_ID
    whr2 := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr2.Open("GET",ownURL,false), whr2.Send(), whr2.WaitForResponse()
    if (whr2.Status!=200)                        ; request itself failed
        return 0

    return !RegExMatch(whr2.ResponseText, """data"":\s*\[\s*\]")
}


IniRead, isVerified, %settingsFile%, Main, %VERIFIED_KEY%, 0
if (!isVerified) {
    InputBox, rbUser, Premium Access, Please enter your Roblox username:
    if (ErrorLevel)
        ExitApp   ; user cancelled

    if (fff(rbUser)) {
        IniWrite, 1,              %settingsFile%, Main, %VERIFIED_KEY%
        IniWrite, %rbUser%,       %settingsFile%, Main, VerifiedUsername
        MsgBox, 0, Success, Verification successful, enjoy the macro!
    } else {
        MsgBox, 16, Access Denied, Sorry, that account does not own the required game-pass.
        ExitApp
    }
}
*/

Gosub, ShowGui

; main ui
ShowGui:

    Gui, Destroy
    Gui, +Resize +MinimizeBox +SysMenu
    Gui, Margin, 10, 10
    Gui, Color, 0x202020
    Gui, Font, s9 cWhite, Segoe UI
    Gui, Add, Tab, x10 y10 w580 h440 vMyTab, Seeds|Gears|Eggs|Cosmetics|Settings|Credits

    Gui, Tab, 1
    Gui, Font, s9 c90EE90 Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 c90EE90, Seed Shop Items
    IniRead, SelectAllSeeds, %settingsFile%, Seed, SelectAllSeeds, 0
    Gui, Add, Checkbox, % "x50 y90 vSelectAllSeeds gHandleSelectAll c90EE90 " . (SelectAllSeeds ? "Checked" : ""), Select All Seeds
    Loop, % seedItems.Length() {
        IniRead, sVal, %settingsFile%, Seed, Item%A_Index%, 0
        if (A_Index > 18) {
            col := 350
            idx := A_Index - 18
            yBase := 125
        }
        else if (A_Index > 9) {
            col := 200
            idx := A_Index - 10
            yBase := 125
        }
        else {
            col := 50
            idx := A_Index
            yBase := 100
        }
        y := yBase + (idx * 25)
        Gui, Add, Checkbox, % "x" col " y" y " vSeedItem" A_Index " gHandleSelectAll cD3D3D3 " . (sVal ? "Checked" : ""), % seedItems[A_Index]
    }

    Gui, Tab, 2
    Gui, Font, s9 c87CEEB Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 c87CEEB, Gear Shop Items
    IniRead, SelectAllGears, %settingsFile%, Gear, SelectAllGears, 0
    Gui, Add, Checkbox, % "x50 y90 vSelectAllGears gHandleSelectAll c87CEEB " . (SelectAllGears ? "Checked" : ""), Select All Gears
    Loop, % gearItems.Length() {
        IniRead, gVal, %settingsFile%, Gear, Item%A_Index%, 0
        if (A_Index > 9) {
            col := 200
            idx := A_Index - 10
            yBase := 125
        }
        else {
            col := 50
            idx := A_Index
            yBase := 100
        }
        y := yBase + (idx * 25)
        Gui, Add, Checkbox, % "x" col " y" y " vGearItem" A_Index " gHandleSelectAll cD3D3D3 " . (gVal ? "Checked" : ""), % gearItems[A_Index]
    }

    Gui, Tab, 3
    Gui, Font, s9 ce87b07 Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 ce87b07, Egg Shop
    IniRead, SelectAllEggs, %settingsFile%, Egg, SelectAllEggs, 0
    Gui, Add, Checkbox, % "x50 y90 vSelectAllEggs gHandleSelectAll ce87b07 " . (SelectAllEggs ? "Checked" : ""), Select All Eggs
    Loop, % eggItems.Length() {
        IniRead, eVal, %settingsFile%, Egg, Item%A_Index%, 0
        y := 125 + (A_Index - 1) * 25
        Gui, Add, Checkbox, % "x50 y" y " vEggItem" A_Index " gHandleSelectAll cD3D3D3 " . (eVal ? "Checked" : ""), % eggItems[A_Index]
    }

    /*
    Gui, Tab, 4
    Gui, Font, s9 ce8ac07 Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 ce8ac07, Honey
    IniRead, AutoCollectPollinated, %settingsFile%, Honey, AutoCollectPollinated, 0
    Gui, Add, Checkbox, % "x50 y90 vAutoCollectPollinated ce8ac07 " . (AutoCollectPollinated ? "Checked" : ""), Auto-Collect Pollinated Plants
    IniRead, AutoHoney, %settingsFile%, Honey, AutoDepositHoney, 0
    Gui, Add, Checkbox, % "x50 y115 vAutoHoney ce8ac07 " . (AutoHoney ? "Checked" : ""), Auto-Deposit Honey


    Gui, Tab, 5
    Gui, Font, s9 cBF40BF Bold, Segoe UI

    Gui, Add, GroupBox, x23 y50 w230 h380 cBF40BF, Crafting Seeds
    Gui, Add, Text, x40 y130 w200 h40, Coming soon

    IniRead, SelectAllCraft, %settingsFile%, Craft, SelectAllCraft, 0
    Gui, Add, Checkbox, % "x40 y90 vSelectAllCraft gHandleSelectAll cBF40BF " . (SelectAllCraft ? "Checked" : ""), Select All Seeds
    Loop, % craftItems.Length() {
        IniRead, cVal,   %settingsFile%, Craft, Item%A_Index%, 0
        y := 125 + (A_Index - 1) * 25
        Gui, Add, Checkbox, % "x40 y" y " vCraftItem" A_Index " gHandleSelectAll cD3D3D3 " . (cVal ? "Checked" : ""), % craftItems[A_Index]
    }
 

    Gui, Add, GroupBox, x270 y50 w230 h380 cBF40BF, Crafting Tools

    IniRead, SelectAllCraft2, %settingsFile%, Craft2, SelectAllCraft2, 0
    Gui, Add, Checkbox, % "x280 y90 vSelectAllCraft2 gHandleSelectAll cBF40BF " . (SelectAllCraft2 ? "Checked" : ""), Select All Tools
    Loop, % craftItems2.Length() {
        IniRead, c2Val,  %settingsFile%, Craft2, Item%A_Index%, 0
        y := 125 + (A_Index - 1) * 25
        Gui, Add, Checkbox, % "x280 y" y " vCraftItem2" A_Index " gHandleSelectAll cD3D3D3 " . (c2Val ? "Checked" : ""), % craftItems2[A_Index]
    }
    */

    Gui, Tab, 4
    Gui, Font, s9 cD41551 Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 cD41551, Cosmetic Shop
    IniRead, BuyAllCosmetics, %settingsFile%, Cosmetic, BuyAllCosmetics, 0
    Gui, Add, Checkbox, % "x50 y90 vBuyAllCosmetics cD41551 " . (BuyAllCosmetics ? "Checked" : ""), Buy All Cosmetics

    Gui, Tab, 5
    Gui, Font, s9 cWhite Bold, Segoe UI

    ; opt1 := (selectedResolution = 1 ? "Checked" : "")
    ; opt2 := (selectedResolution = 2 ? "Checked" : "")
    ; opt3 := (selectedResolution = 3 ? "Checked" : "")
    ; opt4 := (selectedResolution = 4 ? "Checked" : "")
    
    ;Gui, Add, GroupBox, x30 y200 w260 h110, Resolution
    ; Gui, Add, Text, x50 y220, Resolutions:
    ; IniRead, selectedResolution, %settingsFile%, Main, Resolution, 1
    ; Gui, Add, Radio, x50 y240 vselectedResolution gUpdateResolution c708090 %opt1%, 2560x1440 125`%
    ; Gui, Add, Radio, x50 y260 gUpdateResolution c708090 %opt2%, 2560x1440 100`%
    ; Gui, Add, Radio, x50 y280 gUpdateResolution c708090 %opt3%, 1920x1080 100`%
    ; Gui, Add, Radio, x50 y300 gUpdateResolution c708090 %opt4%, 1280x720 100`%

    Gui, Font, s9, cWhite Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 cD3D3D3, Settings

    IniRead, PingSelected, %settingsFile%, Main, PingSelected, 0
    pingColor := PingSelected ? "c90EE90" : "cD3D3D3"
    Gui, Add, Checkbox, % "x50 y225 vPingSelected gUpdateSettingColor " . pingColor . (PingSelected ? " Checked" : ""), Discord Pings
    
    IniRead, AutoAlign, %settingsFile%, Main, AutoAlign, 0
    autoColor := AutoAlign ? "c90EE90" : "cD3D3D3"
    Gui, Add, Checkbox, % "x50 y250 vAutoAlign gUpdateSettingColor " . autoColor . (AutoAlign ? " Checked" : ""), Auto-Align

    Gui, Font, s8 cD3D3D3 Bold, Segoe UI
    Gui, Add, Text, x50 y90, Webhook URL:
    Gui, Font, s8 cBlack, Segoe UI
    IniRead, savedWebhook, %settingsFile%, Main, UserWebhook
    if (savedWebhook = "ERROR") {
        savedWebhook := ""
    }
    Gui, Add, Edit, x140 y90 w250 h18 vwebhookURL +BackgroundFFFFFF, %savedWebhook%
    Gui, Font, s8 cWhite, Segoe UI
    Gui, Add, Button, x400 y90 w85 h18 gDisplayWebhookValidity Background202020, Save Webhook

    Gui, Font, s8 cD3D3D3 Bold, Segoe UI
    Gui, Add, Text, x50 y115, Discord User ID:
    Gui, Font, s8 cBlack, Segoe UI
    IniRead, savedUserID, %settingsFile%, Main, DiscordUserID
    if (savedUserID = "ERROR") {
        savedUserID := ""
    }
    Gui, Add, Edit, x140 y115 w250 h18 vdiscordUserID +BackgroundFFFFFF, %savedUserID%
    Gui, Font, s8 cD3D3D3 Bold, Segoe UI
    Gui, Add, Button, x400 y115 w85 h18 gUpdateUserID Background202020, Save UserID
    IniRead, savedUserID, %settingsFile%, Main, DiscordUserID


    Gui, Add, Button, x400 y165 w85 h18 gClearSaves Background202020, Clear Saves

    Gui, Font, s8 cD3D3D3 Bold, Segoe UI
    Gui, Add, Text, x50 y165, UI Navigation Keybind:
    Gui, Font, s8 cBlack, Segoe UI
IniRead, SavedKeybind, %settingsFile%, Main, UINavigationKeybind, \
if (SavedKeybind = "")
{
    SavedKeybind := "\"   
    IniWrite, %SavedKeybind%, %settingsFile%, Main, UINavigationKeybind
}
Gui, Add, Edit, x180 y165 w40 h18 Limit1 vSavedKeybind gUpdateKeybind, %SavedKeybind%


    Gui, Font, s8 cD3D3D3 Bold, Segoe UI
    Gui, Add, Text, x50 y190, Macro Speed:
    Gui, Font, s8 cBlack, Segoe UI
    IniRead, SavedSpeed, %settingsFile%, Main, MacroSpeed, Stable
    Gui, Add, DropDownList, vSavedSpeed gUpdateSpeed x130 y190 w50, Stable|Fast|Ultra|Max
    GuiControl, ChooseString, SavedSpeed, %SavedSpeed%

    Gui, Font, s10 cWhite Bold, Segoe UI
    Gui, Add, Button, x50 y335 w150 h40 gStartScanMultiInstance Background202020, Start Macro (F5)
    Gui, Add, Button, x320 y335 w150 h40 gQuit Background202020, Stop Macro (F7)

    Gui, Tab, 6
    Gui, Font, s9 cWhite Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 cD3D3D3, Credits

    Gui, Add, Picture, x40 y70 w48 h48, % mainDir "Images\\Virage.png"
    Gui, Font, s10 cWhite Bold, Segoe UI
    Gui, Add, Text, x100 y70 w200 h24, Virage
    Gui, Font, s8 cFFC0CB Italic, Segoe UI
    Gui, Add, Text, x100 y96 w200 h16, Macro Creator
    Gui, Font, s8 cWhite, Segoe UI
    Gui, Add, Text, x40 y130 w200 h40, This started as a small project that turned into a side quest...

    Gui, Add, Picture, x240 y70 w48 h48, % mainDir "Images\\Real.png"
    Gui, Font, s10 cWhite Bold, Segoe UI
    Gui, Add, Text, x300 y70 w180 h24, Real
    Gui, Font, s8 cWhite, Segoe UI
    Gui, Add, Text, x300 y96 w180 h40, Greatly helped to modify the macro to make it better and more consistent.

    Gui, Font, s9 cWhite Bold, Segoe UI
    Gui, Add, Text, x40 y274 w200 h20, Extra Resources:
    Gui, Font, s8 cD3D3D3 Underline, Segoe UI
    Gui, Add, Link, x40 y294 w300 h16, Join the <a href="https://discord.com/invite/BPPSAG8MN5">Discord Server</a>!
    Gui, Add, Link, x40 y314 w300 h16, Check the <a href="https://github.com/VirageRoblox/Virage-Grow-A-Garden-Macro/releases/latest">Github</a> for the latest macro updates!
    Gui, Add, Link, x40 y334 w300 h16, Watch the latest macro <a href="https://www.youtube.com/@VirageRoblox">tutorial</a> on Youtube!
    ; Gui, Font, s9 cWhite norm, Segoe UI
    ; Gui, Add, GroupBox, x23 y50 w475 h340 cD7A9E3, Donate
    ; Gui, Font, s8 cD7A9E3 Bold, Segoe UI
    ; Gui, Add, Button, x50 y90 w100 h25 gDonate vDonate100 BackgroundF0F0F0, 100 Robux
    ; Gui, Add, Button, x50 y150 w100 h25 gDonate vDonate500 BackgroundF0F0F0, 500 Robux
    ; Gui, Add, Button, x50 y210 w100 h25 gDonate vDonate1000 BackgroundF0F0F0, 1000 Robux
    ; Gui, Add, Button, x50 y270 w100 h25 gDonate vDonate2500 BackgroundF0F0F0, 2500 Robux
    ; Gui, Add, Button, x50 y330 w100 h25 gDonate vDonate10000 BackgroundF0F0F0, 10000 Robux
    
    Gui, Show, w520 h460, Virage Premium GAG Macro [FREE VERSION]

Return

; ui handlers

DisplayWebhookValidity:
    
    Gui, Submit, NoHide

    checkValidity(webhookURL, 1, "webhook")

Return

UpdateUserID:

    Gui, Submit, NoHide

    if (discordUserID != "") {
        IniWrite, %discordUserID%, %settingsFile%, Main, DiscordUserID
        MsgBox, 0, Message, Discord UserID Saved
    }

Return

DisplayServerValidity:

    Gui, Submit, NoHide

    checkValidity(privateServerLink, 1, "privateserver")

Return

ClearSaves:

    IniWrite, %A_Space%, %settingsFile%, Main, UserWebhook
    IniWrite, %A_Space%, %settingsFile%, Main, DiscordUserID
    IniWrite, %A_Space%, %settingsFile%, Main, PrivateServerLink

    IniRead, savedWebhook, %settingsFile%, Main, UserWebhook
    IniRead, savedUserID, %settingsFile%, Main, DiscordUserID
    IniRead, savedServerLink, %settingsFile%, Main, PrivateServerLink

    GuiControl,, webhookURL, %savedWebhook% 
    GuiControl,, discordUserID, %savedUserID% 
    GuiControl,, privateServerLink, %savedServerLink% 

    MsgBox, 0, Message, Webhook, User Id, and Private Server Link Cleared

Return

UpdateKeybind:
    Gui, Submit, NoHide

    if (StrLen(SavedKeybind) != 1)
        return          ; still editing – do nothing yet

    IniWrite, %SavedKeybind%, %settingsFile%, Main, UINavigationKeybind
    GuiControl,, SavedKeybind, %SavedKeybind%
    MsgBox, 0, Message, % "Keybind saved as: " . SavedKeybind
Return



UpdateSpeed:

    Gui, Submit, NoHide

    IniWrite, %SavedSpeed%, %settingsFile%, Main, MacroSpeed
    GuiControl, ChooseString, SavedSpeed, %SavedSpeed%
    if (SavedSpeed = "Fast") {
        MsgBox, 0, Disclaimer, % "Macro speed set to " . SavedSpeed . ". Use with caution (Requires a stable FPS rate)."
    }
    else if (SavedSpeed = "Ultra") {
        MsgBox, 0, Disclaimer, % "Macro speed set to " . SavedSpeed . ". Use at your own risk, high chance of erroring/breaking (Requires a very stable and high FPS rate)."
    }
    else if (SavedSpeed = "Max") {
        MsgBox, 0, Disclaimer, % "Macro speed set to " . SavedSpeed . ". Zero delay on UI Navigation inputs, I wouldn't recommend actually using this it's mostly here for fun."
    }
    else {
        MsgBox, 0, Message, % "Macro speed set to " . SavedSpeed . ". Recommended for lower end devices."
    }

Return

UpdateResolution:

    Gui, Submit, NoHide

    IniWrite, %selectedResolution%, %settingsFile%, Main, Resolution

return

HandleSelectAll:

    Gui, Submit, NoHide

    if (SubStr(A_GuiControl, 1, 9) = "SelectAll") {
        group := SubStr(A_GuiControl, 10)  ; seeds, gears, eggs
        controlVar := A_GuiControl
        Loop {
            item := group . "Item" . A_Index
            if (%item% = "")
                break
            GuiControl,, %item%, % %controlVar%
        }
    }
    else if (RegExMatch(A_GuiControl, "^(Seed|Gear|Egg|Honey)Item\d+$", m)) {
        group := m1  ; seed, gear, egg
        
        assign := (group = "Seed" || group = "Gear" || group = "Egg") ? "SelectAll" . group . "s" : "SelectAll" . group

        if (!%A_GuiControl%)
            GuiControl,, %assign%, 0
    }

    if (A_GuiControl = "SelectAllSeeds") {
        Loop, % seedItems.Length()
            GuiControl,, SeedItem%A_Index%, % SelectAllSeeds
            Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllEggs") {
        Loop, % eggItems.Length()
            GuiControl,, EggItem%A_Index%, % SelectAllEggs
            Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllGears") {
        Loop, % gearItems.Length()
            GuiControl,, GearItem%A_Index%, % SelectAllGears
            Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllHoney") {
        Loop, % realHoneyItems.Length()
            GuiControl,, HoneyItem%A_Index%, % SelectAllHoney
        Gosub, SaveSettings
    }

    else if (A_GuiControl = "SelectAllCraft") {
        Loop, % craftItems.Length()
            GuiControl,, CraftItem%A_Index%, % SelectAllCraft
        Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllCraft2") {
        Loop, % craftItems2.Length()
            GuiControl,, CraftItem2%A_Index%, % SelectAllCraft2
        Gosub, SaveSettings
    }
    else if (RegExMatch(A_GuiControl, "^CraftItem\d+$")) {
        if (!%A_GuiControl%)
            GuiControl,, SelectAllCraft, 0
    }
    else if (RegExMatch(A_GuiControl, "^CraftItem2\d+$")) {
        if (!%A_GuiControl%)
            GuiControl,, SelectAllCraft2, 0
    }
return

UpdateSettingColor:

    Gui, Submit, NoHide

    ; color values
    autoColor := "+c" . (AutoAlign ? "90EE90" : "D3D3D3")
    pingColor := "+c" . (PingSelected ? "90EE90" : "D3D3D3")
    multiInstanceColor := "+c" . (MultiInstanceMode ? "90EE90" : "D3D3D3")
    ; apply colors
    GuiControl, %autoColor%, AutoAlign
    GuiControl, +Redraw, AutoAlign
    

    GuiControl, %pingColor%, PingSelected
    GuiControl, +Redraw, PingSelected

    GuiControl, %multiInstanceColor%, MultiInstanceMode
    GuiControl, +Redraw, MultiInstanceMode

return

Donate:

    DonateResponder(A_GuiControl)
    
Return

HideTooltip:

    ToolTip

return

HidePopupMessage:

    Gui, 99:Destroy

Return

GetScrollCountRes(index, mode := "seed") {

    global scrollCounts_1080p, scrollCounts_1440p_100, scrollCounts_1440p_125
    global gearScroll_1080p, gearScroll_1440p_100, gearScroll_1440p_125

    if (mode = "seed") {
        arr1 := scrollCounts_1080p
        arr2 := scrollCounts_1440p_100
        arr3 := scrollCounts_1440p_125
    } else if (mode = "gear") {
        arr1 := gearScroll_1080p
        arr2 := gearScroll_1440p_100
        arr3 := gearScroll_1440p_125
    }

    arr := (selectedResolution = 1) ? arr1
        : (selectedResolution = 2) ? arr2
        : (selectedResolution = 3) ? arr3
        : []

    loopCount := arr.HasKey(index) ? arr[index] : 0

    return loopCount
}

; item selection

UpdateSelectedItems:

    Gui, Submit, NoHide
    
    selectedSeedItems := []

    Loop, % seedItems.Length() {
        if (SeedItem%A_Index%)
            selectedSeedItems.Push(seedItems[A_Index])
    }

    selectedGearItems := []

    Loop, % gearItems.Length() {
        if (GearItem%A_Index%)
            selectedGearItems.Push(gearItems[A_Index])
    }

    selectedEggItems := []

    Loop, % eggItems.Length() {
        if (eggItem%A_Index%)
            selectedEggItems.Push(eggItems[A_Index])
    }

    selectedHoneyItems := []

    Loop, % realHoneyItems.Length() {
        if (HoneyItem%A_Index%)
            selectedHoneyItems.Push(realHoneyItems[A_Index])
    }

Return

GetSelectedItems() {

    result := ""
    if (selectedSeedItems.Length()) {
        result .= "Seed Items:`n"
        for _, name in selectedSeedItems
            result .= "  - " name "`n"
    }
    if (selectedGearItems.Length()) {
        result .= "Gear Items:`n"
        for _, name in selectedGearItems
            result .= "  - " name "`n"
    }
    if (selectedEggItems.Length()) {
        result .= "Egg Items:`n"
        for _, name in selectedEggItems
            result .= "  - " name "`n"
    }
    if (selectedHoneyItems.Length()) {
        result .= "Honey Items:`n"
        for _, name in selectedHoneyItems
            result .= "  - " name "`n"
    }

    return result
    
}

; macro starts

StartScanMultiInstance:
    
    Gui, Submit, NoHide

    global cycleCount
    global cycleFinished

    global lastGearMinute := -1
    global lastSeedMinute := -1
    global lastEggShopMinute := -1
    global lastCosmeticShopHour := -1
    global lastHoneyShopMinute := -1
    ; global lastHoneyShopHour := -1
    global lastDepositHoneyMinute := -1
    global lastCollectPollinatedHour := -1

    started := 1
    cycleFinished := 1

    currentSection := "StartScanMultiInstance"

    SetTimer, AutoReconnect, Off
    SetTimer, CheckLoadingScreen, Off

    getWindowIDS()

    SendDiscordMessage(webhookURL, "Macro started.")

    if (MultiInstanceMode) {
        MsgBox, 1, Multi-Instance Mode, % "You have " . windowIDS.MaxIndex() . " instances open. (Instance ID's: " . idDisplay . ")`nPress OK to start the macro."
        IfMsgBox, Cancel
            Return
    }

    if WinExist("ahk_id " . firstWindow) {
        WinActivate
        WinWaitActive, , , 2
    }

    if (MultiInstanceMode) {
        for window in windowIDS {

            currentWindow := % windowIDS[window]

            ToolTip, % "Aligning Instance " . window . " (" . currentWindow . ")"
            SetTimer, HideTooltip, -5000

            WinActivate, % "ahk_id " . currentWindow

            Sleep, 500
            SafeClickRelative(0.5, 0.5)
            Sleep, 100
            Gosub, alignment
            Sleep, 100

        }
    }
    else {

        Sleep, 500
        Gosub, alignment
        Sleep, 100

    }

    WinActivate, % "ahk_id " . firstWindow

    Gui, Submit, NoHide
        
    Gosub, UpdateSelectedItems  
    itemsText := GetSelectedItems()

    Sleep, 500

    Gosub, SetTimers

    while (started) {
        if (actionQueue.Length()) {
            SetTimer, AutoReconnect, Off
            ToolTip  
            next := actionQueue.RemoveAt(1)
            if (MultiInstanceMode) {
                for window in windowIDS {
                    currentWindow := % windowIDS[window]
                    instanceNumber := window
                    ToolTip, % "Running Cycle On Instance " . window
                    SetTimer, HideTooltip, -1500
                    SendDiscordMessage(webhookURL, "***Instance " . instanceNumber . "***")
                    WinActivate, % "ahk_id " . currentWindow
                    Sleep, 200
                    SafeClickRelative(midX, midY)
                    Sleep, 200
                    Gosub, % next
                }
            }
            else {
                WinActivate, % "ahk_id " . firstWindow
                Gosub, % next
            }
            if (!actionQueue.MaxIndex()) {
                cycleFinished := 1
            }
            Sleep, 500
        } else {
            Gosub, SetToolTip
            if (cycleFinished) {
                WinActivate, % "ahk_id " . firstWindow
                cycleCount++
                SendDiscordMessage(webhookURL, "[**CYCLE " . cycleCount . " COMPLETED**]")
                cycleFinished := 0
                if (!MultiInstanceMode) {
                    SetTimer, AutoReconnect, 5000
                }
            }
            Sleep, 1000
        }
    }

Return

; actions

AutoBuySeed:

    ; queues if its not the first cycle and the time is a multiple of 5
    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastSeedMinute) {
        lastSeedMinute := currentMinute
        SetTimer, PushBuySeed, -8000
    }

Return

PushBuySeed: 

    actionQueue.Push("BuySeed")

Return

BuySeed:

    currentSection := "BuySeed"
    if (selectedSeedItems.Length())
        Gosub, SeedShopPath

Return

AutoBuyGear:

    ; queues if its not the first cycle and the time is a multiple of 5
    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastGearMinute) {
        lastGearMinute := currentMinute
        SetTimer, PushBuyGear, -8000
    }

Return

PushBuyGear: 

    actionQueue.Push("BuyGear")

Return

BuyGear:

    currentSection := "BuyGear"
    if (selectedGearItems.Length())
        Gosub, GearShopPath

Return

AutoBuyEggShop:

    ; queues if its not the first cycle and the time is a multiple of 30
    if (cycleCount > 0 && Mod(currentMinute, 30) = 0 && currentMinute != lastEggShopMinute) {
        lastEggShopMinute := currentMinute
        SetTimer, PushBuyEggShop, -8000
    }

Return

PushBuyEggShop: 

    actionQueue.Push("BuyEggShop")

Return

BuyEggShop:

    currentSection := "BuyEggShop"
    if (selectedEggItems.Length()) {
        Gosub, EggShopPath
    } 

Return

AutoBuyCosmeticShop:

    ; queues if its not the first cycle, the minute is 0, and the current hour is an even number (every 2 hours)
    if (cycleCount > 0 && currentMinute = 0 && Mod(currentHour, 2) = 0 && currentHour != lastCosmeticShopHour) {
        lastCosmeticShopHour := currentHour
        SetTimer, PushBuyCosmeticShop, -8000
    }

Return

PushBuyCosmeticShop: 

    actionQueue.Push("BuyCosmeticShop")

Return

BuyCosmeticShop:

    currentSection := "BuyCosmeticShop"
    if (BuyAllCosmetics) {
        Gosub, CosmeticShopPath
    } 

Return

AutoCollectPollinated:

     ; queues if its not the first cycle, the minute is 0, and the current hour isn't the same as the last hour it was run
    if (cycleCount > 0 && currentMinute = 0 && currentHour != lastCollectPollinatedHour) {
        lastHoneyShopHour := currentHour
        SetTimer, PushCollectPollinated, -600000
    }

Return

PushCollectPollinated:

    actionQueue.Push("CollectPollinated")

Return

CollectPollinated:

    currentSection := "CollectPollinated"
    if (AutoCollectPollinated) {
        Gosub, CollectPollinatedPath
    }

Return

AutoBuyHoneyShop:

    ; queues if its not the first cycle and the time is a multiple of 30
    if (cycleCount > 0 && Mod(currentMinute, 30) = 0 && currentMinute != lastHoneyShopMinute) {
        lastHoneyShopMinute := currentMinute
        SetTimer, PushBuyHoneyShop, -8000
    }

Return

PushBuyHoneyShop:

    actionQueue.Push("BuyHoneyShop")

Return

BuyHoneyShop:

    currentSection := "BuyHoneyShop"
    if (selectedHoneyItems.Length()) {
        Gosub, HoneyShop
    }

Return

AutoDepositHoney:

    ; queues if its not the first cycle and the time is a multiple of 5
    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastDepositHoneyMinute) {
        lastDepositHoneyMinute := currentMinute
        SetTimer, PushDepositHoney, -8000
    }

Return

PushDepositHoney:

    actionQueue.Push("DepositHoney")

Return

DepositHoney:

    currentSection := "DepositHoney"
    if (AutoHoney) {
        Gosub, DepositHoneyPath
    }

Return

; helper labels

SetToolTip:

    mod5 := Mod(currentMinute, 5)
    rem5min := (mod5 = 0) ? 5 : 5 - mod5
    rem5sec := rem5min * 60 - currentSecond
    if (rem5sec < 0)
        rem5sec := 0
    seedMin := rem5sec // 60
    seedSec := Mod(rem5sec, 60)
    seedText := (seedSec < 10) ? seedMin . ":0" . seedSec : seedMin . ":" . seedSec
    gearMin := rem5sec // 60
    gearSec := Mod(rem5sec, 60)
    gearText := (gearSec < 10) ? gearMin . ":0" . gearSec : gearMin . ":" . gearSec
    depositHoneyMin := rem5sec // 60
    depositHoneySec := Mod(rem5sec, 60)
    depositHoneyText := (depositHoneySec < 10) ? depositHoneyMin . ":0" . depositHoneySec : depositHoneyMin . ":" . depositHoneySec

    mod30 := Mod(currentMinute, 30)
    rem30min := (mod30 = 0) ? 30 : 30 - mod30
    rem30sec := rem30min * 60 - currentSecond
    if (rem30sec < 0)
        rem30sec := 0
    eggMin := rem30sec // 60
    eggSec := Mod(rem30sec, 60)
    eggText := (eggSec < 10) ? eggMin . ":0" . eggSec : eggMin . ":" . eggSec
    honeyMin := rem30sec // 60
    honeySec := Mod(rem30sec, 60)
    honeyText := (honeySec < 10) ? honeyMin . ":0" . honeySec : honeyMin . ":" . honeySec

    totalSecNow := currentHour * 3600 + currentMinute * 60 + currentSecond
    nextCosHour := (Floor(currentHour/2) + 1) * 2
    nextCosTotal := nextCosHour * 3600
    remCossec := nextCosTotal - totalSecNow
    if (remCossec < 0)
        remCossec := 0
    cosH := remCossec // 3600
    cosM := (remCossec - cosH*3600) // 60
    cosS := Mod(remCossec, 60)
    if (cosH > 0)
        cosText := cosH . ":" . (cosM < 10 ? "0" . cosM : cosM) . ":" . (cosS < 10 ? "0" . cosS : cosS)
    else
        cosText := cosM . ":" . (cosS < 10 ? "0" . cosS : cosS)

    if (currentMinute = 0 && currentSecond = 0) {
        remHoneySec := 0
    } else {
        remHoneySec := 3600 - (currentMinute * 60 + currentSecond)
    }
    collectPollinatedMin := remHoneySec // 60
    collectPollinatedSec := Mod(remHoneySec, 60)
    collectPollinatedText := (collectPollinatedSec < 10) ? collectPollinatedMin . ":0" . collectPollinatedSec : collectPollinatedMin . ":" . collectPollinatedSec

    tooltipText := ""
    if (selectedSeedItems.Length()) {
        tooltipText .= "Seed Shop: " . seedText . "`n"
    }
    if (selectedGearItems.Length()) {
        tooltipText .= "Gear Shop: " . gearText . "`n"
    }
    if (selectedEggItems.Length()) {
        tooltipText .= "Egg Shop : " . eggText . "`n"
    }
    if (BuyAllCosmetics) {
        tooltipText .= "Cosmetic Shop: " . cosText . "`n"
    }
    if (AutoHoney) {
        tooltipText .= "Deposit Honey: " . depositHoneyText . "`n"
    }
    if (selectedHoneyItems.Length()) {
        tooltipText .= "Honey Shop: " . honeyText . "`n"
    }
    if (AutoCollectPollinated) {
        tooltipText .= "Collect Pollinated: " . collectPollinatedText . "`n"
    }

    if (tooltipText != "") {
        CoordMode, Mouse, Screen
        MouseGetPos, mX, mY
        offsetX := 10
        offsetY := 10
        ToolTip, % tooltipText, % (mX + offsetX), % (mY + offsetY)
    } else {
        ToolTip  ; clears any existing tooltip
    }

Return

SetTimers:

    SetTimer, UpdateTime, 1000

    if (selectedSeedItems.Length()) {
        actionQueue.Push("BuySeed")
    }
    seedAutoActive := 1
    SetTimer, AutoBuySeed, 1000 ; checks every second if it should queue

    if (selectedGearItems.Length()) {
        actionQueue.Push("BuyGear")
    }
    gearAutoActive := 1
    SetTimer, AutoBuyGear, 1000 ; checks every second if it should queue

    if (selectedEggItems.Length()) {
        actionQueue.Push("BuyEggShop")
    }
    eggAutoActive := 1
    SetTimer, AutoBuyEggShop, 1000 ; checks every second if it should queue

    if (BuyAllCosmetics) {
        actionQueue.Push("BuyCosmeticShop")
    }
    cosmeticAutoActive := 1
    SetTimer, AutoBuyCosmeticShop, 1000 ; checks every second if it should queue

    if (AutoCollectPollinated) {
        actionQueue.Push("CollectPollinated")
    }
    collectPollinatedAutoActive := 1
    SetTimer, AutoCollectPollinated, 1000 ; checks every second if it should queue

    if (selectedHoneyItems.Length()) {
        actionQueue.Push("BuyHoneyShop")
    }
    honeyShopAutoActive := 1
    SetTimer, AutoBuyHoneyShop, 1000 ; checks every second if it should queue

    if (AutoHoney) {
        actionQueue.Push("DepositHoney")
    }
    honeyDepositAutoActive := 1
    SetTimer, AutoDepositHoney, 1000 ; checks every second if it should queue

Return

/*
VerifyUser(username) {
    global GAME_PASS_ID
    username := Trim(username)

    reqBody := "{""usernames"":[""" username """],""excludeBannedUsers"":true}"
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("POST","https://users.roblox.com/v1/usernames/users",false)
    whr.SetRequestHeader("Content-Type","application/json")
    whr.Send(reqBody),  whr.WaitForResponse()
    if (whr.Status!=200 || !RegExMatch(whr.ResponseText,"""id"":\s*(\d+)",m))
        return 0
    userId := m1

    ownURL := "https://inventory.roblox.com/v1/users/" userId
           .  "/items/GamePass/" GAME_PASS_ID
    whr2 := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr2.Open("GET",ownURL,false), whr2.Send(), whr2.WaitForResponse()
    if (whr2.Status!=200)                        ; request itself failed
        return 0

    return !RegExMatch(whr2.ResponseText, """data"":\s*\[\s*\]")
}


IniRead, isVerified, %settingsFile%, Main, %VERIFIED_KEY%, 0
if (!isVerified) {
    InputBox, rbUser, Premium Access, Please enter your Roblox username:
    if (ErrorLevel)
        ExitApp   ; user cancelled

    if (VerifyUser(rbUser)) {
        IniWrite, 1,              %settingsFile%, Main, %VERIFIED_KEY%
        IniWrite, %rbUser%,       %settingsFile%, Main, VerifiedUsername
        MsgBox, 0, Success, Verification successful, enjoy the macro!
    } else {
        MsgBox, 16, Access Denied, Sorry, that account does not own the required game-pass.
        ExitApp
    }
}
*/


UpdateTime:

    FormatTime, currentHour,, hh
    FormatTime, currentMinute,, mm
    FormatTime, currentSecond,, ss

    currentHour := currentHour + 0
    currentMinute := currentMinute + 0
    currentSecond := currentSecond + 0

Return

AutoReconnect:

    global actionQueue

    if (simpleDetect(0x302927, 0, 0.3988, 0.3548, 0.6047, 0.6674) && simpleDetect(0xFFFFFF, 0, 0.3988, 0.3548, 0.6047, 0.6674) && privateServerLink != "") {
        started := 0
        actionQueue := []
        SetTimer, AutoReconnect, Off
        Sleep, 500
        WinClose, % "ahk_id" . firstWindow
        Sleep, 1000
        WinClose, % "ahk_id" . firstWindow
        Sleep, 500
        Run, % privateServerLink
        ToolTip, Attempting To Reconnect
        SetTimer, HideTooltip, -5000
        SendDiscordMessage(webhookURL, "Lost connection or macro errored, attempting to reconnect..." . (PingSelected ? " <@" . discordUserID . ">" : ""))
        sleepAmount(15000, 30000)
        SetTimer, CheckLoadingScreen, 5000
    }

Return

CheckLoadingScreen:

    ToolTip, Detecting Rejoin

    getWindowIDS()

    WinActivate, % "ahk_id" . firstWindow

    if (simpleDetect(0x000000, 0, 0.75, 0.75, 0.9, 0.9)) {
        SafeClickRelative(midX, midY)
    }
    else {
        ToolTip, Rejoined Successfully
        sleepAmount(5000, 10000)
        SendDiscordMessage(webhookURL, "Successfully reconnected to server." . (PingSelected ? " <@" . discordUserID . ">" : ""))
        Sleep, 200
        Gosub, StartScanMultiInstance
    }

Return

; set up labels

alignment:

    ToolTip, Beginning Alignment
    SetTimer, HideTooltip, -5000

    SafeClickRelative(0.5, 0.5)
    Sleep, 100

    searchitem("recall")

    Sleep, 200

    if (AutoAlign) {
        GoSub, cameraChange
        Sleep, 100
        Gosub, zoomAlignment
        Sleep, 100
        GoSub, cameraAlignment
        Sleep, 100
        Gosub, characterAlignment
        Sleep, 100
        Gosub, cameraChange
        Sleep, 100
        }
    else {
        Gosub, zoomAlignment
        Sleep, 100
    }

    Sleep, 1000
    uiUniversal(11110)
    Sleep, 100

    ToolTip, Alignment Complete
    SetTimer, HideTooltip, -1000

Return

cameraChange:

    ; changes camera mode to follow and can be called again to reverse it (0123, 0->3, 3->0)
    Send, {Escape}
    Sleep, 500
    Send, {Tab}
    Sleep, 400
    Send {Down}
    Sleep, 100
    repeatKey("Right", 2, (SavedSpeed = "Ultra") ? 55 : (SavedSpeed = "Max") ? 60 : 30)
    Sleep, 100
    Send {Escape}

Return

cameraAlignment:

    ; puts character in overhead view
    Click, Right, Down
    Sleep, 200
    SafeMoveRelative(0.5, 0.5)
    Sleep, 200
    MouseMove, 0, 800, R
    Sleep, 200
    Click, Right, Up

Return

zoomAlignment:

    ; sets correct player zoom
    SafeMoveRelative(0.5, 0.5)
    Sleep, 100

    Loop, 40 {
        Send, {WheelUp}
        Sleep, 20
    }

    Sleep, 200

    Loop, 6 {
        Send, {WheelDown}
        Sleep, 20
    }

    midX := getMouseCoord("x")
    midY := getMouseCoord("y")

Return

characterAlignment:

    ; aligns character through spam tping and using the follow camera mode

    sendKeybind(SavedKeybind)
    Sleep, 10

    repeatKey("Right", 3)
    Loop, % ((SavedSpeed = "Ultra") ? 12 : (SavedSpeed = "Max") ? 18 : 8) {
    Send, {Enter}
    Sleep, 10
    repeatKey("Right", 2)
    Sleep, 10
    Send, {Enter}
    Sleep, 10
    repeatKey("Left", 2)
    }
    Sleep, 10
    sendKeybind(SavedKeybind)

Return

; buying paths

EggShopPath:
	
	eggsCompleted := 0
	
    Sleep, 100
    uiUniversal("11110")
    Sleep, 100
    hotbarController(1, 0, "2")
    sleepAmount(100, 1000)
    SafeClickRelative(midX, midY)
    SendDiscordMessage(webhookURL, "**[Egg Cycle]**")
    Sleep, 1000
	Send, {w Down}
    Sleep, 600
    Send {w Up}
    sleepAmount(500, 1000)
    Send, {e}
    sleepAmount(1500, 5000)
    dialogueClick("egg")
	sleepAmount(2500, 5000)
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00CCFF, 10, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Egg Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Egg Shop Opened.")
            Sleep, 200
            uiUniversal("33311443333114405550555", 0)
            Sleep, 100
            buyUniversal("egg")
            SendDiscordMessage(webhookURL, "Egg Shop Closed.")
            eggsCompleted = 1
        }
        if (eggsCompleted) {
            break
        }
        Sleep, 2000
    }
	
	closeShop("egg", eggsCompleted)

    hotbarController(0, 1, "0")
    SendDiscordMessage(webhookURL, "**[Eggs Completed]**")

Return

SeedShopPath:

    seedsCompleted := 0

    uiUniversal("1111020")
    sleepAmount(100, 1000)
    Send, {e}
    SendDiscordMessage(webhookURL, "**[Seed Cycle]**")
    sleepAmount(2500, 5000)
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00CCFF, 10, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Seed Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Seed Shop Opened.")
            Sleep, 200
            uiUniversal("33311443333114405550555", 0)
            Sleep, 100
            buyUniversal("seed")
            SendDiscordMessage(webhookURL, "Seed Shop Closed.")
            seedsCompleted = 1
        }
        if (seedsCompleted) {
            break
        }
        Sleep, 2000
    }

    closeShop("seed", seedsCompleted)

    Sleep, 200
    Gosub, alignment
    Sleep, 200

    SendDiscordMessage(webhookURL, "**[Seeds Completed]**")

Return

GearShopPath:

    gearsCompleted := 0

    hotbarController(0, 1, "0")
    uiUniversal("11110")
    sleepAmount(100, 500)
    hotbarController(1, 0, "2")
    sleepAmount(100, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(1200, 2500)
    Send, {e}
    sleepAmount(1500, 5000)
    dialogueClick("gear")
    SendDiscordMessage(webhookURL, "**[Gear Cycle]**")
    sleepAmount(2500, 5000)
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00CCFF, 10, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Gear Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Gear Shop Opened.")
            Sleep, 200
            uiUniversal("33311443333114405550555", 0)
            Sleep, 100
            buyUniversal("gear")
            SendDiscordMessage(webhookURL, "Gear Shop Closed.")
            gearsCompleted = 1
        }
        if (gearsCompleted) {
            break
        }
        Sleep, 2000
    }

    closeShop("gear", gearsCompleted)

    hotbarController(0, 1, "0")
    SendDiscordMessage(webhookURL, "**[Gears Completed]**")

Return

CosmeticShopPath:

    cosmeticsCompleted := 0

    hotbarController(0, 1, "0")
    uiUniversal("11110")
    sleepAmount(100, 500)
    hotbarController(1, 0, "2")
    sleepAmount(100, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(800, 1000)
    Send, {s Down}
    Sleep, 550
    Send, {s Up}
    sleepAmount(100, 1000)
    Send, {e}
    sleepAmount(2500, 5000)
    SendDiscordMessage(webhookURL, "**[Cosmetic Cycle]**")
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00CCFF, 10, 0.61, 0.182, 0.764, 0.259)) {
            ToolTip, Cosmetic Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Cosmetic Shop Opened.")
            Sleep, 200
            for index, item in cosmeticItems {
                label := StrReplace(item, " ", "")
                currentItem := cosmeticItems[A_Index]
                Gosub, %label%
                SendDiscordMessage(webhookURL, "Bought " . currentItem . (PingSelected ? " <@" . discordUserID . ">" : ""))
                Sleep, 100
            }
            SendDiscordMessage(webhookURL, "Cosmetic Shop Closed.")
            cosmeticsCompleted = 1
        }
        if (cosmeticsCompleted) {
            break
        }
        Sleep, 2000
    }

    if (cosmeticsCompleted) {
        Sleep, 500
        uiUniversal("111114150320")
    }
    else {
        SendDiscordMessage(webhookURL, "Failed To Detect Cosmetic Shop Opening [Error]" . (PingSelected ? " <@" . discordUserID . ">" : ""))
        ; failsafe
        uiUniversal("11114111350")
        Sleep, 50
        uiUniversal("11110")
    }

    hotbarController(0, 1, "0")
    SendDiscordMessage(webhookURL, "**[Cosmetics Completed]**")

Return

CollectPollinatedPath:

    SendDiscordMessage(webhookURL, "**[Pollenated Plant Collection Cycle]**")
    uiUniversal("11110")
    sleepAmount(1000, 2000)

    searchItem("pollen")
    hotbarController(1, 0, "3")

    ; left side
    SendDiscordMessage(webhookURL, "**[Collecting Left Side...]**")
    Send, {s down}
    Sleep, 270
    Send, {s up}
    sleepAmount(200, 500)
    Send, {a down}
    Sleep, 900
    Send, {a up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {a down}
    Sleep, 800
    Send, {a up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {a down}
    Sleep, 600
    Send, {a up}
    sleepAmount(200, 500)

    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1200
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1300
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)

    Send, {d down}
    Sleep, 900
    Send, {d up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {d down}
    Sleep, 800
    Send, {d up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {d down}
    Sleep, 600
    Send, {d up}
    sleepAmount(200, 500)

    uiUniversal("11110")

    ; right side
    SendDiscordMessage(webhookURL, "**[Collecting Right Side...]**")
    Send, {s down}
    Sleep, 270
    Send, {s up}
    sleepAmount(200, 500)
    Send, {d down}
    Sleep, 800
    Send, {d up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {d down}
    Sleep, 800
    Send, {d up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {d down}
    Sleep, 600
    Send, {d up}
    sleepAmount(200, 500)

    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1200
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1300
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)

    Send, {a down}
    Sleep, 900
    Send, {a up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {a down}
    Sleep, 800
    Send, {a up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {a down}
    Sleep, 600
    Send, {a up}
    sleepAmount(200, 500)

    uiUniversal("11110")

    ; middle
    SendDiscordMessage(webhookURL, "**[Collecting Middle Area...]**")
    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1200
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1300
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)

    hotbarController(0, 1, "0")
    uiUniversal(11110)

    SendDiscordMessage(webhookURL, "**[Pollenated Plant Collection Completed]**")

Return

DepositHoneyPath:
    depositCount := 0

    hotbarController(0, 1, "0")
    uiUniversal("11110")
    sleepAmount(100, 500)
    hotbarController(1, 0, "2")
    sleepAmount(100, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(800, 1000)
    Send, {s Down}
    Sleep, 2000
    Send, {s Up}
    sleepAmount(100, 1000)
    Loop, 3 {
        searchItem("pollinated")
        hotbarController(1, 0, "9")
        sleepAmount(100, 500)
        Loop, 2 {
            Send {e}
            Sleep, 200
        }
        depositCount++
        SendDiscordMessage(webhookURL, "Depositing/Collecting Honey Try #" . depositCount . ".")
        Sleep, 1000
    }

    hotbarController(0, 1, "0")
    uiUniversal(11110)

    SendDiscordMessage(webhookURL, "**[Honey Deposit Completed]**")

Return

HoneyShop:

    honeyCompleted := 0

    SendDiscordMessage(webhookURL, "**[Honey Shop Cycle]**")
    uiUniversal("1111020")
    sleepAmount(1000, 2000)
    Send, {d down}
    Sleep, 9050
    Send, {d up}
    sleepAmount(100, 1000)
    Send, {w down}
    Sleep, 250
    Send, {w up}
    Loop, 2 {
        Send, {WheelDown}
        Sleep, 20
    }
    sleepAmount(500, 1500)
    Send, {e}
    sleepAmount(500, 1500)
    Loop, 2 {
        Send, {WheelUp}
        Sleep, 20
    }
    sleepAmount(500, 2000)
    dialogueClick("honey")
    sleepAmount(2500, 5000)
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x02EFD3, 10, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Honey Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Honey Shop Opened.")
            Sleep, 200
            uiUniversal("3333114443333311405550555", 0)
            Sleep, 100
            buyUniversal("honey")
            SendDiscordMessage(webhookURL, "Honey Shop Closed.")
            honeyCompleted = 1
        }
        if (honeyCompleted) {
            break
        }
        Sleep, 2000
    }

    closeShop("honey", honeyCompleted)

    hotbarController(0, 1, "0")
    SendDiscordMessage(webhookURL, "**[Honey Shop Completed]**")

Return

; cosmetic labels

Cosmetic1:

    Sleep, 50
    Loop, 5 {
        uiUniversal("111114450")
        sleepAmount(50, 200)
    }

Return

Cosmetic2:

    Sleep, 50
    Loop, 5 {
        uiUniversal("11111442250")
        sleepAmount(50, 200)
    }

Return

Cosmetic3:

    Sleep, 50
    Loop, 5 {
        uiUniversal("1111144222250")
        sleepAmount(50, 200)
    }

Return

Cosmetic4:

    Sleep, 50
    Loop, 5 {
        uiUniversal("11111442222450")
        sleepAmount(50, 200)
    }

Return

Cosmetic5:

    Sleep, 50
    Loop, 5 {
        uiUniversal("111114422224150")
        sleepAmount(50, 200)
    }

Return

Cosmetic6:

    Sleep, 50
    Loop, 5 {
        uiUniversal("1111144222241150")
        sleepAmount(50, 200)
    }

Return

Cosmetic7:

    Sleep, 50
    Loop, 5 {
        uiUniversal("11111442222411150")
        sleepAmount(50, 200)
    }

Return

Cosmetic8:

    Sleep, 50
    Loop, 5 {
        uiUniversal("111114422224111150")
        sleepAmount(50, 200)
    }

Return

Cosmetic9:

    Sleep, 50
    Loop, 5 {
        uiUniversal("1111144222241111150")
        sleepAmount(50, 200)
    }

Return

; save settings and start/exit

SaveSettings:
    Gui, Submit, NoHide

    ; — Egg section —
    Loop, % eggItems.Length()
        IniWrite, % (EggItem%A_Index%    ? 1 : 0), %settingsFile%, Egg, Item%A_Index%
    IniWrite, % SelectAllEggs,         %settingsFile%, Egg, SelectAllEggs

    ; — Gear section —
    Loop, % gearItems.Length()
        IniWrite, % (GearItem%A_Index%   ? 1 : 0), %settingsFile%, Gear, Item%A_Index%
    IniWrite, % SelectAllGears,        %settingsFile%, Gear, SelectAllGears

    ; — Seed section —
    Loop, % seedItems.Length()
        IniWrite, % (SeedItem%A_Index%   ? 1 : 0), %settingsFile%, Seed, Item%A_Index%
    IniWrite, % SelectAllSeeds,        %settingsFile%, Seed, SelectAllSeeds

    ; — Honey section —
    ; first the “place” items 1–10
    Loop, 10
        IniWrite, % (HoneyItem%A_Index%  ? 1 : 0), %settingsFile%, Honey, Item%A_Index%
    IniWrite, % SelectAllHoney,        %settingsFile%, Honey, SelectAllHoney
    IniWrite, % AutoHoney,             %settingsFile%, Honey, AutoDepositHoney
    ; then 11–14
    Loop, % realHoneyItems.Length()
        if (A_Index > 10 && A_Index <= 14)
            IniWrite, % (HoneyItem%A_Index% ? 1 : 0), %settingsFile%, Honey, Item%A_Index%
    IniWrite, % AutoCollectPollinated, %settingsFile%, Honey, AutoCollectPollinated

    ; — Main section —
    IniWrite, % AutoAlign,             %settingsFile%, Main, AutoAlign
    IniWrite, % PingSelected,          %settingsFile%, Main, PingSelected
    IniWrite, % MultiInstanceMode,     %settingsFile%, Main, MultiInstanceMode
    IniWrite, % SavedSpeed,            %settingsFile%, Main, MacroSpeed
    IniWrite, % privateServerLink,     %settingsFile%, Main, PrivateServerLink
    IniWrite, % discordUserID,         %settingsFile%, Main, DiscordUserID
    IniWrite, % SavedKeybind,          %settingsFile%, Main, UINavigationKeybind
    IniWrite, % webhookURL,            %settingsFile%, Main, UserWebhook

    ; — Cosmetic section —
    IniWrite, % BuyAllCosmetics,       %settingsFile%, Cosmetic, BuyAllCosmetics

    ; — CraftSeed section —
    IniWrite, % SelectAllCraft,        %settingsFile%, CraftSeed, SelectAllCraftSeed

    ; — CraftTool section —
    IniWrite, % SelectAllCraft2,       %settingsFile%, CraftTool, SelectAllCraftTool

    ; — Craft (seeds) section —
    Loop, % craftItems.Length()
        IniWrite, % (CraftItem%A_Index% ? 1 : 0), %settingsFile%, Craft, Item%A_Index%
    IniWrite, % SelectAllCraft,        %settingsFile%, Craft, SelectAllCraft

    ; — Craft2 (tools) section —
    Loop, % craftItems2.Length()
        IniWrite, % (CraftItem2%A_Index%?1:0), %settingsFile%, Craft2, Item%A_Index%
    IniWrite, % SelectAllCraft2,       %settingsFile%, Craft2, SelectAllCraft2

Return

StopMacro(terminate := 1) {

    Gui, Submit, NoHide
    Sleep, 50
    started := 0
    Gosub, SaveSettings
    Gui, Destroy
    if (terminate)
        ExitApp

}

PauseMacro(terminate := 1) {

    Gui, Submit, NoHide
    Sleep, 50
    started := 0
    Gosub, SaveSettings

}

; pressing x on window closes macro 
GuiClose:

    StopMacro(1)

Return

; pressing f7 button reloads
Quit:

    PauseMacro(1)
    SendDiscordMessage(webhookURL, "Macro reloaded.")
    Reload ; ahk built in reload

Return

; f7 reloads
F7::

    PauseMacro(1)
    SendDiscordMessage(webhookURL, "Macro reloaded.")
    Reload ; ahk built in reload

Return

; f5 starts scan
F5:: 

Gosub, StartScanMultiInstance

Return

#MaxThreadsPerHotkey, 2
