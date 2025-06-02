"use strict";
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/index.tsx
var src_exports = {};
__export(src_exports, {
  default: () => Command
});
module.exports = __toCommonJS(src_exports);
var import_api = require("@raycast/api");
var import_jsx_runtime = require("react/jsx-runtime");
function Command() {
  return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_api.List, {
    children: [
      /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_api.List.Section, {
        title: "Basics",
        children: [
          /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LinkListItem, {
            title: "Familiarize yourself with Raycast",
            link: "https://raycast.com/manual"
          }),
          /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LinkListItem, {
            title: "Install extensions from our public store",
            link: "https://www.raycast.com/store"
          }),
          /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LinkListItem, {
            title: "Build your own extensions with our API",
            link: "https://developers.raycast.com"
          }),
          /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LinkListItem, {
            title: "Invite your teammates",
            link: "raycast://organizations/e-cru/manage"
          })
        ]
      }),
      /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_api.List.Section, {
        title: "Next Steps",
        children: [
          /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LinkListItem, {
            title: "Join the Raycast community",
            link: "https://raycast.com/community"
          }),
          /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LinkListItem, {
            title: "Stay up to date via Twitter",
            link: "https://twitter.com/raycastapp"
          })
        ]
      })
    ]
  });
}
function LinkListItem(props) {
  return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api.List.Item, {
    title: props.title,
    icon: import_api.Icon.Link,
    accessories: [{ text: props.link }],
    actions: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_api.ActionPanel, {
      children: [
        /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api.Action.OpenInBrowser, {
          url: props.link
        }),
        /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api.Action.CopyToClipboard, {
          title: "Copy Link",
          content: props.link
        })
      ]
    })
  });
}
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {});
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsiLi4vLi4vLi4vLi4vRG9jdW1lbnRzL3JheWNhc3QvcmF5Y2FzdC1leHRlbnNpb25zL2dldHRpbmctc3RhcnRlZC9zcmMvaW5kZXgudHN4Il0sCiAgInNvdXJjZXNDb250ZW50IjogWyJpbXBvcnQgeyBBY3Rpb25QYW5lbCwgQWN0aW9uLCBJY29uLCBMaXN0IH0gZnJvbSBcIkByYXljYXN0L2FwaVwiO1xuXG5leHBvcnQgZGVmYXVsdCBmdW5jdGlvbiBDb21tYW5kKCkge1xuICByZXR1cm4gKFxuICAgIDxMaXN0PlxuICAgICAgPExpc3QuU2VjdGlvbiB0aXRsZT1cIkJhc2ljc1wiPlxuICAgICAgICA8TGlua0xpc3RJdGVtIHRpdGxlPVwiRmFtaWxpYXJpemUgeW91cnNlbGYgd2l0aCBSYXljYXN0XCIgbGluaz1cImh0dHBzOi8vcmF5Y2FzdC5jb20vbWFudWFsXCIgLz5cbiAgICAgICAgPExpbmtMaXN0SXRlbSB0aXRsZT1cIkluc3RhbGwgZXh0ZW5zaW9ucyBmcm9tIG91ciBwdWJsaWMgc3RvcmVcIiBsaW5rPVwiaHR0cHM6Ly93d3cucmF5Y2FzdC5jb20vc3RvcmVcIiAvPlxuICAgICAgICA8TGlua0xpc3RJdGVtIHRpdGxlPVwiQnVpbGQgeW91ciBvd24gZXh0ZW5zaW9ucyB3aXRoIG91ciBBUElcIiBsaW5rPVwiaHR0cHM6Ly9kZXZlbG9wZXJzLnJheWNhc3QuY29tXCIgLz5cbiAgICAgICAgPExpbmtMaXN0SXRlbSB0aXRsZT1cIkludml0ZSB5b3VyIHRlYW1tYXRlc1wiIGxpbms9XCJyYXljYXN0Oi8vb3JnYW5pemF0aW9ucy9lLWNydS9tYW5hZ2VcIiAvPlxuICAgICAgPC9MaXN0LlNlY3Rpb24+XG4gICAgICA8TGlzdC5TZWN0aW9uIHRpdGxlPVwiTmV4dCBTdGVwc1wiPlxuICAgICAgICA8TGlua0xpc3RJdGVtIHRpdGxlPVwiSm9pbiB0aGUgUmF5Y2FzdCBjb21tdW5pdHlcIiBsaW5rPVwiaHR0cHM6Ly9yYXljYXN0LmNvbS9jb21tdW5pdHlcIiAvPlxuICAgICAgICA8TGlua0xpc3RJdGVtIHRpdGxlPVwiU3RheSB1cCB0byBkYXRlIHZpYSBUd2l0dGVyXCIgbGluaz1cImh0dHBzOi8vdHdpdHRlci5jb20vcmF5Y2FzdGFwcFwiIC8+XG4gICAgICA8L0xpc3QuU2VjdGlvbj5cbiAgICA8L0xpc3Q+XG4gICk7XG59XG5cbmZ1bmN0aW9uIExpbmtMaXN0SXRlbShwcm9wczogeyB0aXRsZTogc3RyaW5nOyBsaW5rOiBzdHJpbmcgfSkge1xuICByZXR1cm4gKFxuICAgIDxMaXN0Lkl0ZW1cbiAgICAgIHRpdGxlPXtwcm9wcy50aXRsZX1cbiAgICAgIGljb249e0ljb24uTGlua31cbiAgICAgIGFjY2Vzc29yaWVzPXtbeyB0ZXh0OiBwcm9wcy5saW5rIH1dfVxuICAgICAgYWN0aW9ucz17XG4gICAgICAgIDxBY3Rpb25QYW5lbD5cbiAgICAgICAgICA8QWN0aW9uLk9wZW5JbkJyb3dzZXIgdXJsPXtwcm9wcy5saW5rfSAvPlxuICAgICAgICAgIDxBY3Rpb24uQ29weVRvQ2xpcGJvYXJkIHRpdGxlPVwiQ29weSBMaW5rXCIgY29udGVudD17cHJvcHMubGlua30gLz5cbiAgICAgICAgPC9BY3Rpb25QYW5lbD5cbiAgICAgIH1cbiAgICAvPlxuICApO1xufVxuIl0sCiAgIm1hcHBpbmdzIjogIjs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7QUFBQTtBQUFBO0FBQUE7QUFBQTtBQUFBO0FBQUEsaUJBQWdEO0FBQWhEO0FBRWUsU0FBUixVQUEyQjtBQUNoQyxTQUNFLDZDQUFDO0FBQUEsSUFDQztBQUFBLG1EQUFDLGdCQUFLLFNBQUw7QUFBQSxRQUFhLE9BQU07QUFBQSxRQUNsQjtBQUFBLHNEQUFDO0FBQUEsWUFBYSxPQUFNO0FBQUEsWUFBb0MsTUFBSztBQUFBLFdBQTZCO0FBQUEsVUFDMUYsNENBQUM7QUFBQSxZQUFhLE9BQU07QUFBQSxZQUEyQyxNQUFLO0FBQUEsV0FBZ0M7QUFBQSxVQUNwRyw0Q0FBQztBQUFBLFlBQWEsT0FBTTtBQUFBLFlBQXlDLE1BQUs7QUFBQSxXQUFpQztBQUFBLFVBQ25HLDRDQUFDO0FBQUEsWUFBYSxPQUFNO0FBQUEsWUFBd0IsTUFBSztBQUFBLFdBQXVDO0FBQUE7QUFBQSxPQUMxRjtBQUFBLE1BQ0EsNkNBQUMsZ0JBQUssU0FBTDtBQUFBLFFBQWEsT0FBTTtBQUFBLFFBQ2xCO0FBQUEsc0RBQUM7QUFBQSxZQUFhLE9BQU07QUFBQSxZQUE2QixNQUFLO0FBQUEsV0FBZ0M7QUFBQSxVQUN0Riw0Q0FBQztBQUFBLFlBQWEsT0FBTTtBQUFBLFlBQThCLE1BQUs7QUFBQSxXQUFpQztBQUFBO0FBQUEsT0FDMUY7QUFBQTtBQUFBLEdBQ0Y7QUFFSjtBQUVBLFNBQVMsYUFBYSxPQUF3QztBQUM1RCxTQUNFLDRDQUFDLGdCQUFLLE1BQUw7QUFBQSxJQUNDLE9BQU8sTUFBTTtBQUFBLElBQ2IsTUFBTSxnQkFBSztBQUFBLElBQ1gsYUFBYSxDQUFDLEVBQUUsTUFBTSxNQUFNLEtBQUssQ0FBQztBQUFBLElBQ2xDLFNBQ0UsNkNBQUM7QUFBQSxNQUNDO0FBQUEsb0RBQUMsa0JBQU8sZUFBUDtBQUFBLFVBQXFCLEtBQUssTUFBTTtBQUFBLFNBQU07QUFBQSxRQUN2Qyw0Q0FBQyxrQkFBTyxpQkFBUDtBQUFBLFVBQXVCLE9BQU07QUFBQSxVQUFZLFNBQVMsTUFBTTtBQUFBLFNBQU07QUFBQTtBQUFBLEtBQ2pFO0FBQUEsR0FFSjtBQUVKOyIsCiAgIm5hbWVzIjogW10KfQo=
