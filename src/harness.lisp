(in-package #:a2a-parity)

(defun %ensure-http-backend ()
  (or http-protocol:*http-backend*
      (setf http-protocol:*http-backend*
            (http-backend-dexador:make-dexador-backend))))

(defun %ensure-http-server ()
  (or http-server-protocol:*http-server-backend*
      (http-server-backend-hunchentoot:use-hunchentoot-backend)))

(defun %report-from-task (card-name task)
  (list :card card-name
        :echo (echo-text task)
        :state (and task (a2a-protocol:a2a-task-state task))))

(defun lisp-talk (url)
  (%ensure-http-backend)
  (let* ((backend (a2a-backend-jsonrpc:make-jsonrpc-a2a-backend :url url))
         (card (a2a-protocol:fetch-agent-card backend url))
         (task (a2a-protocol:send-message
                backend (a2a-protocol:make-a2a-message :text "pong"))))
    (%report-from-task (a2a-protocol:agent-card-name card) task)))

(defun lisp-inprocess-talk ()
  (let ((agent (make-parity-agent)))
    (%report-from-task
     (a2a-protocol:agent-card-name (a2a-protocol:a2a-agent-card agent))
     (a2a-protocol:send-message
      agent (a2a-protocol:make-a2a-message :text "pong")))))

(defun call-with-lisp-http-server (fn)
  (%ensure-http-server)
  (let* ((port (%free-port))
         (url (format nil "http://127.0.0.1:~a" port))
         (agent (make-parity-agent :url url)))
    (http-server-protocol:with-server
        (s (a2a-backend-jsonrpc:make-a2a-app agent)
           :host "127.0.0.1" :port port)
      (sleep 0.15)
      (funcall fn url))))

(defun lisp-http-talk (url)
  (lisp-talk url))

(defun lisp-http-lisp-server ()
  (call-with-lisp-http-server #'lisp-talk))

(defun lisp-http-peer-server (kind)
  (with-peer-http-server (url kind)
    (lisp-talk url)))

(defun parse-json-line (line)
  (when (and line (plusp (length (string-trim '(#\space) line))))
    (ignore-errors (rpc-protocol:decode-message line))))

(defun %js-string (obj key)
  (let ((v (and obj (gethash key obj))))
    (cond
      ((null v) "")
      ((stringp v) v)
      (t (princ-to-string v)))))

(defun foreign-http-client-talk (kind url)
  (let* ((cmd (http-client-command kind url)))
    (multiple-value-bind (out err)
        (uiop:run-program cmd
                          :output :string
                          :error-output :string
                          :ignore-error-status t)
      (let ((parsed (loop for line in (uiop:split-string out :separator '(#\newline))
                          for rec = (parse-json-line line)
                          when rec collect rec)))
        (unless parsed
          (error "foreign HTTP client ~a produced no JSON~%cmd: ~s~%stdout:~%~a~%stderr:~%~a"
                 kind cmd out err))
        (let ((rec (first (last parsed))))
          (list :card (%js-string rec "card")
                :echo (%js-string rec "echo")
                :state (%js-string rec "state")))))))
