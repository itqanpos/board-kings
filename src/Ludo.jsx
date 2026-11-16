import React, { useState } from 'react';
import { COLORS, HEX, NAMES, SAFE_SPOTS, getTokenCoords, getInitialTokens } from './ludoEngine';

// زهر ثلاثي الأبعاد بشكل يلا لودو
const DiceFace = ({ value }) => {
  const dots = {
    1: [4], 2: [0, 8], 3: [0, 4, 8], 4: [0, 2, 6, 8], 5: [0, 2, 4, 6, 8], 6: [0, 2, 3, 5, 6, 8]
  };
  return (
    <div className="yalla-dice">
      {[...Array(9)].map((_, i) => (
        <div key={i} className={`yalla-dot ${dots[value]?.includes(i) ? 'active' : ''}`} />
      ))}
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
    } else newSixCount = 0;

    setDice(roll);
    setHasRolled(true);
    setSixCount(newSixCount);
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
      
      if (token.pos === -1 && dice === 6) token.pos = 0;
      else if (token.pos !== -1) {
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
      setMessage(`🎉 مبروك ${NAMES[currentPlayer]} فاز!`);
      return;
    }
    endTurn(dice === 6);
  };

  return (
    <div className="yalla-container">
      {/* شريط اللاعبين العلوي */}
      <div className="players-bar">
        {COLORS.map((c, i) => (
          <div key={c} className={`player-badge ${currentPlayer === i ? 'active' : ''}`} style={{ borderColor: HEX[c] }}>
            <span className="avatar" style={{ backgroundColor: HEX[c] }}></span>
            <span className="name">{NAMES[i]}</span>
          </div>
        ))}
        <button className="exit-btn" onClick={onBack}>✕</button>
      </div>
      
      {/* اللوحة الخشبية ثلاثية الأبعاد */}
      <div className="yalla-board-wrapper">
        <div className="wooden-frame">
          <svg viewBox="0 0 15 15" className="yalla-svg">
            <defs>
              {/* تدرجات لونية للخانات */}
              <linearGradient id="redGrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stopColor="#ff5252"/><stop offset="100%" stopColor="#b71c1c"/></linearGradient>
              <linearGradient id="greenGrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stopColor="#69f0ae"/><stop offset="100%" stopColor="#1b5e20"/></linearGradient>
              <linearGradient id="blueGrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stopColor="#40c4ff"/><stop offset="100%" stopColor="#0d47a1"/></linearGradient>
              <linearGradient id="yellowGrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stopColor="#ffff8d"/><stop offset="100%" stopColor="#f57f17"/></linearGradient>
              
              {/* فلتر الظل الداخلي للخانات */}
              <filter id="innerShadow">
                <feOffset dx="0" dy="0"/>
                <feGaussianBlur stdDeviation="0.05" result="offset-blur"/>
                <feComposite operator="out" in="SourceGraphic" in2="offset-blur" result="inverse"/>
                <feFlood floodColor="black" floodOpacity="0.5" result="color"/>
                <feComposite operator="in" in="color" in2="inverse" result="shadow"/>
                <feComposite operator="over" in="shadow" in2="SourceGraphic"/>
              </filter>
            </defs>

            {/* خلفية اللوحة */}
            <rect width="15" height="15" fill="#f5f5f5" rx="1" />
            
            {/* رسم المسار الرئيسي */}
            {[...Array(52)].map((_, i) => {
              const [x, y] = getTokenCoords('red', i, 0); 
              const isSafe = SAFE_SPOTS.includes(i);
              return (
                <rect key={i} x={x} y={y} width="1" height="1" fill={isSafe ? "#e0e0e0" : "#ffffff"} stroke="#bdbdbd" strokeWidth="0.05" filter="url(#innerShadow)"/>
              );
            })}

            {/* مسارات النهاية */}
            {COLORS.map(c => [0,1,2,3,4].map(i => {
               const [x, y] = getTokenCoords(c, 52+i, 0);
               return <rect key={`${c}-home-${i}`} x={x} y={y} width="1" height="1" fill={`url(#${c}Grad)`} stroke="#fff" strokeWidth="0.02" filter="url(#innerShadow)"/>;
            }))}

            {/* البيوت الأربعة */}
            {COLORS.map(c => (
               <g key={`base-${c}`}>
                 <rect x={c === 'red' || c === 'yellow' ? 0 : 9} y={c === 'red' || c === 'green' ? 0 : 9} width="6" height="6" fill={`url(#${c}Grad)`} stroke="#fff" strokeWidth="0.1" rx="0.5" />
                 <rect x={c === 'red' || c === 'yellow' ? 1 : 10} y={c === 'red' || c === 'green' ? 1 : 10} width="4" height="4" fill="#fff" stroke="#e0e0e0" strokeWidth="0.1" rx="0.3" filter="url(#innerShadow)"/>
               </g>
            ))}

            {/* المثلثات الوسطى */}
            <polygon points="6,6 9,6 7.5,7.5" fill="url(#redGrad)" stroke="#fff" strokeWidth="0.05"/>
            <polygon points="9,6 9,9 7.5,7.5" fill="url(#greenGrad)" stroke="#fff" strokeWidth="0.05"/>
            <polygon points="9,9 6,9 7.5,7.5" fill="url(#blueGrad)" stroke="#fff" strokeWidth="0.05"/>
            <polygon points="6,9 6,6 7.5,7.5" fill="url(#yellowGrad)" stroke="#fff" strokeWidth="0.05"/>

            {/* القطع الزجاجية اللامعة */}
            {tokens.map(t => {
              const [cx, cy] = getTokenCoords(t.color, t.pos, parseInt(t.id.split('-')[1]));
              const isMyTurn = t.color === COLORS[currentPlayer];
              const canMove = isMyTurn && hasRolled && (t.pos === -1 ? dice === 6 : t.pos + dice <= 57);
              
              return (
                <g key={t.id} className={`token-group ${canMove ? 'clickable' : ''}`} onClick={() => canMove && moveToken(t.id)}>
                  <circle cx={cx + 0.1} cy={cy + 0.15} r="0.4" fill="rgba(0,0,0,0.4)" />
                  <circle cx={cx} cy={cy} r="0.4" fill={`url(#${t.color}Grad)`} stroke="#fff" strokeWidth="0.08" />
                  <ellipse cx={cx - 0.1} cy={cy - 0.15} rx="0.15" ry="0.08" fill="rgba(255,255,255,0.6)" transform={`rotate(-45 ${cx-0.1} ${cy-0.15})`} />
                </g>
              );
            })}
          </svg>
        </div>
      </div>

      {/* لوحة التحكم السفلية */}
      <div className="yalla-controls">
        {message && <div className="toast-msg">{message}</div>}
        
        <div className="dice-container">
          {dice > 0 ? <DiceFace value={dice} /> : <div className="yalla-dice empty">?</div>}
        </div>

        {!hasRolled ? (
          <button className="yalla-action-btn roll" onClick={rollDice}>رمي الزهر</button>
        ) : (
          <button className="yalla-action-btn pass" onClick={() => endTurn(false)}>تمرير الدور</button>
        )}
      </div>
    </div>
  );
}

export default Ludo;
