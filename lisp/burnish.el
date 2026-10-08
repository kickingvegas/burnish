;;; burnish.el --- Automate Org export and view  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Charles Y. Choi

;; Author: Charles Y. Choi <kickingvegas@gmail.com>
;; URL: https://github.com/kickingvegas/burnish
;; Keywords: tools
;; Package-Version: 0.0.1-rc.3
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

;; TBD

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
  "Alist of export targets their corresponding functions.

Each element is a cons cell (SYMBOL . FUNCTION) where SYMBOL is an
export target and FUNCTION is its corresponding export function.

This variable can be amended to support additional export types provided
that an export function for the new export type is defined."
  :type '(alist :key-type symbol :value-type function)
  :group 'burnish)

(defcustom burnish-export-key "C-<f5>"
  "Key sequence to bind burnish command to."
  :type 'string
  :group 'burnish)


;; Variables

(defvar burnish-backend nil
  "Format backend to export Org file to.

This variable is intended to be set locally in an Org file as described
in Info node `(emacs) Specifying File Variables'.

The value of `burnish-backend' is any key defined in
`burnish-export-functions'.

An example of setting `burnish-backend' is shown below:

-- code begins
\# Local Variables:
\# burnish-backend: html
\# End:
-- code ends

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
  "Burnish Org file."
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
  "Edit local variable `burnish-backend' to CHOICE in Org file.

Adds or updates the declaration of `burnish-backend' in an Org
file, prompting the user to choose a target defined in
`burnish-export-functions'.

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
  "Minor mode for Burnish."
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
