(in-package #:a2a-parity/tests)

(deftest lisp-client-lisp-inprocess
  (ok (catalog-ok-p (lisp-inprocess-talk))))

(deftest lisp-client-lisp-http-server
  (ok (catalog-ok-p (lisp-http-lisp-server))))

(deftest lisp-client-node-http-server
  (if (http-peer-available-p :node)
      (ok (catalog-ok-p (lisp-http-peer-server :node)))
      (skip "node HTTP peer not available")))

(deftest lisp-client-python-http-server
  (if (http-peer-available-p :python)
      (ok (catalog-ok-p (lisp-http-peer-server :python)))
      (skip "python HTTP peer not available")))

(deftest lisp-client-lisp-inprocess-stream
  (ok (stream-ok-p (lisp-inprocess-stream))))

(deftest lisp-client-lisp-http-server-stream
  (ok (stream-ok-p (lisp-http-lisp-server-stream))))

(deftest lisp-client-node-http-server-stream
  (if (http-peer-available-p :node)
      (ok (stream-ok-p (lisp-http-peer-server-stream :node)))
      (skip "node HTTP peer not available")))

(deftest lisp-client-python-http-server-stream
  (if (http-peer-available-p :python)
      (ok (stream-ok-p (lisp-http-peer-server-stream :python)))
      (skip "python HTTP peer not available")))
