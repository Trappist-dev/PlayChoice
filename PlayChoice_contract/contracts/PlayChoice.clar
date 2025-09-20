
;; title: PlayChoice
;; version: 1.0.0
;; summary: Player-driven governance system for game modifications and community events
;; description: A smart contract that enables players to create proposals, vote on game modifications,
;;              and manage community events through decentralized governance.

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u101))
(define-constant ERR_VOTING_CLOSED (err u102))
(define-constant ERR_ALREADY_VOTED (err u103))
(define-constant ERR_INVALID_PROPOSAL (err u104))
(define-constant ERR_INSUFFICIENT_STAKE (err u105))
(define-constant ERR_PROPOSAL_EXECUTED (err u106))

;; Minimum stake required to create a proposal (in microSTX)
(define-constant MIN_PROPOSAL_STAKE u1000000)

;; Voting period in blocks (approximately 1 week = ~1000 blocks)
(define-constant VOTING_PERIOD u1000)

;; Minimum participation threshold (10% of total registered players)
(define-constant MIN_PARTICIPATION_THRESHOLD u10)

;; data vars
(define-data-var proposal-counter uint u0)
(define-data-var total-registered-players uint u0)

;; data maps
;; Player registration
(define-map registered-players principal bool)

;; Proposal structure
(define-map proposals
    uint
    {
        id: uint,
        proposer: principal,
        title: (string-ascii 100),
        description: (string-ascii 500),
        proposal-type: (string-ascii 50), ;; "game-mod", "event", "rule-change"
        target-contract: (optional principal),
        start-block: uint,
        end-block: uint,
        yes-votes: uint,
        no-votes: uint,
        total-votes: uint,
        executed: bool,
        stake: uint
    }
)

;; Vote tracking
(define-map votes
    {proposal-id: uint, voter: principal}
    {vote: bool, voting-power: uint}
)

;; Player voting power (based on participation history)
(define-map player-voting-power principal uint)

;; public functions

;; Register as a player in the governance system
(define-public (register-player)
    (begin
        (asserts! (is-none (map-get? registered-players tx-sender)) ERR_UNAUTHORIZED)
        (map-set registered-players tx-sender true)
        (map-set player-voting-power tx-sender u1)
        (var-set total-registered-players (+ (var-get total-registered-players) u1))
        (ok true)
    )
)

;; Create a new governance proposal
(define-public (create-proposal
    (title (string-ascii 100))
    (description (string-ascii 500))
    (proposal-type (string-ascii 50))
    (target-contract (optional principal))
    (stake uint)
)
    (let
        (
            (proposal-id (+ (var-get proposal-counter) u1))
            (current-block block-height)
        )
        (asserts! (default-to false (map-get? registered-players tx-sender)) ERR_UNAUTHORIZED)
        (asserts! (>= stake MIN_PROPOSAL_STAKE) ERR_INSUFFICIENT_STAKE)
        (asserts! (> (len title) u0) ERR_INVALID_PROPOSAL)
        (asserts! (> (len description) u0) ERR_INVALID_PROPOSAL)

        ;; Store the proposal
        (map-set proposals proposal-id
            {
                id: proposal-id,
                proposer: tx-sender,
                title: title,
                description: description,
                proposal-type: proposal-type,
                target-contract: target-contract,
                start-block: current-block,
                end-block: (+ current-block VOTING_PERIOD),
                yes-votes: u0,
                no-votes: u0,
                total-votes: u0,
                executed: false,
                stake: stake
            }
        )

        ;; Update proposal counter
        (var-set proposal-counter proposal-id)

        (ok proposal-id)
    )
)

;; Vote on a proposal
(define-public (vote-on-proposal (proposal-id uint) (vote-yes bool))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
            (voter-power (default-to u1 (map-get? player-voting-power tx-sender)))
            (current-block block-height)
        )
        (asserts! (default-to false (map-get? registered-players tx-sender)) ERR_UNAUTHORIZED)
        (asserts! (<= current-block (get end-block proposal)) ERR_VOTING_CLOSED)
        (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) ERR_ALREADY_VOTED)

        ;; Record the vote
        (map-set votes {proposal-id: proposal-id, voter: tx-sender}
            {vote: vote-yes, voting-power: voter-power}
        )

        ;; Update proposal vote counts
        (map-set proposals proposal-id
            (merge proposal
                {
                    yes-votes: (if vote-yes
                        (+ (get yes-votes proposal) voter-power)
                        (get yes-votes proposal)
                    ),
                    no-votes: (if vote-yes
                        (get no-votes proposal)
                        (+ (get no-votes proposal) voter-power)
                    ),
                    total-votes: (+ (get total-votes proposal) voter-power)
                }
            )
        )

        ;; Increase voter's voting power for future participation
        (map-set player-voting-power tx-sender (+ voter-power u1))

        (ok true)
    )
)

;; Execute a passed proposal (can be called by anyone after voting period)
(define-public (execute-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
            (current-block block-height)
            (total-players (var-get total-registered-players))
            (participation-rate (* (get total-votes proposal) u100))
            (min-participation (* total-players MIN_PARTICIPATION_THRESHOLD))
        )
        (asserts! (> current-block (get end-block proposal)) ERR_VOTING_CLOSED)
        (asserts! (not (get executed proposal)) ERR_PROPOSAL_EXECUTED)

        ;; Check if proposal passed (more yes votes than no votes + minimum participation)
        (if (and
                (> (get yes-votes proposal) (get no-votes proposal))
                (>= participation-rate min-participation)
            )
            (begin
                ;; Mark as executed
                (map-set proposals proposal-id (merge proposal {executed: true}))
                (ok {passed: true, yes-votes: (get yes-votes proposal), no-votes: (get no-votes proposal)})
            )
            (begin
                ;; Mark as executed but failed
                (map-set proposals proposal-id (merge proposal {executed: true}))
                (ok {passed: false, yes-votes: (get yes-votes proposal), no-votes: (get no-votes proposal)})
            )
        )
    )
)

;; Admin function to set voting power (only contract owner)
(define-public (set-voting-power (player principal) (power uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (map-set player-voting-power player power)
        (ok true)
    )
)

;; read only functions

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)

;; Get vote details for a specific voter and proposal
(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes {proposal-id: proposal-id, voter: voter})
)

;; Check if player is registered
(define-read-only (is-registered-player (player principal))
    (default-to false (map-get? registered-players player))
)

;; Get player voting power
(define-read-only (get-voting-power (player principal))
    (default-to u1 (map-get? player-voting-power player))
)

;; Get total registered players
(define-read-only (get-total-registered-players)
    (var-get total-registered-players)
)

;; Get current proposal counter
(define-read-only (get-proposal-counter)
    (var-get proposal-counter)
)

;; Check if voting is active for a proposal
(define-read-only (is-voting-active (proposal-id uint))
    (match (map-get? proposals proposal-id)
        proposal (and
            (<= block-height (get end-block proposal))
            (>= block-height (get start-block proposal))
        )
        false
    )
)

;; Get proposal results
(define-read-only (get-proposal-results (proposal-id uint))
    (match (map-get? proposals proposal-id)
        proposal
        (some {
            id: proposal-id,
            yes-votes: (get yes-votes proposal),
            no-votes: (get no-votes proposal),
            total-votes: (get total-votes proposal),
            executed: (get executed proposal),
            voting-ended: (> block-height (get end-block proposal))
        })
        none
    )
)

;; private functions

;; Helper function to check if proposal voting has ended
(define-private (is-voting-ended (proposal-id uint))
    (match (map-get? proposals proposal-id)
        proposal (> block-height (get end-block proposal))
        false
    )
)
