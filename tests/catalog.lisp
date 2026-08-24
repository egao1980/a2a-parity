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
