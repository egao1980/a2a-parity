(in-package #:a2a-parity/tests)

(deftest node-client-lisp-http-server
  (if (http-peer-available-p :node)
      (ok (catalog-ok-p
           (call-with-lisp-http-server
            (lambda (url) (foreign-http-client-talk :node url)))))
      (skip "node HTTP peer not available")))

(deftest python-client-lisp-http-server
  (if (http-peer-available-p :python)
      (ok (catalog-ok-p
           (call-with-lisp-http-server
            (lambda (url) (foreign-http-client-talk :python url)))))
      (skip "python HTTP peer not available")))

(deftest node-client-lisp-http-server-stream
  (if (http-peer-available-p :node)
      (ok (stream-ok-p
           (call-with-lisp-http-server
            (lambda (url) (foreign-http-client-stream :node url)))))
      (skip "node HTTP peer not available")))

(deftest python-client-lisp-http-server-stream
  (if (http-peer-available-p :python)
      (ok (stream-ok-p
           (call-with-lisp-http-server
            (lambda (url) (foreign-http-client-stream :python url)))))
      (skip "python HTTP peer not available")))
