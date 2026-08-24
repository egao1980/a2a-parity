(defsystem "a2a-parity"
  :version "0.1.0"
  :description "Interop canary: a2a-protocol vs official Python/Node A2A SDKs"
  :author "egao1980"
  :license "MIT"
  :depends-on ("a2a-protocol"
               "a2a-backend-jsonrpc"
               "rpc-protocol"
               "rpc-backend-inprocess"
               "http-protocol"
               "http-backend-dexador"
               "http-server-protocol"
               "http-server-backend-hunchentoot"
               "uiop"
               "usocket"
               "rove")
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "catalog")
               (:file "peers")
               (:file "harness")
               (:file "report"))
  :in-order-to ((test-op (test-op "a2a-parity/tests"))))

(defsystem "a2a-parity/tests"
  :depends-on ("a2a-parity" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "catalog")
               (:file "lisp-client")
               (:file "foreign-client"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "a2a-parity tests failed"))))
