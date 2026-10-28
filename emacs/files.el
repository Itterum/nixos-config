;;; files.el --- Keep Emacs safety files out of projects -*- lexical-binding: t; -*-

(defconst islands-emacs-cache-directory
  (file-name-as-directory
   (expand-file-name
    "emacs"
    (or (getenv "XDG_CACHE_HOME")
        (expand-file-name "~/.cache")))))

(let ((backup-directory
       (expand-file-name "backups/" islands-emacs-cache-directory))
      (auto-save-directory
       (expand-file-name "auto-save/" islands-emacs-cache-directory))
      (lock-directory
       (expand-file-name "locks/" islands-emacs-cache-directory)))
  (dolist (directory
           (list backup-directory auto-save-directory lock-directory))
    (make-directory directory t)
    (set-file-modes directory #o700))

  (setq backup-directory-alist `(("." . ,backup-directory))
        auto-save-file-name-transforms
        `((".*" ,auto-save-directory sha256))
        lock-file-name-transforms
        `((".*" ,lock-directory sha256))))

(provide 'islands-files)
;;; files.el ends here
