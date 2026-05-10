/**
 * Script used to simulate games with all llm agents
 */
import { AgentStateDto, StateDto } from "../common/types.ts";
import { gameConfig } from "../config/gameConfig.ts";
import { attack } from "../handlers/attack.ts";
import { attackSide } from "../handlers/attackSide.ts";
import { defense } from "../handlers/defense.ts";
import { exploration } from "../handlers/exploration.ts";
import { logGame, LogGameRequest } from "../handlers/gameLog.ts";

type Player = {
  id: number;
  name: string;
  gold: number;
  explorationShipCount: number;
  attackGoldChange: number;
  agentState: AgentStateDto;
};

type State = {
  sessionId: string;
  userId: string;
  players: Player[];
  round: number;
};

// NOTE: Configure number of players
const PLAYER_MODELS = ["agent1", "agent2", "agent3", "agent4"] as const;

const state: State = {
  sessionId: new Date().toISOString(),
  userId: "simulate",
  players: PLAYER_MODELS.map((model, id) => ({
    id,
    name: model,
    gold: gameConfig.startingGold,
    explorationShipCount: 0,
    attackGoldChange: 0,
    agentState: {
      model,
      history: [],
      strategy: "",
      playerAnalysis: {},
    },
  })),
  round: 1,
};

// Handle agent memory
function pushAgentMemory(history: string[], entry: string) {
  history.push(entry);
  if (history.length > gameConfig.maxHistoryItems) {
    history.splice(0, history.length - gameConfig.maxHistoryItems);
  }
}

function rememberPublicEvent(entry: string) {
  for (const player of state.players) {
    pushAgentMemory(player.agentState.history, entry);
  }
}

function rememberPrivateReasoning(
  player: Player,
  phase: string,
  reasoning: string
) {
  pushAgentMemory(
    player.agentState.history,
    `[Private] Round ${state.round} ${phase}: ${reasoning}`
  );
}

// Handle logging
function log(data: LogGameRequest["data"]) {
  logGame({ userId: state.userId, sessionId: state.sessionId, data });
}

// Match common data shape used by demo and simulation
function toStateDto(state: State, player: Player): StateDto {
  return {
    sessionId: state.sessionId,
    userId: state.userId,
    thisPlayerId: player.id,
    agentState: player.agentState,
    players: state.players,
    round: state.round,
  };
}

async function gameLoop() {
  while (true) {
    console.log(`--- ROUND: ${state.round} ---`);
    console.table(
      state.players.map((p) => ({
        Name: p.name,
        Gold: p.gold,
      }))
    );

    log({
      type: "roundStarted",
      round: state.round,
      players: state.players.map((p) => ({
        id: p.id,
        name: p.name,
        gold: p.gold,
        explorationShipCount: p.explorationShipCount,
      })),
    });

    console.log("--- EXPLORATION PHASE ---");
    // Agents choose how to split their ships in parallel
    await Promise.all(
      state.players.map(async (player) => {
        const explorationResult = await exploration({
          state: toStateDto(state, player),
        });
        rememberPrivateReasoning(
          player,
          "Exploration",
          explorationResult.privateThought
        );
        rememberPublicEvent(
          `Round ${state.round} | ${player.name} says: ${explorationResult.discussion}`
        );
        player.explorationShipCount = explorationResult.explorationShipCount;
        player.agentState.strategy = explorationResult.strategy;
        player.agentState.playerAnalysis = explorationResult.playerAnalysis;

        console.log(`[${player.name}]`);
        console.log(`Reasoning: ${explorationResult.privateThought}`);
        console.log(`Strategy: ${explorationResult.strategy}`);
        console.log(
          `Player analysis: ${JSON.stringify(explorationResult.playerAnalysis)}`
        );
        console.log(
          `Action: Sent ${explorationResult.explorationShipCount} ships to explore`
        );
        console.log(`Discussion: ${explorationResult.discussion}\n`);

        log({
          type: "decideExploration",
          playerId: player.id,
          privateThought: explorationResult.privateThought,
          explorationShipCount: explorationResult.explorationShipCount,
          discussion: explorationResult.discussion,
          strategy: explorationResult.strategy,
          playerAnalysis: explorationResult.playerAnalysis,
        });
      })
    );

    // Attack phase
    console.log("--- ATTACK PHASE ---");
    // Random attacker is chosen
    const attackerId = Math.floor(Math.random() * state.players.length);
    const attacker = state.players[attackerId];

    rememberPublicEvent(
      `Round ${state.round} | ${attacker.name} was chosen as the attacker.`
    );

    // Attacker chooses defender and invites allies
    const attackChoice = await attack({ state: toStateDto(state, attacker) });

    const defenderId = attackChoice.defenderId;
    const defender = state.players.find((p) => p.id === defenderId)!;

    const attackerInvitedNames = attackChoice.invitedPlayerIds.map(
      (id) => state.players.find((p) => p.id === id)?.name
    );

    rememberPrivateReasoning(attacker, "Attack", attackChoice.privateThought);
    rememberPublicEvent(
      `Round ${state.round} | ${attacker.name} attacks ${
        defender.name
      }; invited allies: ${attackerInvitedNames.join(", ") || "none"}. ${
        attackChoice.discussion
      }`
    );

    console.log(`[${attacker.name}] (Attacker)`);
    console.log(`Reasoning: ${attackChoice.privateThought}`);
    console.log(
      `Action: Attacked ${defender.name}, invited allies: ${
        attackerInvitedNames.join(", ") || "none"
      }`
    );
    console.log(`Discussion: ${attackChoice.discussion}\n`);

    log({
      type: "decideAttack",
      playerId: attacker.id,
      privateThought: attackChoice.privateThought,
      defenderId: defender.id,
      invitedPlayerIds: attackChoice.invitedPlayerIds,
      discussion: attackChoice.discussion,
    });

    // Defense phase
    console.log("--- ATTACK - DEFENSE PHASE ---");
    // Defender invites allies
    const defenseChoice = await defense({
      state: toStateDto(state, defender),
      attackerId,
    });

    const defenderInvitedNames = defenseChoice.invitedPlayerIds.map(
      (id) => state.players.find((p) => p.id === id)?.name
    );

    rememberPrivateReasoning(defender, "Defense", defenseChoice.privateThought);
    rememberPublicEvent(
      `Round ${state.round} | ${defender.name} defends against ${
        attacker.name
      }; invited allies: ${defenderInvitedNames.join(", ") || "none"}. ${
        defenseChoice.discussion
      }`
    );

    console.log(`[${defender.name}] (Defender)`);
    console.log(`Reasoning: ${defenseChoice.privateThought}`);
    console.log(
      `Action: Invited allies: ${defenderInvitedNames.join(", ") || "none"}`
    );
    console.log(`Discussion: ${defenseChoice.discussion}\n`);

    log({
      type: "decideDefense",
      playerId: defender.id,
      privateThought: defenseChoice.privateThought,
      invitedPlayerIds: defenseChoice.invitedPlayerIds,
      discussion: defenseChoice.discussion,
    });

    // Alliance phase
    console.log("--- ATTACK - ALLIANCE PHASE ---");
    const attackAllies: number[] = [];
    const defenseAllies: number[] = [];

    // Allies choose which side to join in parallel
    await Promise.all(
      state.players.map(async (player) => {
        if (player.id === attackerId || player.id === defenderId) return;

        const hasAttackerSideInvite = attackChoice.invitedPlayerIds.includes(
          player.id
        );
        const hasDefenderSideInvite = defenseChoice.invitedPlayerIds.includes(
          player.id
        );

        if (!hasAttackerSideInvite && !hasDefenderSideInvite) return;

        const sideChoice = await attackSide({
          state: toStateDto(state, player),
          attackerId,
          defenderId,
          hasAttackerSideInvite,
          hasDefenderSideInvite,
        });
        rememberPrivateReasoning(
          player,
          "AttackSide",
          sideChoice.privateThought
        );
        rememberPublicEvent(
          `Round ${state.round} | ${player.name} joins ${sideChoice.side}. ${sideChoice.discussion}`
        );

        console.log(`[${player.name}] (Ally)`);
        console.log(`Reasoning: ${sideChoice.privateThought}`);
        console.log(`Action: Chose to join ${sideChoice.side}`);
        console.log(`Discussion: ${sideChoice.discussion}\n`);

        log({
          type: "decideAttackSide",
          playerId: player.id,
          privateThought: sideChoice.privateThought,
          side: sideChoice.side,
          discussion: sideChoice.discussion,
        });

        if (sideChoice.side === "attack") {
          attackAllies.push(player.id);
        } else if (sideChoice.side === "defense") {
          defenseAllies.push(player.id);
        }
      })
    );

    //  Attack resolution
    console.log("--- ATTACK RESOLUTION ---");
    // Count ships per attack side
    const attackers = [
      attacker,
      ...attackAllies.map((id) => state.players.find((p) => p.id === id)!),
    ];
    const defenders = [
      defender,
      ...defenseAllies.map((id) => state.players.find((p) => p.id === id)!),
    ];

    const attackingShipsCount = attackers.reduce(
      (acc, curr) => acc + gameConfig.shipCount - curr.explorationShipCount,
      0
    );
    const defendingShipsCount = defenders.reduce(
      (acc, curr) => acc + gameConfig.shipCount - curr.explorationShipCount,
      0
    );

    // Determine attack winners
    // Defenders win on stalemate
    const attackWon = attackingShipsCount > defendingShipsCount;
    const winners = attackWon ? attackers : defenders;
    const losers = attackWon ? defenders : attackers;

    console.log(
      `Attacker ships: ${attackingShipsCount}, Defender ships: ${defendingShipsCount}`
    );
    console.log(`${attackWon ? attacker.name : defender.name}'s side wins!\n`);

    rememberPublicEvent(
      `Round ${
        state.round
      } | Combat resolved: attacker side ${attackingShipsCount} ships vs defender side ${defendingShipsCount} ships. Winner: ${
        attackWon ? attacker.name : defender.name
      }'s side.`
    );

    // Attackers capture gold from the losers
    let totalCapturedGold = 0;

    for (const loser of losers) {
      // Each loser loses half of their gold (rounded down)
      const lostGold = Math.floor(loser.gold / 2);
      loser.attackGoldChange = -lostGold;
      totalCapturedGold += lostGold;
    }

    // Winner split the spoils evenly
    const capturedSplit = Math.floor(totalCapturedGold / winners.length);
    for (const winner of winners) {
      winner.attackGoldChange = capturedSplit;
    }

    // Remainder of the gold goes to the lead attacker/defender
    const remainder = totalCapturedGold % winners.length;
    if (remainder > 0) {
      winners[0].attackGoldChange += remainder;
    }

    rememberPublicEvent(
      `Round ${state.round} | Spoils distributed: ${totalCapturedGold} total gold across ${winners.length} winner(s).`
    );

    log({
      type: "attackResolved",
      round: state.round,
      attackerId: attacker.id,
      defenderId: defender.id,
      attackWon,
      players: state.players.map((p) => {
        const isAttackSide = p.id === attackerId || attackAllies.includes(p.id);
        const isDefenseSide =
          p.id === defenderId || defenseAllies.includes(p.id);
        const side = isAttackSide
          ? ("attack" as const)
          : isDefenseSide
          ? ("defense" as const)
          : ("neutral" as const);
        return {
          playerId: p.id,
          side,
          invitedByAttacker: attackChoice.invitedPlayerIds.includes(p.id),
          invitedByDefender: defenseChoice.invitedPlayerIds.includes(p.id),
          homeShips: gameConfig.shipCount - p.explorationShipCount,
          goldChange: p.attackGoldChange,
        };
      }),
    });

    // Apply gold changes
    for (const player of state.players) {
      player.gold += player.explorationShipCount + player.attackGoldChange;
    }

    log({
      type: "explorationResolved",
      round: state.round,
      players: state.players.map((p) => ({
        playerId: p.id,
        explorationShipCount: p.explorationShipCount,
        goldChange: p.explorationShipCount,
      })),
    });

    const roundSummary = state.players
      .map((p) => {
        const goldChange = p.attackGoldChange + p.explorationShipCount;
        const sign = goldChange >= 0 ? "+" : "";
        return `${p.name}: ${p.gold} gold (${sign}${goldChange}), home ${
          gameConfig.shipCount - p.explorationShipCount
        }/${gameConfig.shipCount} ships, exploring ${p.explorationShipCount}`;
      })
      .join(" | ");
    rememberPublicEvent(`Round ${state.round} end | ${roundSummary}`);

    for (const player of state.players) {
      player.explorationShipCount = 0;
      player.attackGoldChange = 0;
    }

    // Check win condition
    const maxGold = Math.max(...state.players.map((p) => p.gold));
    if (maxGold >= gameConfig.winGold) {
      const leaders = state.players.filter((p) => p.gold === maxGold);

      if (leaders.length === 1) {
        const winner = leaders[0];

        log({
          type: "gameEnded",
          round: state.round,
          winnerId: winner.id,
          players: state.players.map((p) => ({
            id: p.id,
            name: p.name,
            gold: p.gold,
          })),
        });

        console.log("Game ended!");
        console.log("Winner:", winner);
        break;
      }

      const tiedNames = leaders.map((p) => p.name).join(", ");
      rememberPublicEvent(
        `Round ${state.round} | ${tiedNames} are tied at ${maxGold} gold (>= ${gameConfig.winGold}). Game continues to next round!`
      );
    }

    log({
      type: "roundEnded",
      round: state.round,
      players: state.players.map((p) => ({
        id: p.id,
        name: p.name,
        gold: p.gold,
      })),
    });

    state.round++;
  }
}

gameLoop();
