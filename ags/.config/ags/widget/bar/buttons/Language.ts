import PanelButton from "../PanelButton";
import { sh } from "lib/utils";
export default () => {
  return PanelButton({
    class_name: "color-picker",
    child: Widget.Icon("language-symbolic"),
    tooltip_text: "Toggle keyboard language ",
    on_clicked: () => {
      sh("hyprctl switchxkblayout all next");
    },
  });
};
