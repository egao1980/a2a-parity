(in-package #:a2a-parity)

(defun make-parity-agent (&key (name "echo") url)
  (a2a-protocol:make-a2a-agent
   :name name
   :url url
   :card (a2a-protocol:make-agent-card
          :name name
          :description "A2A parity echo agent"
          :url url
          :supported-interfaces
          (when url (list (a2a-protocol:make-agent-interface
                           url :protocol-binding "JSONRPC")))
          :skills (list (a2a-protocol:make-agent-skill
                         "echo"
                         :name "Echo"
                         :description "Echoes the first text part"
                         :tags '("echo"))))))

(defun echo-text (task)
  (let* ((arts (and task (a2a-protocol:a2a-task-artifacts task)))
         (art (first arts))
         (parts (and art (a2a-protocol:a2a-artifact-parts art)))
         (part (first parts)))
    (and part (a2a-protocol:a2a-part-text part))))

(defun completed-state-p (state)
  "Accept Lisp keywords, ProtoJSON names, short names, and proto enum 3."
  (or (eq state :completed)
      (eql state 3)
      (member (string-downcase (princ-to-string (or state "")))
              '("task_state_completed" "completed" "3")
              :test #'string=)))

(defun catalog-ok-p (report)
  (let ((card (getf report :card))
        (echo (getf report :echo))
        (state (getf report :state)))
    (and (search "echo" (string-downcase (or card "")))
         (equal echo "pong")
         (completed-state-p state))))
