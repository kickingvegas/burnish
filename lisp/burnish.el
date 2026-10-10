;;; burnish.el --- Automate Org export and view  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Charles Y. Choi

;; Author: Charles Y. Choi <kickingvegas@gmail.com>
;; URL: https://github.com/kickingvegas/burnish
;; Keywords: tools
;; Package-Version: 0.0.1-rc.5
;; Package-Requires: ((emacs "30.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Burnish is an Elisp package that automates the export and viewing of an Org
;; file. With Burnish, users can rapidly iterate and review changes to an Org
;; file.

;; INSTALL

;; Burnish is intended to be run as a minor mode (`burnish-mode') to Org mode.
;; It can be added as a hook to `org-mode-hook'. This will always enable
;; `burnish-mode' whenever an Org file is loaded.

;;    (add-hook 'org-mode-hook #'burnish-mode)

;; Alternately ‘burnish-mode’ can be invoked in an Org buffer as desired:

;;    M-x burnish-mode RET

;; With `burnish-mode', automated export of an Org file and viewing the
;; result is done on every file save.  If this behavior is not desired,
;; then an alternate install is to bind the command `burnish'.

;;    (keymap-set org-mode-map burnish-export-key #'burnish)

;; `burnish-export-key' is a customizable variable whose default value is
;; ‘C-<f5>’.


;;; Code:

(require 'info)
(require 'ox-html)
(require 'ox-md)


;; Customize Definitions

(defgroup burnish nil
  "Group settings for Burnish."
  :group 'convenience)

(defcustom burnish-export-functions '((html . burnish-export-html)
                                      (md . burnish-export-md)
                                      (odt . burnish-export-odt)
                                      (info . burnish-export-info)
                                      (latex-pdf . burnish-export-latex-pdf))
  "Alist of export backends and their corresponding functions.
Each element is a cons cell (SYMBOL . FUNCTION) where SYMBOL is an
export backend and FUNCTION is its corresponding export function.

This customizable variable can be amended to support additional export
backends provided that an export function for the new backend is
defined. Similarly, an existing export function can be overridden with a
user-defined export function."
  :type '(alist :key-type symbol :value-type function)
  :group 'burnish)

(defcustom burnish-export-key "C-<f5>"
  "Key sequence to bind the command `burnish'."
  :type 'string
  :group 'burnish)


;; Variables

(defvar burnish-backend nil
  "Local file variable that must be set in an Org file for `burnish' to run.

It is recommended to use the command `burnish-select-backend' to edit
this variable in an Org file.

The values supported by `burnish-backend' are the keys of the alist
`burnish-export-functions'. By default these keys are:

html — export to HTML
md — export to Markdown
odt — export to Open Office Doc
info — export to Info via Texinfo
latex-pdf — export to LaTeX

Any changes to this variable in the Org file will require reloading it
with the `revert-buffer' command.")

(defvar-keymap burnish-mode-map
  :doc "Keymap for `burnish-mode'."
  burnish-export-key #'burnish)



;; Export Functions

(defun burnish-export-html ()
  "Export Org file to HTML and view."
  (let ((basename (file-name-sans-extension (buffer-file-name))))
    (org-html-export-to-html)
    (browse-url (file-name-with-extension basename "html"))))

(defun burnish-export-md ()
  "Export Org file to Markdown and view."
  (let ((basename (file-name-sans-extension (buffer-file-name))))
    (org-md-export-to-markdown)
    (find-file-other-window (file-name-with-extension basename "md"))))

(defun burnish-export-odt ()
  "Export Org file to ODT and view."
  (let ((basename (file-name-sans-extension (buffer-file-name))))
    (org-odt-export-to-odt)
    (browse-url (file-name-with-extension basename "odt"))))

(defun burnish-export-info ()
  "Export Org file to Info file (via texinfo) and view."
  (let ((basename (file-name-sans-extension (buffer-file-name))))
    (org-texinfo-export-to-info)

    (if (get-buffer "*info*")
        (kill-buffer "*info*"))
    (info (file-name-with-extension basename "info"))
    (info-initialize)))

(defun burnish-export-latex-pdf ()
  "Export Org file to LaTeX PDF and view."
  (let ((basename (file-name-sans-extension (buffer-file-name))))
    (org-latex-export-to-pdf)
    (browse-url (file-name-with-extension basename "pdf"))))


;; Commands

;;;###autoload (autoload 'burnish "burnish" nil t)
(defun burnish ()
  "Run the Org export and view function as specified by `burnish-backend'.

This function is governed by two variables:

- `burnish-backend' — local file variable specifying which export backend
  to use.

- `burnish-export-functions' — alist map whose pairs are (SYMBOL
  FUNCTION), where SYMBOL is a backend key and FUNCTION is its
  corresponding export function."
  (interactive)

  (when (and (derived-mode-p 'org-mode)
             (local-variable-if-set-p 'burnish-backend)
             burnish-backend)

    (if (map-contains-key burnish-export-functions burnish-backend)
        (let* ((fn (map-elt burnish-export-functions burnish-backend)))
          (funcall fn))

      (message
       "burnish-backend: %s is not in burnish-export-functions"
       burnish-backend))))

;;;###autoload (autoload 'burnish-select-backend "burnish" nil t)
(defun burnish-select-backend (choice)
  "Set `burnish-backend' to CHOICE in an Org file.

Prompt the user for CHOICE and set it the local file variable
`burnish-backend' in an Org file.

The prompt supports completion where choices are taken from the keys
defined in `burnish-export-functions'.

This command will either add or update `burnish-backend' as detailed in
Info node `(emacs) Specifying File Variables'.

To load the updated value, call `revert-buffer'."
  (interactive (list (completing-read "Choose Target: "
                                      (map-keys burnish-export-functions)
                                      nil t)))
  (if (and (derived-mode-p 'org-mode)
           (not buffer-read-only))
      (save-excursion
        (add-file-local-variable 'burnish-backend (intern choice))
        (save-buffer))
    (error "Error: burnish-select-backend must be run in an Org file")))



;; Minor Mode

;;;###autoload (autoload 'burnish-mode "burnish" nil t)
(define-minor-mode burnish-mode
  "Minor mode to enable automated Org file export and viewing of the result.

When `burnish-mode' is enabled:
- Automated export and view is triggered by a file save (`save-buffer').
- The key sequence `burnish-export-key' is bound to the command `burnish'.

Disabling `burnish-mode' undoes the above."
  :init-value nil
  :lighter " Bnsh"
  :keymap burnish-mode-map
  (if (derived-mode-p 'org-mode)
      (if burnish-mode
          (add-hook 'after-save-hook #'burnish 0 t)
        (remove-hook 'after-save-hook #'burnish t))
    (error "Minor mode `burnish-mode' only supported for `org-mode'")))

(provide 'burnish)
;;; burnish.el ends here
