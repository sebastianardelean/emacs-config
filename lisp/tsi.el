;;; tsi.el --- tree-sitter indentation -*- lexical-binding: t; -*-

;;; Version: 1.1.1

;;; Author: Dan Orzechowski

;;; URL: https://github.com/orzechowskid/tsi.el

;;; Package-Requires: ((tree-sitter "0.15.2"))

;;; SPDX-License-Identifier: GPLv3

;;; Commentary:
;; a minor mode which provides indentation based on the CST generated by the
;; `tree-sitter` package.  this file does nothing on its own; it requires the
;; installation and configuration of a language-specific helper file containing the
;; actual indentation rules.  See tsi-typescript.el (also provided by this package) for
;; a usage example.

;;; Code:

(require 'tree-sitter)


(defvar tsi-debug
  nil
  "Debug boolean for tsi-mode.  Causes a bunch of helpful(?) text to be spammed to *Messages*.")


(defun tsi--debug (&rest args)
  "Internal function.

Print messages only when `tsi-debug` is `t`."
  (when tsi-debug
    (apply 'message args)))


(defun tsi--node-start-line (node)
  "Internal function.

Returns the number of the line containing the first byte of NODE."
  (if node
      (save-excursion
        (line-number-at-pos (tsc-node-start-position node)))
    1))


(defun tsi--highest-node-at (node)
  "Internal function.

Returns the uppermost tree node sharing a start position with NODE."
  (let* ((parent-node
          (tsc-get-parent node)))
    (while
        (and
         parent-node
         (eq
          (tsc-node-start-position parent-node)
          (tsc-node-start-position node)))
      (setq node parent-node)
      (setq parent-node (tsc-get-parent parent-node)))
    node))


(defun tsi--highest-node-on-same-line-as (node)
  "Internal function.

Returns the uppermost tree node sharing the same line as NODE."
  (let* ((line-number
          (tsi--node-start-line node))
         (node-at-new-point
          (save-excursion
            (forward-line
             (- line-number (line-number-at-pos)))
            (back-to-indentation)
            (tree-sitter-node-at-point))))
    (tsi--highest-node-at node-at-new-point)))

(defun tsi--indent-line-to (column)
  "Internal function.

Indents current line to column. If the point is before the first
non-whitespace character on the line restore point after
indenting."
  (let*
      ((first-non-blank-pos
        (save-excursion
          (back-to-indentation)
          (point)))
       (should-save-excursion ;; true if point is after any leading whitespace
        (< first-non-blank-pos (point))))
    (if should-save-excursion
        (save-excursion
          (indent-line-to column))
      (indent-line-to column))))

;;;###autoload
(defun tsi--walk (indent-info-fn)
  "Indents the current line using information provided by INDENT-INFO-FN.

INDENT-INFO-FN is a function taking two arguments: (current-node parent-node)."
  (tsi--debug "begin indentation")
  (let*
      ;; credit to
      ;; https://codeberg.org/FelipeLema/tree-sitter-indent.el/src/branch/main/tree-sitter-indent.el
      ;; for some of these bound variables here and in tsi--indent-line-to above.
      ((empty-line
        (save-excursion
          (end-of-line)
          (skip-chars-backward " \t")
          (bolp)))
       (highest-node
        (tsi--highest-node-at
         (save-excursion
           (back-to-indentation)
           (tree-sitter-node-at-point))))
       (parent-node
        (or
         (tsc-get-parent highest-node)
         highest-node))
       (current-node
        (if (eq
             parent-node
             highest-node)
            (tree-sitter-node-at-point)
          highest-node))
       (indent-ops
        '()))
    (while parent-node
      (tsi--debug "parent: %s line %d, current: %s line %d" (tsc-node-type parent-node) (tsi--node-start-line parent-node) (tsc-node-type current-node) (tsi--node-start-line current-node))
      (push
       (funcall
        indent-info-fn
        current-node
        parent-node)
       indent-ops)
      (tsi--debug "op: %s" (car indent-ops))
      ;; get outermost node on the line where parent starts
      (setq
       current-node
       (tsi--highest-node-on-same-line-as parent-node))
      (setq
       parent-node
       (tsc-get-parent current-node)))
    (tsi--debug "ops: %s" indent-ops)
    (let ((column
           (seq-reduce
            (lambda (accum elt)
              (cond
               ((numberp elt)
                (+ accum elt))
               (t accum)))
            indent-ops
            0)))
      (tsi--debug "indenting to column %d" column)
      column)))


;;;###autoload
(defun tsi-calculate-indentation (indent-info-fn &optional extra-indent-for-current-line-fn)
  "Calculates the indentation for the current line using INDENT-INFO-FN.

If optional EXTRA-INDENT-FOR-CURRENT-LINE-FN is provided, will
add the extra indentation amount returned by that function to the
indent column. This is useful to handle special cases for the
current line.
"
  (+
   (or (tsi--walk indent-info-fn) 0)
   (or (and extra-indent-for-current-line-fn (funcall extra-indent-for-current-line-fn)) 0)))


;;;###autoload
(defun tsi-indent-line (indent-info-fn &optional extra-indent-for-current-line-fn)
  "Indents the current line the number of characters returned by INDENT-INFO-FN.

If optional EXTRA-INDENT-FOR-CURRENT-LINE-FN is provided, will
add the extra indentation amount returned by that function to the
indent column. This is useful to handle special cases for the
current line.
"

  (tsi--indent-line-to (tsi-calculate-indentation
			indent-info-fn
			extra-indent-for-current-line-fn)))


(provide 'tsi)
;;; tsi.el ends here
