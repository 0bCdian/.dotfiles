import PanelButton from "../PanelButton";
import { hyprland } from "resource:///com/github/Aylur/ags/service/hyprland.js";

const label = Widget.Label({
  // the signal is 'changed' if not specified
  // [Service, callback, signal = 'changed']
  label: "US",
  setup: (self) =>
    self.hook(
      hyprland,
      function (_hyprland, _keyboard, language) {
        const currentLang = language as string;
        self.label = currentLang.includes("Spanish") ? "ES" : "US";
      },
      "keyboard-layout",
    ),
});
export default () => {
  return PanelButton({
    class_name: "color-picker",
    child: label,
    tooltip_text: "Toggle keyboard language",
    on_clicked: () => {
      hyprland.messageAsync("switchxkblayout all next");
    },
  });
};
