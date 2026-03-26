(define-module (azan)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages python))

(define-public gnome-shell-extension-azan
  (package
    (name "gnome-shell-extension-azan")
    (version "master") ; e.g., "1.0" or a git commit hash
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/Abdw3253/azan-gnome-shell-extension.git")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0s43s1znsisg4i1rv6f35635ybyaj22nv79q8qq7z9yv8j1nibww"))))
    (build-system gnu-build-system)
    (arguments
     (list #:tests? #f ; There is no test suite in the Makefile
           #:phases
           #~(modify-phases %standard-phases
               (delete 'configure) ; No ./configure script
               (replace 'install
                 (lambda _
                   ;; The Makefile's "all" target places the compiled extension 
                   ;; inside a "build/<uuid>" directory.
                   ;; We copy the contents of the "build" directory recursively
                   ;; to our target extensions directory.
                   (let ((ext-dir (string-append #$output "/share/gnome-shell/extensions")))
                     (mkdir-p ext-dir)
                     (copy-recursively "build" ext-dir)))))))
    (native-inputs
     ;; glib provides glib-compile-schemas; python is required by the Makefile
     (list `(,glib "bin") python))
    (synopsis "Azan extension for GNOME Shell")
    (description "Provides Islamic prayer times (Azan) in the GNOME Shell.")
    (home-page "https://github.com/Abdw3253/azan-gnome-shell-extension")
    (license license:gpl3+))) ; Assuming GPL, adjust if the repo states otherwise

