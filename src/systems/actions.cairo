


#[dojo::interface]
trait IActions {
    fn start_game(ref world: IWorldDispatcher) -> usize;
    fn join_game(ref world: IWorldDispatcher, session_id: usize);
    fn make_move_opponent(ref world: IWorldDispatcher, session_id: usize, hand: u8, target_hand: u8);
    fn make_move_other_hand(ref world: IWorldDispatcher, session_id: usize, current_hand: u8, transfer: u8);
}
#[dojo::contract]
mod actions {
    use chopsticks::models::game::{Game, Player, GameState, Turn};
    use super::{IActions};
    use starknet::{ContractAddress, get_caller_address};
    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn start_game(ref world: IWorldDispatcher) -> usize {
            let caller = get_caller_address();
            let session_id = world.uuid();
            set!(world, (Game {
                session_id,
                player1: Player { id: caller, left_hand: 1, right_hand: 1 },
                player2: Option::None,
                state: GameState::WaitingForPlayer,
                current_turn: Turn::Player1,
            }));
            session_id
        }

        fn join_game(ref world: IWorldDispatcher, session_id: usize) {
            let caller = get_caller_address();
            let mut game:Game = get!(world,session_id, (Game));
            if game.state != GameState::WaitingForPlayer {
                panic!("Game is not waiting for players");
            }
            game.player2 = Option::Some(Player { id: caller, left_hand: 1, right_hand: 1 });
            game.state = GameState::InProgress;
            set!(world, (Game {
                session_id: game.session_id,
                player1: game.player1,
                player2: game.player2,
                state: game.state,
                current_turn: game.current_turn,
            }));
        }

        fn make_move_opponent(ref world: IWorldDispatcher, session_id: usize, hand: u8, target_hand: u8) {
            let caller = get_caller_address();
            let mut game:Game = get!(world,session_id, (Game));
            if game.state != GameState::InProgress {
                return;
            }
            let active_player = if game.current_turn == Turn::Player1 {
                game.player1
            } else {
                game.player2.unwrap()
            };

            let opponent = if game.current_turn == Turn::Player1 {
                game.player2.unwrap()
            } else {
                game.player1
            };

            let active_hand = if hand == 0 { active_player.left_hand } else { active_player.right_hand };
            let mut opponent_hand = if target_hand == 0 { opponent.left_hand } else { opponent.right_hand };

            opponent_hand += active_hand;
            if opponent_hand >= 5 { opponent_hand = 0; }

            if opponent.left_hand == 0 && opponent.right_hand == 0 {
                game.state = GameState::Finished(caller);
            } else {
                game.current_turn = if game.current_turn == Turn::Player1 {
                    Turn::Player2
                } else {
                    Turn::Player1
                };
            }
            set!(world, (Game {
                session_id: game.session_id,
                player1: game.player1,
                player2: game.player2,
                state: game.state,
                current_turn: game.current_turn,
            }));
        }

        fn make_move_other_hand(ref world: IWorldDispatcher, session_id: usize, current_hand: u8, transfer: u8) {
            let caller = get_caller_address();
            let mut game: Game = get!(world,session_id,(Game));
            if game.state != GameState::InProgress {
                return;
            }

            let mut active_player = if game.current_turn == Turn::Player1 {
                game.player1
            } else {
                game.player2.unwrap()
            };

            let mut left = active_player.left_hand;
            let mut right = active_player.right_hand;

            let mut active_hand = left;
            let mut target_hand = right;
            if current_hand == 0 {
                active_hand = left;
                target_hand = right;
            } else {
                active_hand = right;
                target_hand = left;
            }

            if transfer > active_hand {
                return;
            }

            let new_active_hand = active_hand - transfer;
            let new_target_hand = (target_hand + transfer) % 5;

            if new_active_hand == target_hand && new_target_hand == active_hand {
                return;
            }

            active_hand = new_active_hand;
            target_hand = new_target_hand;

            set!(world, (Game {
                session_id: game.session_id,
                player1: game.player1,
                player2: game.player2,
                state: game.state,
                current_turn: game.current_turn,
            }));
        }
    }
}