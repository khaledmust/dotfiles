(define-module (quake-terminal)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)       ;; Provides 'gnome-extensions'
  #:use-module (gnu packages compression) ;; Provides 'zip' and 'unzip'
  #:use-module (gnu packages gettext))    ;; Provides 'msgfmt'

(define-public gnome-shell-extension-quake-terminal
  (package
    (name "gnome-shell-extension-quake-terminal")
    (version "v1.1.0") ; e.g., "1.0" or a git commit hash
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/diegodario88/quake-terminal.git")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0vbcd3g3zjry4m7051pbnblnj8zygah8lkhsh7hq6vscfcpb282q"))))
    (build-system gnu-build-system)
    (arguments
     (list #:tests? #f ; There is no test suite in the Makefile
           #:phases
           #~(modify-phases %standard-phases
               (delete 'configure) ; No ./configure script
               
               ;; The default 'build phase runs `make` (which triggers `compile`),
               ;; but we explicitly want `make pack` to bundle everything into a zip.
               (replace 'build
                 (lambda _
                   (invoke "make" "pack")))
               
               ;; Unzip the packed extension directly into the final store directory
               ;; and manually compile the schemas so GNOME can read them.
               (replace 'install
                 (lambda _
                   (let* ((ext-dir (string-append #$output 
                                                  "/share/gnome-shell/extensions/"
                                                  "quake-terminal@diegodario88.github.io"))
                          (schemas-dir (string-append ext-dir "/schemas")))
                     (mkdir-p ext-dir)
                     (invoke "unzip" 
                             "quake-terminal@diegodario88.github.io.shell-extension.zip" 
                             "-d" ext-dir)
                     
                     ;; Safely check for the schemas directory and compile it
                     (when (file-exists? schemas-dir)
                       (invoke "glib-compile-schemas" schemas-dir))))))))
    
    (native-inputs
     ;; Tools required to run `make pack`, unpack the result, and compile schemas
     (list `(,glib "bin") gnome-shell zip unzip gettext-minimal))
     
    (synopsis "Quake-style drop-down terminal for GNOME Shell")
    (description "Quake Terminal is a drop-down terminal extension for GNOME Shell.")
    (home-page "https://github.com/diegodario88/quake-terminal")
    (license license:gpl3+)))
