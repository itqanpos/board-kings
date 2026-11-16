import React, { useState } from 'react';
import { COLORS, HEX, NAMES, SAFE_SPOTS, getTokenCoords, getInitialTokens } from './ludoEngine';

// صور القطع (سيارات وكرات 3D)
const TOKEN_IMAGES = {
  red: 'https://cdn-icons-png.flaticon.com/512/3097/3097180.png', // سيارة حمراء
  green: 'https://cdn-icons-png.flaticon.com/512/3097/3097193.png', // سيارة خضراء
  blue: 'https://cdn-icons-png.flaticon.com/512/3097/3097178.png', // كرة زرقاء
  yellow: 'https://cdn-icons-png.flaticon.com/512/3097/3097185.png' // كرة صفراء
};

// صور الزهر الحقيقية
const DICE_IMAGES = {
  1: 'https://cdn-icons-png.flaticon.com/512/123/123402.png',
  2: 'https://cdn-icons-png.flaticon.com/512/123/123400.png',
  3: 'https://cdn-icons-png.flaticon.com/512/123/123399.png',
  4: 'https://cdn-icons-png.flaticon.com/512/123/123398.png',
  5: 'https://cdn-icons-png.flaticon.com/512/123/123397.png',
  6: 'https://cdn-icons-png.flaticon.com/512/123/123396.png'
};

function Ludo({ onBack }) {
  const [tokens, setTokens] = useState(getInitialTokens());
  const [currentPlayer, setCurrentPlayer] = useState(0);
  const [dice, setDice] = useState(0);
  const [hasRolled, setHasRolled] = useState(false);
  const [message, setMessage] = useState('');

  const rollDice = () => {
    if (hasRolled) return;
    const roll = Math.floor(Math.random() * 6) + 1;
    setDice(roll);
    setHasRolled(true);
    setMessage('');

    const hasValidMove = tokens.some(t => 
      t.color === COLORS[currentPlayer] && (t.pos === -1 ? roll === 6 : t.pos + roll <= 57)
    );
    if (!hasValidMove) {
      setMessage('لا توجد حركات متاحة');
      setTimeout(() => endTurn(), 1500);
    }
  };

  const endTurn = (extraTurn = false) => {
    setDice(0);
    setHasRolled(false);
    if (!extraTurn) setCurrentPlayer((prev) => (prev + 1) % 4);
  };

  const moveToken = (tokenId) => {
    if (!hasRolled) return;
    
    setTokens(prevTokens => {
      let newTokens = [...prevTokens];
      let token = newTokens.find(t => t.id === tokenId);
      
      if (token.pos === -1 && dice === 6) token.pos = 0;
      else if (token.pos !== -1) {
        if (token.pos + dice > 57) return prevTokens;
        token.pos += dice;
      }

      // منطق الأكل
      if (token.pos < 52) {
        const absPos = (token.pos + (token.color === 'red' ? 0 : token.color === 'green' ? 13 : token.color === 'blue' ? 26 : 39)) % 52;
        if (!SAFE_SPOTS.includes(absPos)) {
          newTokens.forEach(t => {
            if (t.color !== token.color && t.pos !== -1 && t.pos < 52) {
               const tAbsPos = (t.pos + (t.color === 'red' ? 0 : t.color === 'green' ? 13 : t.color === 'blue' ? 26 : 39)) % 52;
               if (tAbsPos === absPos) t.pos = -1;
            }
          });
        }
      }
      return newTokens;
    });

    endTurn(dice === 6);
  };

  return (
    <div className="game-bg">
      {/* الشريط العلوي */}
      <div className="top-bar">
        <div className={`player-info ${currentPlayer === 0 ? 'active' : ''}`}>
          <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Felix" alt="P1" className="avatar" style={{borderColor: HEX.red}}/>
          <span className="p-name">{NAMES[0]}</span>
        </div>
        <div className={`player-info ${currentPlayer === 1 ? 'active' : ''}`}>
          <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Aneka" alt="P2" className="avatar" style={{borderColor: HEX.green}}/>
          <span className="p-name">{NAMES[1]}</span>
        </div>
        <div className={`player-info ${currentPlayer === 2 ? 'active' : ''}`}>
          <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Jack" alt="P3" className="avatar" style={{borderColor: HEX.blue}}/>
          <span className="p-name">{NAMES[2]}</span>
        </div>
        <div className={`player-info ${currentPlayer === 3 ? 'active' : ''}`}>
          <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Lily" alt="P4" className="avatar" style={{borderColor: HEX.yellow}}/>
          <span className="p-name">{NAMES[3]}</span>
        </div>
      </div>
      
      {/* لوحة اللعب */}
      <div className="board-container">
        <svg viewBox="0 0 15 15" className="ludo-svg">
          <defs>
            <linearGradient id="redGrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stopColor="#FF6B6B"/><stop offset="100%" stopColor="#D32F2F"/></linearGradient>
            <linearGradient id="greenGrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stopColor="#69F0AE"/><stop offset="100%" stopColor="#388E3C"/></linearGradient>
            <linearGradient id="blueGrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stopColor="#40C4FF"/><stop offset="100%" stopColor="#1976D2"/></linearGradient>
            <linearGradient id="yellowGrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stopColor="#FFFF8D"/><stop offset="100%" stopColor="#FBC02D"/></linearGradient>
          </defs>

          <rect width="15" height="15" fill="#FFFFFF" />
          
          {/* المسار */}
          {[...Array(52)].map((_, i) => {
             const [x, y] = getTokenCoords('red', i, 0); 
             const isSafe = SAFE_SPOTS.includes(i);
             return <rect key={i} x={x} y={y} width="1" height="1" fill={isSafe ? "#FFF9C4" : "#FFFFFF"} stroke="#BDBDBD" strokeWidth="0.05" />;
          })}

          {/* مسارات النهاية */}
          {COLORS.map(c => [0,1,2,3,4].map(i => {
             const [x, y] = getTokenCoords(c, 52+i, 0);
             return <rect key={`${c}-home-${i}`} x={x} y={y} width="1" height="1" fill={`url(#${c}Grad)`} stroke="#FFF" strokeWidth="0.05" />;
          }))}

          {/* البيوت */}
          {COLORS.map(c => {
            const isRight = c === 'green' || c === 'blue';
            const isBottom = c === 'blue' || c === 'yellow';
            return (
               <g key={`base-${c}`}>
                 <rect x={isRight ? 9 : 0} y={isBottom ? 9 : 0} width="6" height="6" fill={`url(#${c}Grad)`} stroke="#FFF" strokeWidth="0.1" rx="0.8" />
                 <rect x={isRight ? 10 : 1} y={isBottom ? 10 : 1} width="4" height="4" fill="#FFFFFF" stroke="#E0E0E0" strokeWidth="0.1" rx="0.5" />
               </g>
            )
          })}

          {/* المثلثات الوسطى */}
          <polygon points="6,6 9,6 7.5,7.5" fill="url(#redGrad)" stroke="#FFF" strokeWidth="0.05"/>
          <polygon points="9,6 9,9 7.5,7.5" fill="url(#greenGrad)" stroke="#FFF" strokeWidth="0.05"/>
          <polygon points="9,9 6,9 7.5,7.5" fill="url(#blueGrad)" stroke="#FFF" strokeWidth="0.05"/>
          <polygon points="6,9 6,6 7.5,7.5" fill="url(#yellowGrad)" stroke="#FFF" strokeWidth="0.05"/>

          {/* القطع */}
          {tokens.map(t => {
            const [cx, cy] = getTokenCoords(t.color, t.pos, parseInt(t.id.split('-')[1]));
            const isMyTurn = t.color === COLORS[currentPlayer];
            const canMove = isMyTurn && hasRolled && (t.pos === -1 ? dice === 6 : t.pos + dice <= 57);
            
            return (
              <g key={t.id} className={`token-group ${canMove ? 'clickable' : ''}`} onClick={() => canMove && moveToken(t.id)}>
                <ellipse cx={cx} cy={cy + 0.25} rx="0.3" ry="0.1" fill="rgba(0,0,0,0.4)" />
                <image href={TOKEN_IMAGES[t.color]} x={cx - 0.4} y={cy - 0.45} width="0.8" height="0.8" preserveAspectRatio="xMidYMid meet" />
              </g>
            );
          })}
        </svg>
      </div>

      {/* الشريط السفلي */}
      <div className="bottom-bar">
         <div className="chat-controls">
            <button className="circle-btn">🎤</button>
            <button className="circle-btn">💬</button>
            <button className="circle-btn">😊</button>
         </div>

         <div className="dice-area">
            {message && <div className="toast-msg">{message}</div>}
            {dice > 0 ? (
               <img src={DICE_IMAGES[dice]} alt="dice" className="dice-img-3d" />
            ) : (
               <div className="dice-3d empty" onClick={rollDice}>🎲</div>
            )}
            {hasRolled && <button className="pass-btn" onClick={() => endTurn(false)}>تخطي</button>}
         </div>
      </div>
    </div>
  );
}

export default Ludo;
