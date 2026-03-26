(define-module (athan)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gettext)) ;; Added for translation tools

(define-public gnome-shell-extension-athan
  (package
    (name "gnome-shell-extension-athan")
    (version "Gnome-v49")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/khaledmust/PATCH_EXTENSION_GNOME_athan.git")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1ickp7sfsg07xnn5b1y6zl00spqzsfpz062jcmc1j18j8bgnks9s"))))
    (build-system gnu-build-system)
    (arguments
     (list #:tests? #f ; There is no test suite in the Makefile
           #:phases
           #~(modify-phases %standard-phases
               (delete 'configure) ; No ./configure script
               (replace 'install
                 (lambda _
                   ;; The Makefile places everything in build/athan@goodm4ven.
                   ;; We copy that folder to the final extensions directory.
                   (let ((ext-dir (string-append #$output "/share/gnome-shell/extensions/athan@goodm4ven")))
                     (mkdir-p ext-dir)
                     (copy-recursively "build/athan@goodm4ven" ext-dir)))))))
    (native-inputs
     (list `(,glib "bin") gettext-minimal))
    (synopsis "Athan extension for GNOME Shell")
    (description "Provides Islamic prayer times (Athan) in the GNOME Shell.")
    (home-page "https://github.com/khaledmust/PATCH_EXTENSION_GNOME_athan")
    (license license:gpl3+)))
