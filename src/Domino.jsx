import React, { useState } from 'react';

const generateDeck = () => {
  let deck = [];
  for (let i = 0; i <= 6; i++) {
    for (let j = i; j <= 6; j++) {
      deck.push({ id: `${i}-${j}`, top: i, bottom: j });
    }
  }
  return deck.sort(() => Math.random() - 0.5);
};

const DominoTile = ({ tile, onClick, disabled }) => {
  const renderDots = (num) => {
    const dots = {
      1: [4], 2: [0, 8], 3: [0, 4, 8], 4: [0, 2, 6, 8], 5: [0, 2, 4, 6, 8], 6: [0, 2, 3, 5, 6, 8]
    };
    return (
      <div className="domino-half">
        {[...Array(9)].map((_, i) => (
          <div key={i} className={`domino-dot ${dots[num]?.includes(i) ? 'active' : ''}`} />
        ))}
      </div>
    );
  };

  return (
    <div className={`domino-tile ${disabled ? 'disabled' : ''}`} onClick={disabled ? null : onClick}>
      {renderDots(tile.top)}
      <div className="domino-divider" />
      {renderDots(tile.bottom)}
    </div>
  );
};

function Domino({ onBack }) {
  const [deck, setDeck] = useState(generateDeck());
  const [player1Hand, setPlayer1Hand] = useState([]);
  const [player2Hand, setPlayer2Hand] = useState([]);
  const [board, setBoard] = useState([]);
  const [turn, setTurn] = useState(1);
  const [message, setMessage] = useState('قم بسحب قطعة لتبدأ');

  const startGame = () => {
    let newDeck = generateDeck();
    setPlayer1Hand(newDeck.slice(0, 7));
    setPlayer2Hand(newDeck.slice(7, 14));
    setDeck(newDeck.slice(14));
    setBoard([]);
    setTurn(1);
    setMessage('دور اللاعب 1: العب أي قطعة');
  };

  const playTile = (tile, handSetter, myHand, otherHand) => {
    let newBoard = [...board];
    let leftEnd = newBoard.length > 0 ? newBoard[0].top : null;
    let rightEnd = newBoard.length > 0 ? newBoard[newBoard.length - 1].bottom : null;

    if (newBoard.length === 0) {
      newBoard.push(tile);
    } else {
      if (tile.bottom === leftEnd) {
        newBoard.unshift({ ...tile, top: tile.bottom, bottom: tile.top });
      } else if (tile.top === leftEnd) {
        newBoard.unshift(tile);
      } else if (tile.top === rightEnd) {
        newBoard.push(tile);
      } else if (tile.bottom === rightEnd) {
        newBoard.push({ ...tile, top: tile.bottom, bottom: tile.top });
      } else {
        return;
      }
    }

    setBoard(newBoard);
    const newHand = myHand.filter(t => t.id !== tile.id);
    handSetter(newHand);

    if (newHand.length === 0) {
      setMessage(`🎉 مبروك اللاعب ${turn} فاز!`);
      return;
    }

    setTurn(turn === 1 ? 2 : 1);
    setMessage(`دور اللاعب ${turn === 1 ? 2 : 1}`);
  };

  const checkValid = (tile) => {
    if (board.length === 0) return true;
    const leftEnd = board[0].top;
    const rightEnd = board[board.length - 1].bottom;
    return tile.top === leftEnd || tile.bottom === leftEnd || tile.top === rightEnd || tile.bottom === rightEnd;
  };

  return (
    <div className="domino-container">
      <div className="ludo-header">
        <button className="back-btn" onClick={onBack}>رجوع</button>
        <div className="turn-indicator" style={{ color: turn === 1 ? '#e74c3c' : '#3498db' }}>
          دور اللاعب {turn}
        </div>
      </div>

      {board.length === 0 && (
        <button className="roll-btn" onClick={startGame} style={{ marginBottom: '20px' }}>بدء توزيع القطع</button>
      )}

      <p className="message-text">{message}</p>

      <div className="domino-board">
        {board.map((t, i) => (
          <DominoTile key={i} tile={t} disabled={true} />
        ))}
      </div>

      <div className="player-hand">
        <h4 style={{ color: '#e74c3c', margin: '10px 0' }}>قطعك (اللاعب 1)</h4>
        <div className="hand-scroll">
          {player1Hand.map(t => (
            <DominoTile 
              key={t.id} tile={t} 
              onClick={() => turn === 1 && checkValid(t) && playTile(t, setPlayer1Hand, player1Hand, player2Hand)}
              disabled={turn !== 1 || !checkValid(t)} 
            />
          ))}
        </div>
      </div>

      <div className="player-hand">
        <h4 style={{ color: '#3498db', margin: '10px 0' }}>قطع اللاعب 2</h4>
        <div className="hand-scroll">
          {player2Hand.map(t => (
            <DominoTile 
              key={t.id} tile={t} 
              onClick={() => turn === 2 && checkValid(t) && playTile(t, setPlayer2Hand, player2Hand, player1Hand)}
              disabled={turn !== 2 || !checkValid(t)} 
            />
          ))}
        </div>
      </div>
    </div>
  );
}

export default Domino;
