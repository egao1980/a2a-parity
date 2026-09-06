(in-package #:a2a-parity/tests)

(deftest-parametrize completed-state
    ((state expected)
     (:completed t)
     ("TASK_STATE_COMPLETED" t)
     ("completed" t)
     ("COMPLETED" t)
     (3 t)
     ("3" t)
     (:working nil)
     ("TASK_STATE_WORKING" nil)
     (2 nil))
  (ok (eq expected (and (completed-state-p state) t))))

(deftest catalog-ok-proto-state
  (ok (catalog-ok-p (list :card "echo" :echo "pong" :state "3")))
  (ok (catalog-ok-p (list :card "echo" :echo "pong" :state :completed)))
  (ng (catalog-ok-p (list :card "echo" :echo "" :state :completed)))
  (ng (catalog-ok-p (list :card "echo" :echo "pong" :state :working))))

(deftest stream-event-echo
  (let ((events (list (a2a-protocol:json-object
                       "task" (a2a-protocol:json-object
                               "status" (a2a-protocol:json-object
                                         "state" "TASK_STATE_WORKING")))
                      (a2a-protocol:json-object
                       "artifactUpdate"
                       (a2a-protocol:json-object
                        "artifact" (a2a-protocol:json-object
                                    "parts" (vector (a2a-protocol:json-object
                                                     "text" "pong")))))
                      (a2a-protocol:json-object
                       "statusUpdate"
                       (a2a-protocol:json-object
                        "status" (a2a-protocol:json-object
                                  "state" "TASK_STATE_COMPLETED"))))))
    (multiple-value-bind (echo state)
        (stream-event-echo events)
      (ok (equal "pong" echo))
      (ok (completed-state-p state)))))
