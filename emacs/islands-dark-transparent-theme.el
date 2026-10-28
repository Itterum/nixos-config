;;; islands-dark-transparent-theme.el --- Islands Dark colors -*- lexical-binding: t; -*-

;;; Commentary:
;; JetBrains Islands Dark inspired palette for terminal Emacs.  The editor and
;; which-key backgrounds are left to the terminal, while UI state that needs
;; contrast keeps an explicit background.

;;; Code:

(deftheme islands-dark-transparent
  "JetBrains Islands Dark palette with a transparent terminal background.")

(let ((foreground "#bcbec4")
      (muted "#7a7e85")
      (subtle "#5a5d63")
      (orange "#cf8e6d")
      (green "#6aab73")
      (cyan "#2aacb8")
      (blue "#56a8f5")
      (yellow "#b3ae60")
      (red "#f75464")
      (transparent "unspecified-bg")
      (surface "#2b2d30")
      (surface-dark "#1e1f22")
      (active-line "#202124")
      (selection "#2e436e")
      (highlight "#3d4f6b"))
  (custom-theme-set-faces
   'islands-dark-transparent
   `(default ((t (:foreground ,foreground :background ,transparent))))
   `(cursor ((t (:background ,foreground))))
   `(fringe ((t (:foreground ,subtle :background ,transparent))))
   `(highlight ((t (:background ,highlight))))
   `(hl-line ((t (:background ,active-line))))
   `(region ((t (:background ,selection :extend t))))
   `(secondary-selection ((t (:background ,highlight))))
   `(shadow ((t (:foreground ,subtle))))
   `(minibuffer-prompt ((t (:foreground ,blue :weight bold))))

   `(mode-line ((t (:foreground ,foreground :background ,surface
                    :box nil :weight normal))))
   `(mode-line-active ((t (:foreground ,foreground :background ,surface
                           :box nil :weight normal))))
   `(mode-line-inactive ((t (:foreground ,muted :background ,surface-dark
                             :box nil :weight normal))))
   `(header-line ((t (:foreground ,foreground :background ,surface-dark
                      :box nil :weight normal))))
   `(vertical-border ((t (:foreground ,surface))))
   `(window-divider ((t (:foreground ,surface))))

   `(corfu-default ((t (:foreground ,foreground :background ,surface))))
   `(corfu-current ((t (:foreground ,foreground :background ,highlight))))
   `(corfu-border ((t (:background ,surface-dark))))
   `(corfu-bar ((t (:background ,muted))))
   `(corfu-annotations ((t (:foreground ,muted :background ,surface))))

   `(line-number ((t (:foreground ,subtle :background ,transparent))))
   `(line-number-current-line ((t (:foreground ,foreground
                                  :background ,transparent
                                  :weight normal))))

   `(font-lock-builtin-face ((t (:foreground ,orange))))
   `(font-lock-comment-face ((t (:foreground ,muted :slant italic))))
   `(font-lock-comment-delimiter-face ((t (:foreground ,muted :slant italic))))
   `(font-lock-constant-face ((t (:foreground ,cyan))))
   `(font-lock-doc-face ((t (:foreground ,muted :slant italic))))
   `(font-lock-function-name-face ((t (:foreground ,blue))))
   `(font-lock-keyword-face ((t (:foreground ,orange))))
   `(font-lock-negation-char-face ((t (:foreground ,red))))
   `(font-lock-number-face ((t (:foreground ,cyan))))
   `(font-lock-preprocessor-face ((t (:foreground ,orange))))
   `(font-lock-property-name-face ((t (:foreground ,foreground))))
   `(font-lock-property-use-face ((t (:foreground ,foreground))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,orange))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,orange))))
   `(font-lock-string-face ((t (:foreground ,green))))
   `(font-lock-type-face ((t (:foreground ,yellow))))
   `(font-lock-variable-name-face ((t (:foreground ,foreground))))
   `(font-lock-variable-use-face ((t (:foreground ,foreground))))
   `(font-lock-warning-face ((t (:foreground ,red :weight bold))))

   `(link ((t (:foreground ,blue :underline t))))
   `(link-visited ((t (:foreground ,yellow :underline t))))
   `(error ((t (:foreground ,red :weight bold))))
   `(warning ((t (:foreground ,yellow :weight bold))))
   `(success ((t (:foreground ,green :weight bold))))
   `(isearch ((t (:foreground ,foreground :background ,selection :weight bold))))
   `(lazy-highlight ((t (:foreground ,foreground :background ,highlight))))
   `(match ((t (:foreground ,foreground :background ,highlight))))
   `(show-paren-match ((t (:foreground ,foreground :background ,highlight
                           :weight bold))))
   `(show-paren-mismatch ((t (:foreground ,red :background ,surface
                              :weight bold))))

   `(which-key-key-face ((t (:foreground ,blue :background ,transparent
                             :weight normal :slant normal))))
   `(which-key-command-description-face
     ((t (:foreground ,foreground :background ,transparent
                      :weight normal :slant normal))))
   `(which-key-group-description-face
     ((t (:foreground ,orange :background ,transparent
                      :weight normal :slant normal))))
   `(which-key-note-face ((t (:foreground ,muted :background ,transparent
                              :weight normal :slant normal))))
   `(which-key-separator-face ((t (:foreground ,muted :background ,transparent
                                   :weight normal :slant normal))))
   `(which-key-special-key-face ((t (:foreground ,cyan :background ,transparent
                                     :weight normal :slant normal))))))

(provide-theme 'islands-dark-transparent)

;;; islands-dark-transparent-theme.el ends here
