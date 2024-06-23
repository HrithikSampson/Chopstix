
use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Player {
    #[key]
    id: ContractAddress,
    left_hand: u8,
    right_hand: u8,
}

#[derive(PartialEq, Copy ,Drop, Serde, Introspect)]
enum GameState {
    WaitingForPlayer,
    InProgress,
    Finished: ContractAddress,
}

#[derive(PartialEq ,Copy ,Drop, Serde, Introspect)]
enum Turn {
    Player1,
    Player2,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Game {
    #[key]
    session_id: usize,
    player1: Player,
    player2: Option<Player>,
    state: GameState,
    current_turn: Turn,
}

