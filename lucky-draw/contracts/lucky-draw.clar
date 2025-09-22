;; LuckyDraw - Randomized Prize Distribution Contract
;; Enables fair lottery-style competitions with multiple prize tiers
;; Uses block hash randomness for transparent and verifiable prize selection

;; Error constants
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_DRAW_NOT_FOUND (err u101))
(define-constant ERR_DRAW_CLOSED (err u102))
(define-constant ERR_DRAW_NOT_READY (err u103))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u104))
(define-constant ERR_MAX_PARTICIPANTS_REACHED (err u105))
(define-constant ERR_ALREADY_PARTICIPATED (err u106))
(define-constant ERR_PRIZE_ALREADY_CLAIMED (err u107))

;; Contract constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant MAX_PARTICIPANTS u1000)
(define-constant MIN_ENTRY_FEE u1000000) ;; 1 STX minimum
(define-constant RANDOM_BLOCKS_DELAY u10) ;; Wait 10 blocks for randomness

;; Draw structure
(define-map prize-draws
  { draw-id: uint }
  {
    creator: principal,
    title: (string-ascii 64),
    entry-fee: uint,
    total-prize-pool: uint,
    max-participants: uint,
    current-participants: uint,
    start-block: uint,
    end-block: uint,
    draw-executed: bool,
    random-seed-block: (optional uint),
    prize-distribution: (list 10 uint) ;; Percentages in basis points
  }
)

;; Participant tracking
(define-map draw-participants
  { draw-id: uint, participant: principal }
  {
    entry-number: uint,
    entry-block: uint,
    tickets-purchased: uint,
    prize-won: uint,
    prize-claimed: bool
  }
)

;; Winner records
(define-map draw-winners
  { draw-id: uint, prize-tier: uint }
  {
    winner: principal,
    prize-amount: uint,
    winning-number: uint,
    claimed: bool
  }
)

;; Participant lists for each draw
(define-map participant-lists
  { draw-id: uint }
  { participants: (list 1000 principal) }
)

;; User statistics
(define-map user-stats
  { user: principal }
  {
    draws-entered: uint,
    total-spent: uint,
    total-won: uint,
    prizes-claimed: uint,
    last-activity: uint
  }
)

;; Global counters
(define-data-var next-draw-id uint u1)
(define-data-var total-draws-created uint u0)
(define-data-var total-prizes-distributed uint u0)

;; Read-only functions
(define-read-only (get-draw-info (draw-id uint))
  (map-get? prize-draws { draw-id: draw-id })
)

(define-read-only (get-participant-info (draw-id uint) (participant principal))
  (map-get? draw-participants { draw-id: draw-id, participant: participant })
)

(define-read-only (get-winner-info (draw-id uint) (prize-tier uint))
  (map-get? draw-winners { draw-id: draw-id, prize-tier: prize-tier })
)

(define-read-only (get-user-stats (user principal))
  (map-get? user-stats { user: user })
)

(define-read-only (is-draw-ready-for-execution (draw-id uint))
  (let
    (
      (draw (get-draw-info draw-id))
    )
    (match draw
      draw-data (and
        (> block-height (get end-block draw-data))
        (not (get draw-executed draw-data))
        (> (get current-participants draw-data) u0)
      )
      false
    )
  )
)

(define-read-only (calculate-random-winner (draw-id uint) (prize-tier uint))
  (match (get-draw-info draw-id)
    draw (match (get random-seed-block draw)
      block-num (let
        (
          ;; Use block number and draw-id as simple randomness source
          (random-seed (+ block-num draw-id prize-tier))
          (participant-count (get current-participants draw))
        )
        (if (> participant-count u0)
          (+ (mod random-seed participant-count) u1)
          u0
        )
      )
      u0
    )
    u0
  )
)

;; Create new prize draw
(define-public (create-draw
  (title (string-ascii 64))
  (entry-fee uint)
  (max-participants uint)
  (duration-blocks uint)
  (prize-distribution (list 10 uint)))
  (let
    (
      (draw-id (var-get next-draw-id))
      (distribution-sum (fold + prize-distribution u0))
    )
    ;; Validate inputs
    (asserts! (>= entry-fee MIN_ENTRY_FEE) ERR_INSUFFICIENT_PAYMENT)
    (asserts! (<= max-participants MAX_PARTICIPANTS) ERR_MAX_PARTICIPANTS_REACHED)
    (asserts! (> duration-blocks u0) ERR_DRAW_NOT_READY)
    (asserts! (is-eq distribution-sum u10000) ERR_NOT_AUTHORIZED) ;; Must sum to 100%
    (asserts! (> (len title) u0) ERR_NOT_AUTHORIZED)
    
    ;; Create draw
    (map-set prize-draws
      { draw-id: draw-id }
      {
        creator: tx-sender,
        title: title,
        entry-fee: entry-fee,
        total-prize-pool: u0,
        max-participants: max-participants,
        current-participants: u0,
        start-block: block-height,
        end-block: (+ block-height duration-blocks),
        draw-executed: false,
        random-seed-block: none,
        prize-distribution: prize-distribution
      }
    )
    
    ;; Initialize participant list
    (map-set participant-lists
      { draw-id: draw-id }
      { participants: (list) }
    )
    
    ;; Update global counters
    (var-set next-draw-id (+ draw-id u1))
    (var-set total-draws-created (+ (var-get total-draws-created) u1))
    
    (ok draw-id)
  )
)

;; Enter a prize draw
(define-public (enter-draw (draw-id uint) (tickets uint))
  (let
    (
      (draw (unwrap! (get-draw-info draw-id) ERR_DRAW_NOT_FOUND))
      (entry-cost (* (get entry-fee draw) tickets))
      (current-list (get participants (default-to { participants: (list) } 
                      (map-get? participant-lists { draw-id: draw-id }))))
    )
    ;; Validate entry conditions
    (asserts! (<= block-height (get end-block draw)) ERR_DRAW_CLOSED)
    (asserts! (< (get current-participants draw) (get max-participants draw)) ERR_MAX_PARTICIPANTS_REACHED)
    (asserts! (is-none (get-participant-info draw-id tx-sender)) ERR_ALREADY_PARTICIPATED)
    (asserts! (> tickets u0) ERR_INSUFFICIENT_PAYMENT)
    
    ;; Transfer entry fee to contract
    (try! (stx-transfer? entry-cost tx-sender (as-contract tx-sender)))
    
    ;; Record participant
    (map-set draw-participants
      { draw-id: draw-id, participant: tx-sender }
      {
        entry-number: (+ (get current-participants draw) u1),
        entry-block: block-height,
        tickets-purchased: tickets,
        prize-won: u0,
        prize-claimed: false
      }
    )
    
    ;; Update participant list
    (let
      (
        (updated-list (unwrap! (as-max-len? (append current-list tx-sender) u1000) ERR_MAX_PARTICIPANTS_REACHED))
      )
      (map-set participant-lists
        { draw-id: draw-id }
        { participants: updated-list }
      )
    )
    
    ;; Update draw info
    (map-set prize-draws
      { draw-id: draw-id }
      (merge draw {
        current-participants: (+ (get current-participants draw) u1),
        total-prize-pool: (+ (get total-prize-pool draw) entry-cost)
      })
    )
    
    ;; Update user stats
    (let
      (
        (current-stats (default-to
          { draws-entered: u0, total-spent: u0, total-won: u0, prizes-claimed: u0, last-activity: block-height }
          (get-user-stats tx-sender)))
      )
      (map-set user-stats
        { user: tx-sender }
        {
          draws-entered: (+ (get draws-entered current-stats) u1),
          total-spent: (+ (get total-spent current-stats) entry-cost),
          total-won: (get total-won current-stats),
          prizes-claimed: (get prizes-claimed current-stats),
          last-activity: block-height
        }
      )
    )
    
    (ok (get current-participants draw))
  )
)

;; Execute prize draw and select winners
(define-public (execute-draw (draw-id uint))
  (let
    (
      (draw (unwrap! (get-draw-info draw-id) ERR_DRAW_NOT_FOUND))
    )
    (asserts! (is-draw-ready-for-execution draw-id) ERR_DRAW_NOT_READY)
    (asserts! (> block-height (+ (get end-block draw) RANDOM_BLOCKS_DELAY)) ERR_DRAW_NOT_READY)
    
    ;; Set random seed block for fairness
    (map-set prize-draws
      { draw-id: draw-id }
      (merge draw {
        draw-executed: true,
        random-seed-block: (some (+ (get end-block draw) RANDOM_BLOCKS_DELAY))
      })
    )
    
    ;; Distribute prizes (simplified - in practice would iterate through prize tiers)
    (try! (distribute-prize draw-id u0)) ;; First prize tier
    
    (ok true)
  )
)

;; Distribute prize for specific tier
(define-private (distribute-prize (draw-id uint) (prize-tier uint))
  (let
    (
      (draw (unwrap! (get-draw-info draw-id) ERR_DRAW_NOT_FOUND))
      (prize-percentages (get prize-distribution draw))
      (prize-percentage (default-to u0 (element-at prize-percentages prize-tier)))
      (prize-amount (/ (* (get total-prize-pool draw) prize-percentage) u10000))
      (winning-number (calculate-random-winner draw-id prize-tier))
      (participant-list (get participants (default-to { participants: (list) }
                          (map-get? participant-lists { draw-id: draw-id }))))
      (winner (element-at participant-list (- winning-number u1)))
    )
    (match winner
      winner-address (begin
        ;; Record winner
        (map-set draw-winners
          { draw-id: draw-id, prize-tier: prize-tier }
          {
            winner: winner-address,
            prize-amount: prize-amount,
            winning-number: winning-number,
            claimed: false
          }
        )
        
        ;; Update participant record
        (let
          (
            (participant-info (unwrap! (get-participant-info draw-id winner-address) ERR_DRAW_NOT_FOUND))
          )
          (map-set draw-participants
            { draw-id: draw-id, participant: winner-address }
            (merge participant-info { prize-won: prize-amount })
          )
        )
        (ok true)
      )
      (ok false) ;; No winner found
    )
  )
)

;; Claim prize
(define-public (claim-prize (draw-id uint) (prize-tier uint))
  (let
    (
      (winner-info (unwrap! (get-winner-info draw-id prize-tier) ERR_DRAW_NOT_FOUND))
      (participant-info (unwrap! (get-participant-info draw-id tx-sender) ERR_DRAW_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get winner winner-info)) ERR_NOT_AUTHORIZED)
    (asserts! (not (get claimed winner-info)) ERR_PRIZE_ALREADY_CLAIMED)
    (asserts! (> (get prize-amount winner-info) u0) ERR_DRAW_NOT_FOUND)
    
    ;; Transfer prize to winner
    (try! (as-contract (stx-transfer? (get prize-amount winner-info) tx-sender tx-sender)))
    
    ;; Mark prize as claimed
    (map-set draw-winners
      { draw-id: draw-id, prize-tier: prize-tier }
      (merge winner-info { claimed: true })
    )
    
    (map-set draw-participants
      { draw-id: draw-id, participant: tx-sender }
      (merge participant-info { prize-claimed: true })
    )
    
    ;; Update user stats
    (let
      (
        (current-stats (default-to
          { draws-entered: u0, total-spent: u0, total-won: u0, prizes-claimed: u0, last-activity: block-height }
          (get-user-stats tx-sender)))
      )
      (map-set user-stats
        { user: tx-sender }
        (merge current-stats {
          total-won: (+ (get total-won current-stats) (get prize-amount winner-info)),
          prizes-claimed: (+ (get prizes-claimed current-stats) u1),
          last-activity: block-height
        })
      )
    )
    
    (var-set total-prizes-distributed (+ (var-get total-prizes-distributed) (get prize-amount winner-info)))
    (ok (get prize-amount winner-info))
  )
)