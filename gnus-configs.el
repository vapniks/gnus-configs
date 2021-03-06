;;; gnus-configs.el --- Save/restore gnus display variables

;; Filename: gnus-configs.el
;; Description: Save/restore gnus display variables
;; Author: Joe Bloggs <vapniks@yahoo.com>
;; Maintainer: Joe Bloggs <vapniks@yahoo.com>
;; Copyleft (Ↄ) 2017, Joe Bloggs, all rites reversed.
;; Created: 2017-12-06 00:25:29
;; Version: 0.1
;; Last-Updated: Wed Dec  6 00:36:10 2017
;;           By: Joe Bloggs
;;     Update #: 2
;; URL: https://github.com/vapniks/gnus-configs
;; Keywords: comm convenience
;; Compatibility: GNU Emacs 25.2.1
;; Package-Requires: ((gnus "5.13"))
;;
;; Features that might be required by this library:
;;
;; gnus
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.
;; If not, see <http://www.gnu.org/licenses/>.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Commentary: 

;; Save/restore gnus display variables
;; Each config is stored in a separate file in `gnus-configs-directory'.

;;;;;;;;

;;; Commands:
;;
;; Below is a complete list of commands:
;;
;;  `gnus-configs-load'
;;    Check FILENAME is a valid gnus config file, and load it.
;;  `gnus-configs-save'
;;    Save the values of `gnus-configs-variables' in FILENAME.
;;
;;; Customizable Options:
;;
;; Below is a list of customizable options:
;;
;;  `gnus-configs-variables'
;;    List of variables to be saved by `gnus-configs-save'.
;;  `gnus-configs-directory'
;;    Directory in which to save config files.
;;    default = (concat gnus-home-directory "/configs")

;;
;; All of the above can be customized by:
;;      M-x customize-group RET gnus-configs RET
;;

;;; Installation:
;;
;; Put gnus-configs.el in a directory in your load-path, e.g. ~/.emacs.d/
;; You can add a directory to your load-path with the following line in ~/.emacs
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;; where ~/elisp is the directory you want to add 
;; (you don't need to do this for ~/.emacs.d - it's added by default).
;;
;; Add the following to your ~/.emacs startup file.
;;
;; (require 'gnus-configs)

;;; History:

;;; Require
(require 'gnus)

;;; Code:

(defgroup gnus-configs nil
  "Saveable gnus display configurations."
  :group 'gnus)

(defcustom gnus-configs-variables
  '(gnus-group-highlight
    gnus-group-line-format
    gnus-group-mode-line-format
    gnus-summary-line-format
    gnus-topic-line-format
    gnus-topic-alist
    gnus-topic-topology
    gnus-topic-mode
    gnus-group-listed-groups)
  "List of variables to be saved by `gnus-configs-save'.
Note: `gnus-group-listed-groups' will actually be called as a function
to get the list of currently listed groups."
  :group 'gnus-configs
  :type '(repeat (variable :tag "Variable")))

(defcustom gnus-configs-directory (concat gnus-home-directory "/configs")
  "Directory in which to save config files.
Each file is an elisp file containing definitions for the variables listed 
in `gnus-configs-variables'. The first line of each config file should 
start with \";; Gnus config file\"."
  :group 'gnus-configs
  :type 'directory)

;;;###autoload
(defun gnus-configs-load (filename)
  "Check FILENAME is a valid gnus config file, and load it.
When called interactively prompt the user for a file in `gnus-configs-directory'.
If a prefix arg is supplied then call `gnus-configs-save' instead."
  (interactive (list (or current-prefix-arg
			 (ido-read-file-name
			  "Load Gnus config file: "
			  (if (file-directory-p gnus-configs-directory)
			      gnus-configs-directory
			    (error "Invalid configs directory: %s" gnus-configs-directory))
			  nil t))))
  (if current-prefix-arg
      (let (current-prefix-arg)
	(call-interactively 'gnus-configs-save))
    (unless (file-readable-p filename)
      (error "Unable to read config file: %s" filename))
    (with-temp-buffer (insert-file-contents filename)
		      (unless (string-match "^;+ *GNUS CONFIG FILE" (buffer-string))
			(error "Invalid gnus config file: %s" filename))
		      (eval-buffer))))

;;;###autoload
(defun gnus-configs-save (filename)
  "Save the values of `gnus-configs-variables' in FILENAME.
When called interactively, prompt the user for a file in `gnus-configs-directory'.
If a prefix arg is supplied then call `gnus-configs-load' instead."
  (interactive (list (ido-read-file-name
		      "Save Gnus config file: "
		      (if (file-directory-p gnus-configs-directory)
			  gnus-configs-directory
			(if (not (y-or-n-p (format "Configs dir \"%s\" doesnt exist, create it? "
						   gnus-configs-directory)))
			    (error "Set gnus-configs-directory to an existing directory")
			  (make-directory gnus-configs-directory t)
			  gnus-configs-directory)))))
  (if current-prefix-arg
      (let (current-prefix-arg)
	(call-interactively 'gnus-configs-load))
    (unless (file-writable-p filename)
      (error "Unable to write to %s" filename))
    (with-temp-file filename
      (insert ";; GNUS CONFIG FILE\n")
      (dolist (var gnus-configs-variables)
	(let* ((name (symbol-name var)))
	  (insert (cl-case var
		    (gnus-topic-mode
		     (concat "(with-current-buffer gnus-group-buffer (gnus-topic-mode "
			     (if (with-current-buffer gnus-group-buffer gnus-topic-mode)
				 "1" "-1")
			     "))\n"))
		    (gnus-group-listed-groups "")
		    (t (concat "(setq " name " '" (prin1-to-string (symbol-value var)) ")\n"))))))
      (insert "(gnus-group-list-groups)\n")
      (if (memq 'gnus-group-listed-groups gnus-configs-variables)
	  (insert (concat "(with-current-buffer gnus-group-buffer (gnus-group-list-matching gnus-level-unsubscribed "
			  (prin1-to-string
			   (with-current-buffer gnus-group-buffer
			     (regexp-opt (gnus-group-listed-groups)))) "))\n")))
      (insert "\n;; END GNUS CONFIG FILE"))))

(provide 'gnus-configs)

;; (org-readme-sync)
;; (magit-push)

;;; gnus-configs.el ends here
