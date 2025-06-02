"use strict";var W=Object.create;var g=Object.defineProperty;var G=Object.getOwnPropertyDescriptor;var K=Object.getOwnPropertyNames;var M=Object.getPrototypeOf,R=Object.prototype.hasOwnProperty;var D=(e,n)=>{for(var t in n)g(e,t,{get:n[t],enumerable:!0})},$=(e,n,t,o)=>{if(n&&typeof n=="object"||typeof n=="function")for(let s of K(n))!R.call(e,s)&&s!==t&&g(e,s,{get:()=>n[s],enumerable:!(o=G(n,s))||o.enumerable});return e};var A=(e,n,t)=>(t=e!=null?W(M(e)):{},$(n||!e||!e.__esModule?g(t,"default",{value:e,enumerable:!0}):t,e)),F=e=>$(g({},"__esModule",{value:!0}),e);var q={};D(q,{default:()=>P,onlyName:()=>x,openIn:()=>f,terminal:()=>u});module.exports=F(q);var i=require("@raycast/api"),h=require("react");var I=A(require("node:process"),1),E=require("node:util"),v=require("node:child_process"),O=(0,E.promisify)(v.execFile);async function l(e,{humanReadableOutput:n=!0}={}){if(I.default.platform!=="darwin")throw new Error("macOS only");let t=n?[]:["-ss"],{stdout:o}=await O("osascript",["-e",e,t]);return o.trim()}var y=require("@raycast/api"),_=A(require("fs")),L=(0,y.getPreferenceValues)(),m=L.sshConfig.replace("~",process.env.HOME);function N(e){let t=_.readFileSync(e,"utf8").split(`
`),o=[],s=null;for(let r of t){let d=r.trim();if(!(d.startsWith("#")||d==="")){if(d.startsWith("Host ")&&d!=="Host *")s!==null&&o.push(s),s={id:o.length.toString(),address:"",name:d.substring(5),user:""};else if(s!==null){let w=d.indexOf(" "),a=d.substring(0,w),p=d.substring(w+1);switch(a){case"HostName":s.address=p;break;case"User":s.user=p;break;case"Port":s.port=p;break;case"IdentityFile":s.sshKey=p;break;case"HostNameKey":break;case"RemoteCommand":s.command=p;break;default:break}}}}return s!==null&&o.push(s),o}function U(e,n){let t="";for(let o of n)t+=`Host ${o.name}
`,t+=`  HostName ${o.address}
`,o.user&&(t+=`  User ${o.user}
`),o.port&&(t+=`  Port ${o.port}
`),o.sshKey&&(t+=`  IdentityFile ${o.sshKey}
`),o.command&&(t+=`  RemoteCommand ${o.command}
`),t+=`
`;_.writeFileSync(e,t.trimEnd())}async function b(){switch(m){case"localStorage":{let{connections:e}=await y.LocalStorage.allItems();return e?JSON.parse(e):[]}default:return _.existsSync(m)?N(m):[]}}async function T(e){switch(m){case"localStorage":await y.LocalStorage.setItem("connections",JSON.stringify(e));break;default:U(m,e);break}}var c=require("react/jsx-runtime"),C=(0,i.getPreferenceValues)(),u=C.terminal,f=C.openin,x=C.onlyname;async function j(e){let n;if(x)n=["ssh",e.name].join(" ");else{let a="";e.sshKey&&(a=`-i ${e.sshKey} `);let p="";e.port&&(p=`-p ${e.port} `);let H="",k="";e.command&&(H=`\\"${e.command}\\" `,k="-t");let S=e.address;e.user&&(S=`${encodeURIComponent(e.user)}@${S}`),n=["ssh",k,a,S,p,H].filter(Boolean).join(" ")}let t=`
      -- For the latest version:
      -- https://github.com/DavidMChan/custom-alfred-warp-scripts

      -- Set this property to true to always open in a new window
      property open_in_new_window : ${f=="newWindow"}

      -- Set this property to true to always open in a new tab
      property open_in_new_tab : ${f=="newTab"}

      -- Don't change this :)
      property opened_new_window : false

      -- Handlers
      on new_window()
          tell application "System Events" to tell process "Warp"
              click menu item "New Window" of menu "File" of menu bar 1
              set frontmost to true
          end tell
          delay 0.5
      end new_window

      on new_tab()
          tell application "System Events" to tell process "Warp"
              click menu item "New Tab" of menu "File" of menu bar 1
              set frontmost to true
          end tell
      end new_tab

      on call_forward()
          tell application "Warp" to activate
      end call_forward

      on is_running()
          application "Warp" is running
      end is_running

      on has_windows()
          if not is_running() then return false
          tell application "System Events"
              if windows of process "Warp" is {} then return false
          end tell
          true
      end has_windows

      on send_text(custom_text)
          tell application "System Events"
              keystroke custom_text
          end tell
      end send_text


      -- Main
      if not is_running() then
          call_forward()
          set opened_new_window to true
      else
          call_forward()
          set opened_new_window to false
      end if

      if has_windows() then
          if open_in_new_window and not opened_new_window then
              new_window()
          else if open_in_new_tab and not opened_new_window then
              new_tab()
          end if
      else
          new_window()
      end if


      -- Make sure a window exists before we continue, or the write may fail
      repeat until has_windows()
          delay 0.5
      end repeat
      delay 0.5

      send_text("${n}")
      call_forward()
  `,o=`
    tell application "Terminal"
      do script ""
      activate
      set position of front window to {1, 1}
      set shell to do script "${n}" in window 1
    end tell

    tell application "System Events" to tell process "Terminal"
        set frontmost to true
        windows where title contains "bash"
        if result is not {} then perform action "AXRaise" of item 1 of result
    end tell
  `,s=`
    -- Set this property to true to open in a new window instead of a new tab
      property open_in_new_window : ${f=="newWindow"}

    on new_window()
    	tell application "iTerm" to create window with default profile
    end new_window

    on new_tab()
    	tell application "iTerm" to tell the first window to create tab with default profile
    end new_tab

    on call_forward()
    	tell application "iTerm" to activate
    end call_forward

    on is_running()
    	application "iTerm" is running
    end is_running

    on is_processing()
    	tell application "iTerm" to tell the first window to tell current session to get is processing
    end is_processing

    on has_windows()
    	if not is_running() then return false
    	if windows of application "iTerm" is {} then return false
    	true
    end has_windows

    on send_text(custom_text)
    	tell application "iTerm" to tell the first window to tell current session to write text custom_text
    end send_text

    -- Main
    if has_windows() then
      if open_in_new_window then
        new_window()
      else
        new_tab()
      end if
    else
    	-- If iTerm is not running and we tell it to create a new window, we get two
    	-- One from opening the application, and the other from the command
    	if is_running() then
    		new_window()
    	else
    		call_forward()
    	end if
    end if

    -- Make sure a window exists before we continue, or the write may fail
    repeat until has_windows()
    	delay 0.01
    end repeat

    send_text("${n}")
    call_forward()
  `,r=`
  -- Set this property to true to always open in a new window
  property open_in_new_window : ${f=="newWindow"}

  -- Set this property to true to always open in a new tab
  property open_in_new_tab : ${f=="newTab"}

  -- Don't change this :)
  property opened_new_window : false

  -- Handlers
  on new_window()
      tell application "Alacritty"
          activate
          delay 0.5
          tell application "System Events" to tell process "Alacritty"
              keystroke "n" using {command down}
          end tell
      end tell
      delay 0.5
  end new_window

  on new_tab()
      tell application "Alacritty"
          activate
          tell application "System Events" to tell process "Alacritty"
              keystroke "t" using {command down}
          end tell
      end tell
      delay 0.5
  end new_tab

  on call_forward()
      tell application "Alacritty" to activate
      tell application "Alacritty" to reopen
  end call_forward

  on is_running()
      application "Alacritty" is running
  end is_running

  on has_windows()
      if not is_running() then return false
      tell application "System Events"
          if windows of process "Alacritty" is {} then return false
      end tell
      true
  end has_windows

  on send_text(custom_text)
      tell application "System Events" to tell process "Alacritty"
          keystroke custom_text
      end tell
  end send_text


  -- Main
  if not is_running() then
      call_forward()
      set opened_new_window to true
  else
      call_forward()
      set opened_new_window to false
  end if

  if not has_windows() then
    tell application "Alacritty" to reopen
    delay 0.2
    tell application "Alacritty" to activate
  end if

  if open_in_new_window and not opened_new_window then
      new_window()
  else if open_in_new_tab and not opened_new_window then
      new_tab()
  end if


  -- Make sure a window exists before we continue, or the write may fail
  repeat until has_windows()
      delay 0.5
  end repeat
  delay 0.5
  send_text("${n}
") -- Enter at the end of string
  call_forward()
  `,d=`
  -- Set this property to true to open in a new window instead of a new tab
  property open_in_new_window : ${f=="newWindow"}

  on new_window()
      tell application "System Events" 
          launch application "Hyper"
      end tell
  end new_window

  on new_tab()
      tell application "System Events"
          -- Check if Hyper is already running
          set isRunning to (exists process "Hyper")

          if isRunning then
              -- If Hyper is running, bring it to the front and open a new tab
              tell application "Hyper" to activate
              tell application "System Events" to keystroke "t" using command down
          else
              -- If Hyper isn't running, launch it
              launch application "Hyper"
          end if
      end tell
  end new_tab

  on call_forward()
      tell application "Hyper" to activate
  end call_forward

  on is_running()
      application "Hyper" is running
  end is_running

  -- Hyper doesn't have a direct equivalent to 'is processing', so we'll assume it's ready if it's running
  on is_processing()
      is_running()
  end is_processing

  on has_windows()
      if not is_running() then return false
      -- Hyper always has at least one window, so we'll just check if it's running
      true
  end has_windows

  on send_text(custom_text)
      tell application "System Events"
          keystroke custom_text & return
      end tell
  end send_text

  -- Main
  if has_windows() then
      if open_in_new_window then
          new_window()
      else
          new_tab()
      end if
  else
      -- If Hyper is not running and we tell it to create a new window, we get two
      -- One from opening the application, and the other from the command
      if is_running() then
          new_window()
      else
          call_forward()
      end if
  end if 


  -- Give Hyper some time to load 
  repeat until has_windows()
      delay 0.5
  end repeat
  delay 0.5

  send_text("${n}")
  call_forward()
  `,w=`
  -- Set this property to true to open in a new window instead of a new tab
  property open_in_new_window : ${f=="newWindow"}

  on new_window()
      tell application "Ghostty"
          activate
          tell application "System Events" to tell process "Ghostty"
              keystroke "n" using {command down}
          end tell
      end tell
      delay 0.5
  end new_window

  on new_tab()
      tell application "Ghostty"
          activate
          tell application "System Events" to tell process "Ghostty"
              keystroke "t" using {command down}
          end tell
      end tell
      delay 0.5
  end new_tab

  on call_forward()
      tell application "Ghostty" to activate
  end call_forward

  on is_running()
      application "Ghostty" is running
  end is_running

  on has_windows()
      if not is_running() then return false
      tell application "System Events"
          if windows of process "Ghostty" is {} then return false
      end tell
      true
  end has_windows

  on send_text(custom_text)
      tell application "System Events" to tell process "Ghostty"
          keystroke custom_text & return
      end tell
  end send_text

  -- Main
  if has_windows() then
      if open_in_new_window then
          new_window()
      else
          new_tab()
      end if
  else
      if is_running() then
          new_window()
      else
          call_forward()
      end if
  end if

  -- Give Ghostty some time to load
  repeat until has_windows()
      delay 0.5
  end repeat
  delay 0.5

  send_text("${n}")
  call_forward()
  `;if(u=="iTerm")try{await l(s)}catch(a){await l(o),console.log(a)}else if(u=="Warp")try{await l(t)}catch(a){await l(o),console.log(a)}else if(u=="Alacritty")try{await(0,i.closeMainWindow)(),await l(r)}catch(a){await l(o),console.log(a)}else if(u=="Hyper")try{await l(d)}catch(a){await l(o),console.log(a)}else if(u=="Ghostty")try{await l(w)}catch(a){await l(o),console.log(a)}else await l(o);await(0,i.showHUD)(`\u2705 Connection [${e.name}] opened with [${u}].`)}function B(e){if(x)return e.name;let n=[];e.sshKey&&n.push(`-i ${e.sshKey}`),e.port&&n.push(`-p ${e.port}`),e.command&&n.push(`"${e.command}"`);let t=e.user?`${e.user}@${e.address}`:e.address;return n.unshift("ssh",t),n.filter(Boolean).join(" ")}function P(){let[e,n]=(0,h.useState)([]),[t,o]=(0,h.useState)(!0);(0,h.useEffect)(()=>{(async()=>{o(!0);let r=await b();n(r),o(!1)})()},[]);async function s(r){if(await(0,i.confirmAlert)({title:"Remove Connection",message:`Are you sure you want to remove connection [${r.name}]?`,primaryAction:{title:"Remove",style:i.Alert.ActionStyle.Destructive},dismissAction:{title:"Cancel"}})){let w=await b();w=w.filter(a=>a.id!==r.id),await T(w),n(w),await(0,i.showHUD)(`\u{1F5D1} Connection [${r.name}] removed!`)}}return(0,c.jsx)(i.List,{isLoading:t,children:e.map(r=>(0,c.jsx)(i.List.Item,{actions:(0,c.jsx)(J,{item:r,onItemRemove:s}),id:r.id,title:r.name,subtitle:V(r)},r.name))})}function J({item:e,onItemRemove:n}){let t=B(e);return(0,c.jsxs)(i.ActionPanel,{children:[(0,c.jsxs)(i.ActionPanel.Section,{title:"Operations",children:[(0,c.jsx)(i.Action,{icon:i.Icon.Terminal,title:"Open Connection",onAction:()=>j(e)}),(0,c.jsx)(i.Action.CopyToClipboard,{title:"Copy Connection String",content:t,shortcut:{modifiers:["cmd"],key:"c"}}),(0,c.jsx)(i.Action.Paste,{icon:i.Icon.Text,title:"Paste Connection String",content:t,shortcut:{modifiers:["cmd"],key:"v"},onPaste:()=>(0,i.showHUD)(`\u{1F4DD} Pasting conn. [${e.name}] to active app`)})]}),(0,c.jsx)(i.ActionPanel.Section,{title:"Danger zone",children:(0,c.jsx)(i.Action,{title:"Remove Connection",icon:i.Icon.Trash,style:i.Action.Style.Destructive,onAction:()=>n(e),shortcut:{modifiers:["ctrl"],key:"x"}})})]})}function V(e){return`${e.user?e.user+"@":""}${e.address}${e.port?" Port: "+e.port:""}${e.sshKey?" SSH Key: "+e.sshKey:""} ${e.command?' Command: "'+e.command+'"':""}`}0&&(module.exports={onlyName,openIn,terminal});
