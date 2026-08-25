(in-package #:a2a-parity)

(defun print-matrix ()
  (format t "~&a2a-parity matrix~%")
  (format t "  peers: node=~a python=~a~%"
          (if (node-available-p) "yes" "no")
          (if (python-available-p) "yes" "no"))
  (format t "  catalog: GET agent-card + SendMessage echo~%")
  (format t "  routes: Lisp↔Lisp (in-process + HTTP), Lisp↔Node, Lisp↔Python~%")
  (values))
