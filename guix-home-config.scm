(define-module (guix-home-config)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (gnu services)
  #:use-module (gnu system shadow)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (gnu packages)
  #:use-module (guix packages)
  #:use-module (gnu home services dotfiles)
  #:use-module (gnu packages gnome) ;Provides gnome-themes-extra.
  #:use-module (gnu packages glib) ;Provides gsettings command.
  #:use-module (guix inferior)
  #:use-module (guix channels)
  #:use-module (srfi srfi-1))

(define firefox-channel
  (list (channel
          (name 'nonguix)
          (url "https://gitlab.com/nonguix/nonguix")
          (commit "da4e72efef62d48dbc2eb089c36972ff55fe6acd"))
        (channel
          (name 'guix)
          (url "https://git.guix.gnu.org/guix.git")
          (commit "5f3cd428594f14e9d268c23c8995af5a7a8aaba1"))))

(define my-inferior
  (inferior-for-channels firefox-channel))

(define gtk3-settings-service
  (simple-service 'gtk3-settings home-xdg-configuration-files-service-type
                  `(("gtk-3.0/settings.ini" ,(plain-file "settings.ini"
                                              "[Settings]
gtk-theme-name=Adwaita
gtk-application-prefer-dark-theme=true
")))))

(define gsettings-gtk-service
  (simple-service 'gsettings-gtk home-activation-service-type
                  #~(begin
                      ;; Set the GTK theme to Adwaita
                      (system* #$(file-append glib "/bin/gsettings") "set"
                               "org.gnome.desktop.interface" "gtk-theme"
                               "'Adwaita'")
                      ;; Set the color scheme to prefer dark mode (used by modern GNOME/GTK)
                      (system* #$(file-append glib "/bin/gsettings") "set"
                               "org.gnome.desktop.interface" "color-scheme"
                               "'prefer-dark'"))))

(define my-flatpak-services
  (simple-service 'flatpak-sync home-activation-service-type
                  #~(begin
                      ;; 1. Add the Flathub repository
                      (system* "flatpak"
                       "remote-add"
                       "--user"
                       "--if-not-exists"
                       "flathub"
                       "https://dl.flathub.org/repo/flathub.flatpakrepo")

                      ;; 2. Loop through a list of your desired Flatpak apps
                      (for-each (lambda (app)
                                  (system* "flatpak"
                                           "install"
                                           "--user"
                                           "-y"
                                           "flathub"
                                           app))
                                '("com.slack.Slack" "com.spotify.Client"
                                  "cc.arduino.IDE2"
                                  "com.sweethome3d.Sweethome3d")))))

(define my-flatpak-directory
  (simple-service 'flatpak-xdg-data-dirs
                  home-environment-variables-service-type
                  `(("XDG_DATA_DIRS" . "$XDG_DATA_DIRS:$HOME/.local/share/flatpak/exports/share"))))

(define my-wallpaper
  (origin
    (method url-fetch)
    (uri "https://w.wallhaven.cc/full/rq/wallhaven-rq215j.png")
    (sha256 (base32 "0raqpraxlak5hqbdndbzbqi1jzcblh693b16xrlyimsf1addgys4"))))

(define my-gnome-activation
  (simple-service 'configure-gnome-settings home-activation-service-type
                  (with-imported-modules '((guix build utils))
                                         #~(begin
                                             (use-modules (guix build utils))

                                             (let ((gsettings #$(file-append (gexp-input
                                                                              glib
                                                                              "bin")
                                                                 "/bin/gsettings"))
                                                   ;; Bind the long custom keybinding path to a variable to save space
                                                   (custom0-path
                                                    "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/")
                                                   (custom1-path
                                                    "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/")
                                                   (custom2-path
                                                    "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"))
                                               
                                               ;; General Desktop Settings
                                               (invoke gsettings "set"
                                                "org.gnome.desktop.interface"
                                                "color-scheme" "prefer-dark")
                                               (invoke gsettings "set"
                                                "org.gnome.desktop.interface"
                                                "cursor-theme"
                                                "Bibata-Modern-Ice")
                                               (invoke gsettings "set"
                                                "org.gnome.desktop.background"
                                                "picture-uri-dark"
                                                (string-append "file://"
                                                               #$my-wallpaper))

                                               (invoke gsettings "set"
                                                "org.gnome.settings-daemon.plugins.media-keys"
                                                "custom-keybindings"
                                                "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/',
                        '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']")

                                               ;; Configure the custom keybinding
                                               (invoke gsettings "set"
                                                       custom0-path "name"
                                                       "Emacs")
                                               (invoke gsettings "set"
                                                       custom0-path "command"
                                                       "emacs")
                                               (invoke gsettings "set"
                                                       custom0-path "binding"
                                                       "<Super>E")

                                               (invoke gsettings "set"
                                                       custom1-path "name"
                                                       "File Explorer")
                                               (invoke gsettings "set"
                                                       custom1-path "command"
                                                       "nautilus")
                                               (invoke gsettings "set"
                                                       custom1-path "binding"
                                                       "<Super>F")

                                               (invoke gsettings "set"
                                                       custom2-path "name"
                                                       "Firefox")
                                               (invoke gsettings "set"
                                                       custom2-path "command"
                                                       "firefox")
                                               (invoke gsettings "set"
                                                       custom2-path "binding"
                                                       "<Super>B"))))))

(define my-variables
  (simple-service 'add-custom-paths home-environment-variables-service-type
                  `(("PATH" . "~/.config/emacs/bin:$PATH"))))

(define my-nix-packages
  (simple-service 'install-nix-packages
                  home-activation-service-type
                  #~(begin
                      ;; Optionally update your Nix channels automatically
                      (system* "nix-channel" "--update")
                      
                      ;; Install your desired packages from Nix
                      (system* "nix-env" "-iA" 
                               "nixpkgs.hello" 
                               "nixpkgs.bat"
                               "nixpkgs.ripgrep"))))

(define home-config
  (home-environment
    (packages (append (list (first (lookup-inferior-packages my-inferior
                                                             "firefox")))

                      (specifications->packages (list "alacritty"
                                                      "bibata-cursor-theme"
                                                      "bitwarden-desktop"
                                                      "emacs"
                                                      "git"
                                                      "fd"
                                                      "flatpak"
                                                      "font-iosevka"
                                                      "font-jetbrains-mono"
                                                      "font-vazirmatn"
                                                      "gcc-toolchain"
                                                      "geany"
                                                      "gnome-shell-extension-gsconnect"
                                                      "gnome-shell-extension-clipboard-indicator"
                                                      "icedove"
                                                      "kicad"
                                                      "kicad-templates"
                                                      "kicad-symbols"
                                                      "kicad-packages3d"
                                                      "kicad-footprints"
                                                      "kicad-doc"
                                                      "lshw"
                                                      "ripgrep"
                                                      "vscodium"))))
    (services
     (append (list ; my-flatpak-services
                   ; my-flatpak-directory
                   my-gnome-activation
                   my-variables
                   gtk3-settings-service
                   gsettings-gtk-service

                   (service home-bash-service-type
                            (home-bash-configuration
                             (environment-variables '(("PS1" . "\\[\\e[1;32m\\]\\u \\[\\e[1;34m\\]\\w \\[\\e[0m\\]λ ")
                                                      ("EDITOR" . "emacsclient")))
                             
                             (aliases '(("gs" . "git status")
                                        ("ll" . "ls -alF")
                                        ("ghr" . "guix home reconfigure -L ~/dotfiles/modules ~/dotfiles/guix-home-config.scm")
                                        ("gup" . "guix pull")
                                        ("gsr" . "sudo guix system reconfigure /etc/config.scm")
                                        ("gcl" . "guix home delete-generations && guix package --delete-generations")
                                        ("format" . "guix style -f")))))
                   
                   (service home-files-service-type
                            `((".guile" ,%default-dotguile)
                              (".Xdefaults" ,%default-xdefaults)))

                   (service home-xdg-configuration-files-service-type
                            `(("gdb/gdbinit" ,%default-gdbinit)
                              ("nano/nanorc" ,%default-nanorc)))

                   (service home-dotfiles-service-type
                            (home-dotfiles-configuration (directories '("./"))
                                                         (layout 'plain)
                                                         (excluded '(".*~"
                                                                     ".*\\.swp"
                                                                     "\\.git"
                                                                     "\\.gitignore"
                                                                     "\\modules"
                                                                     "guix-home-config.scm")))))
             %base-home-services))))

home-config
