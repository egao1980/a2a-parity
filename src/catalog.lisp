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

(defun %ht (obj)
  (and (hash-table-p obj) obj))

(defun %part-text (part)
  (let ((part (%ht part)))
    (when part
      (or (let ((text (gethash "text" part)))
            (and (stringp text) (plusp (length text)) text))
          (let ((content (gethash "content" part)))
            (cond
              ((stringp content) content)
              ((hash-table-p content)
               (or (gethash "value" content) (gethash "text" content)))
              (t nil)))))))

(defun %artifact-echo (artifact)
  (let ((artifact (%ht artifact)))
    (when artifact
      (let ((parts (gethash "parts" artifact)))
        (loop for part in (cond
                            ((null parts) nil)
                            ((vectorp parts) (coerce parts 'list))
                            ((listp parts) parts)
                            (t (list parts)))
              for text = (%part-text part)
              when text return text)))))

(defun stream-event-echo (events)
  "Pull echo text + terminal state from SendStreamingMessage events."
  (let ((text nil)
        (state nil))
    (dolist (raw events)
      (let ((ev (%ht raw)))
        (when ev
          (let ((task (or (gethash "task" ev)
                          (let ((p (%ht (gethash "payload" ev))))
                            (when (and p (equal (gethash "$case" p) "task"))
                              (gethash "value" p))))))
            (when (%ht task)
              (let ((arts (gethash "artifacts" task)))
                (when arts
                  (let ((art (if (vectorp arts) (elt arts 0) (first arts))))
                    (setf text (or (%artifact-echo art) text)))))
              (let ((st (%ht (gethash "status" task))))
                (when st
                  (setf state (or (gethash "state" st) state))))))
          (let ((au (or (gethash "artifactUpdate" ev)
                        (gethash "artifact_update" ev))))
            (when (%ht au)
              (setf text (or (%artifact-echo (gethash "artifact" au)) text))))
          (let ((su (or (gethash "statusUpdate" ev)
                        (gethash "status_update" ev))))
            (when (%ht su)
              (let ((st (%ht (gethash "status" su))))
                (when st
                  (setf state (or (gethash "state" st) state)))))))))
    (values text state)))

(defun stream-ok-p (report)
  (catalog-ok-p report))
