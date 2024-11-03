import PanelButton from "../PanelButton";
import { sh } from "lib/utils";
export default () => {
  return PanelButton({
    class_name: "color-picker",
    child: Widget.Icon("image-symbolic"),
    tooltip_text: "Set random image",
    on_clicked: () => {
      sh("waypaper-engine ri");
    },
    on_secondary_click: () => {
      sh("waypaper-engine run --wayland");
    },
  });
};
