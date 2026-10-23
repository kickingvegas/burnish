;;; test-burnish.el --- Casual Suite Tests      -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Charles Y. Choi

;; Author: Charles Choi <kickingvegas@gmail.com>
;; Keywords: tools

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

;;

;;; Code:

(require 'ert)
(require 'burnish-test-utils)
(require 'burnish)
(require 'map)

(ert-deftest test-burnish-export-functions ()
  "Test `burnish-export-functions'."

  (should (custom-variable-p 'burnish-export-functions))

  (let* ((keys (list 'html 'md 'odt 'info 'latex-pdf)))
    (mapc (lambda (key)
            (should (map-contains-key burnish-export-functions key)))
          keys))

  (should (eq (map-elt burnish-export-functions 'html) #'burnish-export-html))
  (should (eq (map-elt burnish-export-functions 'md) #'burnish-export-md))
  (should (eq (map-elt burnish-export-functions 'odt) #'burnish-export-odt))
  (should (eq (map-elt burnish-export-functions 'info) #'burnish-export-info))
  (should (eq (map-elt burnish-export-functions 'latex-pdf) #'burnish-export-latex-pdf)))

(ert-deftest test-burnish-export-key ()
  "Test `burnish-export-key'."

  (should (custom-variable-p 'burnish-export-key))
  (should (string-equal burnish-export-key "C-<f5>")))

(provide 'test-burnish)
;;; test-burnish.el ends here
