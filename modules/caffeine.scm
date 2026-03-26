(define-module (caffeine)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (gnu packages glib)
  #:use-module ((guix licenses) #:prefix license:))

(define-public gnome-shell-extension-caffeine
  (package
    (name "gnome-shell-extension-caffeine")
    (version "59")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/eonpatapon/gnome-shell-extension-caffeine.git")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0sv0iqfb6kjhgcg4pb59n91dyf667vax96kfhz5ik5hhx9n0z43w")))) ;; Make sure your actual hash is here
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("caffeine@patapon.info" "share/gnome-shell/extensions/"))
           
           ;; We add a custom phase to run after the 'install phase
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'install 'compile-schemas
                 (lambda _
                   (invoke "glib-compile-schemas"
                           (string-append #$output "/share/gnome-shell/extensions/caffeine@patapon.info/schemas")))))))
    
    (native-inputs
     ;; The glib-compile-schemas command is in the "bin" output of glib
     (list `(,glib "bin")))
     
    (synopsis "Disable the screensaver and auto suspend in GNOME")
    (description "Caffeine is a GNOME Shell extension that adds a toggle to 
disable the screensaver and auto suspend.")
    (home-page "https://github.com/eonpatapon/gnome-shell-extension-caffeine")
    (license license:gpl2+)))
