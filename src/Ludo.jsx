import React, { useState } from 'react';
import { COLORS, HEX, NAMES, SAFE_SPOTS, getTokenCoords, getInitialTokens } from './ludoEngine';

// دالة لرسم النرد بشكل احترافي (نقط)
const DiceFace = ({ value, color }) => {
  const dots = {
    1: [4], 2: [0, 8], 3: [0, 4, 8], 4: [0, 2, 6, 8], 5: [0, 2, 4, 6, 8], 6: [0, 2, 3, 5, 6, 8]
  };
  return (
    <div className="dice-3d" style={{ borderColor: color }}>
      <div className="dice-grid">
        {[...Array(9)].map((_, i) => (
          <div key={i} className={`dice-dot ${dots[value]?.includes(i) ? 'active' : ''}`} style={{ backgroundColor: color }} />
        ))}
      </div>
    </div>
  );
};

function Ludo({ onBack }) {
  const [tokens, setTokens] = useState(getInitialTokens());
  const [currentPlayer, setCurrentPlayer] = useState(0);
  const [dice, setDice] = useState(0);
  const [hasRolled, setHasRolled] = useState(false);
  const [sixCount, setSixCount] = useState(0);
  const [message, setMessage] = useState('');

  const rollDice = () => {
    if (hasRolled) return;
    const roll = Math.floor(Math.random() * 6) + 1;
    
    let newSixCount = sixCount;
    if (roll === 6) {
      newSixCount++;
      if (newSixCount === 3) {
        setMessage('3 رميات 6! خسرت الدور.');
        setTimeout(() => endTurn(), 1500);
        return;
      }
    } else {
      newSixCount = 0;
    }

    setDice(roll);
    setHasRolled(true);
    setSixCount(newSixCount);
    setMessage('');

    const hasValidMove = tokens.some(t => 
      t.color === COLORS[currentPlayer] && 
      (t.pos === -1 ? roll === 6 : t.pos + roll <= 57)
    );
    
    if (!hasValidMove) {
      setMessage('لا توجد حركات متاحة');
      setTimeout(() => endTurn(), 1500);
    }
  };

  const endTurn = (extraTurn = false) => {
    setDice(0);
    setHasRolled(false);
    if (!extraTurn) {
      setCurrentPlayer((prev) => (prev + 1) % 4);
      setSixCount(0);
    }
  };

  const moveToken = (tokenId) => {
    if (!hasRolled) return;
    
    setTokens(prevTokens => {
      let newTokens = [...prevTokens];
      let token = newTokens.find(t => t.id === tokenId);
      
      if (token.pos === -1 && dice === 6) {
        token.pos = 0;
      } else if (token.pos !== -1) {
        if (token.pos + dice > 57) return prevTokens;
        token.pos += dice;
      }

      if (token.pos < 52) {
        const absPos = (token.pos + (token.color === 'red' ? 0 : token.color === 'green' ? 13 : token.color === 'blue' ? 26 : 39)) % 52;
        
        if (!SAFE_SPOTS.includes(absPos)) {
          newTokens.forEach(t => {
            if (t.color !== token.color && t.pos !== -1 && t.pos < 52) {
               const tAbsPos = (t.pos + (t.color === 'red' ? 0 : t.color === 'green' ? 13 : t.color === 'blue' ? 26 : 39)) % 52;
               if (tAbsPos === absPos) {
                 t.pos = -1;
                 setMessage(`تم أكل قطعة ${NAMES[t.index]}!`);
               }
            }
          });
        }
      }
      return newTokens;
    });

    const playerTokens = tokens.filter(t => t.color === COLORS[currentPlayer]);
    if (playerTokens.every(t => t.pos === 57)) {
      setMessage(`🎉 مبروك ${NAMES[currentPlayer]} فاز باللعبة!`);
      return;
    }

    endTurn(dice === 6);
  };

  return (
    <div className="ludo-container">
      <div className="ludo-header">
        <button className="back-btn" onClick={onBack}>رجوع</button>
        <div className="turn-indicator">
          دور: <span style={{ color: HEX[COLORS[currentPlayer]], textShadow: '0 0 10px ' + HEX[COLORS[currentPlayer]] }}>{NAMES[currentPlayer]}</span>
        </div>
      </div>
      
      <div className="ludo-board-wrapper">
        <svg viewBox="0 0 15 15" className="ludo-svg">
          {/* تعريف التدرجات اللونية للوحة */}
          <defs>
            <radialGradient id="gradRed" cx="30%" cy="30%"><stop offset="0%" stopColor="#ff6b6b"/><stop offset="100%" stopColor="#c0392b"/></radialGradient>
            <radialGradient id="gradGreen" cx="30%" cy="30%"><stop offset="0%" stopColor="#55efc4"/><stop offset="100%" stopColor="#27ae60"/></radialGradient>
            <radialGradient id="gradBlue" cx="30%" cy="30%"><stop offset="0%" stopColor="#74b9ff"/><stop offset="100%" stopColor="#2980b9"/></radialGradient>
            <radialGradient id="gradYellow" cx="30%" cy="30%"><stop offset="0%" stopColor="#ffeaa7"/><stop offset="100%" stopColor="#f39c12"/></radialGradient>
            <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
              <feDropShadow dx="0.1" dy="0.2" stdDeviation="0.1" floodOpacity="0.4"/>
            </filter>
          </defs>

          <rect width="15" height="15" fill="#f8f9fa" stroke="#333" strokeWidth="0.2" />
          
          {/* رسم المسار */}
          {[...Array(52)].map((_, i) => {
             const [x, y] = getTokenCoords('red', i, 0); 
             const isSafe = SAFE_SPOTS.includes(i);
             return (
               <rect key={i} x={x} y={y} width="1" height="1" fill={isSafe ? "#e2e8f0" : "#fff"} stroke="#cbd5e1" strokeWidth="0.05" />
             );
          })}

          {/* مسارات النهاية */}
          {COLORS.map(c => [0,1,2,3,4].map(i => {
             const [x, y] = getTokenCoords(c, 52+i, 0);
             return <rect key={`${c}-home-${i}`} x={x} y={y} width="1" height="1" fill={`url(#grad${c.charAt(0).toUpperCase() + c.slice(1)})`} stroke="#fff" strokeWidth="0.05" />;
          }))}

          {/* البيوت */}
          {COLORS.map(c => (
             <g key={`base-${c}`}>
               <rect x={c === 'red' || c === 'yellow' ? 0 : 9} y={c === 'red' || c === 'green' ? 0 : 9} width="6" height="6" fill={`url(#grad${c.charAt(0).toUpperCase() + c.slice(1)})`} stroke="#fff" strokeWidth="0.2" />
               <rect x={c === 'red' || c === 'yellow' ? 1 : 10} y={c === 'red' || c === 'green' ? 1 : 10} width="4" height="4" fill="#fff" stroke="#cbd5e1" strokeWidth="0.1" rx="0.5" />
             </g>
          ))}

          {/* المنتصف */}
          <polygon points="6,6 9,6 7.5,7.5" fill="url(#gradRed)" stroke="#fff" strokeWidth="0.05"/>
          <polygon points="9,6 9,9 7.5,7.5" fill="url(#gradGreen)" stroke="#fff" strokeWidth="0.05"/>
          <polygon points="9,9 6,9 7.5,7.5" fill="url(#gradBlue)" stroke="#fff" strokeWidth="0.05"/>
          <polygon points="6,9 6,6 7.5,7.5" fill="url(#gradYellow)" stroke="#fff" strokeWidth="0.05"/>

          {/* رسم القطع بتأثير 3D */}
          {tokens.map(t => {
            const [cx, cy] = getTokenCoords(t.color, t.pos, parseInt(t.id.split('-')[1]));
            const isMyTurn = t.color === COLORS[currentPlayer];
            const canMove = isMyTurn && hasRolled && (t.pos === -1 ? dice === 6 : t.pos + dice <= 57);
            
            return (
              <g key={t.id} className={`token-group ${canMove ? 'clickable' : ''}`} onClick={() => canMove && moveToken(t.id)}>
                <circle cx={cx + 0.1} cy={cy + 0.2} r="0.45" fill="rgba(0,0,0,0.4)" />
                <circle cx={cx} cy={cy} r="0.45" fill={`url(#grad${t.color.charAt(0).toUpperCase() + t.color.slice(1)})`} stroke="#fff" strokeWidth="0.1" filter="url(#shadow)" />
              </g>
            );
          })}
        </svg>
      </div>

      <div className="ludo-controls">
        <div className="dice-wrapper">
          {dice > 0 ? <DiceFace value={dice} color={HEX[COLORS[currentPlayer]]} /> : <div className="dice-3d empty">?</div>}
        </div>
        
        {message && <p className="message-text">{message}</p>}

        {!hasRolled ? (
          <button className="roll-btn" onClick={rollDice}>رمي الزهر</button>
        ) : (
          <button className="roll-btn end-turn" onClick={() => endTurn(false)}>إنهاء الدور</button>
        )}
      </div>
    </div>
  );
}

export default Ludo;
