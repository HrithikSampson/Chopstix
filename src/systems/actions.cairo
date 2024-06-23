
#[dojo::contract]
mod actions {
    
    #[dojo::interface]
    trait IActions {
        fn start_game(ref world: IWorldDispatcher) -> felt252;
        fn join_game(ref world: IWorldDispatcher, session_id: felt252);
        fn make_move_opponent(ref world: IWorldDispatcher, session_id: felt252, hand: felt252, target_hand: felt252);
        fn make_move_other_hand(ref world: IWorldDispatcher, session_id: felt252, current_hand: felt252, transfer: felt252);
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn start_game(ref world: IWorldDispatcher) -> usize {
            let caller = get_caller_address();
            let session_id: felt252 = world.uuid();
            let game = Game {
                session_id,
                player1: Player { id: caller, left_hand: 1, right_hand: 1 },
                player2: None,
                state: GameState::WaitingForPlayer,
                current_turn: Turn::Player1,
            };
            set!(world,game);
            world.emit(GameStarted { session_id });
            session_id
        }

        fn join_game(ref world: IWorldDispatcher, session_id: felt252) {
            let caller = get_caller_address();
            let mut game = get!(world,session_id,(Game));
            if game.state != GameState::WaitingForPlayer {
                panic("Game is not waiting for players");
            }
            game.player2 = Some(Player { id: caller, left_hand: 1, right_hand: 1 });
            game.state = GameState::InProgress;
            set!(world,game);
            world.emit(PlayerJoined { session_id, player_id: caller });
        }

        fn make_move_opponent(ref world: IWorldDispatcher, session_id: felt252, hand: u8, target_hand: u8) {
            let caller = get_caller_address();
            let mut game = get!(world,session_id,(Game));
            if game.state != GameState::InProgress {
                panic("Game is not in progress");
            }

            let active_player = if game.current_turn == Turn::Player1 {
                &mut game.player1
            } else {
                game.player2.as_mut().unwrap()
            };

            let opponent = if game.current_turn == Turn::Player1 {
                game.player2.as_mut().unwrap()
            } else {
                &mut game.player1
            };

            let active_hand = if hand == 0 { active_player.left_hand } else { active_player.right_hand };
            let opponent_hand = if target_hand == 0 { &mut opponent.left_hand } else { &mut opponent.right_hand };

            *opponent_hand += active_hand;
            if *opponent_hand >= 5 { *opponent_hand = 0; }

            if opponent.left_hand == 0 && opponent.right_hand == 0 {
                game.state = GameState::Finished(caller);
            } else {
                game.current_turn = if game.current_turn == Turn::Player1 {
                    Turn::Player2
                } else {
                    Turn::Player1
                };
            }

            set!(world,game);
            world.emit(MoveMade { session_id, player_id: caller, move_type: 1 });
        }

        fn make_move_other_hand(ref world: IWorldDispatcher, session_id: felt252, current_hand: felt252, transfer: felt252) {
            let caller = get_caller_address();
            let mut game = get!(world,session_id,(Game));
            if game.state != GameState::InProgress {
                panic("Game is not in progress");
            }

            let active_player = if game.current_turn == Turn::Player1 {
                &mut game.player1
            } else {
                game.player2.as_mut().unwrap()
            };

            let left = &mut active_player.left_hand;
            let right = &mut active_player.right_hand;

            let active_hand;
            let target_hand;
            if current_hand == 0 {
                active_hand = left;
                target_hand = right;
            } else {
                active_hand = right;
                target_hand = left;
            }

            if transfer > *active_hand {
                panic("Cannot transfer more than the amount in your hand");
            }

            let new_active_hand = *active_hand - transfer;
            let new_target_hand = (*target_hand + transfer) % 5;

            if new_active_hand == *target_hand && new_target_hand == *active_hand {
                panic("Symmetric operations are not allowed");
            }

            *active_hand = new_active_hand;
            *target_hand = new_target_hand;

            set!(world,game);
            world.emit(MoveMade { session_id, player_id: caller, move_type: 2 });
        }
    }
}