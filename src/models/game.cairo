
use starknet::ContractAddress;*;

#[derive(Clone, Copy, Drop, Serde)]
#[dojo::model]
struct Player {
    #[key]
    id: ContractAddress,
    left_hand: u8,
    right_hand: u8,
}

#[derive(Clone, Copy, Drop, Serde)]
#[dojo::model]
enum GameState {
    WaitingForPlayer,
    InProgress,
    Finished(ContractAddress), // Player ID of the winner
}

#[derive(Clone, Copy, Drop, Serde)]
#[dojo::model]
enum Turn {
    Player1,
    Player2,
}

#[derive(Clone, Copy, Drop, Serde)]
#[dojo::model]
struct Game {
    #[key]
    session_id: felt252,
    player1: Player,
    player2: Option<Player>,
    state: GameState,
    current_turn: Turn,
}

