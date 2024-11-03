# My Linux Environment Dotfiles ⚙️🐧

Here's where I will store all of my relevant configurations for things like fish,
nvim, kitty, hyprland etc. To use this dotfiles follow the instructions:

1. Clone this repo into your `$HOME` directory:

```bash
git clone git@github.com:0bCdian/.dotfiles.git
```

2. Install [stow](https://www.gnu.org/software/stow/) if you haven't already:

```bash
  sudo pacman -S stow
```

Or

```bash
yay stow
```

> [!NOTE]
> Go to the gnu stow link for more information on how to install on distros.

3. CD into the downloaded .dotfiles directory:

```bash
cd .dotfiles
```

4. Stow what you want, for example:

```bash
# This copies the contents of the hypr directory in $HOME/.config/hypr
stow hypr
```

---

> [!IMPORTANT]
> Please before opening an issue, read how gnu stow works.
> Also please only install what you know how to use,
> I don't have the time to help debug other's configs.
