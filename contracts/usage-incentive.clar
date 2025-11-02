;; fee-rebate.clar
;; Fee Rebate Contract
;; - Users call `pay-fee` to transfer STX to this contract and have the amount recorded.
;; - When user's cumulative paid fees >= fee-threshold, they can call `claim-rebate`.
;; - Rebate is computed as: floor(total_paid * rebate_rate / 100).
;; - After claiming, user's total_paid resets to 0.
;; - Owner can set parameters and withdraw funds.

(define-constant ERR-NOT-OWNER u100)
(define-constant ERR-NOT-ELIGIBLE u101)
(define-constant ERR-TRANSFER-FAILED u102)
(define-constant ERR-CONTRACT-INSUFFICIENT u103)
(define-constant ERR-USER-NOT-FOUND u104)

;; contract owner is the deployer (tx-sender at deploy-time)
(define-constant contract-owner tx-sender)

;; Map: (user) -> (total-paid)
(define-map fee-records
  {user: principal}            ;; map key
  {total-paid: uint})

;; Configurable params
(define-data-var fee-threshold uint u1000) ;; default threshold (in micro-STX) - adjust to suit tests
(define-data-var rebate-rate uint u10)     ;; percent, e.g., 10 => 10%

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helper / Read-only functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-read-only (get-owner)
  contract-owner)

(define-read-only (get-fee-threshold)
  (var-get fee-threshold))

(define-read-only (get-rebate-rate)
  (var-get rebate-rate))

;; returns user's recorded total paid (or u0)
(define-read-only (get-total-paid (addr principal))
  (match (map-get? fee-records {user: addr})
    entry (get total-paid entry)
    (begin u0)))

;; get contract STX balance
(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Public functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; pay-fee: user transfers STX to contract; amount is recorded.
(define-public (pay-fee (amount uint))
  (begin
    ;; require non-zero amount
    (asserts! (not (is-eq amount u0)) (err ERR-TRANSFER-FAILED))

    ;; perform STX transfer from tx-sender -> this contract
    (match (stx-transfer? amount tx-sender (as-contract tx-sender))
      transfer-ok
        (begin
          ;; update map: get prev total (if any)
          (let ((prev (match (map-get? fee-records {user: tx-sender})
                         entry (get total-paid entry)
                         (begin u0))))
            (map-set fee-records
              {user: tx-sender}
              {total-paid: (+ prev amount)}))
          (ok true))
      transfer-err (err ERR-TRANSFER-FAILED))))

;; claim-rebate: if user's total-paid >= threshold, compute rebate and transfer from contract to user.
;; returns (ok rebate-amount) or (err code)
(define-public (claim-rebate)
  (match (map-get? fee-records {user: tx-sender})
    entry
      (let ((paid (get total-paid entry))
            (threshold (var-get fee-threshold))
            (rate (var-get rebate-rate)))
        (if (>= paid threshold)
            (let ((rebate (/ (* paid rate) u100)))
              ;; ensure contract has enough balance
              (let ((bal (stx-get-balance (as-contract tx-sender))))
                (if (>= bal rebate)
                    (match (stx-transfer? rebate (as-contract tx-sender) tx-sender)
                      tf-ok
                        (begin
                          ;; reset user's total-paid after successful payout
                          (map-set fee-records {user: tx-sender} {total-paid: u0})
                          (ok rebate))
                      tf-err (err ERR-TRANSFER-FAILED))
                  (err ERR-CONTRACT-INSUFFICIENT))))
            (err ERR-NOT-ELIGIBLE)))
    (err ERR-USER-NOT-FOUND)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Admin-only functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-private (is-owner (p principal))
  (is-eq p contract-owner))

;; Set threshold (owner only)
(define-public (set-threshold (new-threshold uint))
  (begin
    (asserts! (is-owner tx-sender) (err ERR-NOT-OWNER))
    (asserts! (> new-threshold u0) (err ERR-TRANSFER-FAILED))
    (var-set fee-threshold new-threshold)
    (ok new-threshold)))

;; Set rebate rate (percent, 0..100) (owner only)
(define-public (set-rebate-rate (new-rate uint))
  (begin
    (asserts! (is-owner tx-sender) (err ERR-NOT-OWNER))
    (asserts! (<= new-rate u100) (err ERR-TRANSFER-FAILED))
    (var-set rebate-rate new-rate)
    (ok new-rate)))

;; Owner can withdraw STX from contract to an address
(define-public (owner-withdraw (to principal) (amount uint))
  (begin
    (asserts! (is-owner tx-sender) (err ERR-NOT-OWNER))
    (asserts! (> amount u0) (err ERR-TRANSFER-FAILED))
    (asserts! (not (is-eq to (as-contract tx-sender))) (err ERR-TRANSFER-FAILED))
    (let ((bal (stx-get-balance (as-contract tx-sender))))
      (asserts! (>= bal amount) (err ERR-CONTRACT-INSUFFICIENT))
      (match (stx-transfer? amount (as-contract tx-sender) to)
        ok (ok true)
        err (err ERR-TRANSFER-FAILED)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; End of contract
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
